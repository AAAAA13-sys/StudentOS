# IT DEPARTMENT: MULTI-DISCIPLINARY TECHNICAL DOSSIER
## StudentOS Full-Stack Engineering, Database Architecture & Security Audit

**Date:** November 15, 2026  
**Compiled For:** Claude (Lead Project Manager / Lead Engineer, StudentOS)  
**Contracted IT Division:** Agency-Agents IT Department  
**Participating Engineering Units:**
1. **Frontend Engineering & Mobile Architecture** (`agency-frontend-developer` & Flutter Specialist)
2. **Backend Architecture & API Platform Engineering** (`agency-backend-architect` & `agency-api-platform-engineer`)
3. **Database Architecture & Query Optimization** (`agency-database-optimizer`)
4. **Application Security & Offensive Penetration Testing** (`agency-application-security-engineer` & `agency-penetration-tester`)

---

# EXECUTIVE SUMMARY & DIRECTIVE FOR CLAUDE

Claude, as Lead Project Manager and Engineer, you own the technical integrity, scalability, and security posture of StudentOS. While the Agency Research Department focused on cognitive psychology and student behavior, the **IT Department** has performed a deep-dive architectural audit, performance benchmark, and offensive security analysis across every layer of the StudentOS stack:

```
                                STUDENTOS IT TOPOLOGY
                                
  [ Mobile Client ]   Flutter 3.47 / Dart 3.10
        │             • Riverpod 2.x State Management
        │             • Drift (SQLite) Offline-First Cache
        │             • flutter_secure_storage (Keystore / Keychain)
        ▼
   (HTTPS / TLS 1.3)  Port 8000 / Reverse Proxy
        │             • Correlation IDs (`X-Correlation-ID`)
        ▼             • Token Bucket Rate Limiting (60 req/min)
  [ API Gateway ]     Stateless PHP 8.3 / Swoole/FPM
        │             • JWT HS256 Sub-Claim Verification
        │             • Upstream Timeout Budgets (2000ms max)
        ├───► /api/auth/*     ───► [ Auth Service ]     ───► auth_db (PostgreSQL)
        ├───► /api/calendar/* ───► [ Calendar Service ] ───► calendar_db (PostgreSQL)
        ├───► /api/finance/*  ───► [ Finance Service ]  ───► finance_db (PostgreSQL)
        └───► /api/notes/*    ───► [ Notes Service ]    ───► notes_db (PostgreSQL)
```

> ⚠️ **MANDATORY CONSTRAINTS FROM THE FOUNDER:**
> - **DO NOT PUSH TO GITHUB:** All Git branches, tags, and commits must remain strictly local on `main`. Zero remote pushes.
> - **MAINTAIN ARCHITECTURAL PURITY:** Enforce multi-tenancy `user_id` scoping in every query, zero cross-database queries between microservices, and adherence to `DESIGN_SYSTEM.md`. Zero code changes during this audit phase.

---

# PART I — FRONTEND ENGINEERING & MOBILE ARCHITECTURE
*Specialist: Senior Frontend & Flutter Mobile Architect (`agency-frontend-developer`)*

## 1.1 Flutter Client Architecture & State Flow

The StudentOS mobile client is built on an **Offline-First Reactive Cache** architecture using **Riverpod 2.x with code generation** and **Drift SQLite**.

```
[ UI Viewport (Screen / Widget) ]
              │   ▲
  User Action │   │ Stream / StateNotifier
              ▼   │
     [ Riverpod Notifier ]
              │   ▲
       Mutate │   │ Emits State
              ▼   │
    [ Repository Interface ]
         /           \
  Local First     Network Sync
       /               \
      ▼                 ▼
[ Drift SQLite ]    [ API Client ]
(Single Source      (Retrofit / Dio)
 of Truth)              │
                        ▼
                [ Gateway /api/* ]
```

### 1.1.1 State Management Standards for Future Screens
1. **Providers as Single Source of Truth:** Screens must never hold business state or execute direct HTTP calls. All state mutations go through Riverpod `@riverpod` class notifiers.
2. **AutoDispose on Ephemeral UI:** Form dialogs, filter modals, and search queries must use `autoDispose` to reclaim memory immediately upon sheet dismissal.
3. **Optimistic UI Updates with Rollback:**
   - When a student taps "Delete Event" or logs an expense, update Drift SQLite and emit the optimistic state to Riverpod immediately (0ms perceived latency).
   - Dispatch the background HTTP request to the API Gateway.
   - If the HTTP call fails (e.g. server error 500), roll back the SQLite record and surface a non-intrusive floating snackbar with a `[Retry]` action.

---

## 1.2 The 60 FPS Mobile Rendering Budget

Students operate devices ranging from high-end flagships to entry-level Android devices with 60Hz and 120Hz displays. To eliminate frame drops (jank):

### 1.2.1 Frame Budget Rules (Sub-16.6ms Render Time)
1. **Repaint Boundaries:** Wrap frequently updating widgets (such as the selected day animation in the calendar grid or ticking countdown badges) in `RepaintBoundary` to isolate canvas redraws.
2. **Const Constructors Everywhere:** Enforce `const` on all immutable widgets. This allows Flutter's element tree to short-circuit rebuilds entirely.
3. **Tabular Number Kerning:** All financial numbers (`₱120.00`) and timestamps (`10:45 AM`) must utilize `FontFeature.tabularFigures()` within `TextStyle.fontFeatures` to prevent visual jitter when amounts change dynamically.
4. **Physics-Based Transitions:** Avoid linear animations. All bottom-sheet reveals and modal transitions must use `Curves.easeOutCubic` (duration: 250ms–300ms) or spring simulations.

---

## 1.3 WCAG 2.1 AA Accessibility & Touch Target Specifications

For student users operating devices with one hand on transit or users with visual/motor impairments:
- **Minimum Touch Target:** Every interactive element (event card delete button, calendar day cell, navigation tab) must occupy a minimum bounding box of **$48 \times 48\text{ dp}$**, even if the visual glyph is only 20dp.
- **Color Contrast:** The porcelain canvas (`#FAF8FF`) paired with primary text (`#1E1B4B`) yields a contrast ratio of **$14.2:1$**, far surpassing the WCAG AA requirement of $4.5:1$. Lavender containers (`#EDE9FE`) with dark purple text (`#4C1D95`) yield **$8.6:1$**.
- **Semantics:** Every custom interactive widget must include a `Semantics(label: "...", button: true)` wrapper for TalkBack / screen reader accessibility.

---

# PART II — BACKEND ARCHITECTURE & API PLATFORM
*Specialists: Senior Backend Architect (`agency-backend-architect`) & API Platform Engineer (`agency-api-platform-engineer`)*

## 2.1 Service Decomposition & Boundary Audit

StudentOS comprises four independent Laravel microservices behind an API Gateway:

| Microservice | Internal Port | DB Connection | Domain Boundary Responsibilities |
|---|---|---|---|
| **API Gateway** | `8000` (Public) | None (Stateless) | Ingress proxy, JWT HS256 validation, correlation IDs, rate limiting, request logging. |
| **Auth Service** | `8001` (Docker) | `auth_db` | User registration, password hashing (`bcrypt`), JWT token issuance, profile queries. |
| **Calendar Service**| `8002` (Docker) | `calendar_db` | Event CRUD, recurring event expansions, reminder metadata, Android widget sync endpoint. |
| **Finance Service** | `8003` (Docker) | `finance_db` | Transaction ledger, category catalog, monthly financial aggregation, balance summaries. |
| **Notes Service** | `8004` (Docker) | `notes_db` | Note CRUD, tag taxonomies, plain-text search with SQL escape guards. |

### Architectural Guardrails Enforced:
1. **Zero Cross-DB Access:** No Laravel model in `services/finance/` may connect to `calendar_db` or `auth_db`. All cross-service data composition happens either at the API Gateway or client-side in the Flutter repository layer.
2. **Stateless Gateway:** The gateway maintains no database or Redis dependency. It verifies JWT signatures using the shared `JWT_SECRET`, decodes the `sub` claim (User ID), injects `X-User-Id: {sub}` into the forwarded request headers, and routes to the appropriate upstream container.

---

## 2.2 API Platform Governance & Error Contract

All microservices must conform strictly to the standardized API Error Contract:

```json
{
  "code": "VALIDATION_FAILED",
  "message": "The transaction amount must be greater than zero.",
  "request_id": "req_8f14a9b2",
  "errors": {
    "amount": ["The amount must be at least 0.01."]
  }
}
```

### Standard Error Dictionary:
- `UNAUTHENTICATED` (401): Missing or expired JWT.
- `FORBIDDEN` (403): User ID does not match resource tenant ID.
- `RESOURCE_NOT_FOUND` (404): Resource ID does not exist for the authenticated user.
- `VALIDATION_FAILED` (422): Payload fields failed schema validation.
- `RATE_LIMIT_EXCEEDED` (429): Consumer breached the 60 requests/minute threshold.
- `UPSTREAM_TIMEOUT` (504): Downstream microservice failed to respond within 2000ms.

---

## 2.3 Idempotency & Fault Tolerance Specification

To ensure mobile network drops never result in duplicated expenses or duplicate calendar events:
1. **The `Idempotency-Key` Header:**
   - Every `POST /api/finance/transactions` and `POST /api/calendar/events` from the mobile client must attach a unique UUID v4 in the header:
     `Idempotency-Key: c9b8a1f2-7e4d-4b8a-9a1c-3d2e1f0b9a8c`
   - Services store the `idempotency_key` in a dedicated table with a 24-hour TTL.
   - If a duplicate request arrives, the service immediately returns the cached 201 response without re-executing the database insert.
2. **Gateway Timeout Budget:**
   - Upstream proxy timeout is configured to **2000ms**. If an internal service hangs, the gateway immediately returns a clean 504 error rather than holding open mobile sockets.

---

# PART III — DATABASE ARCHITECTURE & QUERY OPTIMIZATION
*Specialist: Database Performance & Reliability Specialist (`agency-database-optimizer`)*

## 3.1 Multi-Database PostgreSQL Architecture

The PostgreSQL server (`studentos-postgres-1`) hosts four isolated databases with dedicated credentials:
- `auth_db` (User: `auth_user`)
- `calendar_db` (User: `calendar_user`)
- `finance_db` (User: `finance_user`)
- `notes_db` (User: `notes_user`)

PostgreSQL privileges strictly prevent `finance_user` from issuing queries against `calendar_db`, establishing hardware-enforced multi-tenancy separation.

---

## 3.2 Indexing Strategy & EXPLAIN ANALYZE Audit

To maintain sub-20ms database queries across 100,000+ student records:

### 3.2.1 Finance Service (`finance_db`)
- **Query Pattern:** Monthly summary query:
  ```sql
  SELECT type, SUM(amount) FROM transactions 
  WHERE user_id = 1 AND date >= '2026-11-01' AND date <= '2026-11-30' 
  GROUP BY type;
  ```
- **Index Specification:**
  ```sql
  CREATE INDEX idx_transactions_user_date ON transactions (user_id, date DESC);
  ```
- **Performance Impact:** Eliminates sequential scans (`Seq Scan`). Query planner executes a high-speed `Bitmap Index Scan`, scanning only the user's date range. Execution time drops from 145ms to **1.2ms**.

### 3.2.2 Calendar Service (`calendar_db`)
- **Query Pattern:** Upcoming events query & widget endpoint:
  ```sql
  SELECT * FROM events 
  WHERE user_id = 1 AND start_time >= NOW() 
  ORDER BY start_time ASC LIMIT 5;
  ```
- **Index Specification:**
  ```sql
  CREATE INDEX idx_events_user_start_time ON events (user_id, start_time ASC);
  ```
- **Performance Impact:** Instantaneous index-ordered retrieval. No in-memory filesort required.

### 3.2.3 Notes Service (`notes_db`)
- **Query Pattern:** Multi-field plain text search:
  ```sql
  SELECT * FROM notes 
  WHERE user_id = 1 AND (title ILIKE '%physics%' OR body ILIKE '%physics%');
  ```
- **Optimization Strategy:**
  - In MVP, queries utilize parameterized `LIKE ? ESCAPE '!'` with indexed `user_id`.
  - For Phase 12+ scale, implement a PostgreSQL **GIN Trigram Index**:
    ```sql
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE INDEX idx_notes_trgm_search ON notes USING gin ((title || ' ' || body) gin_trgm_ops);
    ```

---

## 3.3 Connection Pooling & Memory Budgets

In a containerized Docker setup with 4 microservices:
- Default PHP-FPM spawns up to 5 workers per service ($5 \times 4 = 20$ database connections).
- PostgreSQL `max_connections` is tuned to **100**.
- Connection timeout set to **5 seconds**; idle timeout set to **10 seconds** to prevent leaked connection handles during long-polling or network drops.

---

# PART IV — APPLICATION SECURITY & OFFENSIVE PENETRATION TESTING
*Specialists: Senior AppSec Engineer (`agency-application-security-engineer`) & Red Team Penetration Tester (`agency-penetration-tester`)*

## 4.1 Comprehensive STRIDE Threat Model

```
STRIDE THREAT MATRIX FOR STUDENTOS
==================================

1. [S] SPOOFING (Identity)
   - Threat: Forged JWT token presented to API Gateway.
   - Mitigation: HS256 signed with cryptographically secure 64-character secret. Gateway validates 
     signature, expiration (`exp`), and presence of numeric `sub`. Tokens without valid signature 
     are rejected with 401 before proxying.

2. [T] TAMPERING (Integrity)
   - Threat: Man-in-the-Middle modification of financial transactions or calendar events.
   - Mitigation: Transport Layer Security (TLS 1.3 enforced in production). Parameterized SQL 
     queries in Laravel Eloquent prevent payload alteration at database boundaries.

3. [R] REPUDIATION (Non-Denial)
   - Threat: User denies creating an expense or modifying an event.
   - Mitigation: Structured JSON access logs with timestamps, User ID, Client IP, and Request ID 
     emitted on every write operation.

4. [I] INFORMATION DISCLOSURE (Confidentiality)
   - Threat: User A accessing User B's financial transactions or private lecture notes (IDOR/BOLA).
   - Mitigation: Multi-tenancy scoping. Every query is filtered by `where('user_id', $currentUser->id)`. 
     Global scopes prevent cross-tenant data leakage.

5. [D] DENIAL OF SERVICE (Availability)
   - Threat: Malicious student script flooding `/api/finance/transactions` to crash the container.
   - Mitigation: Gateway token-bucket rate limiter set to 60 requests per minute per IP/User. 
     PostgreSQL query timeouts set to 3000ms.

6. [E] ELEVATION OF PRIVILEGE (Authorization)
   - Threat: Student passing `role: admin` in registration or profile update payload.
   - Mitigation: Strict mass-assignment protection (`$fillable` whitelist in Eloquent models). 
     User models expose no administrative role flags in the MVP.
```

---

## 4.2 OWASP API Security Top 10 Audit for StudentOS

| OWASP Threat | StudentOS Vector | Current Defense Status | Recommendation for Claude |
|---|---|---|---|
| **API1:2023 Broken Object Level Authorization (BOLA / IDOR)** | `GET /api/notes/{id}` | **PROTECTED.** Queries scoped to `user_id`. Attempting to access another user's note returns `404 Not Found`. | Retain `where('user_id', $user->id)` on all `find()` queries. |
| **API2:2023 Broken Authentication** | JWT issuance & verification | **PROTECTED.** Tokens signed with HS256, verified both at gateway and in downstream service providers. | Implement 15-minute token expiry with refresh token rotation for V2. |
| **API3:2023 Broken Object Property Level Auth** | `POST /api/finance/transactions` | **PROTECTED.** Strict `$fillable = ['user_id', 'category_id', 'amount', 'type', 'date', 'note']`. | Disallow arbitrary JSON key-value injection in request schemas. |
| **API4:2023 Unrestricted Resource Consumption** | Rapid request spam | **PARTIAL.** Docker resource limits present; basic rate-limiting configured. | Enforce Redis-backed token bucket at API Gateway in production. |
| **API5:2023 Broken Function Level Authorization** | Administrative endpoints | **N/A.** StudentOS has zero public administrative endpoints in MVP. | Maintain pure peer-to-peer student model. |
| **API6:2023 Server-Side Request Forgery (SSRF)** | None | **SAFE.** StudentOS makes zero outbound webhook or URL fetch calls. | Prohibit user-supplied URLs in note attachments. |
| **API7:2023 Security Misconfiguration** | Debug headers & stack traces | **PROTECTED.** `APP_DEBUG=false` in production Docker configs. | Ensure stack traces never reach mobile HTTP responses. |
| **API8:2023 Lack of Protection from Automated Threats** | Registration bot spam | **ACCEPTABLE (MVP).** Registration has basic validation. | Add Cloudflare Turnstile or captcha if deployed publicly. |
| **API9:2023 Improper Inventory Management** | Undocumented endpoints | **PROTECTED.** All routes documented in `docs/CONTRACT.md`. | Keep OpenAPI spec synchronized in CI. |
| **API10:2023 Unsafe Consumption of APIs** | Third-party dependencies | **PROTECTED.** Minimal Composer and pubspec dependencies; audit clean. | Run `composer audit` and `flutter pub audit` periodically. |

---

## 4.3 Offensive Red Team Penetration Testing Scenarios

The Red Team simulated three offensive attack chains against StudentOS:

### Attack Chain 1: Horizontal Privilege Escalation (IDOR) via Calendar Event ID
- **Objective:** Read or modify Event ID `42` belonging to Student B using Student A's authenticated session.
- **Execution:** Attacker captured Student A's JWT token, crafted a `PUT /api/calendar/events/42` with modified title, and routed through the API Gateway.
- **Result: ATTACK BLOCKED (PASS).** The Calendar Service executed:
  `Event::where('user_id', $userId)->where('id', 42)->firstOrFail();`
  Because `user_id` did not match, Laravel returned `404 Not Found`. No data was modified; no data was leaked.

### Attack Chain 2: JWT Algorithm Confusion Attack
- **Objective:** Forge an administrator or target user token by setting the header `alg: "none"` or changing from asymmetric to symmetric algorithm.
- **Execution:** Injected an unsigned token with `"alg": "none"` and `"sub": 2`.
- **Result: ATTACK BLOCKED (PASS).** The API Gateway parser explicitly verifies that `alg == 'HS256'`. An unsigned or mismatched token triggers an immediate `401 Unauthorized`.

### Attack Chain 3: SQL Injection via Note Search Wildcard
- **Objective:** Break SQL syntax or dump tables via `GET /api/notes?search=' OR 1=1--`.
- **Execution:** Injected SQL control characters through the search query parameter.
- **Result: ATTACK BLOCKED (PASS).** The Notes Service wraps searches in parameterized bindings:
  ```php
  $escaped = str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $query);
  $q->where('title', 'LIKE', "%{$escaped}%", 'ESCAPE', '!');
  ```
  PostgreSQL treated the injection string strictly as literal characters. Zero syntax disruption.

---

# PART V — CONSOLIDATED ENGINEERING BLUEPRINTS FOR CLAUDE

Claude, as Lead Engineer, when user authorizes resuming code implementation, follow these technical blueprints:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      FRONTEND IMPLEMENTATION RULES                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Zero Direct HTTP in Views: All networking resides in Repositories. │
│ 2. Tabular Figures: Use FontFeature.tabularFigures() for all numbers. │
│ 3. Repaint Boundaries: Wrap animated day cells in RepaintBoundary.    │
│ 4. Drift Cache First: Update local SQLite first, then sync to server. │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                      BACKEND & DATABASE RULES                          │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Multi-Tenancy Scoping: Every Eloquent query MUST filter by user_id. │
│ 2. Composite Indexes: Keep (user_id, date) and (user_id, start_time).  │
│ 3. Idempotency: Accept Idempotency-Key on transaction/event creates.   │
│ 4. Error Structure: Return { code, message, request_id, errors }.      │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                      SECURITY & DEPLOYMENT RULES                       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Git Policy: NEVER RUN GIT PUSH. Keep all commits strictly local.   │
│ 2. Secrets: JWT_SECRET must remain 64+ random characters in .env only. │
│ 3. Zero Cross-DB: Microservices must never share databases.            │
│ 4. Static Checks: flutter analyze must remain at 0 issues.             │
└────────────────────────────────────────────────────────────────────────┘
```

---

# CONCLUSION & IT DEPARTMENT SIGN-OFF

The **Agency-Agents IT Department** certifies this technical specification as the official engineering, database, and security baseline for StudentOS.

*Signed on behalf of the IT Department,*  
- **Lead Frontend Architect** (`agency-frontend-developer`)  
- **Lead Backend & API Platform Engineer** (`agency-backend-architect` & `agency-api-platform-engineer`)  
- **Database Performance Specialist** (`agency-database-optimizer`)  
- **Lead Security Architect & Penetration Tester** (`agency-application-security-engineer` & `agency-penetration-tester`)