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

function envBool(name, fallback) {
  const raw = process.env[name];
  if (raw == null || raw.trim() === '') return fallback;
  return raw.trim().toLowerCase() === 'true';
}

module.exports = {
  port: envInt('PORT', 8080),
  apiFootballKey,
  apiFootballBaseUrl:
    process.env.API_FOOTBALL_BASE_URL?.trim() ||
    'https://v3.football.api-sports.io',
  rateLimitMax: envInt('RATE_LIMIT_MAX', 120),
  rateLimitWindowMs: envInt('RATE_LIMIT_WINDOW_MS', 15 * 60 * 1000),
  enableCors: process.env.ENABLE_CORS === 'true',
  trustProxy: process.env.TRUST_PROXY !== 'false',

  notificationsEnabled: envBool('NOTIFICATIONS_ENABLED', false),
  notificationsDryRun: envBool('NOTIFICATIONS_DRY_RUN', true),
  notificationsPollSeconds: envInt('NOTIFICATIONS_POLL_SECONDS', 60),
  notificationsDedupTtlSeconds: envInt('NOTIFICATIONS_DEDUP_TTL_SECONDS', 6 * 60 * 60),
  notificationsDryRunLogMax: envInt('NOTIFICATIONS_DRY_RUN_LOG_MAX', 200),
  firebaseServiceAccountJson:
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim() || '',
};
