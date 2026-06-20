'use strict';

const { parseFixtureSnapshot } = require('./eventDetector');

/**
 * World Cup 2026 notification scope — worker only tracks this league.
 * @param {number} leagueId
 * @param {number} wcLeagueId
 */
function isWorldCupFixture(snapshot, wcLeagueId) {
  return snapshot.leagueId === wcLeagueId;
}

/**
 * @param {unknown[]} items raw API-Football fixture rows
 * @param {number} wcLeagueId
 */
function filterWorldCupLiveItems(items, wcLeagueId) {
  if (!Array.isArray(items)) return [];
  return items.filter((item) => {
    const snapshot = parseFixtureSnapshot(item);
    return snapshot.fixtureId > 0 && isWorldCupFixture(snapshot, wcLeagueId);
  });
}

/**
 * Build query for league-scoped live fixtures (API-Football supports league + season + live).
 * @param {number} wcLeagueId
 * @param {number} wcSeason
 */
function worldCupLiveQuery(wcLeagueId, wcSeason) {
  return {
    live: 'all',
    league: wcLeagueId,
    season: wcSeason,
  };
}

module.exports = {
  isWorldCupFixture,
  filterWorldCupLiveItems,
  worldCupLiveQuery,
};
