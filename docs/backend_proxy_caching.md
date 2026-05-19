# Backend proxy — recommended server-side cache TTL

Client-side TTLs in Kickora mirror these buckets. Configure your **Kickora backend** (reverse proxy or app cache) with similar values to minimize API-Football cost.

| Resource | Endpoint pattern | Recommended TTL |
|----------|------------------|-----------------|
| Live matches | `GET /matches/live` | **60s** |
| Today matches | `GET /matches/today` | **5m** |
| Upcoming matches | `GET /matches/upcoming` | **5m** |
| Finished matches | `GET /matches/finished` | **10m** |
| Competitions list | `GET /competitions` | **24h** |
| Competition by id | `GET /competitions/{id}` | **24h** |
| Standings | `GET /standings/{competitionId}` | **10m** |
| Teams | `GET /teams/{competitionId}` | **24h** |
| Player search | `GET /players/search` | **24h** |
| Match details | `GET /matches/{id}` | **2m** |
| Match events | `GET /matches/{id}/events` | **2m** |
| Match statistics | `GET /matches/{id}/statistics` | **2m** |
| Match lineups | `GET /matches/{id}/lineups` | **2m** |

## Environment variables (Flutter)

```bash
--dart-define=KICKORA_API_MODE=backend
--dart-define=KICKORA_BACKEND_URL=https://your-api.example.com
```

Never ship `KICKORA_API_KEY` in Play Store release builds.
