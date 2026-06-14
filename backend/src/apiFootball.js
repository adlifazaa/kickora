'use strict';

const config = require('./config');
const { usageTracker } = require('./usageTracker');

const FINISHED_SHORT = new Set(['FT', 'AET', 'PEN', 'AWD', 'WO']);
const UPCOMING_SHORT = new Set(['NS', 'TBD', 'PST']);

function todayIso() {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
}

function statusShort(fixtureItem) {
  return (
    fixtureItem?.fixture?.status?.short ??
    fixtureItem?.status?.short ??
    ''
  ).toUpperCase();
}

function filterByLeague(body, leagueId, season) {
  if (leagueId == null || `${leagueId}`.trim() === '') return body;
  if (!body || !Array.isArray(body.response)) return body;
  const id = parseInt(`${leagueId}`, 10);
  const seasonNum =
    season != null && `${season}`.trim() !== '' ? parseInt(`${season}`, 10) : null;
  const response = body.response.filter((item) => {
    const league = item?.league ?? {};
    if (league.id !== id) return false;
    if (seasonNum != null && league.season !== seasonNum) return false;
    return true;
  });
  return {
    ...body,
    results: response.length,
    response,
  };
}

function filterFixtureResponse(body, predicate) {
  if (!body || !Array.isArray(body.response)) return body;
  const response = body.response.filter((item) => predicate(statusShort(item)));
  return {
    ...body,
    results: response.length,
    response,
  };
}

function buildUrlPattern(path, query = {}) {
  const keys = Object.keys(query).filter(
    (k) => query[k] != null && `${query[k]}`.trim() !== '',
  );
  if (keys.length === 0) return path;
  return `${path}?${keys.sort().join('&')}`;
}

/**
 * @param {string} path
 * @param {Record<string, string|number>} query
 * @param {{ callerRoute?: string, source?: string }} [meta]
 */
async function fetchUpstream(path, query = {}, meta = {}) {
  if (!config.apiFootballKey) {
    const err = new Error('API_FOOTBALL_KEY is not configured on the server');
    err.statusCode = 503;
    err.code = 'not_configured';
    throw err;
  }

  const url = new URL(path, config.apiFootballBaseUrl);
  for (const [key, value] of Object.entries(query)) {
    if (value != null && `${value}`.trim() !== '') {
      url.searchParams.set(key, `${value}`);
    }
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);

  try {
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'x-apisports-key': config.apiFootballKey,
      },
      signal: controller.signal,
    });

    const text = await res.text();
    let body;
    try {
      body = text ? JSON.parse(text) : {};
    } catch {
      const err = new Error('Invalid JSON from API-Football');
      err.statusCode = 502;
      throw err;
    }

    if (res.status === 429) {
      const err = new Error('API-Football rate limit');
      err.statusCode = 429;
      throw err;
    }

    if (!res.ok) {
      const err = new Error(`API-Football HTTP ${res.status}`);
      err.statusCode = res.status >= 500 ? 502 : res.status;
      throw err;
    }

    usageTracker.recordUpstream({
      callerRoute: meta.callerRoute,
      urlPattern: buildUrlPattern(path, query),
      source: meta.source || 'proxy',
    });

    return body;
  } catch (e) {
    if (e.name === 'AbortError') {
      const err = new Error('API-Football request timed out');
      err.statusCode = 504;
      throw err;
    }
    throw e;
  } finally {
    clearTimeout(timeout);
  }
}

function leagueSeasonQuery(req) {
  const league = req.query.competitionId ?? req.query.league;
  const season = req.query.season;
  const out = {};
  if (league != null && `${league}`.trim() !== '') out.league = `${league}`;
  if (season != null && `${season}`.trim() !== '') out.season = `${season}`;
  return out;
}

module.exports = {
  todayIso,
  fetchUpstream,
  filterFixtureResponse,
  filterByLeague,
  statusShort,
  FINISHED_SHORT,
  UPCOMING_SHORT,
  leagueSeasonQuery,
  buildUrlPattern,
};
