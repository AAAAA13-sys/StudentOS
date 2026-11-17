# StudentOS — Mobile Design System & Anti-Slop Specification

**Version:** 1.0 (Post-MVP UI Refinement)  
**Target:** Flutter Android / iOS  
**Aesthetic:** Modern Anti-Slop, Calming Porcelain with Hint of Lavender Accent  
**Primary Guideline:** Material 3 Expressive + Apple Human Interface Guidelines + Anti-Slop Manifesto

---

## 1. Executive Summary & Anti-Slop Manifesto

### 1.1 What is "AI Slop" in Mobile UI?
Modern AI-generated and template-driven mobile apps suffer from predictable design anti-patterns:
1. **Purple Gradient Syndrome:** Heavy, saturated 45-degree indigo-to-magenta gradients splashed across every background, card, and hero section.
2. **Motion Bloat:** Sluggish 600ms–800ms floating transitions, gratuitous bounce animations, and parallax effects that delay real user action.
3. **Card-in-Card Clutter:** Cards nested inside cards with 12px blurry drop-shadows (`box-shadow: 0 10px 30px rgba(0,0,0,0.15)`) that create visual noise rather than structure.
4. **Emoji as Icons:** Using raw Unicode emojis (🎉, 💰, 📅, 📝) instead of clean, unified vector iconographies.
5. **Chaotic Typography:** Inconsistent font weights, arbitrary sizes, lack of baseline grid, and non-tabular numbers that jump when values update.
6. **Navigation Overcrowding:** Jamming 5+ heavy items, floating action buttons, and secondary settings into a cramped bottom bar.

### 1.2 The Anti-Slop Principles for StudentOS
StudentOS is a high-utility productivity suite for students. It must feel calm, instantaneous, focused, and crafted:
- **Restraint Over Spectacle:** 90% of the UI is clean, breathable canvas. The lavender palette is a **delicate accent**, not a full-screen purple wash.
- **Hairlines Over Heavy Shadows:** High-craft 0.75px–1.0px subtle borders (`#E2D6F5` light / `#4A3A7A` dark) replace muddy drop-shadows to define depth.
- **Tabular Figures for Data:** All currency amounts (`₱120.00`), dates, and durations use monospace/tabular figure alignment (`fontFeatures: [FontFeature.tabularFigures()]`).
- **Tactile, Snappy Micro-Interactions:** 
  - Button taps: **100ms–140ms** subtle lavender ripple.
  - Sheet and drawer transitions: **250ms–300ms** utilizing physics-based deceleration (`Curves.easeOutCubic`).
- **Dual-Tier Ergonomics:** Thumb-friendly 3-destination bottom bar for frequent module switching, paired with a **Hamburger Drawer** for back up, restore, home-screen widgets and About (no account: the app is local-only).

---

## 2. "Hint of Lavender" Color Architecture

### 2.1 The Philosophy: Calming Lavender + Slate Contrast
Lavender is scientifically proven to evoke calmness, reduce cognitive load, and foster mental clarity. Rather than neon violet, StudentOS uses a muted, royal lavender primary paired with soft lavender-tinted surfaces.

### 2.2 Color Tokens (Midnight Lavender Scheme)

| Token Name | Hex Code | Purpose |
|------------|----------|---------|
| `midnightIndigo` | `#0B0720` | Deepest Midnight/Indigo: Dark mode scaffold background, high-contrast text |
| `darkPurple` | `#25134D` | Dark Purple: dark mode containers (chips, filled inputs) |
| `cardDark` | `#170E38` | Dark mode cards, sheets, dialogs, drawer, nav bar: one step above `#0B0720` |
| `mutedLight` | `#5E5873` | Light mode secondary text, hints, inactive nav icons (5.7:1 on `#F2E9FF`) |
| `vibrantViolet` | `#6A2FC8` | Vibrant Violet: Primary Brand Accent, key CTA buttons, active tab indicators |
| `mediumLavender` | `#9D71E8` | Medium Lavender: Secondary accent, dark mode primary, outlines |
| `lightLilac` | `#D1B8FF` | Light Lilac: Light mode primary container, active chips, selected pill fill |
| `paleLavenderWhite` | `#F2E9FF` | Pale Lavender White: Light mode scaffold canvas, subtle card background |
| `surfaceWhite` | `#FFFFFF` | Card surfaces, modal sheets, dialogs (Light mode) |
| `hairlineLight`| `#E2D6F5` | 1px border stroke for light cards and dividers |
| `hairlineDark` | `#4A3A7A` | 1px border stroke for dark cards, sheets, dialogs and dividers (~2:1 on `#0B0720`) |

### 2.3 Semantic Module Accents
Each module maintains identity without breaking overall harmony:
- **Calendar:** Vibrant Violet (`#6A2FC8` light / `#9D71E8` dark) — Schedule, time, classes.
- **Finance (Income):** Sage Emerald (`#059669` light / `#34D399` dark) — Money received, positive balance.
- **Finance (Expense):** Rose Coral (`#E11D48` light / `#FB7185` dark) — Money spent, negative balance.
- **Notes:** Warm Amber (`#D97706` light / `#FBBF24` dark) — Ideas, tags, lecture highlights.

---

## 3. Typography Hierarchy

### 3.1 Type Scale Specification
Base font family: **Plus Jakarta Sans** (Google Fonts) with system fallback to **Roboto** (Android) and **San Francisco** (iOS).

```
Display Large   | 32sp | Bold (700)      | Tracking -0.5px | Screen hero titles
Headline Small  | 24sp | SemiBold (600)  | Tracking -0.2px | Section headings, dialog titles
Title Large     | 20sp | SemiBold (600)  | Tracking 0px    | Screen AppBars, modal headers
Title Medium    | 16sp | SemiBold (600)  | Tracking 0.1px  | Card titles, note titles
Body Large      | 15sp | Regular (400)   | Tracking 0.15px | Note body, descriptions (1.5 line height)
Body Medium     | 14sp | Regular (400)   | Tracking 0.2px  | List subtitles, hints
Label Large     | 14sp | Medium (500)    | Tracking 0.1px  | Button labels, chip text
Label Medium    | 12sp | Medium (500)    | Tracking 0.4px  | Category pills, time badges
Label Small     | 11sp | Regular (400)   | Tracking 0.5px  | Timestamps, meta info
```

### 3.2 Tabular Numbers Rule
For all monetary figures, financial summaries, and time durations:
```dart
style: textTheme.headlineMedium?.copyWith(
  fontWeight: FontWeight.w700,
  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
)
```

---

## 4. Navigation Architecture: The Dual-Tier Standard

### 4.1 Tier 1: Bottom Navigation Bar (`NavigationBar`)
Thumb-zone navigation for the 3 daily destinations. On 2026-11-17 the owner asked for "the clock combined with the calendar", so the former Clock tab now lives inside Calendar:
1. **Calendar** (`Icons.calendar_today_rounded` / `Icons.calendar_month_rounded`): a full-width segmented control under the app bar switches Schedule (default), Alarms and Focus. Each view owns its app-bar actions and FAB (Schedule: Today, More, add event; Alarms: add alarm; Focus: settings, no FAB). System Back on Alarms or Focus returns to Schedule. Schedule is one scrolling page: month grid, pinned day header, shifts, compact event rows (72dp minimum, note as a trailing icon, delete in the edit sheet or by long-press). Focus keeps the idle view to one screen (compact plan card, Start, Today card, collapsed week and top-apps tiles). A running focus session shows a 40dp banner above the bar everywhere except Calendar > Focus. The routes `/clock` and `/focus` redirect to `/calendar?view=alarm|focus`. Sheets open on the root navigator so they cover the bottom bar. The ringing alarm screen is native Android, drawn in the Midnight Lavender colours.
2. **Finance** (`Icons.account_balance_wallet_outlined` / `Icons.account_balance_wallet_rounded`): one hero, the "Left this month" card (balance, spent-of-income bar, income and spent, top-3 categories); a 56dp Work pay row only when shifts exist; transactions grouped by day, one hairline card per day, delete inside the edit sheet. Safe-to-Spend was removed from the UI on 2026-11-17 (owner: "i dont need safe allowance"); its settings keys stay in the database and backups.
3. **Notes** (`Icons.article_outlined` / `Icons.article_rounded`): compact cards with a 2-line preview and one meta row; delete by long-press or in the editor.

**Design Details:**
- Height: 68dp.
- Indicator pill: Light Lilac container (`#D1B8FF` light / `#25134D` dark).
- Active icon color: `#6A2FC8` (Vibrant Violet).
- Inactive icon color: `#5E5873` (`mutedLight`).
- Background: Seamlessly matches or sits on `#FFFFFF` with a 1px top hairline border.

### 4.2 Tier 2: The Hamburger Drawer (`NavigationDrawer`)
Located at the top-left of every screen's app bar (`Icons.menu_rounded`). It holds what is not a tab and never repeats the bottom bar:
- **Header:** app name and the line "Everything is stored on this device."
- **Your data:** Back up to a file, Restore from a file.
- **About:** app version.

### 4.2.1 Top bar
Every tab uses `AppTopBar`: menu button, left-aligned tab name (`Calendar`, `Finance`, `Notes`), at most two actions. Calendar has Today and a More menu (Add a class); Finance and Notes have none. Month switching is not in the bar: `MonthSwitcher` sits in the content on Calendar and Finance.

### 4.3 Interactive Digital Calendar Component Specification
A true working digital calendar replaces static month headers with an interactive 7-column month grid:
- **Month Grid Architecture:**
  - 7-column header: `S M T W T F S` in `onSurfaceVariant` (medium 11sp).
  - 5 to 6 row grid dynamically calculating weekday offset for the active month.
  - Cell size: 38×34dp with circular touch targets.
  - **Selected Day:** Solid Vibrant Violet (`#6A2FC8`) circle with bold white text.
  - **Today Indicator:** Outlined Lavender circle with primary text.
  - **Event Dot:** 4px dot below day number indicating scheduled classes/events on that date.
  - Tapping any day cell sets `_selectedDate` with a 150ms cubic ease animation, updates the agenda view, and pre-fills that date in the Add Event modal.
- **Dual-Mode Agenda Below Calendar:**
  - Date header with event count and quick `+` add button.
  - Filter chip toggle: `Day View` (focused daily schedule) vs `All Events` (month overview).
  - Cards feature Lavender date badge (`NOV 15`), time & duration (`2:45 PM (60m)`), location, recurrence pill (`Repeats daily`), and delete action.

---

## 5. Motion, Curves & Micro-Interactions

### 5.1 Easing Standards
Never use linear transitions or slow robotic springs. Use standard Material 3 / iOS natural deceleration curves:
- **`Curves.easeOutCubic`:** Used for sheet entrance, drawer slide-in, dialog popups (250ms–300ms).
- **`Curves.easeInOutCubic`:** Used for tab page changes, state morphing (200ms–250ms).
- **`Curves.fastOutSlowIn`:** Used for expanding cards or collapsing panels.

### 5.2 Modal Bottom Sheets
- Rounded top corners: `BorderRadius.vertical(top: Radius.circular(24))`.
- Visual drag handle: 36px wide × 4px high, color `outlineVariant.withOpacity(0.5)`.
- Background: Pure surface white (`#FFFFFF`) in light mode, `#170E38` in dark mode.
- Keyboard-aware padding: `EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)`.

---

## 6. Anti-Slop Verification Checklist for Mobile

Before declaring any UI task done, verify:
- [ ] No gradient backgrounds used as screen backdrops.
- [ ] All borders are hairline thin (0.75px–1.0px) with subtle contrast.
- [ ] No raw Unicode emojis used in place of icons.
- [ ] Bottom navigation has exactly 3 destinations (Calendar, Finance, Notes); Clock lives in Calendar as the Alarms and Focus views.
- [ ] The top bar has the tab name and at most two actions.
- [ ] The menu opens smoothly and holds only non-tab items.
- [ ] Money numbers use `FontFeature.tabularFigures()`.
- [ ] Tap targets are minimum 48×48dp.
- [ ] Bottom sheets dismiss smoothly and respect keyboard insets.
- [ ] App is tested in both Light Mode and Dark Mode.

---

## Mascot: Ponpon

Ponpon is an orange tabby puspin (pusang Pinoy), StudentOS's mascot. Use the `Ponpon` widget (`lib/core/widgets/ponpon.dart`), never an emoji or a photo.

| Mood | Use |
|------|-----|
| `happy` | Default, menu header, empty lists that are fine to be empty |
| `sleepy` | Nothing scheduled, no alarms, focus breaks |
| `yelling` | A ringing alarm |
| `smug` | "Still awake?", a search with no match, a paused timer |
| `focused` | The focus timer |

Sizes: 56-64 in headers, 88-120 in empty states, 48-56dp centred at the end of each home-screen widget. Ponpon's colours do not follow the theme. Android-side images come from `tool/render_ponpon_test.dart`.

### Talk bubble ("Ponpon says")

`PonponTalk` (`lib/core/widgets/ponpon_talk.dart`) is a compact row: Ponpon at 48dp and a speech bubble with its tail pointing at him. Use it for one-line, rule-based insights at the top of Calendar (Schedule view only), Finance and Notes, via `PonponTalkSlot`. Never on Alarms or Focus, and never next to an empty-state Ponpon (the slot is suppressed there).

- Fill is `primaryContainer`, text `onPrimaryContainer` (so Midnight Lavender follows the theme), outline a 0.75px `outlineVariant` hairline, no shadow. Text is `bodyMedium`, two lines at most, tabular figures.
- Tap the bubble for the next tip: 200ms `easeOutCubic` cross-fade, and Ponpon takes the tip's mood. The close button (48dp) hides the bubble for the rest of the app session; it is in memory only and returns on the next launch. No insights, no bubble.
- At most 4 tips per screen, sorted by priority. Rules live in `lib/features/insights/` as pure functions of `now` and on-device data. No network, no AI.
- Tone: short, plain, friendly, a little cheeky for `smug`. No emoji, no scolding, no exclamation marks. Money as `₱2,300` (whole pesos unless there are centavos); times as `8:00 AM`. Never mention Safe-to-Spend.
- Screen readers hear "Ponpon says: <text>" with the hint "Next tip".


