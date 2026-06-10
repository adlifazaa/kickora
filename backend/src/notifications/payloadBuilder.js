'use strict';

const { buildDedupKey } = require('./dedupStore');

/** Wire values — mirrors Flutter NotificationType.wireValue. */
const WIRE = {
  matchStarted: 'match_started',
  goalScored: 'goal_scored',
  redCard: 'red_card',
  halftime: 'halftime',
  matchFinished: 'match_finished',
};

/**
 * @param {number} home
 * @param {number} away
 */
function formatScore(home, away) {
  return `${home} - ${away}`;
}

/**
 * @param {{
 *   type: string,
 *   fixtureId: number,
 *   homeTeam: string,
 *   awayTeam: string,
 *   homeScore: number,
 *   awayScore: number,
 *   homeTeamId: number,
 *   awayTeamId: number,
 *   leagueId?: number|null,
 *   teamId?: number|null,
 *   teamName?: string|null,
 *   playerId?: number|null,
 *   minute?: string|null,
 *   topic: string,
 * }} input
 */
function buildNotificationPayload(input) {
  const score = formatScore(input.homeScore, input.awayScore);
  const { title, body } = buildArabicCopy(input.type, {
    homeTeam: input.homeTeam,
    awayTeam: input.awayTeam,
    teamName: input.teamName,
    score,
  });

  const minute = input.minute ?? '';
  const teamId = input.teamId ?? input.homeTeamId;
  const playerId = input.playerId ?? '';

  const dedupKey = buildDedupKey({
    fixtureId: input.fixtureId,
    type: input.type,
    minute,
    teamId,
    playerId,
    score,
  });

  const data = {
    type: input.type,
    matchId: String(input.fixtureId),
    teamId: teamId != null ? String(teamId) : '',
    competitionId:
      input.leagueId != null && input.leagueId > 0
        ? String(input.leagueId)
        : '',
    title,
    body,
    homeTeam: input.homeTeam,
    awayTeam: input.awayTeam,
    score,
    minute,
    topic: input.topic,
  };

  return {
    topic: input.topic,
    title,
    body,
    data,
    dedupKey,
  };
}

/**
 * @param {string} type
 * @param {{
 *   homeTeam: string,
 *   awayTeam: string,
 *   teamName?: string|null,
 *   score: string,
 * }} ctx
 */
function buildArabicCopy(type, ctx) {
  switch (type) {
    case WIRE.matchStarted:
      return {
        title: 'بدأت المباراة',
        body: `بدأت المباراة: ${ctx.homeTeam} ضد ${ctx.awayTeam}`,
      };
    case WIRE.goalScored: {
      const team = ctx.teamName ?? ctx.homeTeam;
      return {
        title: 'هدف!',
        body: `هدف! ${team} — ${ctx.score}`,
      };
    }
    case WIRE.redCard: {
      const team = ctx.teamName ?? ctx.homeTeam;
      return {
        title: 'بطاقة حمراء',
        body: `بطاقة حمراء: ${team}`,
      };
    }
    case WIRE.halftime:
      return {
        title: 'نهاية الشوط الأول',
        body: `نهاية الشوط الأول: ${ctx.homeTeam} ${ctx.score} ${ctx.awayTeam}`,
      };
    case WIRE.matchFinished:
      return {
        title: 'نهاية المباراة',
        body: `نهاية المباراة: ${ctx.homeTeam} ${ctx.score} ${ctx.awayTeam}`,
      };
    default:
      return {
        title: 'Kickora',
        body: `${ctx.homeTeam} ${ctx.score} ${ctx.awayTeam}`,
      };
  }
}

module.exports = {
  WIRE,
  formatScore,
  buildNotificationPayload,
  buildArabicCopy,
};
