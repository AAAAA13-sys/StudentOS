# ACCOMPLISHED — StudentOS Audit Trail

Entries are appended, never edited. Corrections are new entries that reference the earlier date.

## Session 1: Project bootstrap
**Date:** 2026-11-15
**Verified by:** lead-pm
**Evidence:** `git init` on `main`; `docs/CONTRACT.md`; `docker-compose.yml`; `.claude/agents/` holds the seven roster agents; Docker daemon 29.8.2 reachable.
**Skills installed:** graphify (`pip install graphifyy` then `python -m graphify install`; the `graphify` launcher is not on PATH, so use `python -m graphify`). superpowers and ui-ux-pro-max were already installed and are listed by the harness.
**Decisions:**
- JWT is HS256 with a shared `JWT_SECRET`; the gateway validates before forwarding and every service validates again and takes the user id only from `sub`.
- One PostgreSQL container, four databases, one role per service (a role cannot connect to another service's database).
- Only the gateway is published to the host (port 8000). Services are reachable only on the compose network.
- Services run on PHP 8.3 in Docker; host PHP 8.2 runs composer and SQLite-backed tests. The owner's XAMPP `php.ini` is left untouched.
- Flutter project lives in `app/`.
**Open items:** Part 2.10 user validation is the owner's to run; see `PROGRESS.md` notes.
