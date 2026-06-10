'use strict';

const express = require('express');

/**
 * @param {{ worker: ReturnType<import('./worker').createNotificationWorker> }} deps
 */
function createNotificationRouter({ worker }) {
  const router = express.Router();

  router.get('/notifications/status', (_req, res) => {
    res.json({
      ok: true,
      ...worker.getStatus(),
    });
  });

  router.get('/notifications/dry-run-events', (req, res) => {
    const limit = Number.parseInt(req.query.limit ?? '50', 10);
    const safeLimit = Number.isFinite(limit) ? Math.min(Math.max(limit, 1), 200) : 50;
    res.json({
      ok: true,
      count: worker.dryRunLog.size,
      events: worker.dryRunLog.list(safeLimit),
    });
  });

  router.post('/notifications/test-dry-run', express.json(), async (req, res, next) => {
    try {
      if (!worker.getStatus().enabled) {
        return res.status(400).json({
          ok: false,
          error: 'Notifications worker is disabled. Set NOTIFICATIONS_ENABLED=true.',
        });
      }

      const body = req.body ?? {};
      const snapshot = {
        fixtureId: Number(body.fixtureId ?? 999001),
        status: body.status ?? '1H',
        elapsed: Number(body.elapsed ?? 12),
        homeTeamId: Number(body.homeTeamId ?? 100),
        awayTeamId: Number(body.awayTeamId ?? 200),
        homeTeam: body.homeTeam ?? 'الفريق أ',
        awayTeam: body.awayTeam ?? 'الفريق ب',
        homeScore: Number(body.homeScore ?? 1),
        awayScore: Number(body.awayScore ?? 0),
        leagueId: Number(body.leagueId ?? 39),
      };

      const type = body.type ?? 'goal_scored';
      const result = await worker.testDryRunEvent({
        type,
        snapshot,
        teamId: body.teamId != null ? Number(body.teamId) : snapshot.homeTeamId,
        teamName: body.teamName ?? snapshot.homeTeam,
        playerId: body.playerId != null ? Number(body.playerId) : 501,
        minute: body.minute ?? '12',
      });

      res.json({
        ok: true,
        result,
        hint: worker.getStatus().dryRun
          ? 'DRY_RUN active — check GET /notifications/dry-run-events or server logs.'
          : 'Real FCM may have been sent (NOTIFICATIONS_DRY_RUN=false).',
      });
    } catch (e) {
      next(e);
    }
  });

  return router;
}

module.exports = { createNotificationRouter };
