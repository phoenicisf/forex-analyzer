---
name: health-check
description: Verify all services are running and healthy — checks web (port 3000), API (port 5000/health), Celery worker, PostgreSQL, and Redis. Use this skill after deploying, restarting containers, debugging connectivity, or before running integration tests. Trigger on "health check", "are services running", "check status", "is everything up", "service down", "connectivity issue".
---

# Skill: Health Check

## Steps

1. **Check Web service (port 3000)**
   - `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000`
   - Expected: HTTP 200
2. **Check API service (port 5000)**
   - `curl -s http://localhost:5000/health`
   - Expected: JSON with `{ "status": "healthy" }` and HTTP 200
3. **Check Worker (Celery)**
   - `celery -A worker.celery_app:celery_app inspect ping`
   - Expected: pong response from at least one worker node
4. **Check Postgres (port 5432)**
   - `pg_isready -h localhost -p 5432`
   - Or: `docker compose exec postgres pg_isready`
   - Expected: accepting connections
5. **Check Redis (port 6379)**
   - `redis-cli -h localhost -p 6379 ping`
   - Expected: `PONG`

## Output Format

| Service  | Endpoint / Command         | Status  | Details          |
|----------|----------------------------|---------|------------------|
| Web      | http://localhost:3000       | UP/DOWN | HTTP status code |
| API      | http://localhost:5000/health| UP/DOWN | Response body    |
| Worker   | celery inspect ping        | UP/DOWN | Node count       |
| Postgres | pg_isready :5432           | UP/DOWN | Connection info  |
| Redis    | redis-cli ping :6379       | UP/DOWN | PONG / error     |

## Rules

- Run all checks; do not stop at the first failure
- Report every service even if healthy (full picture)
- If a service is DOWN, include the error message or exit code
- Suggest a fix or next step for any DOWN service
