'use strict';

const { fetchUpstream } = require('../apiFootball');
const { DedupStore } = require('./dedupStore');
const { DryRunLog } = require('./dryRunLog');
const {
  detectNewFixtureEvents,
  detectStatusEvents,
  parseFixtureSnapshot,
} = require('./eventDetector');
const { createFcmSender } = require('./fcmSender');

/**
 * @param {import('../config')} config
 * @param {object} [deps]
 */
function createNotificationWorker(config, deps = {}) {
  const fetchLive = deps.fetchLive ?? (() => fetchUpstream('/fixtures', { live: 'all' }));
  const fetchEvents =
    deps.fetchEvents ??
    ((fixtureId) =>
      fetchUpstream('/fixtures/events', { fixture: fixtureId }));

  const dedupStore =
    deps.dedupStore ??
    new DedupStore({ ttlSeconds: config.notificationsDedupTtlSeconds });
  const dryRunLog =
    deps.dryRunLog ?? new DryRunLog(config.notificationsDryRunLogMax);

  const log = deps.log ?? console.log;
  const warn = deps.warn ?? console.warn;

  const sender = createFcmSender(config, {
    dedupStore,
    dryRunLog,
    log,
    warn,
  });

  /** @type {Map<number, { snapshot: object, eventKeys: Set<string> }>} */
  const fixtureState = new Map();

  let timer = null;
  let pollInFlight = false;
  let lastPollAt = null;
  let lastPollError = null;
  let lastPollStats = {
    liveFixtures: 0,
    statusEvents: 0,
    fixtureEvents: 0,
    notificationsSent: 0,
    notificationsSkipped: 0,
  };

  async function pollOnce() {
    if (!config.notificationsEnabled) return;
    if (pollInFlight) return;
    pollInFlight = true;
    lastPollError = null;

    try {
      const body = await fetchLive();
      const items = Array.isArray(body?.response) ? body.response : [];
      const seenIds = new Set();
      const stats = {
        liveFixtures: items.length,
        statusEvents: 0,
        fixtureEvents: 0,
        notificationsSent: 0,
        notificationsSkipped: 0,
      };

      for (const item of items) {
        const snapshot = parseFixtureSnapshot(item);
        if (!snapshot.fixtureId) continue;
        seenIds.add(snapshot.fixtureId);

        const prev = fixtureState.get(snapshot.fixtureId);

        // First time we see a live fixture: seed event keys only (no historic spam).
        if (!prev) {
          let eventKeys = new Set();
          try {
            const eventsBody = await fetchEvents(snapshot.fixtureId);
            const rows = Array.isArray(eventsBody?.response)
              ? eventsBody.response
              : [];
            eventKeys = detectNewFixtureEvents(new Set(), rows).keys;
          } catch (e) {
            if (e.statusCode === 429) {
              warn('[kickora-notify] API-Football rate limit — skipping remaining event fetches this cycle');
              break;
            }
            warn(
              `[kickora-notify] events seed failed fixture=${snapshot.fixtureId} err=${e.message}`,
            );
          }
          fixtureState.set(snapshot.fixtureId, { snapshot, eventKeys });
          continue;
        }

        const statusEvents = detectStatusEvents(prev.snapshot, snapshot);
        stats.statusEvents += statusEvents.length;

        for (const ev of statusEvents) {
          const result = await sender.sendMatchEvent({
            type: ev.type,
            snapshot,
            minute: ev.minute,
          });
          stats.notificationsSent += result.sent;
          stats.notificationsSkipped += result.skipped;
        }

        let eventKeys = prev.eventKeys;
        try {
          const eventsBody = await fetchEvents(snapshot.fixtureId);
          const rows = Array.isArray(eventsBody?.response)
            ? eventsBody.response
            : [];
          const detected = detectNewFixtureEvents(eventKeys, rows);
          eventKeys = detected.keys;
          stats.fixtureEvents += detected.events.length;

          for (const ev of detected.events) {
            const result = await sender.sendMatchEvent({
              type: ev.wireType,
              snapshot,
              teamId: ev.teamId,
              teamName: ev.teamName,
              playerId: ev.playerId,
              minute: ev.minute,
            });
            stats.notificationsSent += result.sent;
            stats.notificationsSkipped += result.skipped;
          }
        } catch (e) {
          if (e.statusCode === 429) {
            warn('[kickora-notify] API-Football rate limit — skipping remaining event fetches this cycle');
            break;
          }
          warn(
            `[kickora-notify] events fetch failed fixture=${snapshot.fixtureId} err=${e.message}`,
          );
        }

        fixtureState.set(snapshot.fixtureId, { snapshot, eventKeys });
      }

      for (const id of fixtureState.keys()) {
        if (!seenIds.has(id)) fixtureState.delete(id);
      }

      lastPollAt = new Date().toISOString();
      lastPollStats = stats;
      log(
        `[kickora-notify] poll complete live=${stats.liveFixtures} statusEvents=${stats.statusEvents} fixtureEvents=${stats.fixtureEvents} sent=${stats.notificationsSent} skipped=${stats.notificationsSkipped} dryRun=${config.notificationsDryRun}`,
      );
    } catch (e) {
      lastPollError = e.message;
      if (e.statusCode === 429) {
        warn('[kickora-notify] API-Football rate limit on live fixtures — will retry next cycle');
      } else {
        warn(`[kickora-notify] poll failed: ${e.message}`);
      }
    } finally {
      pollInFlight = false;
    }
  }

  function start() {
    if (!config.notificationsEnabled) {
      log('[kickora-notify] worker disabled (NOTIFICATIONS_ENABLED=false)');
      return;
    }

    const intervalMs = Math.max(15, config.notificationsPollSeconds) * 1000;
    log(
      `[kickora-notify] worker starting interval=${config.notificationsPollSeconds}s dryRun=${config.notificationsDryRun} realFcm=${sender.canSendReal()}`,
    );

    timer = setInterval(() => {
      pollOnce().catch((e) => warn(`[kickora-notify] unhandled poll error: ${e.message}`));
    }, intervalMs);
    timer.unref?.();

    pollOnce().catch((e) => warn(`[kickora-notify] initial poll error: ${e.message}`));
  }

  function stop() {
    if (timer) {
      clearInterval(timer);
      timer = null;
    }
  }

  function getStatus() {
    return {
      enabled: config.notificationsEnabled,
      dryRun: config.notificationsDryRun,
      pollSeconds: config.notificationsPollSeconds,
      realFcmConfigured: Boolean(config.firebaseServiceAccountJson),
      realFcmActive: Boolean(sender.canSendReal()),
      running: Boolean(timer),
      pollInFlight,
      lastPollAt,
      lastPollError,
      lastPollStats,
      trackedFixtures: fixtureState.size,
      dedupEntries: dedupStore.size(),
      dryRunLogSize: dryRunLog.size,
    };
  }

  /**
   * Inject a synthetic event for admin testing (always respects enabled/dedup/dry-run).
   */
  async function testDryRunEvent(event) {
    const snapshot = event.snapshot;
    return sender.sendMatchEvent({
      type: event.type,
      snapshot,
      teamId: event.teamId ?? null,
      teamName: event.teamName ?? null,
      playerId: event.playerId ?? null,
      minute: event.minute ?? null,
    });
  }

  return {
    start,
    stop,
    pollOnce,
    getStatus,
    testDryRunEvent,
    dryRunLog,
    dedupStore,
    fixtureState,
    sender,
  };
}

module.exports = { createNotificationWorker };
