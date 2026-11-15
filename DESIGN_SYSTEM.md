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
- **Hairlines Over Heavy Shadows:** High-craft 0.75px–1.0px subtle borders (`#E4E0F0` light / `#2B273F` dark) replace muddy drop-shadows to define depth.
- **Tabular Figures for Data:** All currency amounts (`₱120.00`), dates, and durations use monospace/tabular figure alignment (`fontFeatures: [FontFeature.tabularFigures()]`).
- **Tactile, Snappy Micro-Interactions:** 
  - Button taps: **100ms–140ms** subtle lavender ripple.
  - Sheet and drawer transitions: **250ms–300ms** utilizing physics-based deceleration (`Curves.easeOutCubic`).
- **Dual-Tier Ergonomics:** Thumb-friendly 3-destination bottom bar for frequent module switching, paired with an elegant **Hamburger Drawer** for account profile, offline sync status, and secondary utilities.

---

## 2. "Hint of Lavender" Color Architecture

### 2.1 The Philosophy: Calming Lavender + Slate Contrast
Lavender is scientifically proven to evoke calmness, reduce cognitive load, and foster mental clarity. Rather than neon violet, StudentOS uses a muted, royal lavender primary paired with soft lavender-tinted surfaces.

### 2.2 Color Tokens

| Token Name | Hex Code | Purpose |
|------------|----------|---------|
| `lavender700` | `#6D28D9` | High-contrast interactive elements, active text, focused states |
| `lavender600` | `#7C3AED` | Primary Brand Color: Key CTA buttons, active icons, selected pill indicator |
| `lavender500` | `#8B5CF6` | Vibrant accent, tag highlights, dark mode secondary |
| `lavender300` | `#C4B5FD` | Dark mode primary text, subtle icon tint |
| `lavender100` | `#EDE9FE` | Light mode container background: active chips, selected cards, pill fill |
| `lavender50` | `#F5F3FF` | Very soft lavender tint for hover states and secondary cards |
| `lavenderMist` | `#FAF8FF` | Light mode scaffold background: crisp porcelain with 0.5% lavender warmth |
| `surfaceWhite` | `#FFFFFF` | Card surfaces, modal sheets, dialogs (Light mode) |
| `hairlineLight`| `#E4E0F0` | 1px border stroke for light cards and dividers |
| `hairlineDark` | `#2D2845` | 1px border stroke for dark cards and dividers |
| `obsidian950` | `#0D0C14` | Dark mode scaffold background (Deep obsidian lavender) |
| `obsidian900` | `#151322` | Dark mode card background |
| `obsidian800` | `#1E1B30` | Dark mode elevated surface (bottom sheet, dialog) |

### 2.3 Semantic Module Accents
Each module maintains identity without breaking overall harmony:
- **Calendar:** Lavender Iris (`#7C3AED` light / `#A78BFA` dark) — Schedule, time, classes.
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
Thumb-zone navigation strictly dedicated to the 3 frequent daily student tasks:
1. **Calendar** (`Icons.calendar_today_rounded` / `Icons.calendar_month_rounded`)
2. **Finance** (`Icons.account_balance_wallet_outlined` / `Icons.account_balance_wallet_rounded`)
3. **Notes** (`Icons.article_outlined` / `Icons.article_rounded`)

**Design Details:**
- Height: 68dp.
- Indicator pill: Soft lavender container (`#EDE9FE` light / `#2D2845` dark).
- Active icon color: `#7C3AED` (Lavender 600).
- Inactive icon color: `#64748B` (Muted Slate).
- Background: Seamlessly matches or sits on `#FFFFFF` with a 1px top hairline border.

### 4.2 Tier 2: The Hamburger Drawer (`NavigationDrawer`)
Located at the top-left of every screen's AppBar (`Icons.menu_rounded`). Tapping it slides in the StudentOS Command Center:
- **Header:**
  - Student Avatar circle (Lavender background with student initials or profile icon).
  - Student Name & Email (`ivan.perez@studentos.test`).
  - Active Connectivity & Offline Badge: `● Drift SQLite Synced`.
- **Items:**
  - Calendar View (Direct jump).
  - Finance Tracker (Direct jump).
  - Lecture Notes (Direct jump).
  - Profile & Account (`/profile`).
- **Utilities Section:**
  - Quick summary: Database Status (PostgreSQL Microservices + Local Drift).
  - Gateway Host: `http://10.0.2.2:8000` (or `http://127.0.0.1:8000`).
  - App Version & MVP Build number.
- **Footer:**
  - Logout action with confirmation dialog.

### 4.3 Interactive Digital Calendar Component Specification
A true working digital calendar replaces static month headers with an interactive 7-column month grid:
- **Month Grid Architecture:**
  - 7-column header: `S M T W T F S` in `onSurfaceVariant` (medium 11sp).
  - 5 to 6 row grid dynamically calculating weekday offset for the active month.
  - Cell size: 38×34dp with circular touch targets.
  - **Selected Day:** Solid Lavender (`#7C3AED`) circle with bold white text.
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
- Background: Pure surface white (`#FFFFFF`) in light mode, `#1E1B30` in dark mode.
- Keyboard-aware padding: `EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)`.

---

## 6. Anti-Slop Verification Checklist for Mobile

Before declaring any UI task done, verify:
- [ ] No gradient backgrounds used as screen backdrops.
- [ ] All borders are hairline thin (0.75px–1.0px) with subtle contrast.
- [ ] No raw Unicode emojis used in place of icons.
- [ ] Bottom navigation has exactly 3 destinations (Calendar, Finance, Notes).
- [ ] Hamburger Drawer opens smoothly and provides access to Profile, Sync status, and Logout.
- [ ] Money numbers use `FontFeature.tabularFigures()`.
- [ ] Tap targets are minimum 48×48dp.
- [ ] Bottom sheets dismiss smoothly and respect keyboard insets.
- [ ] App is tested in both Light Mode and Dark Mode.
