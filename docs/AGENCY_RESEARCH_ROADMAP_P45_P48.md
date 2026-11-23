# Agency-Agents Research Department Roadmap — StudentOS (Phases 45–48)

**Date:** November 24, 2026  
**Baseline Commit:** `32b5df6` (Phase 44)  
**Contributing Units:** `agency-ux-researcher`, `agency-behavioral-nudge-engine`, `agency-psychologist`, `agency-anthropologist`, `agency-trend-researcher`, `agency-research-synthesist`  
**Stack & Policy:** 100% Local-First Flutter/Dart + Kotlin + Drift SQLite, zero accounts, zero network calls, zero monetization/payment features, zero Safe-to-Spend UI, zero school/grade modules, strictly **3 bottom `NavigationDestination`s** (`Calendar`, `Finance`, `Notes` per `DESIGN_SYSTEM.md` §4).

---

## 1. Cross-Pillar Gap Analysis (Post-Phase 44)

Inspecting `app/lib/features/` (`calendar/`, `finance/`, `notes/`, `focus/`, `work/`, `phone/`, `insights/`) and `app_database.dart` (10 tables at schema v9: `events`, `transactions`, `notes`, `settings`, `shifts`, `phone_days`, `phone_app_days`, `alarms`, `focus_logs`, `bills`) highlights four high-value gaps:

1. **UX Friction (`agency-ux-researcher`) — No Standalone Action / Errand Primitive:**  
   Checklists currently exist only inside `CalendarEvent.notes` or buried inside `Note.body` (no standalone due date, no repeat-on-complete, no Overdue/Today triage). Unscheduled working-student errands (*"Send DTR", "Buy lab gown", "Claim clearance"*) pollute timed `CalendarEvent` blocks and trigger false `"Overlaps with..."` warnings in `WeekAgenda`.
2. **Cognitive Psychology (`agency-psychologist`) — Unclosed Zeigarnik Loops & Ephemeral Recall:**  
   Open non-timed tasks consume working memory because there is no trusted daily action queue. Meanwhile, `QuizSheetView` discards `Got it` / `Missed` outcomes on close instead of scheduling spaced reviews.
3. **Behavioral Nudge (`agency-behavioral-nudge-engine`) — Flat Balance Ambiguity:**  
   `FinanceScreen` shows a flat `"Left this month"` (`income - spent`) plus `WorkPayRow` and `BillsRow`, without positive goal pockets (mental accounting without Safe-to-Spend allowance math or scolding category budgets).
4. **Anthropology (`agency-anthropologist`) — Informal Student Economy:**  
   Working students frequently front group expenses or borrow/lend small amounts tied to `PaydaySchedule`, with no lightweight local IOU ledger separate from personal `Transactions`.
5. **2025/2026 Collegiate Trends (`agency-trend-researcher`):**  
   Students are leaving bloated, cloud-gated suites (Notion, subscription task apps) for fast offline-first tools with <3s capture that still work in campus Wi-Fi dead zones.

---

## 2. Top 4 New Module Roadmap (RICE Matrix: Phases 45–48)

$$\text{RICE} = \frac{\text{Reach (1–10)} \times \text{Impact (0.5–3.0)} \times \text{Confidence (0.0–1.0)}}{\text{Effort (person-days)}}$$

| Rank / Phase | New Module | Navigation Home | Core Student Value & Behavioral Integration | R | I | C | E | RICE |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **#1 (Phase 45)** | **Tasks** *(Action & Errand Queue)* | `Notes` segmented toggle (`Notes \| Tasks`) + `DayTasks` on `Calendar > Schedule` | Offloads Zeigarnik loops into `Overdue / Today / Upcoming / Anytime` buckets with repeat-on-complete, without polluting timed schedules or adding a 4th bottom tab; Ponpon `seeTasks` insight. | 10 | 2.5 | 0.95 | 1.5 | **15.8** |
| **#2 (Phase 46)** | **Savings Pockets** *(Goal Pots in Finance)* | `Finance` segmented toggle (`Cashflow \| Goals`) | Thaler mental accounting + goal-gradient progress bars (`₱3,500 / ₱8,000`) with optional `"Stash part of pay"` after `"I got paid"`, zero Safe-to-Spend math. | 8 | 2.5 | 0.90 | 1.5 | **12.0** |
| **#3 (Phase 47)** | **IOUs & Splits** *(Owed / Owing Ledger)* | `Finance` (`Cashflow` row or third sub-view) | Payday-anchored closure (`"Payday today: settle ₱300 with..."`) keeping temporary loans separate from real spending until settled. | 7 | 2.0 | 0.85 | 1.5 | **7.9** |
| **#4 (Phase 48)** | **Spaced Recall Deck** *(Persistent Review Queue)* | Inside `Notes` & `QuizSheetView` | Persists `Got it` / `Missed` intervals (Leitner spacing) prioritizing notes linked to upcoming `CalendarEvent.isExam` deadlines. | 6 | 2.0 | 0.85 | 1.5 | **6.8** |

---

## 3. Phase 45 Target Architecture — Module #1: Tasks

- **Schema v10 (`TaskRows`):** `id`, `title`, `notes` (nullable), `dueOn` (`YYYY-MM-DD` nullable), `repeat` (`'none'|'daily'|'weekly'|'monthly'`), `done` (bool), `doneAt` (nullable `DateTime`), `createdAt` (`DateTime`).
- **Backup v6 (`BackupService`):** Exports/restores `tasks` with automatic `[]` fallback for v1–v5 backups, reactive `backupStatusProvider` updates, and `AppDrawer` invalidation.
- **UI Parity:** Mirrors `Calendar`'s `SegmentedButton` pattern inside `NotesScreen` (`Notes | Tasks`, `notesViewProvider`, system Back returns `Tasks -> Notes`), plus `DayTasks` below `DayShifts` on `Calendar > Schedule` day view (`SizedBox.shrink()` when empty) and `PonponAction.seeTasks`.
