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
    if (Date.now() >= entry.expiresAt) {
      this._store.delete(key);
      return null;
    }
    return entry.body;
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

/** TTL seconds per Kickora route pattern (see docs/backend_proxy_caching.md). */
const ROUTE_TTL_SECONDS = [
  { pattern: /^\/matches\/live$/, ttl: 60 },
  { pattern: /^\/matches\/today$/, ttl: 5 * 60 },
  { pattern: /^\/matches\/upcoming$/, ttl: 5 * 60 },
  { pattern: /^\/matches\/finished$/, ttl: 10 * 60 },
  { pattern: /^\/competitions$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/competitions\/\d+$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/competitions\/\d+\/top-scorers$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/standings\/\d+$/, ttl: 10 * 60 },
  { pattern: /^\/teams\/\d+$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/players\/search$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/players\/\d+$/, ttl: 24 * 60 * 60 },
  { pattern: /^\/matches\/\d+$/, ttl: 2 * 60 },
  { pattern: /^\/matches\/\d+\/events$/, ttl: 2 * 60 },
  { pattern: /^\/matches\/\d+\/statistics$/, ttl: 2 * 60 },
  { pattern: /^\/matches\/\d+\/lineups$/, ttl: 2 * 60 },
];

function ttlForPath(pathname) {
  for (const { pattern, ttl } of ROUTE_TTL_SECONDS) {
    if (pattern.test(pathname)) return ttl;
  }
  return 60;
}

function cacheKey(req) {
  const url = new URL(req.originalUrl || req.url, 'http://local');
  const qs = [...url.searchParams.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}=${v}`)
    .join('&');
  return `${req.method}:${url.pathname}${qs ? `?${qs}` : ''}`;
}

module.exports = {
  MemoryCache,
  ttlForPath,
  cacheKey,
};
