# api.taxy.pt security smoke — 0.7.14

Run on 2026-09-02 using unauthenticated, non-destructive requests only.

| Check | Result |
|---|---|
| HTTPS and hostname validation | PASS |
| `GET /health` | 200, JSON, `Cache-Control: no-store` |
| Overview without authorization | 401, JSON, no-store |
| Pending invoices without authorization | 401, JSON, no-store |
| Invalid synthetic session | 401 |
| Write-like invoice route | 404 |
| Debug stack trace in sampled responses | Not observed |
| Secret-shaped fields in sampled responses | Not observed |
| Browser CORS wildcard | Not present |

This is a bounded configuration smoke, not a penetration test. No credential,
session token or fiscal payload was used.
