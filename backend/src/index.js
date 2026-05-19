'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const config = require('./config');
const { MemoryCache } = require('./cache');
const { createRouter } = require('./routes');

const app = express();
const cache = new MemoryCache();

if (config.trustProxy) {
  app.set('trust proxy', 1);
}

app.disable('x-powered-by');

if (config.enableCors) {
  app.use((_req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (_req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });
}

app.use(
  rateLimit({
    windowMs: config.rateLimitWindowMs,
    max: config.rateLimitMax,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
      errors: [{ message: 'Too many requests' }],
      response: [],
    },
  }),
);

function sendJson(res, body) {
  res.status(200).json(body);
}

app.use(createRouter({ cache, sendJson }));

app.use((_req, res) => {
  res.status(404).json({
    errors: [{ message: 'Not found' }],
    response: [],
  });
});

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  const status = err.statusCode && Number.isFinite(err.statusCode) ? err.statusCode : 502;
  if (status >= 500) {
    console.error('[kickora-proxy] upstream error:', err.code || err.message);
  }
  res.status(status).json({
    errors: [{ message: err.code === 'not_configured' ? 'Service not configured' : 'Upstream unavailable' }],
    response: [],
  });
});

if (!config.apiFootballKey) {
  console.warn(
    '[kickora-proxy] WARNING: API_FOOTBALL_KEY is missing — football routes will return 503 until set.',
  );
}

const server = app.listen(config.port, () => {
  console.log(`[kickora-proxy] listening on port ${config.port}`);
});

setInterval(() => cache.purgeExpired(), 5 * 60 * 1000).unref?.();

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});
