'use strict';

/**
 * Simulates status transitions on real fixture IDs to validate kickoff/HT/FT
 * detection + dry-run output without waiting for real match phases.
 */

const PROXY_BASE =
  process.env.KICKORA_PROXY_URL?.trim() || 'https://kickora-aoi0.onrender.com';

const { createNotificationWorker } = require('../src/notifications/worker');
const { parseFixtureSnapshot } = require('../src/notifications/eventDetector');
const { WIRE } = require('../src/notifications/payloadBuilder');

const config = {
  notificationsEnabled: true,
  notificationsDryRun: true,
  notificationsPollSeconds: 60,
  notificationsDedupTtlSeconds: 6 * 60 * 60,
  notificationsDryRunLogMax: 200,
  firebaseServiceAccountJson: '',
};

async function fetchProxy(path) {
  const res = await fetch(`${PROXY_BASE}${path}`);
  return res.json();
}

async function main() {
  const live = await fetchProxy('/matches/live');
  const item = live.response?.[0];
  if (!item) {
    console.log('No live fixtures for simulation');
    return;
  }

  const worker = createNotificationWorker(config, {
    fetchLive: async () => live,
    fetchEvents: async () => ({ response: [] }),
    log: (m) => console.log(m),
    warn: (m) => console.warn(m),
  });

  const base = parseFixtureSnapshot(item);
  console.log('Simulating on fixture:', base.fixtureId, base.homeTeam, 'vs', base.awayTeam);

  // Seed as if we saw NS earlier
  worker.fixtureState.set(base.fixtureId, {
    snapshot: { ...base, status: 'NS', homeScore: 0, awayScore: 0, elapsed: 0 },
    eventKeys: new Set(),
  });

  const transitions = [
    { label: 'match_started', status: '1H', elapsed: 1, homeScore: 0, awayScore: 0, type: WIRE.matchStarted },
    { label: 'halftime', status: 'HT', elapsed: 45, homeScore: 1, awayScore: 0, type: WIRE.halftime },
    { label: 'fulltime', status: 'FT', elapsed: 90, homeScore: 2, awayScore: 1, type: WIRE.matchFinished },
  ];

  for (const t of transitions) {
    worker.dryRunLog.clear();
    worker.dedupStore.clear();
    const snap = { ...base, status: t.status, elapsed: t.elapsed, homeScore: t.homeScore, awayScore: t.awayScore };
    worker.fixtureState.set(base.fixtureId, {
      snapshot: worker.fixtureState.get(base.fixtureId).snapshot,
      eventKeys: new Set(),
    });
    // manual status detect via poll with crafted live body
    const liveBody = {
      response: [{
        ...item,
        fixture: { ...item.fixture, status: { short: t.status, elapsed: t.elapsed } },
        goals: { home: t.homeScore, away: t.awayScore },
      }],
    };
    const w2 = createNotificationWorker(config, {
      fetchLive: async () => liveBody,
      fetchEvents: async () => ({ response: [] }),
      log: () => {},
      warn: () => {},
      dedupStore: worker.dedupStore,
      dryRunLog: worker.dryRunLog,
    });
    w2.fixtureState.set(base.fixtureId, worker.fixtureState.get(base.fixtureId));
    await w2.pollOnce();
    const events = worker.dryRunLog.list(10);
    console.log(`\n[${t.label}] dry-run entries: ${events.length}`);
    for (const e of events) {
      console.log(JSON.stringify({
        topic: e.topic,
        title: e.title,
        body: e.body,
        type: e.data?.type,
        dedupKey: e.dedupKey,
        topicSendKey: e.topicSendKey,
      }));
    }
    worker.fixtureState.set(base.fixtureId, {
      snapshot: snap,
      eventKeys: new Set(),
    });
  }

  // Goal + red card simulation
  console.log('\n[goal_scored + red_card] via testDryRunEvent');
  worker.dedupStore.clear();
  worker.dryRunLog.clear();
  await worker.testDryRunEvent({
    type: WIRE.goalScored,
    snapshot: { ...base, homeScore: 1, awayScore: 0 },
    teamId: base.homeTeamId,
    teamName: base.homeTeam,
    playerId: 999,
    minute: '23',
  });
  await worker.testDryRunEvent({
    type: WIRE.redCard,
    snapshot: { ...base, homeScore: 1, awayScore: 0 },
    teamId: base.awayTeamId,
    teamName: base.awayTeam,
    playerId: 888,
    minute: '67',
  });
  for (const e of worker.dryRunLog.list(20)) {
    console.log(JSON.stringify({
      topic: e.topic,
      title: e.title,
      body: e.body,
      type: e.data?.type,
      dedupKey: e.dedupKey,
    }));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
