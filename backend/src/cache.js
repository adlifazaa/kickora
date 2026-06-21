'use strict';

/** In-memory TTL cache (single instance). Replace with Redis if you scale horizontally. */
class MemoryCache {
  constructor() {
    /** @type {Map<string, { expiresAt: number, body: object }>} */
    this._store = new Map();
  }

  get(key) {
    const entry = this._store.get(key);
    if (!entry) return null;
    if (Date.now() >= entry.expiresAt) return null;
    return entry.body;
  }

  /** Expired entries kept until [purgeExpired] — used for quota-protection fallback. */
  getStale(key) {
    const entry = this._store.get(key);
    return entry ? entry.body : null;
  }

  set(key, body, ttlSeconds) {
    if (ttlSeconds <= 0) return;
    this._store.set(key, {
      expiresAt: Date.now() + ttlSeconds * 1000,
      body,
    });
  }

  purgeExpired() {
    const now = Date.now();
    for (const [key, entry] of this._store) {
      if (now >= entry.expiresAt) this._store.delete(key);
    }
  }
}

const LIVE_STATUSES = new Set([
  '1H', '2H', 'LIVE', 'INPLAY', 'ET', 'BT', 'P', 'INT', 'HT',
]);
const FINISHED_STATUSES = new Set(['FT', 'AET', 'PEN', 'AWD', 'WO']);

/** TTL seconds per Kickora route pattern. */
const ROUTE_TTL_SECONDS = [
  { pattern: /^\/news\/world-cup$/, ttl: 30 * 60 },
  { pattern: /^\/matches\/live$/, ttl: 45 },
  { pattern: /^\/matches\/today$/, ttl: 3 * 60 },
  { pattern: /^\/matches\/upcoming$/, ttl: 10 * 60 },
  { pattern: /^\/matches\/finished$/, ttl: 12 * 60 * 60 },
  { pattern: /^\/competitions$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/competitions\/\d+$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/competitions\/\d+\/top-scorers$/, ttl: 20 * 60 },
  { pattern: /^\/competitions\/\d+\/matches$/, ttl: 15 * 60 },
  { pattern: /^\/standings\/\d+$/, ttl: 15 * 60 },
  { pattern: /^\/teams\/\d+$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/players\/search$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/players\/\d+$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/matches\/\d+$/, ttl: 45 },
  { pattern: /^\/matches\/\d+\/events$/, ttl: 45 },
  { pattern: /^\/matches\/\d+\/statistics$/, ttl: 45 },
  { pattern: /^\/matches\/\d+\/lineups$/, ttl: 45 },
];

function ttlForPath(pathname) {
  for (const { pattern, ttl } of ROUTE_TTL_SECONDS) {
    if (pattern.test(pathname)) return ttl;
  }
  return 60;
}

function statusShortFromItem(item) {
  return (
    item?.fixture?.status?.short ??
    item?.status?.short ??
    ''
  ).toUpperCase();
}

/** True when any fixture in an API-Football list response is in play. */
function responseHasLiveFixtures(body) {
  if (!body || !Array.isArray(body.response)) return false;
  return body.response.some((item) =>
    LIVE_STATUSES.has(statusShortFromItem(item)),
  );
}

/** Shorter TTL when a fixture list includes live matches. */
function ttlForFixtureListBody(body, defaultTtlSeconds) {
  if (responseHasLiveFixtures(body)) return 45;
  return defaultTtlSeconds;
}

/** Status-aware TTL for match detail and sub-resources. */
function ttlForMatchStatus(statusShort) {
  const s = (statusShort || '').toUpperCase();
  if (LIVE_STATUSES.has(s)) return 45;
  if (FINISHED_STATUSES.has(s)) return 24 * 60 * 60;
  if (!s) return 45;
  return 60 * 60;
}

function ttlForMatchResource(pathname, statusShort) {
  if (
    /^\/matches\/\d+$/.test(pathname) ||
    /^\/matches\/\d+\/(events|statistics|lineups)$/.test(pathname)
  ) {
    return ttlForMatchStatus(statusShort);
  }
  return ttlForPath(pathname);
}

function cacheKey(req) {
  const url = new URL(req.originalUrl || req.url, 'http://local');
  const qs = [...url.searchParams.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}=${v}`)
    .join('&');
  return `${req.method}:${url.pathname}${qs ? `?${qs}` : ''}`;
}

/** One upstream fetch per calendar day — league filters are applied in-memory. */
function canonicalTodayCacheKey(date) {
  return `GET:/matches/today?date=${date}`;
}

module.exports = {
  MemoryCache,
  ttlForPath,
  ttlForMatchStatus,
  ttlForMatchResource,
  ttlForFixtureListBody,
  responseHasLiveFixtures,
  statusShortFromItem,
  cacheKey,
  canonicalTodayCacheKey,
  LIVE_STATUSES,
  FINISHED_STATUSES,
};
