'use strict';

/** FCM topic naming — mirrors Flutter [NotificationTopics]. */

function teamTopic(teamId) {
  return `team_${teamId}`;
}

function matchTopic(fixtureId) {
  return `match_${fixtureId}`;
}

function competitionTopic(leagueId) {
  return `competition_${leagueId}`;
}

/**
 * Topics to fan out a match event notification.
 * @param {{
 *   fixtureId: number,
 *   homeTeamId: number,
 *   awayTeamId: number,
 *   leagueId?: number|null,
 * }} ids
 * @returns {string[]}
 */
function topicsForMatchEvent(ids) {
  const topics = [
    matchTopic(ids.fixtureId),
    teamTopic(ids.homeTeamId),
    teamTopic(ids.awayTeamId),
  ];
  if (ids.leagueId != null && ids.leagueId > 0) {
    topics.push(competitionTopic(ids.leagueId));
  }
  return topics;
}

module.exports = {
  teamTopic,
  matchTopic,
  competitionTopic,
  topicsForMatchEvent,
};
