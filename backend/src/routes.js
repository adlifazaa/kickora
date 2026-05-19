'use strict';

const express = require('express');
const {
  todayIso,
  fetchUpstream,
  filterFixtureResponse,
  FINISHED_SHORT,
  UPCOMING_SHORT,
  leagueSeasonQuery,
} = require('./apiFootball');
const { cacheKey, ttlForPath } = require('./cache');

/**
 * @param {{ cache: import('./cache').MemoryCache, sendJson: Function }} deps
 */
function createRouter({ cache, sendJson }) {
  const router = express.Router();

  async function cachedFetch(req, res, fetcher) {
    const key = cacheKey(req);
    const hit = cache.get(key);
    if (hit) {
      res.setHeader('X-Kickora-Cache', 'HIT');
      return sendJson(res, hit);
    }

    const body = await fetcher();
    const ttl = ttlForPath(new URL(req.originalUrl, 'http://x').pathname);
    cache.set(key, body, ttl);
    res.setHeader('X-Kickora-Cache', 'MISS');
    return sendJson(res, body);
  }

  router.get('/health', (_req, res) => {
    res.json({
      ok: true,
      service: 'kickora-backend-proxy',
      timestamp: new Date().toISOString(),
    });
  });

  router.get('/matches/live', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const q = { live: 'all', ...leagueSeasonQuery(req) };
      return fetchUpstream('/fixtures', q);
    }).catch(next);
  });

  router.get('/matches/today', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const date = req.query.date ?? todayIso();
      return fetchUpstream('/fixtures', { date, ...leagueSeasonQuery(req) });
    }).catch(next);
  });

  router.get('/matches/upcoming', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const leagueQ = leagueSeasonQuery(req);
      let body;
      if (req.query.date) {
        body = await fetchUpstream('/fixtures', {
          date: req.query.date,
          ...leagueQ,
        });
      } else if (Object.keys(leagueQ).length === 0) {
        body = await fetchUpstream('/fixtures', { next: '50' });
      } else {
        body = await fetchUpstream('/fixtures', {
          date: req.query.date ?? todayIso(),
          ...leagueQ,
        });
      }
      return filterFixtureResponse(
        body,
        (short) => UPCOMING_SHORT.has(short) || short === '',
      );
    }).catch(next);
  });

  router.get('/matches/finished', (req, res, next) => {
    cachedFetch(req, res, async () => {
      const body = await fetchUpstream('/fixtures', {
        date: req.query.date ?? todayIso(),
        ...leagueSeasonQuery(req),
      });
      return filterFixtureResponse(body, (short) => FINISHED_SHORT.has(short));
    }).catch(next);
  });

  router.get('/competitions', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/leagues', { current: 'true' }),
    ).catch(next);
  });

  router.get('/competitions/:id/top-scorers', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/players/topscorers', {
        league: req.params.id,
        season: req.query.season,
      }),
    ).catch(next);
  });

  router.get('/competitions/:id', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/leagues', {
        id: req.params.id,
        season: req.query.season,
      }),
    ).catch(next);
  });

  router.get('/standings/:competitionId', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/standings', {
        league: req.params.competitionId,
        season: req.query.season,
      }),
    ).catch(next);
  });

  router.get('/teams/:competitionId', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/teams', {
        league: req.params.competitionId,
        season: req.query.season,
      }),
    ).catch(next);
  });

  router.get('/players/search', (req, res, next) => {
    const q = (req.query.q ?? '').trim();
    if (!q) {
      return sendJson(res, { get: '/players', parameters: { search: '' }, errors: [], results: 0, response: [] });
    }
    cachedFetch(req, res, () =>
      fetchUpstream('/players', { search: q, season: req.query.season }),
    ).catch(next);
  });

  router.get('/players/:id', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/players', { id: req.params.id, season: req.query.season }),
    ).catch(next);
  });

  router.get('/matches/:id', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/fixtures', { id: req.params.id }),
    ).catch(next);
  });

  router.get('/matches/:id/events', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/fixtures/events', { fixture: req.params.id }),
    ).catch(next);
  });

  router.get('/matches/:id/statistics', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/fixtures/statistics', { fixture: req.params.id }),
    ).catch(next);
  });

  router.get('/matches/:id/lineups', (req, res, next) => {
    cachedFetch(req, res, () =>
      fetchUpstream('/fixtures/lineups', { fixture: req.params.id }),
    ).catch(next);
  });

  return router;
}

module.exports = { createRouter };
