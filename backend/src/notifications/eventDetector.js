'use strict';

const { WIRE } = require('./payloadBuilder');

const UPCOMING_STATUSES = new Set(['NS', 'TBD', 'PST', '']);
const LIVE_START_STATUSES = new Set(['1H', '2H', 'LIVE', 'INPLAY', 'ET', 'BT', 'P', 'INT']);
const FINISHED_STATUSES = new Set(['FT', 'AET', 'PEN', 'AWD', 'WO']);

/**
 * @param {object} fixtureItem API-Football fixture envelope item
 */
function parseFixtureSnapshot(fixtureItem) {
  const fixture = fixtureItem?.fixture ?? {};
  const league = fixtureItem?.league ?? {};
  const teams = fixtureItem?.teams ?? {};
  const goals = fixtureItem?.goals ?? {};
  const score = fixtureItem?.score ?? {};

  const homeGoals = pickScore(goals.home, score, 'home');
  const awayGoals = pickScore(goals.away, score, 'away');

  return {
    fixtureId: intOrZero(fixture.id),
    status: (fixture.status?.short ?? '').toUpperCase(),
    elapsed: intOrZero(fixture.status?.elapsed),
    homeTeamId: intOrZero(teams.home?.id),
    awayTeamId: intOrZero(teams.away?.id),
    homeTeam: teams.home?.name ?? '',
    awayTeam: teams.away?.name ?? '',
    homeScore: homeGoals,
    awayScore: awayGoals,
    leagueId: intOrZero(league.id),
  };
}

function pickScore(liveGoals, score, side) {
  if (liveGoals != null && liveGoals !== '') {
    const n = Number(liveGoals);
    if (Number.isFinite(n)) return n;
  }
  const fulltime = score?.fulltime ?? {};
  const halftime = score?.halftime ?? {};
  const val = fulltime[side] ?? halftime[side];
  if (val == null || val === '') return 0;
  const n = Number(val);
  return Number.isFinite(n) ? n : 0;
}

/**
 * @param {object} raw API-Football event row
 */
function parseEventRow(raw) {
  const time = raw?.time ?? {};
  const elapsed = intOrZero(time.elapsed);
  const extra = intOrZero(time.extra);
  const minute = extra > 0 ? `${elapsed}+${extra}` : `${elapsed}`;

  const team = raw?.team ?? {};
  const player = raw?.player ?? {};
  const typeRaw = (raw?.type ?? '').toString();
  const detailRaw = (raw?.detail ?? '').toString();

  let wireType = null;
  if (isGoal(typeRaw, detailRaw)) wireType = WIRE.goalScored;
  else if (isRedCard(typeRaw, detailRaw)) wireType = WIRE.redCard;

  if (!wireType) return null;

  return {
    wireType,
    minute,
    teamId: intOrZero(team.id),
    teamName: team.name ?? '',
    playerId: intOrZero(player.id),
    playerName: player.name ?? '',
    eventKey: `${wireType}:${minute}:${intOrZero(team.id)}:${intOrZero(player.id)}`,
  };
}

function isGoal(type, detail) {
  const t = type.toLowerCase();
  const d = detail.toLowerCase();
  return t.includes('goal') || d.includes('goal');
}

function isRedCard(type, detail) {
  const t = type.toLowerCase();
  const d = detail.toLowerCase();
  if (!t.includes('card') && !d.includes('card')) return false;
  return d.includes('red') || d.includes('second yellow');
}

/**
 * Detect status-transition notifications between polls.
 * @param {object|null} previous
 * @param {object} current parsed snapshot
 * @returns {object[]}
 */
function detectStatusEvents(previous, current) {
  if (!previous) return [];

  const events = [];
  const prev = previous.status;
  const next = current.status;

  if (prev === next) return events;

  if (isMatchStartedTransition(prev, next)) {
    events.push({
      type: WIRE.matchStarted,
      minute: next === 'HT' ? 'HT' : `${current.elapsed || 0}`,
    });
  }

  if (next === 'HT' && prev !== 'HT') {
    events.push({
      type: WIRE.halftime,
      minute: 'HT',
    });
  }

  if (isFinishedTransition(prev, next)) {
    events.push({
      type: WIRE.matchFinished,
      minute: 'FT',
    });
  }

  return events;
}

function isMatchStartedTransition(prev, next) {
  if (!UPCOMING_STATUSES.has(prev)) return false;
  return LIVE_START_STATUSES.has(next) || next === 'HT';
}

function isFinishedTransition(prev, next) {
  if (FINISHED_STATUSES.has(prev)) return false;
  return FINISHED_STATUSES.has(next);
}

/**
 * Detect new goal/red-card rows since last poll.
 * @param {Set<string>} previousKeys
 * @param {object[]} eventRows raw API-Football events
 * @returns {{ events: object[], keys: Set<string> }}
 */
function detectNewFixtureEvents(previousKeys, eventRows) {
  const keys = new Set(previousKeys);
  const events = [];

  for (const raw of eventRows) {
    const parsed = parseEventRow(raw);
    if (!parsed) continue;
    if (keys.has(parsed.eventKey)) continue;
    keys.add(parsed.eventKey);
    events.push(parsed);
  }

  return { events, keys };
}

function intOrZero(value) {
  if (value == null || value === '') return 0;
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

module.exports = {
  UPCOMING_STATUSES,
  LIVE_START_STATUSES,
  FINISHED_STATUSES,
  parseFixtureSnapshot,
  parseEventRow,
  detectStatusEvents,
  detectNewFixtureEvents,
  isGoal,
  isRedCard,
  isMatchStartedTransition,
  isFinishedTransition,
};
