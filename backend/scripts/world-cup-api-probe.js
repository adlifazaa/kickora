#!/usr/bin/env node
'use strict';

/**
 * Live API probe — FIFA World Cup fixture discovery evidence.
 * Usage: node backend/scripts/world-cup-api-probe.js [baseUrl]
 */

const base =
  (process.argv[2] || 'https://kickora-aoi0.onrender.com').replace(/\/$/, '');

const today = new Date().toISOString().slice(0, 10);

async function get(path) {
  const url = `${base}${path}`;
  const res = await fetch(url);
  const body = await res.json();
  return { url, status: res.status, body };
}

function wcFixtures(body) {
  return (body.response || []).filter((f) => f.league?.id === 1);
}

function summarizeFixture(f) {
  if (!f) return null;
  return {
    fixtureId: f.fixture?.id,
    date: f.fixture?.date,
    status: f.fixture?.status?.short,
    leagueId: f.league?.id,
    leagueName: f.league?.name,
    season: f.league?.season,
    home: f.teams?.home?.name,
    away: f.teams?.away?.name,
  };
}

async function main() {
  console.log('Kickora World Cup API probe');
  console.log('base:', base);
  console.log('date:', today);
  console.log('---');

  const compList = await get('/competitions');
  const wcEntry = (compList.body.response || []).find((e) => e.league?.id === 1);
  const wcSeasonCurrent = wcEntry?.seasons?.find((s) => s.current)?.year;

  console.log('COMPETITIONS World Cup entry:');
  console.log(
    JSON.stringify(
      wcEntry
        ? {
            leagueId: wcEntry.league.id,
            name: wcEntry.league.name,
            currentSeason: wcSeasonCurrent,
            seasonStart: wcEntry.seasons?.find((s) => s.current)?.start,
            seasonEnd: wcEntry.seasons?.find((s) => s.current)?.end,
          }
        : null,
      null,
      2,
    ),
  );

  const compById = await get('/competitions/1');
  const compByIdSeason = compById.body.response?.[0]?.seasons?.find(
    (s) => s.current,
  )?.year;

  console.log('\nCOMPETITION BY ID (no season param):');
  console.log(
    JSON.stringify(
      {
        results: compById.body.results,
        leagueId: compById.body.response?.[0]?.league?.id,
        name: compById.body.response?.[0]?.league?.name,
        currentSeason: compByIdSeason,
      },
      null,
      2,
    ),
  );

  const probes = [
    ['WC today season=2025 (app bug)', `/matches/today?date=${today}&competitionId=1&season=2025`],
    ['WC today season=2026 (correct)', `/matches/today?date=${today}&competitionId=1&season=2026`],
    ['All today no season', `/matches/today?date=${today}`],
    ['All today season=2025 (app bug)', `/matches/today?date=${today}&season=2025`],
    ['WC upcoming season=2026', `/matches/upcoming?date=${today}&competitionId=1&season=2026`],
    ['FIFA Club World Cup id=15 today', `/matches/today?date=${today}&competitionId=15&season=2025`],
  ];

  for (const [label, path] of probes) {
    const { body } = await get(path);
    const wc = wcFixtures(body);
    const first = summarizeFixture(wc[0] || body.response?.[0]);
    const next = wc.find((f) => f.fixture?.status?.short === 'NS');
    console.log(`\n${label}`);
    console.log('  parameters:', JSON.stringify(body.parameters));
    console.log('  total results:', body.results);
    console.log('  worldCupFixtures:', wc.length);
    console.log('  first:', JSON.stringify(first));
    console.log(
      '  next NS:',
      next ? summarizeFixture(next).date : 'none',
    );
    if (wc.length > 0) {
      console.log(
        '  raw snippet:',
        JSON.stringify(wc[0]).slice(0, 280),
      );
    }
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
