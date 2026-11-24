# Agency-Agents Research Department Roadmap — StudentOS (Phases 49–52)

**Date:** November 24, 2026  
**Baseline Commit:** `c17874c` (Phase 48 — Spaced Recall Deck, schema v13, Backup v9)  
**Contributing Units:**  
- **UX & Design Architecture (`613f7aa3`):** `agency-ux-researcher` + `agency-ui-designer`  
- **Cognitive Psychology & Behavioral Nudge (`f440a106`):** `agency-psychologist` + `agency-behavioral-nudge-engine`  
- **Systems & Local-First Android (`f997cce6`):** `agency-software-architect` + `agency-anthropologist`  
**Policy:** 100% local-first Flutter/Dart + Kotlin Android + Drift SQLite (`no INTERNET` in release), zero accounts, zero network, zero monetization/payments, zero Safe-to-Spend UI, zero school gradebook bloat, strictly 3 bottom `NavigationDestination`s (`Calendar`, `Finance`, `Notes`).

---

## 1. Cross-Disciplinary Diagnosis (Post-Phase 48)

With all four Phase 45–48 modules shipped (`Tasks`, `Savings Pockets`, `IOUs & Splits`, `Spaced Recall Deck`), StudentOS covers all major local capture and tracking primitives. The specialist audit across UX, Psychology, and Systems converged on three remaining structural bottlenecks:

1. **Unanchored Focus & Study Execution (`f440a106` + `613f7aa3`):**
   `focus_logs` records anonymous timer runs (`startedAt`, `endedAt`, `focusMs`, `rounds`, `endedEarly`) with no link to *what* the student studied (`events`, `tasks`, `notes`/`recall_reviews`). Tapping `PonponAction.startFocus` drops the user onto a generic 25m×4 timer with zero subject context, no low-friction starter sprint after early exits or short-rest nights, and no post-session loop closure (`Mark done` / `Review quiz`).
2. **Siloed Historical Telemetry & Lack of Portable Exports (`f997cce6` + `613f7aa3`):**
   `FocusRepository.totalsSince()` is queried only for today, `PhoneController` slices only 7 days (while `UsageStatsManager` silently expires if the student skips `Calendar > Alarms` for >7 days), `FinanceRepository.getTransactions(month, category)` isn't surfaced in UI search/drill-down, and `BackupService` exports opaque whole-DB JSON only (no `.csv` for shift DTR / expenses or `.md` for summaries).
3. **Home Screen, Notification Shade & Multi-Entity Navigation Friction (`f997cce6` + `613f7aa3`):**
   Nine entity types live across 3 tabs and 9 sub-views (`Schedule | Alarms | Focus`, `Cashflow | Goals | IOUs`, `Notes | Tasks | Recall`), yet only `Notes` has search, `wake_plan.dart` ignores early `Shift`s, and `Today` widget (`CalendarWidgetProvider.kt`) doesn't surface `Tasks` or `Shift`s.

---

## 2. Prioritized Module Roadmap (Phases 49–52)

| Phase | Initiative | Primary Anchor | Key Behavioral & Technical Value | Schema / Backup Impact | RICE |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **49** | **Context-Bound Focus Intentions & Adaptive Micro-Sprints** | `Calendar > Focus` + `Tasks` / `Exam` / `Recall` | Optional target binding (`task`, `event`, `recall`), 1-tap `10m starter` / `15m sprint` one-shot overrides without mutating saved settings, contextual `PonponAction.startFocus`, and post-session `Mark done` / `Review cards` closure. | Schema v14 (`focus_logs` nullable `targetType`, `targetId`, `targetLabel`), Backup v10 | **14.0** |
| **50** | **Month in Review, Finance Drill-Down & Portable Exports (`.csv` / `.md`)** | `AppDrawer` (`/review`) + `Finance > Cashflow` | Cross-pillar monthly synthesis (`shifts`, `focus_logs`, `transactions`, `tasks`, `recall_reviews`, `phone_days`), throttled `PhoneRepository.sync()` on resume, Finance Cashflow search/type filter + tappable `CategoryBreakdownSheet`, and formula-safe `.csv`/`.md` exports via `FilePicker.saveFile`. | Zero schema change (`v14`), zero Kotlin change | **14.3** |
| **51** | **Cross-Tab Global Search & Command Palette + Android `FocusTileService`** | `AppDrawer` / `AppTopBar` search + Quick Settings tile | Instant in-memory search across all 9 entities + quick actions (`Add expense`, `Add task`, `Start focus`, `Month in review`) plus offline `FocusTileService.kt` Quick Settings tile (API 34+ `PendingIntent` safe). | Zero schema change, 1 additive Kotlin `TileService` | **10.8** |
| **52** | **Today Command Widget v2, Shift-Aware Wake Guard & Wind-Down** | `Calendar > Alarms`, `CalendarWidgetProvider.kt`, `shortcuts.xml` | Guards early `Shift`s in `alarmGapFor`, adds opt-in Wind-Down reminder + Evening Shutdown / Rest notice, adds `add_task`/`open_recall` shortcuts, and shows shifts + up to 2 checkable tasks on Today widget reconciled via Drift on resume. | Optional Settings keys + `daily_checkins` (Schema v15 if check-in log added) | **9.2** |
