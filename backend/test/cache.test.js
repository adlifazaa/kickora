'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ttlForPath,
  ttlForMatchStatus,
  ttlForMatchResource,
  ttlForFixtureListBody,
  responseHasLiveFixtures,
  cacheKey,
  canonicalTodayCacheKey,
} = require('../src/cache');
const {
  leagueSeasonQuery,
  filterFixtureResponse,
  filterByLeague,
} = require('../src/apiFootball');
const { UsageTracker } = require('../src/usageTracker');

test('ttlForPath assigns expected buckets', () => {
  assert.equal(ttlForPath('/news/world-cup'), 30 * 60);
  assert.equal(ttlForPath('/matches/live'), 45);
  assert.equal(ttlForPath('/matches/today'), 3 * 60);
  assert.equal(ttlForPath('/competitions'), 24 * 60 * 60);
  assert.equal(ttlForPath('/competitions/1/top-scorers'), 20 * 60);
  assert.equal(ttlForPath('/competitions/1/matches'), 15 * 60);
  assert.equal(ttlForPath('/standings/39'), 15 * 60);
  assert.equal(ttlForPath('/matches/finished'), 12 * 60 * 60);
  assert.equal(ttlForPath('/matches/upcoming'), 10 * 60);
});

test('ttlForMatchStatus uses live, finished, and upcoming buckets', () => {
  assert.equal(ttlForMatchStatus('1H'), 45);
  assert.equal(ttlForMatchStatus('FT'), 24 * 60 * 60);
  assert.equal(ttlForMatchStatus('NS'), 60 * 60);
  assert.equal(ttlForMatchStatus(''), 45);
});

test('ttlForFixtureListBody shortens TTL when live fixtures present', () => {
  const liveBody = {
    response: [{ fixture: { status: { short: '2H' } } }],
  };
  const quietBody = {
    response: [{ fixture: { status: { short: 'NS' } } }],
  };
  assert.equal(ttlForFixtureListBody(liveBody, 3 * 60), 45);
  assert.equal(ttlForFixtureListBody(quietBody, 3 * 60), 3 * 60);
});

test('responseHasLiveFixtures detects in-play rows', () => {
  assert.equal(
    responseHasLiveFixtures({
      response: [{ fixture: { status: { short: 'HT' } } }],
    }),
    true,
  );
  assert.equal(
    responseHasLiveFixtures({
      response: [{ fixture: { status: { short: 'FT' } } }],
    }),
    false,
  );
});

test('ttlForMatchResource applies status-aware TTL', () => {
  assert.equal(ttlForMatchResource('/matches/123/events', 'FT'), 24 * 60 * 60);
  assert.equal(ttlForMatchResource('/matches/123/events', '1H'), 45);
  assert.equal(ttlForMatchResource('/matches/123/lineups', 'NS'), 60 * 60);
  assert.equal(ttlForMatchResource('/matches/123/lineups', ''), 45);
});

test('cacheKey is stable for query order', () => {
  const reqA = {
    method: 'GET',
    originalUrl: '/matches/today?season=2024&competitionId=39',
  };
  const reqB = {
    method: 'GET',
    originalUrl: '/matches/today?competitionId=39&season=2024',
  };
  assert.equal(cacheKey(reqA), cacheKey(reqB));
});

test('leagueSeasonQuery maps competitionId to league', () => {
  const q = leagueSeasonQuery({
    query: { competitionId: '39', season: '2024' },
  });
  assert.deepEqual(q, { league: '39', season: '2024' });
});

test('filterByLeague keeps only matching league (and optional season)', () => {
  const body = {
    response: [
      { league: { id: 39, season: 2024 }, fixture: { id: 1 } },
      { league: { id: 1, season: 2026 }, fixture: { id: 2 } },
      { league: { id: 39, season: 2025 }, fixture: { id: 3 } },
    ],
  };
  const byLeague = filterByLeague(body, '39');
  assert.equal(byLeague.results, 2);
  const bySeason = filterByLeague(body, '39', '2024');
  assert.equal(bySeason.results, 1);
  assert.equal(bySeason.response[0].fixture.id, 1);
});

test('canonicalTodayCacheKey ignores competition query params', () => {
  assert.equal(
    canonicalTodayCacheKey('2026-06-09'),
    'GET:/matches/today?date=2026-06-09',
  );
});

test('filterFixtureResponse keeps only matching statuses', () => {
  const body = {
    response: [
      { fixture: { status: { short: 'FT' } } },
      { fixture: { status: { short: 'NS' } } },
    ],
  };
  const filtered = filterFixtureResponse(body, (s) => s === 'FT');
  assert.equal(filtered.results, 1);
  assert.equal(filtered.response.length, 1);
});

test('UsageTracker counts upstream and cache stats', () => {
  const tracker = new UsageTracker();
  tracker.recordUpstream({
    callerRoute: '/matches/live',
    urlPattern: '/fixtures?live',
    source: 'proxy',
  });
  tracker.recordCache('/matches/live', true);
  tracker.recordCache('/matches/live', false);

  const status = tracker.getStatus({
    dailyThreshold: 100,
    pollSeconds: 120,
    protectionPollSeconds: 300,
  });
  assert.equal(status.upstreamTotal, 1);
  assert.equal(status.upstreamByRoute['/matches/live'], 1);
  assert.equal(status.cacheHits['/matches/live'], 1);
  assert.equal(status.cacheMisses['/matches/live'], 1);
  assert.equal(status.protectionActive, false);
});

test('UsageTracker activates protection at threshold', () => {
  const tracker = new UsageTracker();
  for (let i = 0; i < 5; i += 1) {
    tracker.recordUpstream({ callerRoute: '/test', urlPattern: '/fixtures' });
  }
  assert.equal(tracker.isProtectionActive(5), true);
  const status = tracker.getStatus({
    dailyThreshold: 5,
    pollSeconds: 120,
    protectionPollSeconds: 300,
  });
  assert.equal(status.protectionActive, true);
  assert.equal(status.effectivePollSeconds, 300);
});
