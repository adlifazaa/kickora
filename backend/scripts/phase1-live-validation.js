'use strict';

/**
 * Phase 1 live validation — uses production Kickora proxy for football data
 * when API_FOOTBALL_KEY is not set locally. Worker + dedup + dry-run logic
 * runs locally; no real FCM.
 */

const PROXY_BASE =
  process.env.KICKORA_PROXY_URL?.trim() || 'https://kickora-aoi0.onrender.com';

const POLL_SECONDS = Number.parseInt(
  process.env.NOTIFICATIONS_POLL_SECONDS ?? '60',
  10,
) || 60;

const CYCLES = Number.parseInt(process.env.VALIDATION_CYCLES ?? '6', 10) || 6;

const { createNotificationWorker } = require('../src/notifications/worker');

const config = {
  notificationsEnabled: true,
  notificationsDryRun: true,
  notificationsPollSeconds: POLL_SECONDS,
  notificationsDedupTtlSeconds: 6 * 60 * 60,
  notificationsDryRunLogMax: 200,
  firebaseServiceAccountJson: '',
};

async function fetchProxy(path) {
  const url = `${PROXY_BASE}${path}`;
  const res = await fetch(url, { headers: { Accept: 'application/json' } });
  if (!res.ok) {
    const err = new Error(`Proxy HTTP ${res.status} for ${path}`);
    err.statusCode = res.status;
    throw err;
  }
  return res.json();
}

const fetchLive = () => fetchProxy('/matches/live');
const fetchEvents = (fixtureId) =>
  fetchProxy(`/matches/${fixtureId}/events`);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function summarizeEvents(events) {
  const byType = {};
  for (const e of events) {
    const t = e.data?.type ?? 'unknown';
    byType[t] = (byType[t] ?? 0) + 1;
  }
  return byType;
}

async function main() {
  console.log('=== Kickora Phase 1 Live Validation ===');
  console.log(`Proxy: ${PROXY_BASE}`);
  console.log(`Poll interval: ${POLL_SECONDS}s | Cycles: ${CYCLES}`);
  console.log(`DRY_RUN: true | FCM: disabled\n`);

  const livePreview = await fetchLive();
  const liveCount = livePreview.response?.length ?? 0;
  console.log(`Live fixtures now: ${liveCount}`);
  for (const item of (livePreview.response ?? []).slice(0, 5)) {
    const f = item.fixture ?? {};
    const t = item.teams ?? {};
    const g = item.goals ?? {};
    console.log(
      `  - ${f.id} ${f.status?.short} ${f.status?.elapsed}' ${t.home?.name} ${g.home}-${g.away} ${t.away?.name}`,
    );
  }
  console.log('');

  const logs = [];
  const worker = createNotificationWorker(config, {
    fetchLive,
    fetchEvents,
    log: (msg) => {
      logs.push({ at: new Date().toISOString(), level: 'info', msg });
      console.log(msg);
    },
    warn: (msg) => {
      logs.push({ at: new Date().toISOString(), level: 'warn', msg });
      console.warn(msg);
    },
  });

  let apiCalls = 1; // initial preview
  for (let i = 1; i <= CYCLES; i += 1) {
    console.log(`\n--- Poll cycle ${i}/${CYCLES} @ ${new Date().toISOString()} ---`);
    apiCalls += 1; // live fixtures
    const trackedBefore = worker.fixtureState.size;
    await worker.pollOnce();
    apiCalls += worker.fixtureState.size; // events per tracked fixture (approx)
    const status = worker.getStatus();
    console.log(
      `tracked=${status.trackedFixtures} (was ${trackedBefore}) dedup=${status.dedupEntries} dryRunLog=${status.dryRunLogSize}`,
    );
    if (i < CYCLES) await sleep(POLL_SECONDS * 1000);
  }

  const dryEvents = worker.dryRunLog.list(200);
  const status = worker.getStatus();

  console.log('\n=== Validation summary ===');
  console.log(JSON.stringify({
    cycles: CYCLES,
    pollSeconds: POLL_SECONDS,
    estimatedApiCalls: apiCalls,
    lastPollStats: status.lastPollStats,
    dryRunEventsTotal: dryEvents.length,
    dryRunByType: summarizeEvents(dryEvents),
    dedupEntries: status.dedupEntries,
    trackedFixtures: status.trackedFixtures,
  }, null, 2));

  console.log('\n=== Dry-run events (all captured) ===');
  if (dryEvents.length === 0) {
    console.log('(none — first cycle seeds state; no new goals/cards/status changes during window)');
  } else {
    for (const e of dryEvents) {
      console.log(JSON.stringify(e, null, 2));
    }
  }

  // Verify dedup: no duplicate topicSendKey in log
  const keys = dryEvents.map((e) => e.topicSendKey);
  const dupKeys = keys.filter((k, i) => keys.indexOf(k) !== i);
  console.log(`\nDuplicate topicSendKeys in log: ${dupKeys.length}`);

  return { dryEvents, status, apiCalls };
}

main().catch((e) => {
  console.error('Validation failed:', e);
  process.exit(1);
});
