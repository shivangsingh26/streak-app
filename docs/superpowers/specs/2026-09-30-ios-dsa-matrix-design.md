# DSA Daily Matrix — iOS app design

Date: 2026-09-30
Status: approved in chat, awaiting written-spec review

## Goal

A native iPhone app for keeping a daily Data Structures & Algorithms streak. Open it, see the streak,
tap once when a problem is solved, feel it, leave. It replaces the PWA as the thing on the phone; the
web app in this repo stays as it is.

It is the first piece of what will later become a daily-routine app (routines, timetable reminders,
calendar sync). v1 builds none of that, but its data model and project layout must not block it.

## Scope

In v1:

- One main screen: streak, total, big solve button, optional note, 16-week heatmap.
- Multiple solves per day.
- Log, edit and delete solves on any past day (Day sheet).
- Undo toast after each solve.
- Native haptics, synthesised chime, particle burst + shockwave.
- Home Screen widgets (small, medium with an interactive "+" button) and Lock Screen widgets
  (circular, rectangular, inline).

Not in v1: reminders/notifications, iCloud sync, stats screen, settings screen, onboarding, light
mode, backup export, Large widget, Control Center control, Live Activities, gym or any other habit.

## Platform

- iOS 26 minimum; the user's phone runs iOS 27.
- Swift 6 language mode (strict concurrency), SwiftUI, SwiftData, WidgetKit, App Intents, Core Haptics,
  AVAudioEngine. No third-party dependencies.
- Built with Xcode 27. Xcode 26.6 (installed) ships only the iOS 26.5 SDK and cannot install onto an
  iOS 27 device, so the user updates Xcode before the first device build.
- Signed with the user's free Apple ID (personal team). App Groups work on a personal team; the build
  expires after 7 days and is renewed by running again from Xcode. Data survives re-installs.

## Screens and interaction

### Home

Dark OLED look carried over from the PWA (base `#09090B`, zinc-900 surfaces with a 1 px white-8%
border, emerald `#10B981` accent, amber→red flame accent).

- **Top bar:** wordmark; streak pill (flame icon + `14d`, monospaced); total pill (`🎯 142`).
  The flame pulses when the streak is ≥ 3. When today has no solve but the streak is alive, the pill
  shows a small amber dot ("at risk").
- **Hero card:**
  - Date line and a prompt that depends on state: no streak ("One problem. Today."), at risk ("Keep the
    chain alive."), solved today ("Streak secured.").
  - Big circular button. Before today's first solve: a slow breathing glow. Press: springs to 0.96
    scale. Release inside the button fires; dragging off before release cancels.
  - After today's first solve the button stays tappable and reads "✓ N solved today · tap to add".
  - Optional note field below the button. Placeholder "Problem / pattern (optional)". Text after the
    first `|` is shown as a pattern tag. Pressing Return on the keyboard logs a solve.
  - Today's solves listed under the button as compact rows (note, pattern tag, time).
- **Heatmap card:**
  - 16 weeks, columns Sun→Sat, current week last, horizontally scrollable and scrolled to today on
    appear. Month labels; Mon/Wed/Fri row labels.
  - Cell shade by that day's solve count: 0 zinc, 1 light emerald, 2 medium, 3+ full emerald with glow.
  - Today has an outer ring. Future cells are blank and not tappable.
  - Tapping a past day or today opens the Day sheet.
  - The cell for a day that just got its first solve plays a scale pop (1.25 → 1).
- **Undo toast:** after each solve, a toast with "Undo" for ~4 s. Undo deletes exactly that solve.

### Day sheet

Presented as a sheet with medium and large detents.

- Header: full date and that day's count.
- List of solves: note (or "Problem Solved"), pattern tag, time.
- Tap a solve → edit its note and time. The time picker is limited to that same calendar day.
- Swipe to delete.
- "+ Add solve": note field + time. Time defaults to now for today, 12:00 for past days.
- Streak, total, heatmap and widgets update immediately.

### Feedback

| Event | Haptic (Core Haptics) | Sound | Visual |
|---|---|---|---|
| First solve of the day | Custom double transient pulse (crisp, then heavier) | Sine chime: C6 (1046.5 Hz) gliding to G6 (1567.98 Hz), exponential decay ~250 ms | Full particle burst from touch point + shockwave ring across card; heatmap cell pop |
| Extra solve same day | Single light transient | Short, quieter chime | Small burst |
| Undo / delete | Light tick | none | none |

- Audio uses the `.ambient` session category: respects the silent switch and mixes with other audio
  instead of interrupting it. The audio engine and haptic engine are started on touch-down so release
  feedback has no start-up delay. If the haptic engine is unavailable or resets, the app recreates it
  and otherwise continues silently.
- The particle system is drawn in SwiftUI (`TimelineView` + `Canvas`), not a library.
- With Reduce Motion on: no particles, no shockwave, no breathing/pulsing; haptics and sound stay.

## Data

SwiftData store located in the App Group container so the app and widget extension share it.

```swift
@Model final class Solve {
    var id: UUID
    var day: String        // "YYYY-MM-DD", the local calendar day the solve counts for
    var solvedAt: Date     // exact time, for display and ordering
    var note: String?      // trimmed, collapsed whitespace, max 140 chars; nil when blank
}
```

- `day` is fixed when the solve is created (or chosen in the Day sheet). It is never re-derived from
  `solvedAt`, so timezone changes never move a solve to another day.
- Nothing derived is stored. Streak, total, per-day counts and the heatmap are computed from solves.
- Future habits/routines will be added as new models via a SwiftData migration; v1 adds no habit field.

## Streak rules

Ported from the web app, same test cases.

- A day counts when it has ≥ 1 solve.
- Current streak = consecutive counted days ending today; if today has none, ending yesterday. It
  becomes 0 only after a full day passes with no solve.
- Longest streak = longest run of consecutive counted days in all history (never less than current).
- Total = number of solves.
- "At risk" = today has no solve and current streak > 0.
- Date arithmetic uses calendar-day numbers, so DST and time of day cannot shift days.

## Edge cases

- **Day rollover while the app is open or backgrounded:** "today" is recomputed on
  `NSCalendarDayChanged`, on `significantTimeChange`, and whenever the scene becomes active.
- **Timezone travel:** solves keep their stored `day`; "today" is the current local day.
- **Solve after midnight:** counts for the new day. Fix via the Day sheet if needed. No grace hour.
- **Future days:** cannot be opened or given solves.
- **Editing time:** restricted to the solve's own day; moving a solve means delete + re-add.
- **Deleting today's last solve:** button returns to the unsolved state; streak recomputes.
- **Rapid double taps:** each completed press-and-release inside the button is one solve; the undo
  toast covers accidental extras.
- **Store open failure:** logged; the app shows an error message instead of crashing, and never deletes
  the store automatically.
- **App deletion:** deletes all history (no iCloud, no export in v1). Re-installing from Xcode keeps it.
- **User changes device clock:** accepted as-is; no tamper protection.

## Widgets

All widgets read the shared store. After any change in the app or from the widget button, the app
calls `WidgetCenter.shared.reloadAllTimelines()`.

- **Small (Home):** streak number with flame, "✓ N today" or "At risk", mini 5-week grid.
- **Medium (Home):** streak + total on the left, 16-week heatmap on the right, "+" button.
- **Circular (Lock):** streak number in a ring; ring full when today is solved.
- **Rectangular (Lock):** "🔥 14d · 2 today" and the latest note.
- **Inline (Lock):** "🔥 14d · ✓ today" or "🔥 14d · at risk".

Behaviour:

- The "+" button runs an App Intent that inserts a solve for today with no note and reloads widget
  timelines. Widgets cannot play haptics, sound or particles; the button only shows a brief check.
- Each timeline contains the current entry plus one at the next local midnight, so the widget flips
  to the new day (e.g. "at risk") without the app running and without spending refresh budget.
- Tapping a widget outside the button opens the app.
- Colours use `widgetAccentable` / rendering-mode checks so tinted, clear and StandBy modes stay
  legible.

## Project layout

Lives in `ios/` inside this repo; the web app is untouched.

```
ios/
  project.yml                 XcodeGen definition
  Shared/                     compiled into app + widget
    Solve.swift               SwiftData model
    SolveStore.swift          container setup (App Group), add/edit/delete
    DayKey.swift              calendar-day helpers
    Streak.swift              streak/total/at-risk calculation
    Heatmap.swift             16-week grid + count→shade
  DSAMatrix/                  app target
    DSAMatrixApp.swift
    HomeView.swift, HeroCard.swift, HeatmapView.swift, DaySheet.swift, UndoToast.swift
    Feedback/ Haptics.swift, Chime.swift, ParticleBurst.swift
  DSAMatrixWidget/            widget extension
    Widgets.swift, Provider.swift, LogSolveIntent.swift, widget views
  DSAMatrixTests/
    StreakTests.swift, HeatmapTests.swift, SolveStoreTests.swift
```

- Bundle IDs: `com.shivangsingh.dsamatrix`, `com.shivangsingh.dsamatrix.widget`.
- App Group: `group.com.shivangsingh.dsamatrix`.
- The generated `.xcodeproj` is committed so the project opens without XcodeGen installed.
- App icon reuses the matrix icon from the web app.

## Testing

Automated (run by Claude, `xcodebuild test` on the simulator):

- Streak: empty log, today counted, today open keeps yesterday's streak, reset after a missed day,
  gaps, multiple solves on one day count once, leap day, year boundary, DST boundaries.
- Longest streak and total, including multiple solves per day.
- Heatmap: 16 full weeks, Sunday-first, today in the last column, only later days marked future,
  contiguous; shade mapping for 0/1/2/3+.
- Store: add, edit note/time, delete, per-day grouping, note normalisation, in an in-memory container.

Manual in the simulator (Claude): first solve, extra solve, undo, Day sheet add/edit/delete on a past
day, midnight rollover by changing simulator time, every widget family; screenshots of each state.

Manual on the phone (user): haptic feel, chime through the speaker and silent switch, widgets on the
real Home and Lock Screens, the "+" button, 7-day re-sign.

## Install steps (user, one-time)

1. Update Xcode to 27; run `sudo xcode-select -s /Applications/Xcode.app`.
2. Xcode → Settings → Accounts → add Apple ID.
3. Connect the iPhone; enable Settings → Privacy & Security → Developer Mode (phone restarts).
4. Select the personal team for both targets; Run on the iPhone.
5. First launch: Settings → General → VPN & Device Management → trust the developer.
6. Every 7 days: connect and Run again.

## Later (not v1, but the design leaves room)

Reminder notifications, backup export/import, stats screen, iCloud sync (needs paid account; SwiftData
supports it), more habits and routines, timetable notifications, calendar integration via EventKit.
