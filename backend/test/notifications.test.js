'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  DedupStore,
  buildDedupKey,
  buildTopicSendKey,
} = require('../src/notifications/dedupStore');
const {
  detectNewFixtureEvents,
  detectStatusEvents,
  parseEventRow,
  parseFixtureSnapshot,
} = require('../src/notifications/eventDetector');
const { DryRunLog } = require('../src/notifications/dryRunLog');
const {
  WIRE,
  buildArabicCopy,
  buildNotificationPayload,
} = require('../src/notifications/payloadBuilder');
const {
  competitionTopic,
  matchTopic,
  teamTopic,
  topicsForMatchEvent,
} = require('../src/notifications/topics');
const { createFcmSender } = require('../src/notifications/fcmSender');
const { createNotificationWorker } = require('../src/notifications/worker');

function mockConfig(overrides = {}) {
  return {
    notificationsEnabled: false,
    notificationsDryRun: true,
    notificationsPollSeconds: 60,
    notificationsDedupTtlSeconds: 3600,
    notificationsDryRunLogMax: 50,
    firebaseServiceAccountJson: '',
    ...overrides,
  };
}

test('buildDedupKey is stable and includes all parts', () => {
  const key = buildDedupKey({
    fixtureId: 42,
    type: 'goal_scored',
    minute: '67',
    teamId: 7,
    playerId: 501,
    score: '2 - 1',
  });
  assert.equal(key, '42:goal_scored:67:7:501:2 - 1');
});

test('buildTopicSendKey scopes dedup per topic fan-out', () => {
  const eventKey = buildDedupKey({
    fixtureId: 1,
    type: 'goal_scored',
    minute: '10',
    teamId: 5,
    playerId: 9,
    score: '1 - 0',
  });
  assert.equal(buildTopicSendKey(eventKey, 'team_5'), `${eventKey}@team_5`);
  assert.notEqual(
    buildTopicSendKey(eventKey, 'team_5'),
    buildTopicSendKey(eventKey, 'match_1'),
  );
});

test('DedupStore prevents duplicate claims', () => {
  const store = new DedupStore({ ttlSeconds: 60, now: () => 1000 });
  assert.equal(store.tryClaim('a'), true);
  assert.equal(store.tryClaim('a'), false);
  assert.equal(store.size(), 1);
});

test('topicsForMatchEvent uses match, both teams, and competition', () => {
  assert.deepEqual(topicsForMatchEvent({
    fixtureId: 99,
    homeTeamId: 10,
    awayTeamId: 20,
    leagueId: 39,
  }), ['match_99', 'team_10', 'team_20', 'competition_39']);

  assert.equal(teamTopic(7), 'team_7');
  assert.equal(matchTopic(123), 'match_123');
  assert.equal(competitionTopic(39), 'competition_39');
});

test('detectStatusEvents emits kickoff, halftime, and full time', () => {
  const base = {
    fixtureId: 1,
    homeTeamId: 10,
    awayTeamId: 20,
    homeTeam: 'A',
    awayTeam: 'B',
    homeScore: 0,
    awayScore: 0,
    leagueId: 39,
    elapsed: 0,
  };

  const kickoff = detectStatusEvents(
    { ...base, status: 'NS' },
    { ...base, status: '1H', elapsed: 1 },
  );
  assert.deepEqual(kickoff, [{ type: WIRE.matchStarted, minute: '1' }]);

  const ht = detectStatusEvents(
    { ...base, status: '1H', elapsed: 45 },
    { ...base, status: 'HT', homeScore: 1, awayScore: 0, elapsed: 45 },
  );
  assert.deepEqual(ht, [{ type: WIRE.halftime, minute: 'HT' }]);

  const ft = detectStatusEvents(
    { ...base, status: '2H', homeScore: 2, awayScore: 1, elapsed: 90 },
    { ...base, status: 'FT', homeScore: 2, awayScore: 1, elapsed: 90 },
  );
  assert.deepEqual(ft, [{ type: WIRE.matchFinished, minute: 'FT' }]);
});

test('detectStatusEvents returns nothing without previous snapshot', () => {
  const current = parseFixtureSnapshot({
    fixture: { id: 5, status: { short: '1H', elapsed: 10 } },
    teams: { home: { id: 1, name: 'H' }, away: { id: 2, name: 'A' } },
    goals: { home: 0, away: 0 },
    league: { id: 39 },
  });
  assert.deepEqual(detectStatusEvents(null, current), []);
});

test('parseEventRow detects goals and red cards', () => {
  const goal = parseEventRow({
    time: { elapsed: 12, extra: null },
    team: { id: 1, name: 'Home' },
    player: { id: 99, name: 'Scorer' },
    type: 'Goal',
    detail: 'Normal Goal',
  });
  assert.equal(goal.wireType, WIRE.goalScored);
  assert.equal(goal.eventKey, 'goal_scored:12:1:99');

  const red = parseEventRow({
    time: { elapsed: 70, extra: null },
    team: { id: 2, name: 'Away' },
    player: { id: 55, name: 'Sent Off' },
    type: 'Card',
    detail: 'Red Card',
  });
  assert.equal(red.wireType, WIRE.redCard);
});

test('detectNewFixtureEvents only returns unseen events', () => {
  const rows = [
    {
      time: { elapsed: 10, extra: null },
      team: { id: 1, name: 'H' },
      player: { id: 1, name: 'P1' },
      type: 'Goal',
      detail: 'Normal Goal',
    },
    {
      time: { elapsed: 55, extra: null },
      team: { id: 2, name: 'A' },
      player: { id: 2, name: 'P2' },
      type: 'Goal',
      detail: 'Normal Goal',
    },
  ];

  const first = detectNewFixtureEvents(new Set(), rows);
  assert.equal(first.events.length, 2);

  const second = detectNewFixtureEvents(first.keys, rows);
  assert.equal(second.events.length, 0);
});

test('buildArabicCopy uses required Arabic templates', () => {
  assert.equal(
    buildArabicCopy(WIRE.matchStarted, {
      homeTeam: 'ريال',
      awayTeam: 'برشلونة',
      score: '0 - 0',
    }).body,
    'بدأت المباراة: ريال ضد برشلونة',
  );
  assert.equal(
    buildArabicCopy(WIRE.goalScored, {
      homeTeam: 'ريال',
      awayTeam: 'برشلونة',
      teamName: 'ريال',
      score: '1 - 0',
    }).body,
    'هدف! ريال — 1 - 0',
  );
  assert.equal(
    buildArabicCopy(WIRE.redCard, {
      homeTeam: 'ريال',
      awayTeam: 'برشلونة',
      teamName: 'برشلونة',
      score: '1 - 0',
    }).body,
    'بطاقة حمراء: برشلونة',
  );
});

test('buildNotificationPayload matches Flutter wire fields', () => {
  const payload = buildNotificationPayload({
    type: WIRE.goalScored,
    fixtureId: 42,
    homeTeam: 'A',
    awayTeam: 'B',
    homeScore: 1,
    awayScore: 0,
    homeTeamId: 10,
    awayTeamId: 20,
    leagueId: 39,
    teamId: 10,
    teamName: 'A',
    playerId: 501,
    minute: '12',
    topic: 'team_10',
  });

  assert.equal(payload.data.type, 'goal_scored');
  assert.equal(payload.data.matchId, '42');
  assert.equal(payload.data.teamId, '10');
  assert.equal(payload.data.competitionId, '39');
  assert.equal(payload.data.topic, 'team_10');
  assert.equal(payload.data.score, '1 - 0');
  assert.equal(payload.data.minute, '12');
});

test('createFcmSender dry-run logs without sending when enabled', async () => {
  const dryRunLog = new DryRunLog(10);
  const dedupStore = new DedupStore({ ttlSeconds: 3600 });
  const logs = [];
  const sender = createFcmSender(
    mockConfig({ notificationsEnabled: true, notificationsDryRun: true }),
    {
      dryRunLog,
      dedupStore,
      log: (msg) => logs.push(msg),
    },
  );

  const snapshot = {
    fixtureId: 1,
    homeTeamId: 10,
    awayTeamId: 20,
    homeTeam: 'A',
    awayTeam: 'B',
    homeScore: 1,
    awayScore: 0,
    leagueId: 39,
  };

  const first = await sender.sendMatchEvent({
    type: WIRE.goalScored,
    snapshot,
    teamId: 10,
    teamName: 'A',
    playerId: 99,
    minute: '12',
  });
  assert.equal(first.dryRun, true);
  assert.equal(first.sent, 4);
  assert.equal(dryRunLog.size, 4);
  assert.match(logs[0], /kickora-notify:dry-run/);

  const second = await sender.sendMatchEvent({
    type: WIRE.goalScored,
    snapshot,
    teamId: 10,
    teamName: 'A',
    playerId: 99,
    minute: '12',
  });
  assert.equal(second.sent, 0);
  assert.equal(second.skipped, 4);
  assert.equal(dryRunLog.size, 4);
});

test('createFcmSender does nothing when notifications disabled', async () => {
  const dryRunLog = new DryRunLog(10);
  const dedupStore = new DedupStore({ ttlSeconds: 3600 });
  const sender = createFcmSender(mockConfig({ notificationsEnabled: false }), {
    dryRunLog,
    dedupStore,
  });

  const result = await sender.sendMatchEvent({
    type: WIRE.matchStarted,
    snapshot: {
      fixtureId: 1,
      homeTeamId: 10,
      awayTeamId: 20,
      homeTeam: 'A',
      awayTeam: 'B',
      homeScore: 0,
      awayScore: 0,
      leagueId: 39,
    },
  });

  assert.equal(result.sent, 0);
  assert.equal(result.disabled, true);
  assert.equal(dryRunLog.size, 0);
});

test('worker seeds first-seen fixtures without sending notifications', async () => {
  const dryRunLog = new DryRunLog(20);
  const dedupStore = new DedupStore({ ttlSeconds: 3600 });

  const liveBody = {
    response: [
      {
        fixture: { id: 500, status: { short: '1H', elapsed: 30 } },
        league: { id: 39 },
        teams: {
          home: { id: 1, name: 'H' },
          away: { id: 2, name: 'A' },
        },
        goals: { home: 1, away: 0 },
      },
    ],
  };

  const eventsBody = {
    response: [
      {
        time: { elapsed: 10, extra: null },
        team: { id: 1, name: 'H' },
        player: { id: 9, name: 'Scorer' },
        type: 'Goal',
        detail: 'Normal Goal',
      },
    ],
  };

  let eventFetches = 0;
  let liveResponse = liveBody;
  let eventsResponse = eventsBody;

  const worker = createNotificationWorker(
    mockConfig({ notificationsEnabled: true, notificationsDryRun: true }),
    {
      dryRunLog,
      dedupStore,
      fetchLive: async () => liveResponse,
      fetchEvents: async () => {
        eventFetches += 1;
        return eventsResponse;
      },
      log: () => {},
      warn: () => {},
    },
  );

  await worker.pollOnce();
  assert.equal(eventFetches, 1);
  assert.equal(dryRunLog.size, 0);
  assert.equal(worker.fixtureState.size, 1);

  liveResponse = {
    response: [
      {
        fixture: { id: 500, status: { short: '1H', elapsed: 31 } },
        league: { id: 39 },
        teams: {
          home: { id: 1, name: 'H' },
          away: { id: 2, name: 'A' },
        },
        goals: { home: 2, away: 0 },
      },
    ],
  };

  eventsResponse = {
    response: [
      ...eventsBody.response,
      {
        time: { elapsed: 31, extra: null },
        team: { id: 1, name: 'H' },
        player: { id: 10, name: 'Scorer2' },
        type: 'Goal',
        detail: 'Normal Goal',
      },
    ],
  };

  await worker.pollOnce();
  assert.equal(eventFetches, 2);
  assert.equal(dryRunLog.size, 4);
});

test('worker getStatus reports dry run and disabled defaults', () => {
  const worker = createNotificationWorker(mockConfig());
  const status = worker.getStatus();
  assert.equal(status.enabled, false);
  assert.equal(status.dryRun, true);
  assert.equal(status.realFcmActive, false);
});

test('canSendReal returns boolean even when Firebase JSON is configured', async () => {
  const fakeServiceAccount =
    '{"type":"service_account","private_key":"-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n"}';
  const dryRunLog = new DryRunLog(10);
  const dedupStore = new DedupStore({ ttlSeconds: 3600 });
  const sender = createFcmSender(
    mockConfig({
      notificationsEnabled: true,
      notificationsDryRun: false,
      firebaseServiceAccountJson: fakeServiceAccount,
    }),
    { dryRunLog, dedupStore },
  );
  assert.equal(typeof sender.canSendReal(), 'boolean');
  assert.equal(sender.canSendReal(), true);
});

test('getStatus realFcmActive is boolean when Firebase JSON is configured', () => {
  const fakeServiceAccount =
    '{"type":"service_account","private_key":"-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n"}';
  const worker = createNotificationWorker(
    mockConfig({
      notificationsEnabled: true,
      notificationsDryRun: false,
      firebaseServiceAccountJson: fakeServiceAccount,
    }),
  );
  const status = worker.getStatus();
  assert.equal(typeof status.realFcmActive, 'boolean');
  assert.equal(status.realFcmActive, true);
  assert.equal(typeof status.realFcmConfigured, 'boolean');
});

test('/notifications/status response never contains secrets', () => {
  const {
    toPublicNotificationStatus,
    assertNoSecretsInJson,
  } = require('../src/notifications/notificationStatus');
  const { createNotificationRouter } = require('../src/notifications/routes');

  const fakeServiceAccount =
    '{"type":"service_account","project_id":"test","private_key":"-----BEGIN PRIVATE KEY-----\\nLEAK\\n-----END PRIVATE KEY-----\\n","client_email":"firebase-adminsdk@test.iam.gserviceaccount.com"}';

  const worker = createNotificationWorker(
    mockConfig({
      notificationsEnabled: true,
      notificationsDryRun: false,
      firebaseServiceAccountJson: fakeServiceAccount,
    }),
  );

  const publicStatus = toPublicNotificationStatus(worker.getStatus());
  assert.equal(typeof publicStatus.realFcmActive, 'boolean');
  assert.equal(publicStatus.realFcmActive, true);

  const router = createNotificationRouter({ worker });
  const layer = router.stack.find((l) => l.route?.path === '/notifications/status');
  assert.ok(layer);

  const handler = layer.route.stack[0].handle;
  let body;
  const res = {
    json(payload) {
      body = payload;
    },
  };
  handler({}, res);
  const json = JSON.stringify(body);
  assertNoSecretsInJson(json);
  assert.equal(body.realFcmActive, true);
  assert.equal(typeof body.realFcmActive, 'boolean');
  assert.equal(body.ok, true);
});
