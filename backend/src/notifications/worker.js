'use strict';

const { fetchUpstream } = require('../apiFootball');
const { usageTracker } = require('../usageTracker');
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
  const fetchLive =
    deps.fetchLive ??
    (() =>
      fetchUpstream('/fixtures', { live: 'all' }, {
        callerRoute: 'notification-worker/live',
        source: 'notification-worker',
      }));
  const fetchEvents =
    deps.fetchEvents ??
    ((fixtureId) =>
      fetchUpstream('/fixtures/events', { fixture: fixtureId }, {
        callerRoute: 'notification-worker/events',
        source: 'notification-worker',
      }));

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
    eventCallsSkipped: 0,
    quotaProtection: false,
  };

  function quotaProtectionActive() {
    const threshold = config.usageDailyThreshold ?? 6000;
    return usageTracker.isProtectionActive(threshold);
  }

  function effectivePollSeconds() {
    if (quotaProtectionActive()) {
      return Math.max(
        config.usageProtectionPollSeconds ?? 300,
        (config.notificationsPollSeconds ?? 120) * 2,
      );
    }
    return config.notificationsPollSeconds ?? 120;
  }

  /** World Cup + already-tracked fixtures get event polling priority. */
  function shouldPollEvents(snapshot, isFirstSeen) {
    if (quotaProtectionActive()) return false;

    const wcLeague = config.notificationsWorldCupLeagueId ?? 1;
    if (snapshot.leagueId === wcLeague) return true;

    // Non-WC: only continue tracking fixtures we already follow (no seed spam).
    if (isFirstSeen) return false;
    return fixtureState.has(snapshot.fixtureId);
  }

  async function pollOnce() {
    if (!config.notificationsEnabled) return;
    if (pollInFlight) return;
    pollInFlight = true;
    lastPollError = null;

    const protection = quotaProtectionActive();
    let eventCallsThisCycle = 0;
    const maxEvents = config.notificationsMaxEventCallsPerCycle ?? 15;

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
        eventCallsSkipped: 0,
        quotaProtection: protection,
      };

      // World Cup fixtures first when capping event calls.
      const sorted = [...items].sort((a, b) => {
        const aWc =
          parseFixtureSnapshot(a).leagueId ===
          (config.notificationsWorldCupLeagueId ?? 1)
            ? 0
            : 1;
        const bWc =
          parseFixtureSnapshot(b).leagueId ===
          (config.notificationsWorldCupLeagueId ?? 1)
            ? 0
            : 1;
        return aWc - bWc;
      });

      for (const item of sorted) {
        const snapshot = parseFixtureSnapshot(item);
        if (!snapshot.fixtureId) continue;
        seenIds.add(snapshot.fixtureId);

        const prev = fixtureState.get(snapshot.fixtureId);
        const isFirstSeen = !prev;

        if (isFirstSeen) {
          let eventKeys = new Set();
          if (
            shouldPollEvents(snapshot, true) &&
            eventCallsThisCycle < maxEvents
          ) {
            try {
              eventCallsThisCycle += 1;
              const eventsBody = await fetchEvents(snapshot.fixtureId);
              const rows = Array.isArray(eventsBody?.response)
                ? eventsBody.response
                : [];
              eventKeys = detectNewFixtureEvents(new Set(), rows).keys;
            } catch (e) {
              if (e.statusCode === 429) {
                warn(
                  '[kickora-notify] API-Football rate limit — skipping remaining event fetches this cycle',
                );
                break;
              }
              warn(
                `[kickora-notify] events seed failed fixture=${snapshot.fixtureId} err=${e.message}`,
              );
            }
          } else {
            stats.eventCallsSkipped += 1;
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
        if (
          shouldPollEvents(snapshot, false) &&
          eventCallsThisCycle < maxEvents
        ) {
          try {
            eventCallsThisCycle += 1;
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
              warn(
                '[kickora-notify] API-Football rate limit — skipping remaining event fetches this cycle',
              );
              break;
            }
            warn(
              `[kickora-notify] events fetch failed fixture=${snapshot.fixtureId} err=${e.message}`,
            );
          }
        } else {
          stats.eventCallsSkipped += 1;
        }

        fixtureState.set(snapshot.fixtureId, { snapshot, eventKeys });
      }

      for (const id of fixtureState.keys()) {
        if (!seenIds.has(id)) fixtureState.delete(id);
      }

      lastPollAt = new Date().toISOString();
      lastPollStats = stats;
      log(
        `[kickora-notify] poll complete live=${stats.liveFixtures} statusEvents=${stats.statusEvents} fixtureEvents=${stats.fixtureEvents} eventCalls=${eventCallsThisCycle} skipped=${stats.eventCallsSkipped} sent=${stats.notificationsSent} quotaProtection=${protection} dryRun=${config.notificationsDryRun}`,
      );
    } catch (e) {
      lastPollError = e.message;
      if (e.statusCode === 429) {
        warn(
          '[kickora-notify] API-Football rate limit on live fixtures — will retry next cycle',
        );
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

    log(
      `[kickora-notify] worker starting interval=${effectivePollSeconds()}s maxEventCalls=${config.notificationsMaxEventCallsPerCycle} dryRun=${config.notificationsDryRun} realFcm=${sender.canSendReal()}`,
    );

    const tick = () => {
      pollOnce()
        .catch((e) =>
          warn(`[kickora-notify] unhandled poll error: ${e.message}`),
        )
        .finally(() => {
          const delayMs = Math.max(15, effectivePollSeconds()) * 1000;
          timer = setTimeout(tick, delayMs);
          timer.unref?.();
        });
    };

    tick();
  }

  function stop() {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
  }

  function getStatus() {
    return {
      enabled: config.notificationsEnabled,
      dryRun: config.notificationsDryRun,
      pollSeconds: config.notificationsPollSeconds,
      effectivePollSeconds: effectivePollSeconds(),
      maxEventCallsPerCycle: config.notificationsMaxEventCallsPerCycle,
      quotaProtectionActive: quotaProtectionActive(),
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
