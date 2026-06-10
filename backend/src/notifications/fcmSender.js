'use strict';

const { buildTopicSendKey } = require('./dedupStore');
const { buildNotificationPayload } = require('./payloadBuilder');
const { topicsForMatchEvent } = require('./topics');

/**
 * @param {import('../config')} config
 */
function createFcmSender(config, deps = {}) {
  const dryRunLog = deps.dryRunLog;
  const dedupStore = deps.dedupStore;
  const log = deps.log ?? console.log;
  const warn = deps.warn ?? console.warn;

  let admin = null;
  let messaging = null;
  let initError = null;

  function canSendReal() {
    return (
      config.notificationsEnabled &&
      !config.notificationsDryRun &&
      config.firebaseServiceAccountJson
    );
  }

  function ensureFirebase() {
    if (messaging) return messaging;
    if (initError) throw initError;
    if (!config.firebaseServiceAccountJson) {
      initError = new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not configured');
      throw initError;
    }
    try {
      // Lazy require so tests/disabled mode never load firebase-admin.
      // eslint-disable-next-line global-require
      admin = require('firebase-admin');
      if (!admin.apps.length) {
        const credentials = JSON.parse(config.firebaseServiceAccountJson);
        admin.initializeApp({
          credential: admin.credential.cert(credentials),
        });
      }
      messaging = admin.messaging();
      return messaging;
    } catch (e) {
      initError = e;
      throw e;
    }
  }

  /**
   * Fan out one logical match event to all relevant topics.
   * @param {{
   *   type: string,
   *   snapshot: object,
   *   teamId?: number|null,
   *   teamName?: string|null,
   *   playerId?: number|null,
   *   minute?: string|null,
   * }} event
   * @returns {Promise<{ sent: number, skipped: number, dryRun: boolean }>}
   */
  async function sendMatchEvent(event) {
    if (!config.notificationsEnabled) {
      return { sent: 0, skipped: 0, dryRun: false, disabled: true };
    }

    const snapshot = event.snapshot;
    const topics = topicsForMatchEvent({
      fixtureId: snapshot.fixtureId,
      homeTeamId: snapshot.homeTeamId,
      awayTeamId: snapshot.awayTeamId,
      leagueId: snapshot.leagueId,
    });

    let sent = 0;
    let skipped = 0;
    const dryRun = config.notificationsDryRun;

    for (const topic of topics) {
      const payload = buildNotificationPayload({
        type: event.type,
        fixtureId: snapshot.fixtureId,
        homeTeam: snapshot.homeTeam,
        awayTeam: snapshot.awayTeam,
        homeScore: snapshot.homeScore,
        awayScore: snapshot.awayScore,
        homeTeamId: snapshot.homeTeamId,
        awayTeamId: snapshot.awayTeamId,
        leagueId: snapshot.leagueId,
        teamId: event.teamId ?? null,
        teamName: event.teamName ?? null,
        playerId: event.playerId ?? null,
        minute: event.minute ?? null,
        topic,
      });

      const topicKey = buildTopicSendKey(payload.dedupKey, topic);
      if (!dedupStore.tryClaim(topicKey)) {
        skipped += 1;
        continue;
      }

      if (dryRun) {
        const entry = {
          mode: 'dry_run',
          topic: payload.topic,
          title: payload.title,
          body: payload.body,
          data: payload.data,
          dedupKey: payload.dedupKey,
          topicSendKey: topicKey,
        };
        dryRunLog?.append(entry);
        log(
          `[kickora-notify:dry-run] topic=${payload.topic} dedup=${payload.dedupKey} title="${payload.title}" body="${payload.body}" data=${JSON.stringify(payload.data)}`,
        );
        sent += 1;
        continue;
      }

      try {
        const msg = {
          topic: payload.topic,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: stringifyData(payload.data),
          android: { priority: 'high' },
        };
        const fcm = ensureFirebase();
        await fcm.send(msg);
        log(
          `[kickora-notify:sent] topic=${payload.topic} dedup=${payload.dedupKey}`,
        );
        sent += 1;
      } catch (e) {
        warn(
          `[kickora-notify:error] topic=${payload.topic} dedup=${payload.dedupKey} err=${e.message}`,
        );
      }
    }

    return { sent, skipped, dryRun };
  }

  return {
    canSendReal,
    ensureFirebase,
    sendMatchEvent,
  };
}

/** FCM data values must be strings. */
function stringifyData(data) {
  const out = {};
  for (const [key, value] of Object.entries(data)) {
    out[key] = value == null ? '' : String(value);
  }
  return out;
}

module.exports = { createFcmSender, stringifyData };
