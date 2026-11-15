# StudentOS — Architecture & API Contract (fixed 2026-11-15)

> **2026-11-15: not used by the app any more.** The owner made StudentOS a local, single-user app
> (see `AGENTS.md` Part 0). The Flutter app stores data on the device and never calls these
> services. This document still describes the code under `services/`.

This is the binding contract between all services, the gateway, and the Flutter app.
It exists so work can be built in parallel. Do not deviate; if something here is wrong
or missing, report it to the Lead PM instead of improvising.

## 1. Repository layout

```
StudentOS/
  docker-compose.yml          # postgres + 4 services + gateway
  .env / .env.example         # compose secrets (.env is gitignored)
  docker/php/Dockerfile       # shared image recipe (build context = a service dir)
  docker/postgres/init-dbs.sh # creates auth_db, calendar_db, finance_db, notes_db + one role each
  services/auth               # Laravel — Auth Service
  services/calendar           # Laravel — Calendar Service
  services/finance            # Laravel — Finance Service
  services/notes              # Laravel — Notes Service
  services/gateway            # Laravel — API Gateway (stateless, no database)
  app/                        # Flutter app (Android-first)
  docs/                       # contract, plans
```

## 2. Runtime topology

| Container | Internal URL | Host port | Database / role |
|-----------|--------------|-----------|-----------------|
| gateway   | http://gateway:8000  | **8000** (only public entry) | none |
| auth      | http://auth:8000     | none | auth_db / auth_user |
| calendar  | http://calendar:8000 | none | calendar_db / calendar_user |
| finance   | http://finance:8000  | none | finance_db / finance_user |
| notes     | http://notes:8000    | none | notes_db / notes_user |
| postgres  | postgres:5432        | 54329 (debug only) | — |

- Each service owns its database and its own DB role. No service touches another's database.
- The Flutter app only knows the gateway base URL (emulator default `http://10.0.2.2:8000`,
  overridable with `--dart-define=API_BASE_URL=...`).
- Every service gets its config from environment variables set in `docker-compose.yml`
  (`DB_CONNECTION=pgsql`, `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`,
  `JWT_SECRET`, `APP_KEY`, `LOG_CHANNEL=stderr`, `SESSION_DRIVER=array`, `CACHE_STORE=file`,
  `QUEUE_CONNECTION=sync`). No secrets in code.
- Container start command (set by the Dockerfile): `php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000`.
  The gateway overrides it to skip `migrate`.

## 3. JWT contract

- Library: `firebase/php-jwt` (^6 or ^7). Algorithm **HS256**. Secret: env `JWT_SECRET` (read via `config('jwt.secret')`, file `config/jwt.php`).
- Issued only by the Auth Service on register/login. Lifetime 7 days. No refresh tokens in the MVP.
- Claims: `iss` = `"studentos-auth"`, `sub` = user id **as a string**, `email`, `name`, `iat`, `exp`.
- Sent as `Authorization: Bearer <token>`.
- The gateway validates the token (signature, `exp`, `iss`) before forwarding. Invalid/missing → `401 {"message":"Unauthenticated."}`, never forwarded.
- **Every service validates the token again itself** (defence in depth) and derives the user id only from `sub`. Services never trust a user id from the body, query, or a header.
- Never log tokens or request bodies.

### Standard middleware (identical in every service)

`app/Http/Middleware/AuthenticateJwt.php`, alias `jwt`:

```php
public function handle(Request $request, Closure $next): Response
{
    $token = $request->bearerToken();
    if (! $token) {
        return response()->json(['message' => 'Unauthenticated.'], 401);
    }
    try {
        $claims = JWT::decode($token, new Key(config('jwt.secret'), 'HS256'));
    } catch (\Throwable $e) {
        return response()->json(['message' => 'Unauthenticated.'], 401);
    }
    if (($claims->iss ?? null) !== 'studentos-auth' || ! ctype_digit((string) ($claims->sub ?? ''))) {
        return response()->json(['message' => 'Unauthenticated.'], 401);
    }
    app(\App\Support\CurrentUser::class)->set((int) $claims->sub);
    return $next($request);
}
```

`App\Support\CurrentUser` is a scoped singleton (`$this->app->scoped(...)`) with `set(int $id)`, `id(): ?int`, and `idOrFail(): int` (throws if unset).

### Multi-tenancy (non-negotiable)

- Every table has a `user_id` (unsigned big integer, indexed, NOT NULL). No FK to another service's DB.
- Every tenant model uses the trait `App\Models\Concerns\BelongsToUser`, which
  1. adds a **global scope** `where user_id = CurrentUser::idOrFail()`, and
  2. sets `user_id` in the `creating` hook from `CurrentUser` (never from input; `user_id` is not fillable).
- Accessing another user's record must return **404**, not 403.
- Each service must have a feature test proving user B cannot read/update/delete user A's record.

## 4. HTTP conventions

- JSON only. Services force JSON responses (`Accept: application/json` behaviour even if header absent).
- Validation errors: Laravel default `422 {"message": "...", "errors": {"field": ["..."]}}`.
- Not found: `404 {"message":"Not found."}`. Server errors must not leak stack traces (`APP_DEBUG=false`).
- Timestamps are ISO-8601 UTC with `Z` (e.g. `2026-11-20T01:30:00Z`). The app converts to local time.
- List responses: `{"data": [...]}`. Single-resource responses: `{"data": {...}}` (auth is the exception, see below).
- IDs are integers.
- Health: `GET /api/<service>/health` → `200 {"status":"ok","service":"<name>"}`; for DB-backed services it runs `SELECT 1` and returns `503 {"status":"degraded",...}` on failure. Health is public (no JWT).
- Service route files use the full public path (the gateway forwards the path unchanged), e.g. the calendar service itself serves `/api/calendar/events`.

## 5. Gateway

- `ANY /api/{service}/{path?}` where service ∈ `auth|calendar|finance|notes` → forwarded to `<SERVICE>_SERVICE_URL` (env: `AUTH_SERVICE_URL`, `CALENDAR_SERVICE_URL`, `FINANCE_SERVICE_URL`, `NOTES_SERVICE_URL`) with the same method, path, query string, JSON body, and `Authorization` header. Also `ANY /api/notes` (no trailing path).
- Public (no JWT): `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/{service}/health`, and `GET /api/health` (gateway's own: `{"status":"ok","service":"gateway"}`).
- Everything else requires a valid JWT (section 3).
- Unknown service prefix → `404 {"message":"Not found."}`.
- Upstream unreachable / timeout (connect 3 s, total 10 s) → `502 {"message":"Service unavailable."}`.
- Upstream status code and JSON body are passed through unchanged (including 204 with empty body).
- Throttle `POST /api/auth/login` and `POST /api/auth/register`: 10 requests/minute per client IP → `429`.
- Access log line per request to stderr: method, path (no query string), status, duration ms, user id if authenticated. **No bodies, no tokens, no Authorization header.**

## 6. Auth Service — `/api/auth/*`

Table `users`: `id`, `name`, `email` (unique, stored lower-case), `password` (bcrypt/argon hash), timestamps.
(The `users` table is the one table whose tenant key is its own `id`.)

User JSON: `{"id":1,"name":"Ana","email":"ana@example.com","created_at":"...Z"}` — never the password hash.

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| GET  | /api/auth/health   | – | – | 200 health |
| POST | /api/auth/register | – | `name` (req, ≤100), `email` (req, email, unique), `password` (req, min 8) | 201 `{"user":{...},"token":"..."}` |
| POST | /api/auth/login    | – | `email`, `password` | 200 `{"user":{...},"token":"..."}`; bad credentials → 401 `{"message":"Invalid credentials."}` |
| GET  | /api/auth/me       | JWT | – | 200 `{"user":{...}}` |
| POST | /api/auth/logout   | JWT | – | 204 (stateless; client discards the token) |

## 7. Calendar Service — `/api/calendar/*` (all JWT except health)

Table `events`: `id`, `user_id`, `title` (≤150), `starts_at` (UTC datetime), `duration_minutes` (int, 1–1440, default 60),
`location` (nullable ≤150), `notes` (nullable text), `recurrence` (`none|daily|weekly|monthly`, default `none`),
`recurrence_until` (nullable date, inclusive), `reminder_minutes` (nullable int 0–10080), timestamps.

Event JSON:
```json
{"id":1,"title":"Math 101","starts_at":"2026-11-20T01:30:00Z","duration_minutes":90,
 "location":"Room 204","notes":null,"recurrence":"weekly","recurrence_until":"2026-12-18",
 "reminder_minutes":15,"created_at":"...Z","updated_at":"...Z"}
```

| Method | Path | Notes |
|--------|------|-------|
| GET | /api/calendar/health | public |
| GET | /api/calendar/events | Without params: `{"data":[Event,...]}` — raw events ordered by `starts_at`. With **both** `from` and `to` (ISO-8601 datetimes, `to` > `from`, span ≤ 366 days): `{"data":[Occurrence,...]}` — recurrences expanded server-side, ordered by `occurrence_start`. |
| POST | /api/calendar/events | body = event fields; 201 `{"data":Event}` |
| GET | /api/calendar/events/{id} | `{"data":Event}` |
| PUT | /api/calendar/events/{id} | partial update allowed; `{"data":Event}` |
| DELETE | /api/calendar/events/{id} | 204 |
| GET | /api/calendar/widget | `{"next_event": {"id":1,"title":"Math 101","starts_at":"...Z","location":"Room 204"} }` or `{"next_event": null}` |

- **Occurrence** = Event JSON + `"occurrence_start":"...Z"` (the start of that specific occurrence; for non-recurring events equals `starts_at`).
- Expansion: daily = +1 day, weekly = +7 days, monthly = +1 month without overflow (Jan 31 → Feb 28/29), all computed in UTC from `starts_at`; stop after `recurrence_until` (inclusive, end of that UTC day) if set. An occurrence is included when `from <= occurrence_start < to`.
- Widget `next_event`: the earliest occurrence (recurrences included) with `occurrence_start >= now`; its `starts_at` field is that occurrence's start. Look ahead at most 366 days.

## 8. Finance Service — `/api/finance/*` (all JWT except health)

Table `transactions`: `id`, `user_id`, `type` (`income|expense`), `amount` (decimal(12,2), > 0), `category`, `occurred_on` (date), `note` (nullable ≤255), timestamps.

Categories (fixed, exact strings): `Food`, `Transport`, `School`, `Entertainment`, `Allowance`, `Part-time Job`, `Other`.

Transaction JSON: `{"id":1,"type":"expense","amount":120.50,"category":"Food","occurred_on":"2026-11-15","note":"Lunch","created_at":"...Z","updated_at":"...Z"}` — `amount` is a JSON number.

| Method | Path | Notes |
|--------|------|-------|
| GET | /api/finance/health | public |
| GET | /api/finance/categories | `{"data":["Food","Transport",...]}` |
| GET | /api/finance/transactions | optional `month=YYYY-MM`, `category=<name>`, `type=income|expense`; ordered by `occurred_on` desc, `id` desc; `{"data":[...]}` |
| POST | /api/finance/transactions | 201 `{"data":Transaction}` |
| GET | /api/finance/transactions/{id} | `{"data":Transaction}` |
| PUT | /api/finance/transactions/{id} | partial update allowed |
| DELETE | /api/finance/transactions/{id} | 204 |
| GET | /api/finance/summary | `month=YYYY-MM` (default: current month, UTC) |

Summary JSON:
```json
{"month":"2026-11","total_income":5000.00,"total_expenses":1320.50,"balance":3679.50,
 "by_category":[{"category":"Food","type":"expense","total":820.50}, ...]}
```
`by_category` lists only categories that have transactions in that month, ordered by `total` desc. Sums are computed in SQL on the decimal column (no float accumulation).

## 9. Notes Service — `/api/notes/*` (all JWT except health)

Table `notes`: `id`, `user_id`, `title` (≤200), `body` (text, may be empty string), `tags` (JSON array of strings), timestamps.
Tags are normalised on write: trimmed, lower-cased, de-duplicated, each ≤30 chars, max 20 tags.

Note JSON: `{"id":1,"title":"Lecture 3","body":"...","tags":["math","exam"],"created_at":"...Z","updated_at":"...Z"}`

| Method | Path | Notes |
|--------|------|-------|
| GET | /api/notes/health | public |
| GET | /api/notes | optional `q` (case-insensitive substring match on title, body, or any tag) and `tag` (exact tag match); ordered by `updated_at` desc; `{"data":[...]}` |
| POST | /api/notes | 201 `{"data":Note}` |
| GET | /api/notes/{id} | numeric id only |
| PUT | /api/notes/{id} | partial update allowed |
| DELETE | /api/notes/{id} | 204 |
| GET | /api/notes/tags | `{"data":["exam","math",...]}` — the user's distinct tags, sorted |

Search must use bound parameters and escape `%`/`_` in `q`. It must work on PostgreSQL (production) and SQLite (tests).

## 10. Testing & verification

- Each Laravel service ships PHPUnit feature tests that run on the host with SQLite in-memory
  (`phpunit.xml`: `DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`, `JWT_SECRET=testing-secret-testing-secret-0123456789`).
  Host PHP is 8.2 (XAMPP) with `pdo_sqlite`; so `composer.json` must allow PHP ^8.2 and migrations must be SQLite-compatible.
- End-to-end verification is done by the Lead PM with curl against `http://localhost:8000` through the gateway on real PostgreSQL.
- Agents do **not** run `git commit` and do not run `docker compose` — the Lead PM integrates, verifies, and commits.
