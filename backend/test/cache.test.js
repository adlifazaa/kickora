'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { ttlForPath, cacheKey } = require('../src/cache');
const { leagueSeasonQuery, filterFixtureResponse } = require('../src/apiFootball');

test('ttlForPath assigns expected buckets', () => {
  assert.equal(ttlForPath('/matches/live'), 60);
  assert.equal(ttlForPath('/competitions'), 24 * 60 * 60);
  assert.equal(ttlForPath('/standings/39'), 10 * 60);
  assert.equal(ttlForPath('/matches/123/events'), 2 * 60);
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
