# api.taxy.pt security smoke — 0.7.15

Run on 2026-09-02 using unauthenticated, non-destructive requests only.

| Check | Result |
|---|---|
| HTTPS and hostname validation | PASS |
| `GET /health` | 200, JSON, `Cache-Control: no-store` |
| Overview without authorization | 401, JSON, no-store |
| Invalid synthetic authorization | 401 |
| Write-like invoice route | 404 |
| Debug stack trace in sampled responses | Not observed |
| Secret-shaped fields in sampled responses | Not observed |
| Browser CORS wildcard | Not present |

This was a bounded configuration smoke, not a penetration test. No real
credential, session token or fiscal payload was used.
