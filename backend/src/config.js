'use strict';

function envInt(name, fallback) {
  const raw = process.env[name];
  if (raw == null || raw.trim() === '') return fallback;
  const n = Number.parseInt(raw, 10);
  return Number.isFinite(n) ? n : fallback;
}

const apiFootballKey =
  process.env.API_FOOTBALL_KEY?.trim() ||
  process.env.KICKORA_API_FOOTBALL_KEY?.trim() ||
  '';

const newsApiKey = process.env.NEWS_API_KEY?.trim() || '';

function envBool(name, fallback) {
  const raw = process.env[name];
  if (raw == null || raw.trim() === '') return fallback;
  return raw.trim().toLowerCase() === 'true';
}

module.exports = {
  port: envInt('PORT', 8080),
  apiFootballKey,
  newsApiKey,
  apiFootballBaseUrl:
    process.env.API_FOOTBALL_BASE_URL?.trim() ||
    'https://v3.football.api-sports.io',
  rateLimitMax: envInt('RATE_LIMIT_MAX', 120),
  rateLimitWindowMs: envInt('RATE_LIMIT_WINDOW_MS', 15 * 60 * 1000),
  enableCors: process.env.ENABLE_CORS === 'true',
  trustProxy: process.env.TRUST_PROXY !== 'false',

  notificationsEnabled: envBool('NOTIFICATIONS_ENABLED', false),
  notificationsDryRun: envBool('NOTIFICATIONS_DRY_RUN', true),
  /** Poll interval for live fixtures (seconds). Default 120 to reduce API quota. */
  notificationsPollSeconds: envInt('NOTIFICATIONS_POLL_SECONDS', 120),
  /** Max event API calls per worker poll cycle. */
  notificationsMaxEventCallsPerCycle: envInt('NOTIFICATIONS_MAX_EVENT_CALLS', 15),
  /** World Cup league id — notification worker tracks this league only. */
  notificationsWorldCupLeagueId: envInt('NOTIFICATIONS_WC_LEAGUE_ID', 1),
  /** World Cup season year for league-scoped live fixture polling. */
  notificationsWorldCupSeason: envInt('NOTIFICATIONS_WC_SEASON', 2026),
  notificationsDedupTtlSeconds: envInt('NOTIFICATIONS_DEDUP_TTL_SECONDS', 6 * 60 * 60),
  notificationsDryRunLogMax: envInt('NOTIFICATIONS_DRY_RUN_LOG_MAX', 200),
  firebaseServiceAccountJson:
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim() || '',

  /** Daily upstream API-Football call budget before quota protection kicks in. */
  usageDailyThreshold: envInt('USAGE_DAILY_THRESHOLD', 6000),
  /** Poll interval when quota protection is active (seconds). */
  usageProtectionPollSeconds: envInt('USAGE_PROTECTION_POLL_SECONDS', 300),
};
