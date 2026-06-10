'use strict';

const SECRET_MARKERS = [
  'private_key',
  'BEGIN PRIVATE KEY',
  'service_account',
  'client_email',
  'firebase-adminsdk',
  'x-apisports-key',
  'API_FOOTBALL_KEY',
  'FIREBASE_SERVICE_ACCOUNT_JSON',
];

/**
 * Whitelist-only public status for HTTP responses (never includes secrets).
 * @param {object} status from worker.getStatus()
 */
function toPublicNotificationStatus(status) {
  const stats = status.lastPollStats ?? {};
  return {
    enabled: Boolean(status.enabled),
    dryRun: Boolean(status.dryRun),
    running: Boolean(status.running),
    pollInFlight: Boolean(status.pollInFlight),
    pollSeconds: Number(status.pollSeconds) || 0,
    realFcmConfigured: Boolean(status.realFcmConfigured),
    realFcmActive: Boolean(status.realFcmActive),
    lastPollAt: status.lastPollAt ?? null,
    lastPollError: sanitizeErrorMessage(status.lastPollError),
    lastPollStats: {
      liveFixtures: Number(stats.liveFixtures) || 0,
      statusEvents: Number(stats.statusEvents) || 0,
      fixtureEvents: Number(stats.fixtureEvents) || 0,
      notificationsSent: Number(stats.notificationsSent) || 0,
      notificationsSkipped: Number(stats.notificationsSkipped) || 0,
    },
    trackedFixtures: Number(status.trackedFixtures) || 0,
    dedupEntries: Number(status.dedupEntries) || 0,
    dryRunLogSize: Number(status.dryRunLogSize) || 0,
  };
}

function sanitizeErrorMessage(message) {
  if (message == null || message === '') return null;
  const text = String(message);
  for (const marker of SECRET_MARKERS) {
    if (text.includes(marker)) return 'upstream_error';
  }
  return text;
}

/**
 * @param {string} json
 */
function assertNoSecretsInJson(json) {
  const lower = json.toLowerCase();
  for (const marker of SECRET_MARKERS) {
    if (lower.includes(marker.toLowerCase())) {
      throw new Error(`Secret marker leaked in JSON: ${marker}`);
    }
  }
}

module.exports = {
  toPublicNotificationStatus,
  assertNoSecretsInJson,
  SECRET_MARKERS,
};
