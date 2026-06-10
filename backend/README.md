# Kickora Backend Proxy

Production flow:

```text
Kickora app  →  this server  →  API-Football (v3)
```

The Flutter app never receives the API-Football key. It calls Kickora-shaped routes (`/matches/live`, `/competitions`, …) and expects the same JSON envelope as API-Football (`response` array).

## Required environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `API_FOOTBALL_KEY` | **Yes** | Your API-Football key (server only) |
| `PORT` | No | Listen port (default `8080`) |
| `RATE_LIMIT_MAX` | No | Max requests per IP per window (default `120`) |
| `RATE_LIMIT_WINDOW_MS` | No | Rate-limit window in ms (default `900000` = 15 min) |
| `ENABLE_CORS` | No | Set `true` for browser testing only |
| `TRUST_PROXY` | No | Set `false` if not behind a reverse proxy |
| `NOTIFICATIONS_ENABLED` | No | `true` to start live notification worker (default `false`) |
| `NOTIFICATIONS_DRY_RUN` | No | `true` = log only, no FCM send (default `true`) |
| `NOTIFICATIONS_POLL_SECONDS` | No | Live poll interval (default `60`) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | No | Firebase Admin JSON (single line); required only when enabled **and** dry run is `false` |

Alias: `KICKORA_API_FOOTBALL_KEY` (same as `API_FOOTBALL_KEY`).

Copy `.env.example` to `.env` for local runs (never commit `.env`).

## Local run

```bash
cd backend
cp .env.example .env
# Edit .env — set API_FOOTBALL_KEY
npm install
npm start
```

Health check:

```bash
curl http://localhost:8080/health
```

Sample data route (uses your API quota):

```bash
curl "http://localhost:8080/competitions"
```

Cache header: `X-Kickora-Cache: HIT` or `MISS`.

## Cheapest deployment options

| Platform | Why | Rough cost |
|----------|-----|------------|
| **Railway** | Simple Node deploy, env vars UI, free tier credits | ~$0–5/mo at low traffic |
| **Render** | Free web service (cold start) or $7/mo always-on | $0 or $7/mo |
| **Fly.io** | Small VM, good for always-on proxy | ~$3–5/mo |
| **Google Cloud Run** | Pay per request; scales to zero | Pennies at MVP scale |

Recommendation for Kickora MVP: **Railway** or **Render Web Service** with this repo’s `backend/` folder as root.

### Railway (example)

1. New project → Deploy from GitHub → set **Root Directory** to `backend`.
2. Variables: `API_FOOTBALL_KEY`, `PORT=8080`, `TRUST_PROXY=true`.
3. Deploy → copy public URL (e.g. `https://kickora-api.up.railway.app`).

### Render (recommended)

1. **New Web Service** → connect this GitHub repo.
2. **Root Directory:** `backend`
3. **Runtime:** Node
4. **Build command:** `npm install`
5. **Start command:** `npm start`
6. **Health check path:** `/health` (optional but recommended)
7. **Environment variables** (Render dashboard → Environment):

| Variable | Value |
|----------|--------|
| `API_FOOTBALL_KEY` | Your API-SPORTS key (**required**, secret) |
| `PORT` | `8080` (Render sets this automatically; explicit is fine) |
| `TRUST_PROXY` | `true` |
| `RATE_LIMIT_MAX` | `120` (optional) |
| `RATE_LIMIT_WINDOW_MS` | `900000` (optional, 15 min) |
| `ENABLE_CORS` | `false` (optional; set `true` only for browser testing) |

Alternatively, import `render.yaml` from the repo root (Blueprint) — it pre-configures the above.

8. Deploy → copy the public URL (e.g. `https://kickora-api.onrender.com`).
9. Use that URL as `KICKORA_BACKEND_URL` in Flutter (no API key in the app).

**Free tier note:** Render free web services spin down after inactivity (cold start ~30–60s on first request). For production traffic, use a paid instance ($7/mo always-on).

Verify:

```bash
curl https://YOUR_SERVICE.onrender.com/health
curl "https://YOUR_SERVICE.onrender.com/competitions"
```

## Point the Flutter app at the proxy

Mock stays the default when no backend URL is set. For production data, pass only the backend URL (mode auto-detects):

```bash
flutter run --dart-define=KICKORA_BACKEND_URL=https://YOUR_DEPLOYED_URL
```

Explicit mode (optional):

```bash
flutter run --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://YOUR_DEPLOYED_URL
```

Release (no version bump in this step):

```bash
flutter build appbundle --release --dart-define=KICKORA_BACKEND_URL=https://YOUR_DEPLOYED_URL
```

Do **not** pass `KICKORA_API_KEY` in store builds.

## Verify end-to-end

1. `curl https://YOUR_DEPLOYED_URL/health` → `{"ok":true,...}`
2. `curl https://YOUR_DEPLOYED_URL/competitions` → JSON with `response` array
3. Run the app with `KICKORA_API_MODE=backend` and `KICKORA_BACKEND_URL` — live matches and competitions should load (not mock)

## Server-side caching

In-memory TTL cache per route (see `src/cache.js` and `docs/backend_proxy_caching.md`). For multiple instances, add Redis later; a single small VM is enough for early production.

## API routes (contract)

| Kickora route | Upstream |
|---------------|----------|
| `GET /matches/live` | `/fixtures?live=all` |
| `GET /matches/today` | `/fixtures?date=` |
| `GET /matches/upcoming` | `/fixtures` (+ upcoming filter) |
| `GET /matches/finished` | `/fixtures` (+ finished filter) |
| `GET /competitions` | `/leagues?current=true` |
| `GET /competitions/:id` | `/leagues?id=` |
| `GET /competitions/:id/top-scorers` | `/players/topscorers` |
| `GET /standings/:id` | `/standings` |
| `GET /teams/:id` | `/teams` |
| `GET /players/search?q=` | `/players?search=` |
| `GET /players/:id` | `/players?id=` |
| `GET /matches/:id` | `/fixtures?id=` |
| `GET /matches/:id/events` | `/fixtures/events` |
| `GET /matches/:id/statistics` | `/fixtures/statistics` |
| `GET /matches/:id/lineups` | `/fixtures/lineups` |

Query params from the app: `season`, `competitionId`, `date`, `q`.

## Live notification worker (Phase 1)

Polls API-Football live fixtures, detects goals/cards/status changes, and fans out FCM topic messages. **DRY_RUN is on by default** — no real pushes until you opt in.

Local dry-run:

```bash
# .env
NOTIFICATIONS_ENABLED=true
NOTIFICATIONS_DRY_RUN=true
NOTIFICATIONS_POLL_SECONDS=60
```

```bash
npm start
curl http://localhost:8080/notifications/status
curl http://localhost:8080/notifications/dry-run-events
curl -X POST http://localhost:8080/notifications/test-dry-run \
  -H "Content-Type: application/json" \
  -d '{"type":"goal_scored","fixtureId":42,"homeTeam":"ريال","awayTeam":"برشلونة","homeScore":1,"awayScore":0}'
```

Admin routes: `GET /notifications/status`, `GET /notifications/dry-run-events`, `POST /notifications/test-dry-run`.
