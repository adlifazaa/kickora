'use strict';

const express = require('express');
const {
  todayIso,
  fetchUpstream,
  filterFixtureResponse,
  statusShort,
  FINISHED_SHORT,
  UPCOMING_SHORT,
  leagueSeasonQuery,
} = require('./apiFootball');
const { cacheKey, ttlForPath, ttlForMatchResource } = require('./cache');
const { fetchWorldCupNews } = require('./newsProvider');
const { usageTracker } = require('./usageTracker');
const config = require('./config');

/**
 * @param {{ cache: import('./cache').MemoryCache, sendJson: Function }} deps
 */
function createRouter({ cache, sendJson }) {
  const router = express.Router();

  function protectionActive() {
    return usageTracker.isProtectionActive(config.usageDailyThreshold);
  }

  function matchStatusFromBody(body) {
    const item = body?.response?.[0];
    return statusShort(item);
  }

  function matchStatusFromCache(matchId) {
    const cached = cache.get(`GET:/matches/${matchId}`);
    if (cached) return matchStatusFromBody(cached);
    const stale = cache.getStale(`GET:/matches/${matchId}`);
    if (stale) return matchStatusFromBody(stale);
    return '';
  }

  async function cachedFetch(req, res, fetcher, options = {}) {
    const pathname = new URL(req.originalUrl, 'http://x').pathname;
    const key = cacheKey(req);
    const hit = cache.get(key);
    if (hit) {
      usageTracker.recordCache(pathname, true);
      res.setHeader('X-Kickora-Cache', 'HIT');
      return sendJson(res, hit);
    }

    usageTracker.recordCache(pathname, false);

    if (protectionActive() && options.allowStaleOnProtection !== false) {
      const stale = cache.getStale(key);
      if (stale) {
        res.setHeader('X-Kickora-Cache', 'STALE');
        res.setHeader('X-Kickora-Quota-Protection', 'active');
        return sendJson(res, stale);
      }
    }

    const body = await fetcher();
    let ttl = options.ttlOverride ?? ttlForPath(pathname);

    if (options.matchStatus != null) {
      ttl = ttlForMatchResource(pathname, options.matchStatus);
    } else if (/^\/matches\/\d+$/.test(pathname)) {
      ttl = ttlForMatchResource(pathname, matchStatusFromBody(body));
    } else if (/^\/matches\/\d+\/(events|statistics|lineups)$/.test(pathname)) {
      const matchId = pathname.split('/')[2];
      ttl = ttlForMatchResource(pathname, matchStatusFromCache(matchId));
    }

    if (protectionActive()) {
      ttl = Math.max(ttl, ttl * 3);
    }

    cache.set(key, body, ttl);
    res.setHeader('X-Kickora-Cache', 'MISS');
    if (protectionActive()) {
      res.setHeader('X-Kickora-Quota-Protection', 'active');
    }
    return sendJson(res, body);
  }

  function upstreamMeta(callerRoute) {
    return { callerRoute, source: 'proxy' };
  }

  router.get('/health', (_req, res) => {
    res.json({
      ok: true,
      service: 'kickora-backend-proxy',
      timestamp: new Date().toISOString(),
    });
  });

  router.get('/usage/status', (_req, res) => {
    res.json({
      ok: true,
      ...usageTracker.getStatus({
        dailyThreshold: config.usageDailyThreshold,
        pollSeconds: config.notificationsPollSeconds,
        protectionPollSeconds: config.usageProtectionPollSeconds,
      }),
    });
  });

  router.get('/matches/live', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const q = { live: 'all', ...leagueSeasonQuery(req) };
      return fetchUpstream('/fixtures', q, upstreamMeta('/matches/live'));
    }).catch(next);
  });

  router.get('/matches/today', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const date = req.query.date ?? todayIso();
      return fetchUpstream(
        '/fixtures',
        { date, ...leagueSeasonQuery(req) },
        upstreamMeta('/matches/today'),
      );
    }).catch(next);
  });

  router.get('/matches/upcoming', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const leagueQ = leagueSeasonQuery(req);
      let body;
      if (req.query.date) {
        body = await fetchUpstream(
          '/fixtures',
          { date: req.query.date, ...leagueQ },
          upstreamMeta('/matches/upcoming'),
        );
      } else if (Object.keys(leagueQ).length === 0) {
        body = await fetchUpstream(
          '/fixtures',
          { next: '50' },
          upstreamMeta('/matches/upcoming'),
        );
      } else {
        body = await fetchUpstream(
          '/fixtures',
          { date: req.query.date ?? todayIso(), ...leagueQ },
          upstreamMeta('/matches/upcoming'),
        );
      }
      return filterFixtureResponse(
        body,
        (short) => UPCOMING_SHORT.has(short) || short === '',
      );
    }).catch(next);
  });

  router.get('/matches/finished', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const body = await fetchUpstream(
        '/fixtures',
        {
          date: req.query.date ?? todayIso(),
          ...leagueSeasonQuery(req),
        },
        upstreamMeta('/matches/finished'),
      );
      return filterFixtureResponse(body, (short) => FINISHED_SHORT.has(short));
    }).catch(next);
  });

  router.get('/news/world-cup', (req, res, next) => {
    cachedFetch(req, res, () => fetchWorldCupNews()).catch(next);
  });

  router.get('/competitions', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/leagues',
        { current: 'true' },
        upstreamMeta('/competitions'),
      ),
    ).catch(next);
  });

  /** All fixtures for a league/season — one call replaces per-day fetches (World Cup hub). */
  router.get('/competitions/:id/matches', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/fixtures',
        { league: req.params.id, season: req.query.season },
        upstreamMeta('/competitions/:id/matches'),
      ),
    ).catch(next);
  });

  router.get('/competitions/:id/top-scorers', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/players/topscorers',
        { league: req.params.id, season: req.query.season },
        upstreamMeta('/competitions/:id/top-scorers'),
      ),
    ).catch(next);
  });

  router.get('/competitions/:id', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/leagues',
        { id: req.params.id, season: req.query.season },
        upstreamMeta('/competitions/:id'),
      ),
    ).catch(next);
  });

  router.get('/standings/:competitionId', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/standings',
        { league: req.params.competitionId, season: req.query.season },
        upstreamMeta('/standings/:competitionId'),
      ),
    ).catch(next);
  });

  router.get('/teams/:competitionId', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/teams',
        { league: req.params.competitionId, season: req.query.season },
        upstreamMeta('/teams/:competitionId'),
      ),
    ).catch(next);
  });

  router.get('/players/search', (req, res, next) => {
    const q = (req.query.q ?? '').trim();
    if (!q) {
      return sendJson(res, {
        get: '/players',
        parameters: { search: '' },
        errors: [],
        results: 0,
        response: [],
      });
    }
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/players',
        { search: q, season: req.query.season },
        upstreamMeta('/players/search'),
      ),
    ).catch(next);
  });

  router.get('/players/:id', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/players',
        { id: req.params.id, season: req.query.season },
        upstreamMeta('/players/:id'),
      ),
    ).catch(next);
  });

  router.get('/matches/:id', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/fixtures',
        { id: req.params.id },
        upstreamMeta('/matches/:id'),
      ),
    ).catch(next);
  });

  router.get('/matches/:id/events', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/fixtures/events',
        { fixture: req.params.id },
        upstreamMeta('/matches/:id/events'),
      ),
    ).catch(next);
  });

  router.get('/matches/:id/statistics', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/fixtures/statistics',
        { fixture: req.params.id },
        upstreamMeta('/matches/:id/statistics'),
      ),
    ).catch(next);
  });

  router.get('/matches/:id/lineups', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream(
        '/fixtures/lineups',
        { fixture: req.params.id },
        upstreamMeta('/matches/:id/lineups'),
      ),
    ).catch(next);
  });

  return router;
}

module.exports = { createRouter };
