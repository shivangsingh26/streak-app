# DSA Daily Matrix iOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A native SwiftUI iPhone app (plus Home/Lock Screen widgets) for keeping a daily DSA streak with multiple solves per day and editable history.

**Architecture:** Pure value-type logic (`Day`, `Streak`, `Summary`, `Heatmap`, `Note`) lives in `ios/Shared/` and is compiled into both the app and the widget extension. Persistence is one SwiftData model (`Solve`) behind a thread-safe `SolveStore` that opens a fresh `ModelContext` per call, so writes from the widget process are always visible to the app. The app's single `@Observable` `AppModel` holds `[SolveRecord]` snapshots and a derived `Summary`; SwiftUI views read only from it. Feedback (Core Haptics, synthesized chime, SwiftUI Canvas particles) sits in its own small types.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, WidgetKit, App Intents, Core Haptics, AVAudioEngine, Swift Testing, XCTest (UI smoke test only), XcodeGen 2.46.

**Spec:** `docs/superpowers/specs/2026-09-30-ios-dsa-matrix-design.md`

## Global Constraints

- iOS deployment target `26.0`; built with Xcode 27 / iOS 27 SDK.
- `SWIFT_VERSION = 6.0` (strict concurrency). Do NOT set default actor isolation; mark UI classes `@MainActor` explicitly.
- No third-party dependencies.
- App bundle ID `com.shivangsingh.dsamatrix`; widget `com.shivangsingh.dsamatrix.widget`; App Group `group.com.shivangsingh.dsamatrix`.
- Everything lives under `ios/`; the web app files are not touched.
- iPhone only, portrait, dark only.
- Colors: base `#09090B`, surface `#18181B`, border white 8%, emerald `#10B981` / `#34D399` / `#059669`, amber `#F59E0B`, flame red `#EF4444`.
- Note: trimmed, whitespace collapsed, max 140 chars, blank → `nil`, shown as "Problem Solved". Text after the first `|` is the pattern tag.
- Streak: a day counts with ≥ 1 solve; if today is empty the streak is the run ending yesterday.
- Follow `.claude/skills/swiftui-pro`, `swiftdata-pro`, `widgetkit`, `app-intents` guidance (installed locally): `foregroundStyle` not `foregroundColor`, explicit `save()`, no `@Query` outside views, `containerBackground(for: .widget)`.
- Simulator for all commands: `iPhone 17` (override with `make test SIM="iPhone Air"`).

## File Map

```
ios/
  project.yml                         XcodeGen project definition
  Makefile                            generate / build / test / run / shots
  Design/AppIcon.svg                  full-bleed icon source
  Shared/                             compiled into app AND widget
    Day.swift                         local calendar day value type
    Streak.swift                      StreakStats + streak math
    Summary.swift                     records → counts + stats (app + widget)
    Heatmap.swift                     16-week grid + count→level
    Note.swift                        note normalisation / title|pattern split
    SolveRecord.swift                 Sendable snapshot of a solve
    SolveSchema.swift                 SwiftData @Model + versioned schema
    SolveStore.swift                  container + add/update/delete/fetch
    Theme.swift                       colors
  DSAMatrix/                          app target
    DSAMatrixApp.swift                entry, store wiring, day-change hooks
    AppModel.swift                    @Observable state + actions
    DSAMatrix.entitlements
    Assets.xcassets/AppIcon.appiconset/{Contents.json,icon-1024.png}
    Feedback/Haptics.swift
    Feedback/Chime.swift
    Feedback/ParticleSystem.swift     burst model
    Feedback/ParticleLayer.swift      Canvas renderer
    Home/HomeView.swift
    Home/TopBar.swift
    Home/Prompt.swift
    Home/HeroCard.swift
    Home/ButtonFace.swift
    Home/PressScaleStyle.swift
    Home/Ripple.swift
    Home/SolveRow.swift
    Home/UndoToast.swift
    Heatmap/HeatmapCard.swift
    Heatmap/HeatCell.swift
    DaySheet/DaySheet.swift
    DaySheet/SolveEditor.swift
  DSAMatrixWidget/                    widget extension
    DSAMatrixWidget.entitlements
    MatrixWidgetBundle.swift
    MatrixProvider.swift
    MatrixWidget.swift
    LogSolveIntent.swift
    Views/MiniGrid.swift
    Views/SmallWidgetView.swift
    Views/MediumWidgetView.swift
    Views/AccessoryViews.swift
  DSAMatrixTests/                     Swift Testing, hosted in app
    DayTests.swift
    StreakTests.swift
    HeatmapTests.swift
    NoteTests.swift
    SolveStoreTests.swift
    AppModelTests.swift
    PromptTests.swift
  DSAMatrixUITests/
    SmokeTests.swift                  launches, taps, captures screenshots
```

---

### Task 1: Project scaffold

**Files:**
- Create: `ios/project.yml`, `ios/Makefile`, `ios/Design/AppIcon.svg`, `ios/DSAMatrix/DSAMatrixApp.swift`, `ios/DSAMatrix/DSAMatrix.entitlements`, `ios/DSAMatrix/Assets.xcassets/Contents.json`, `ios/DSAMatrix/Assets.xcassets/AppIcon.appiconset/Contents.json`, `ios/DSAMatrix/Assets.xcassets/AppIcon.appiconset/icon-1024.png`, `ios/DSAMatrixTests/ScaffoldTests.swift`, `ios/Shared/.gitkeep`
- Modify: `.gitignore`

**Interfaces:**
- Produces: `make generate`, `make build`, `make test` working from `ios/`. Later tasks add files under `Shared/`, `DSAMatrix/`, `DSAMatrixTests/` and re-run `make generate` implicitly (every make target regenerates).

- [ ] **Step 1: Install XcodeGen**

Run: `brew install xcodegen && xcodegen --version`
Expected: `Version: 2.46.0` (or newer)

- [ ] **Step 2: Write `ios/project.yml`** (widget and UI-test targets are added in Tasks 10 and 11)

```yaml
name: DSAMatrix
options:
  bundleIdPrefix: com.shivangsingh
  deploymentTarget:
    iOS: "26.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "6.0"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
    CODE_SIGN_STYLE: Automatic
    DEVELOPMENT_TEAM: ""
    TARGETED_DEVICE_FAMILY: "1"
    ENABLE_USER_SCRIPT_SANDBOXING: YES
targets:
  DSAMatrix:
    type: application
    platform: iOS
    sources:
      - DSAMatrix
      - Shared
    entitlements:
      path: DSAMatrix/DSAMatrix.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.shivangsingh.dsamatrix
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.shivangsingh.dsamatrix
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_CFBundleDisplayName: DSA Matrix
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
        INFOPLIST_KEY_UIUserInterfaceStyle: Dark
        INFOPLIST_KEY_UIStatusBarStyle: UIStatusBarStyleLightContent
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
  DSAMatrixTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - DSAMatrixTests
    dependencies:
      - target: DSAMatrix
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.shivangsingh.dsamatrix.tests
        GENERATE_INFOPLIST_FILE: YES
schemes:
  DSAMatrix:
    build:
      targets:
        DSAMatrix: all
    test:
      targets:
        - DSAMatrixTests
```

- [ ] **Step 3: Write `ios/Makefile`** (recipe lines are TAB-indented)

```make
PROJECT = DSAMatrix.xcodeproj
SCHEME  = DSAMatrix
SIM    ?= iPhone 17
DEST    = platform=iOS Simulator,name=$(SIM)
DERIVED = build
APP     = $(DERIVED)/Build/Products/Debug-iphonesimulator/DSAMatrix.app
XCB     = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -derivedDataPath $(DERIVED)

.PHONY: generate build test run shots

generate:
	xcodegen generate --quiet

build: generate
	$(XCB) build -quiet

test: generate
	$(XCB) test -quiet -only-testing:DSAMatrixTests

run: build
	xcrun simctl boot '$(SIM)' 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted $(APP)
	xcrun simctl launch --terminate-running-process booted com.shivangsingh.dsamatrix $(ARGS)

shots: generate
	rm -rf $(DERIVED)/shots.xcresult shots
	$(XCB) test -quiet -only-testing:DSAMatrixUITests -resultBundlePath $(DERIVED)/shots.xcresult
	xcrun xcresulttool export attachments --path $(DERIVED)/shots.xcresult --output-path shots
```

- [ ] **Step 4: Write entitlements, placeholder app, placeholder test**

`ios/DSAMatrix/DSAMatrix.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.shivangsingh.dsamatrix</string>
	</array>
</dict>
</plist>
```

`ios/DSAMatrix/DSAMatrixApp.swift` (replaced in Task 8):
```swift
import SwiftUI

@main
struct DSAMatrixApp: App {
    var body: some Scene {
        WindowGroup {
            Text("DSA Matrix")
        }
    }
}
```

`ios/DSAMatrixTests/ScaffoldTests.swift` (deleted in Task 2):
```swift
import Testing
@testable import DSAMatrix

@Test func scaffoldBuilds() {
    #expect(true)
}
```

`ios/Shared/.gitkeep`: empty file (XcodeGen needs the folder to exist).

- [ ] **Step 5: App icon**

`ios/Design/AppIcon.svg` — full-bleed version of `public/icons/icon.svg` (no outer rounded rect; iOS masks the corners):
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#18181B"/><stop offset="1" stop-color="#09090B"/>
    </linearGradient>
    <linearGradient id="em" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#34D399"/><stop offset="1" stop-color="#059669"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" fill="url(#bg)"/>
  <g transform="translate(106 106)">
    <g fill="#27272A">
      <rect x="0" y="0" width="66" height="66" rx="14"/><rect x="78" y="0" width="66" height="66" rx="14"/>
      <rect x="234" y="0" width="66" height="66" rx="14"/><rect x="0" y="78" width="66" height="66" rx="14"/>
      <rect x="0" y="156" width="66" height="66" rx="14"/><rect x="156" y="234" width="66" height="66" rx="14"/>
    </g>
    <g fill="url(#em)">
      <rect x="156" y="0" width="66" height="66" rx="14"/><rect x="78" y="78" width="66" height="66" rx="14"/>
      <rect x="156" y="78" width="66" height="66" rx="14"/><rect x="234" y="78" width="66" height="66" rx="14"/>
      <rect x="78" y="156" width="66" height="66" rx="14"/><rect x="156" y="156" width="66" height="66" rx="14"/>
      <rect x="234" y="156" width="66" height="66" rx="14"/><rect x="0" y="234" width="66" height="66" rx="14"/>
      <rect x="78" y="234" width="66" height="66" rx="14"/><rect x="234" y="234" width="66" height="66" rx="14"/>
    </g>
    <rect x="227" y="227" width="80" height="80" rx="20" fill="none" stroke="#FAFAFA" stroke-opacity="0.85" stroke-width="5"/>
  </g>
</svg>
```

Render to an opaque 1024 PNG (JPEG round-trip strips alpha, which App Store icons must not have):
```bash
cd ios
mkdir -p DSAMatrix/Assets.xcassets/AppIcon.appiconset
qlmanage -t -s 1024 -o /tmp Design/AppIcon.svg
sips -s format jpeg /tmp/AppIcon.svg.png --out /tmp/appicon.jpg
sips -s format png -z 1024 1024 /tmp/appicon.jpg --out DSAMatrix/Assets.xcassets/AppIcon.appiconset/icon-1024.png
sips -g pixelWidth -g hasAlpha DSAMatrix/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```
Expected: `pixelWidth: 1024`, `hasAlpha: no`. Open the PNG and check it shows the dark grid (not a white or cropped thumbnail). If `qlmanage` output is wrong, fall back to `sips -s format png -z 1024 1024 ../public/icons/icon-maskable-512.png --out <same path>`.

`ios/DSAMatrix/Assets.xcassets/Contents.json`:
```json
{ "info" : { "author" : "xcode", "version" : 1 } }
```

`ios/DSAMatrix/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    { "filename" : "icon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

- [ ] **Step 6: Ignore build output** — append to repo-root `.gitignore`:
```
# iOS
ios/build/
ios/shots/
```

- [ ] **Step 7: Build and test**

Run: `cd ios && make test`
Expected: `** TEST SUCCEEDED **` (with `-quiet`, success prints little; exit code 0). If it fails with "requires a development team", add `CODE_SIGN_IDENTITY="-"` to the `XCB` line in the Makefile and re-run.

- [ ] **Step 8: Commit** (the generated `DSAMatrix.xcodeproj` is committed, per spec)

```bash
git add .gitignore ios
git commit -m "Scaffold iOS app project with XcodeGen"
```

---

### Task 2: `Day` — local calendar day

**Files:**
- Create: `ios/Shared/Day.swift`, `ios/DSAMatrixTests/DayTests.swift`
- Delete: `ios/DSAMatrixTests/ScaffoldTests.swift`, `ios/Shared/.gitkeep`

**Interfaces:**
- Produces:
  - `struct Day: Hashable, Comparable, Sendable, Identifiable` with `let number: Int` (days since 1970-01-01), `var id: Int`
  - `init(number: Int)`, `init(_ date: Date, calendar: Calendar = .current)`, `init?(year: Int, month: Int, day: Int)`, `init?(key: String)`
  - `var key: String` (`"YYYY-MM-DD"`), `var components: (year: Int, month: Int, day: Int)`, `var weekday: Int` (0 = Sunday)
  - `func adding(days: Int) -> Day`
  - `func startDate(in calendar: Calendar = .current) -> Date`, `func date(hour: Int, minute: Int = 0, in calendar: Calendar = .current) -> Date`, `func timeRange(in calendar: Calendar = .current) -> ClosedRange<Date>`

- [ ] **Step 1: Write the failing tests** — `ios/DSAMatrixTests/DayTests.swift`

```swift
import Foundation
import Testing
@testable import DSAMatrix

struct DayTests {
    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    @Test func keyRoundTrips() {
        let day = Day(key: "2026-09-30")
        #expect(day?.key == "2026-09-30")
        #expect(Day(number: 1).key == "1970-01-02")
    }

    @Test func rejectsInvalidKeys() {
        #expect(Day(key: "2026-02-29") == nil)
        #expect(Day(key: "2026-9-30") == nil)
        #expect(Day(key: "2026-13-01") == nil)
        #expect(Day(key: "hello") == nil)
        #expect(Day(key: "2024-02-29") != nil)
    }

    @Test func addsAcrossMonthAndYearBoundaries() {
        #expect(Day(key: "2026-12-31")!.adding(days: 1).key == "2027-01-01")
        #expect(Day(key: "2026-03-01")!.adding(days: -1).key == "2026-02-28")
        #expect(Day(key: "2024-03-01")!.adding(days: -1).key == "2024-02-29")
    }

    @Test func weekdays() {
        #expect(Day(key: "2026-09-30")!.weekday == 3) // Wednesday
        #expect(Day(key: "2026-09-27")!.weekday == 0) // Sunday
        #expect(Day(key: "1969-12-31")!.weekday == 3) // negative day numbers
    }

    @Test func usesLocalCalendarDay() {
        let tokyo = calendar("Asia/Tokyo")
        let newYork = calendar("America/New_York")
        // 2026-01-05 23:30 UTC is already Jan 6 in Tokyo, still Jan 5 in New York.
        let instant = Date(timeIntervalSince1970: 1_767_655_800)
        #expect(Day(instant, calendar: tokyo).key == "2026-01-06")
        #expect(Day(instant, calendar: newYork).key == "2026-01-05")
    }

    @Test func dstDaysAreOneDayApart() {
        let newYork = calendar("America/New_York")
        let before = Day(key: "2026-03-07")!
        let dst = Day(key: "2026-03-08")! // US DST starts
        #expect(dst.adding(days: -1) == before)
        #expect(Day(dst.startDate(in: newYork), calendar: newYork) == dst)
        #expect(Day(dst.date(hour: 23, minute: 59, in: newYork), calendar: newYork) == dst)
    }

    @Test func timeRangeCoversTheWholeDay() {
        let newYork = calendar("America/New_York")
        let day = Day(key: "2026-09-30")!
        let range = day.timeRange(in: newYork)
        #expect(Day(range.lowerBound, calendar: newYork) == day)
        #expect(Day(range.upperBound, calendar: newYork) == day)
        #expect(Day(range.upperBound.addingTimeInterval(1), calendar: newYork) == day.adding(days: 1))
    }

    @Test func ordering() {
        #expect(Day(key: "2026-09-29")! < Day(key: "2026-09-30")!)
    }
}
```

- [ ] **Step 2: Delete the scaffold test and placeholder, regenerate, run to verify failure**

```bash
rm ios/DSAMatrixTests/ScaffoldTests.swift ios/Shared/.gitkeep
cd ios && make test
```
Expected: FAIL — compile error `cannot find 'Day' in scope`.

- [ ] **Step 3: Implement** — `ios/Shared/Day.swift`

```swift
import Foundation

/// A local calendar day. Stored and compared as an integer day number
/// (days since 1970-01-01 in the proleptic Gregorian calendar), so DST
/// transitions and time of day can never shift one day into another.
struct Day: Hashable, Comparable, Sendable, Identifiable {
    let number: Int

    var id: Int { number }

    init(number: Int) {
        self.number = number
    }

    /// The calendar day `date` falls on in `calendar`'s time zone.
    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)!
    }

    init?(year: Int, month: Int, day: Int) {
        let parts = DateComponents(year: year, month: month, day: day)
        guard parts.isValidDate(in: Self.utc), let date = Self.utc.date(from: parts) else { return nil }
        number = Int((date.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    /// Parses `"YYYY-MM-DD"`.
    init?(key: String) {
        let parts = key.split(separator: "-")
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    var key: String {
        let (year, month, day) = components
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    var components: (year: Int, month: Int, day: Int) {
        let date = Date(timeIntervalSince1970: TimeInterval(number) * 86_400)
        let parts = Self.utc.dateComponents([.year, .month, .day], from: date)
        return (parts.year!, parts.month!, parts.day!)
    }

    /// 0 = Sunday … 6 = Saturday. 1970-01-01 was a Thursday.
    var weekday: Int {
        ((number + 4) % 7 + 7) % 7
    }

    func adding(days: Int) -> Day {
        Day(number: number + days)
    }

    /// The first instant of this day in `calendar`'s time zone.
    func startDate(in calendar: Calendar = .current) -> Date {
        date(hour: 0, in: calendar)
    }

    func date(hour: Int, minute: Int = 0, in calendar: Calendar = .current) -> Date {
        let (year, month, day) = components
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Every instant that belongs to this day, for time pickers.
    func timeRange(in calendar: Calendar = .current) -> ClosedRange<Date> {
        startDate(in: calendar)...adding(days: 1).startDate(in: calendar).addingTimeInterval(-1)
    }

    static func < (lhs: Day, rhs: Day) -> Bool {
        lhs.number < rhs.number
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ios && make test`
Expected: PASS, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add ios
git commit -m "Add Day calendar-day value type"
```

---

### Task 3: Streak math and `Summary`

**Files:**
- Create: `ios/Shared/Streak.swift`, `ios/Shared/Note.swift`, `ios/Shared/SolveRecord.swift`, `ios/Shared/Summary.swift`, `ios/DSAMatrixTests/StreakTests.swift`, `ios/DSAMatrixTests/NoteTests.swift`

**Interfaces:**
- Consumes: `Day` (Task 2).
- Produces:
  - `struct StreakStats: Equatable, Sendable { var current, longest, total, todayCount: Int; var isAtRisk: Bool; var statusText: String }` with memberwise init `StreakStats(current:longest:total:todayCount:)` (all default 0)
  - `enum Streak { static func stats(counts: [Day: Int], today: Day) -> StreakStats; static func current(days: Set<Day>, today: Day) -> Int; static func longest(days: Set<Day>) -> Int }`
  - `enum Note { static let maxLength = 140; static let defaultTitle = "Problem Solved"; static func normalize(_ raw: String) -> String?; static func split(_ note: String?) -> (title: String, pattern: String?) }`
  - `struct SolveRecord: Identifiable, Hashable, Sendable { let id: UUID; let day: Day; let solvedAt: Date; let note: String?; var title: String; var pattern: String? }`
  - `struct Summary: Equatable, Sendable { let today: Day; let counts: [Day: Int]; let stats: StreakStats; let latestNote: String?; init(records: [SolveRecord], today: Day) }`

- [ ] **Step 1: Write the failing tests**

`ios/DSAMatrixTests/StreakTests.swift`:
```swift
import Foundation
import Testing
@testable import DSAMatrix

struct StreakTests {
    private let today = Day(key: "2026-09-30")!
    private func back(_ n: Int) -> Day { today.adding(days: -n) }
    private func days(_ list: Day...) -> Set<Day> { Set(list) }

    @Test func emptyIsZero() {
        #expect(Streak.current(days: [], today: today) == 0)
        #expect(Streak.longest(days: []) == 0)
    }

    @Test func countsTodayAndTheRunBeforeIt() {
        #expect(Streak.current(days: days(today, back(1), back(2)), today: today) == 3)
    }

    @Test func openTodayKeepsYesterdaysStreak() {
        #expect(Streak.current(days: days(back(1), back(2), back(3)), today: today) == 3)
    }

    @Test func resetsAfterAFullMissedDay() {
        #expect(Streak.current(days: days(back(2), back(3)), today: today) == 0)
    }

    @Test func stopsAtFirstGap() {
        #expect(Streak.current(days: days(today, back(1), back(3), back(4)), today: today) == 2)
    }

    @Test func spansLeapDayAndYearBoundary() {
        let leap = Day(key: "2024-03-01")!
        #expect(Streak.current(days: days(leap, leap.adding(days: -1), leap.adding(days: -2)), today: leap) == 3)
        let newYear = Day(key: "2026-01-01")!
        #expect(Streak.current(days: days(newYear, newYear.adding(days: -1)), today: newYear) == 2)
    }

    @Test func longestFindsBestHistoricalRun() {
        let set = days(back(20), back(13), back(12), back(11), back(10), back(1), today)
        #expect(Streak.longest(days: set) == 4)
    }

    @Test func multipleSolvesPerDayCountOnceForStreakButAllForTotal() {
        let stats = Streak.stats(counts: [today: 3, back(1): 2, back(5): 1], today: today)
        #expect(stats == StreakStats(current: 2, longest: 2, total: 6, todayCount: 3))
        #expect(!stats.isAtRisk)
    }

    @Test func atRiskWhenTodayEmptyAndStreakAlive() {
        let stats = Streak.stats(counts: [back(1): 1, back(2): 1], today: today)
        #expect(stats.current == 2)
        #expect(stats.todayCount == 0)
        #expect(stats.isAtRisk)
        #expect(stats.statusText == "At risk")
    }

    @Test func zeroCountsAreIgnored() {
        let stats = Streak.stats(counts: [today: 0, back(1): 1], today: today)
        #expect(stats.current == 1)
        #expect(stats.todayCount == 0)
    }

    @Test func statusText() {
        #expect(StreakStats(current: 3, longest: 3, total: 5, todayCount: 2).statusText == "✓ 2 today")
        #expect(StreakStats().statusText == "Solve one today")
    }

    @Test func summaryAggregatesRecords() {
        let records = [
            SolveRecord(id: UUID(), day: back(1), solvedAt: back(1).date(hour: 9), note: "Two Sum | Hash Map"),
            SolveRecord(id: UUID(), day: today, solvedAt: today.date(hour: 8), note: nil),
            SolveRecord(id: UUID(), day: today, solvedAt: today.date(hour: 21), note: "LRU Cache"),
        ]
        let summary = Summary(records: records, today: today)
        #expect(summary.counts == [back(1): 1, today: 2])
        #expect(summary.stats == StreakStats(current: 2, longest: 2, total: 3, todayCount: 2))
        #expect(summary.latestNote == "LRU Cache")
    }
}
```

`ios/DSAMatrixTests/NoteTests.swift`:
```swift
import Foundation
import Testing
@testable import DSAMatrix

struct NoteTests {
    @Test func normalizesWhitespaceAndBlanks() {
        #expect(Note.normalize("   ") == nil)
        #expect(Note.normalize("") == nil)
        #expect(Note.normalize("  33.  Search |  Binary \n") == "33. Search | Binary")
    }

    @Test func truncatesTo140Characters() {
        let long = String(repeating: "a", count: 200)
        #expect(Note.normalize(long)?.count == 140)
    }

    @Test func splitsTitleAndPattern() {
        #expect(Note.split("33. Search in Rotated Sorted Array | Modified Binary Search")
            == ("33. Search in Rotated Sorted Array", "Modified Binary Search"))
        #expect(Note.split("LRU Cache") == ("LRU Cache", nil))
        #expect(Note.split(nil) == ("Problem Solved", nil))
        #expect(Note.split("| DP") == ("Problem Solved", "DP"))
        #expect(Note.split("Two Sum |") == ("Two Sum", nil))
    }

    @Test func recordExposesTitleAndPattern() {
        let record = SolveRecord(id: UUID(), day: Day(number: 0), solvedAt: .now, note: "Two Sum | Hash Map")
        #expect(record.title == "Two Sum")
        #expect(record.pattern == "Hash Map")
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd ios && make test`
Expected: FAIL — `cannot find 'Streak' in scope` (and `Note`, `SolveRecord`, `Summary`).

- [ ] **Step 3: Implement**

`ios/Shared/Streak.swift`:
```swift
import Foundation

struct StreakStats: Equatable, Sendable {
    var current = 0
    var longest = 0
    var total = 0
    var todayCount = 0

    /// Today has no solve yet but yesterday's run is alive.
    var isAtRisk: Bool { todayCount == 0 && current > 0 }

    var statusText: String {
        if todayCount > 0 { return "✓ \(todayCount) today" }
        return isAtRisk ? "At risk" : "Solve one today"
    }
}

enum Streak {
    static func stats(counts: [Day: Int], today: Day) -> StreakStats {
        let days = Set(counts.filter { $0.value > 0 }.keys)
        let current = current(days: days, today: today)
        return StreakStats(
            current: current,
            longest: max(longest(days: days), current),
            total: counts.values.reduce(0, +),
            todayCount: counts[today] ?? 0
        )
    }

    /// Run of consecutive days ending today — or ending yesterday while today is still open.
    static func current(days: Set<Day>, today: Day) -> Int {
        var cursor = days.contains(today) ? today : today.adding(days: -1)
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = cursor.adding(days: -1)
        }
        return count
    }

    static func longest(days: Set<Day>) -> Int {
        var longest = 0
        var run = 0
        var previous: Int?
        for number in days.map(\.number).sorted() {
            run = previous.map { number == $0 + 1 } == true ? run + 1 : 1
            longest = max(longest, run)
            previous = number
        }
        return longest
    }
}
```

`ios/Shared/Note.swift`:
```swift
import Foundation

enum Note {
    static let maxLength = 140
    static let defaultTitle = "Problem Solved"

    /// Collapses whitespace, trims, caps length. Blank becomes nil.
    static func normalize(_ raw: String) -> String? {
        let collapsed = raw.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let capped = String(collapsed.prefix(maxLength)).trimmingCharacters(in: .whitespaces)
        return capped.isEmpty ? nil : capped
    }

    /// "33. Search | Binary Search" → ("33. Search", "Binary Search").
    static func split(_ note: String?) -> (title: String, pattern: String?) {
        guard let note, !note.isEmpty else { return (defaultTitle, nil) }
        guard let bar = note.firstIndex(of: "|") else { return (note, nil) }
        let title = note[..<bar].trimmingCharacters(in: .whitespaces)
        let pattern = note[note.index(after: bar)...].trimmingCharacters(in: .whitespaces)
        return (title.isEmpty ? defaultTitle : title, pattern.isEmpty ? nil : pattern)
    }
}
```

`ios/Shared/SolveRecord.swift`:
```swift
import Foundation

/// A read-only, Sendable snapshot of a stored solve. Views and widgets use this,
/// never the SwiftData model, so nothing crosses actor boundaries.
struct SolveRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    let day: Day
    let solvedAt: Date
    let note: String?

    var title: String { Note.split(note).title }
    var pattern: String? { Note.split(note).pattern }
}
```

`ios/Shared/Summary.swift`:
```swift
import Foundation

/// Everything the UI and widgets derive from the solve history.
struct Summary: Equatable, Sendable {
    let today: Day
    let counts: [Day: Int]
    let stats: StreakStats
    let latestNote: String?

    init(records: [SolveRecord], today: Day) {
        var counts: [Day: Int] = [:]
        for record in records {
            counts[record.day, default: 0] += 1
        }
        self.today = today
        self.counts = counts
        stats = Streak.stats(counts: counts, today: today)
        latestNote = records.max { $0.solvedAt < $1.solvedAt }?.note
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ios && make test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ios
git commit -m "Add streak math, note parsing and summary"
```

---

### Task 4: Heatmap grid

**Files:**
- Create: `ios/Shared/Heatmap.swift`, `ios/DSAMatrixTests/HeatmapTests.swift`

**Interfaces:**
- Consumes: `Day`.
- Produces:
  - `struct HeatmapCell: Hashable, Sendable, Identifiable { let day: Day; let isToday: Bool; let isFuture: Bool; var id: Int }`
  - `struct HeatmapWeek: Hashable, Sendable, Identifiable { let monthLabel: String?; let cells: [HeatmapCell]; var id: Int }` (7 cells, Sunday first)
  - `enum Heatmap { static let defaultWeeks = 16; static func weeks(endingAt today: Day, count: Int = defaultWeeks) -> [HeatmapWeek]; static func level(for count: Int) -> Int }` (level 0…3)

- [ ] **Step 1: Write the failing tests** — `ios/DSAMatrixTests/HeatmapTests.swift`

```swift
import Testing
@testable import DSAMatrix

struct HeatmapTests {
    private let today = Day(key: "2026-09-30")! // Wednesday
    private var grid: [HeatmapWeek] { Heatmap.weeks(endingAt: today) }

    @Test func sixteenFullSundayFirstWeeksEndingThisWeek() {
        #expect(grid.count == 16)
        #expect(grid.allSatisfy { $0.cells.count == 7 })
        #expect(grid.allSatisfy { $0.cells[0].day.weekday == 0 })
        #expect(grid.last!.cells.contains { $0.day == today })
    }

    @Test func exactlyOneTodayAndOnlyLaterDaysAreFuture() {
        let cells = grid.flatMap(\.cells)
        #expect(cells.filter(\.isToday).map(\.day) == [today])
        #expect(cells.filter(\.isFuture).map(\.day.key) == ["2026-10-01", "2026-10-02", "2026-10-03"])
    }

    @Test func contiguousDays() {
        let numbers = grid.flatMap(\.cells).map(\.day.number)
        #expect(zip(numbers, numbers.dropFirst()).allSatisfy { $1 - $0 == 1 })
    }

    @Test func customWeekCount() {
        #expect(Heatmap.weeks(endingAt: today, count: 5).count == 5)
    }

    @Test func monthLabelsOnlyWhereMonthChanges() {
        let labelled = grid.filter { $0.monthLabel != nil }
        #expect(labelled.count >= 3)
        #expect(labelled.count <= 5)
    }

    @Test func levels() {
        #expect([0, 1, 2, 3, 4, 10, -1].map(Heatmap.level(for:)) == [0, 1, 2, 3, 3, 3, 0])
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd ios && make test`
Expected: FAIL — `cannot find 'Heatmap' in scope`.

- [ ] **Step 3: Implement** — `ios/Shared/Heatmap.swift`

```swift
import Foundation

struct HeatmapCell: Hashable, Sendable, Identifiable {
    let day: Day
    let isToday: Bool
    let isFuture: Bool

    var id: Int { day.number }
}

struct HeatmapWeek: Hashable, Sendable, Identifiable {
    /// Short month name when a new month starts in this column.
    let monthLabel: String?
    /// Sunday → Saturday.
    let cells: [HeatmapCell]

    var id: Int { cells[0].day.number }
}

enum Heatmap {
    static let defaultWeeks = 16

    /// GitHub-style columns of weeks; the last column is the current week.
    static func weeks(endingAt today: Day, count: Int = defaultWeeks) -> [HeatmapWeek] {
        let lastSaturday = today.adding(days: 6 - today.weekday)
        let firstSunday = lastSaturday.adding(days: -(count * 7 - 1))
        var weeks: [HeatmapWeek] = []
        var previousMonth = -1

        for week in 0..<count {
            let cells = (0..<7).map { offset in
                let day = firstSunday.adding(days: week * 7 + offset)
                return HeatmapCell(day: day, isToday: day == today, isFuture: day > today)
            }
            let first = cells[0].day.components
            var label: String?
            if first.month != previousMonth {
                // Skip a label on the first column when the next month starts within days,
                // so two labels never collide.
                let cramped = week == 0 && first.day > 17
                if !cramped { label = Calendar.current.shortMonthSymbols[first.month - 1] }
                previousMonth = first.month
            }
            weeks.append(HeatmapWeek(monthLabel: label, cells: cells))
        }
        return weeks
    }

    /// 0 = none, 1, 2, 3 = three or more.
    static func level(for count: Int) -> Int {
        min(max(count, 0), 3)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ios && make test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ios
git commit -m "Add heatmap grid builder"
```

---

### Task 5: SwiftData model and `SolveStore`

**Files:**
- Create: `ios/Shared/SolveSchema.swift`, `ios/Shared/SolveStore.swift`, `ios/DSAMatrixTests/SolveStoreTests.swift`

**Interfaces:**
- Consumes: `Day`, `Note`, `SolveRecord`.
- Produces:
  - `enum SchemaV1: VersionedSchema` containing `@Model final class Solve { var uuid: UUID; var day: String; var solvedAt: Date; var note: String? }`; `typealias Solve = SchemaV1.Solve`; `enum SolveMigrationPlan: SchemaMigrationPlan`
  - `final class SolveStore: Sendable` — `static let appGroupID`, `init(inMemory: Bool = false) throws`, `func fetchAll() throws -> [SolveRecord]` (sorted by `solvedAt`), `@discardableResult func add(day: Day, at date: Date, note: String) throws -> SolveRecord`, `func update(id: UUID, note: String, solvedAt: Date) throws`, `func delete(id: UUID) throws`
  - `extension Logger { static let store: Logger }`

- [ ] **Step 1: Write the failing tests** — `ios/DSAMatrixTests/SolveStoreTests.swift`

```swift
import Foundation
import Testing
@testable import DSAMatrix

struct SolveStoreTests {
    private let day = Day(key: "2026-09-30")!

    @Test func addsAndFetchesSortedByTime() throws {
        let store = try SolveStore(inMemory: true)
        try store.add(day: day, at: day.date(hour: 21), note: "LRU Cache")
        try store.add(day: day, at: day.date(hour: 8), note: "  Two   Sum  ")
        let records = try store.fetchAll()
        #expect(records.map(\.note) == ["Two Sum", "LRU Cache"])
        #expect(records.allSatisfy { $0.day == day })
    }

    @Test func blankNoteIsStoredAsNil() throws {
        let store = try SolveStore(inMemory: true)
        let record = try store.add(day: day, at: day.date(hour: 9), note: "   ")
        #expect(record.note == nil)
        #expect(try store.fetchAll().first?.note == nil)
    }

    @Test func updatesNoteAndTime() throws {
        let store = try SolveStore(inMemory: true)
        let record = try store.add(day: day, at: day.date(hour: 9), note: "old")
        try store.update(id: record.id, note: "new | DP", solvedAt: day.date(hour: 10, minute: 30))
        let updated = try #require(try store.fetchAll().first)
        #expect(updated.note == "new | DP")
        #expect(updated.solvedAt == day.date(hour: 10, minute: 30))
        #expect(updated.day == day)
    }

    @Test func deletesOnlyTheTarget() throws {
        let store = try SolveStore(inMemory: true)
        let keep = try store.add(day: day, at: day.date(hour: 9), note: "keep")
        let drop = try store.add(day: day, at: day.date(hour: 10), note: "drop")
        try store.delete(id: drop.id)
        #expect(try store.fetchAll().map(\.id) == [keep.id])
    }

    @Test func missingIDsAreIgnored() throws {
        let store = try SolveStore(inMemory: true)
        try store.update(id: UUID(), note: "x", solvedAt: .now)
        try store.delete(id: UUID())
        #expect(try store.fetchAll().isEmpty)
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd ios && make test`
Expected: FAIL — `cannot find 'SolveStore' in scope`.

- [ ] **Step 3: Implement**

`ios/Shared/SolveSchema.swift`:
```swift
import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Solve.self] }

    @Model
    final class Solve {
        #Index<Solve>([\.day])

        var uuid: UUID
        /// "YYYY-MM-DD" — the local day this solve counts for. Fixed at creation;
        /// never re-derived from `solvedAt`, so time-zone changes can't move it.
        var day: String
        var solvedAt: Date
        var note: String?

        init(uuid: UUID = UUID(), day: String, solvedAt: Date, note: String?) {
            self.uuid = uuid
            self.day = day
            self.solvedAt = solvedAt
            self.note = note
        }
    }
}

typealias Solve = SchemaV1.Solve

/// Future schema versions (habits, routines) add a stage here.
enum SolveMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
```

`ios/Shared/SolveStore.swift`:
```swift
import Foundation
import OSLog
import SwiftData

extension Logger {
    static let store = Logger(subsystem: "com.shivangsingh.dsamatrix", category: "store")
}

/// Thread-safe access to the solve database shared by the app and widget.
/// Every call opens a fresh `ModelContext`, so it always reads what the other
/// process last wrote and no model object ever escapes the call.
final class SolveStore: Sendable {
    static let appGroupID = "group.com.shivangsingh.dsamatrix"

    let container: ModelContainer

    init(inMemory: Bool = false) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: try Self.storeURL())
        container = try ModelContainer(
            for: schema,
            migrationPlan: SolveMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func storeURL() throws -> URL {
        let fileManager = FileManager.default
        let base: URL
        if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            base = group
        } else {
            // Only when the App Group entitlement is missing (e.g. an unsigned build).
            Logger.store.warning("App Group unavailable; widget will not see app data")
            base = URL.applicationSupportDirectory
        }
        let directory = base.appending(path: "Store", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "DSAMatrix.store")
    }

    func fetchAll() throws -> [SolveRecord] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Solve>(sortBy: [SortDescriptor(\.solvedAt)])
        return try context.fetch(descriptor).compactMap(SolveRecord.init)
    }

    @discardableResult
    func add(day: Day, at date: Date, note: String) throws -> SolveRecord {
        let context = ModelContext(container)
        let solve = Solve(day: day.key, solvedAt: date, note: Note.normalize(note))
        context.insert(solve)
        try context.save()
        return SolveRecord(id: solve.uuid, day: day, solvedAt: date, note: solve.note)
    }

    func update(id: UUID, note: String, solvedAt: Date) throws {
        let context = ModelContext(container)
        guard let solve = try fetch(id, in: context) else { return }
        solve.note = Note.normalize(note)
        solve.solvedAt = solvedAt
        try context.save()
    }

    func delete(id: UUID) throws {
        let context = ModelContext(container)
        guard let solve = try fetch(id, in: context) else { return }
        context.delete(solve)
        try context.save()
    }

    private func fetch(_ id: UUID, in context: ModelContext) throws -> Solve? {
        var descriptor = FetchDescriptor<Solve>(predicate: #Predicate { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

extension SolveRecord {
    /// Nil only for a row with a corrupt day key, which is then skipped.
    init?(_ solve: Solve) {
        guard let day = Day(key: solve.day) else {
            Logger.store.error("Skipping solve with invalid day \(solve.day, privacy: .public)")
            return nil
        }
        self.init(id: solve.uuid, day: day, solvedAt: solve.solvedAt, note: solve.note)
    }
}
```

If the compiler rejects `configurations: [configuration]`, use the variadic form `configurations: configuration`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ios && make test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ios
git commit -m "Add SwiftData solve model and store"
```

---

### Task 6: `AppModel`

**Files:**
- Create: `ios/DSAMatrix/AppModel.swift`, `ios/DSAMatrixTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `SolveStore`, `Summary`, `SolveRecord`, `Day`, `StreakStats`.
- Produces: `@MainActor @Observable final class AppModel`
  - `init(store: SolveStore?, now: @escaping () -> Date = { Date() }, reloadWidgets: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() })`
  - `private(set) var records: [SolveRecord]`, `private(set) var summary: Summary`, `private(set) var errorMessage: String?`
  - `var today: Day`, `var stats: StreakStats`, `func count(on: Day) -> Int`, `func records(on: Day) -> [SolveRecord]`
  - `func reload()` — re-fetch and recompute "today" (call on foreground and day change)
  - `@discardableResult func logSolve(note: String, on day: Day? = nil, at date: Date? = nil) -> SolveRecord?`
  - `func update(_ id: UUID, note: String, solvedAt: Date)`, `func delete(_ id: UUID)`
  - DEBUG only: `func seedDemoHistory()`

- [ ] **Step 1: Write the failing tests** — `ios/DSAMatrixTests/AppModelTests.swift`

```swift
import Foundation
import Testing
@testable import DSAMatrix

@MainActor
struct AppModelTests {
    private let noon = Day(key: "2026-09-30")!.date(hour: 12)

    private func makeModel(clock: @escaping () -> Date, reloads: @escaping () -> Void = {}) throws -> AppModel {
        AppModel(store: try SolveStore(inMemory: true), now: clock, reloadWidgets: reloads)
    }

    @Test func firstAndExtraSolvesToday() throws {
        let model = try makeModel(clock: { self.noon })
        #expect(model.stats == StreakStats())

        model.logSolve(note: "Two Sum")
        #expect(model.stats == StreakStats(current: 1, longest: 1, total: 1, todayCount: 1))

        model.logSolve(note: "", at: noon.addingTimeInterval(60))
        #expect(model.stats == StreakStats(current: 1, longest: 1, total: 2, todayCount: 2))
        #expect(model.records(on: model.today).map(\.title) == ["Two Sum", "Problem Solved"])
    }

    @Test func loggingAPastDayExtendsTheStreak() throws {
        let model = try makeModel(clock: { self.noon })
        model.logSolve(note: "today")
        let yesterday = model.today.adding(days: -1)
        model.logSolve(note: "forgot", on: yesterday, at: yesterday.date(hour: 12))
        #expect(model.stats.current == 2)
        #expect(model.count(on: yesterday) == 1)
    }

    @Test func deletingTodaysOnlySolveReturnsToOpenState() throws {
        let model = try makeModel(clock: { self.noon })
        let yesterday = model.today.adding(days: -1)
        model.logSolve(note: "", on: yesterday, at: yesterday.date(hour: 12))
        let record = try #require(model.logSolve(note: "oops"))
        model.delete(record.id)
        #expect(model.stats.todayCount == 0)
        #expect(model.stats.isAtRisk)
        #expect(model.stats.current == 1)
    }

    @Test func updateChangesNoteAndTime() throws {
        let model = try makeModel(clock: { self.noon })
        let record = try #require(model.logSolve(note: "old"))
        let later = model.today.date(hour: 18)
        model.update(record.id, note: "new | Graphs", solvedAt: later)
        let updated = try #require(model.records.first)
        #expect(updated.pattern == "Graphs")
        #expect(updated.solvedAt == later)
    }

    @Test func dayRolloverOnReload() throws {
        var now = noon
        let model = try makeModel(clock: { now })
        model.logSolve(note: "")
        #expect(!model.stats.isAtRisk)

        now = noon.addingTimeInterval(86_400)
        model.reload()
        #expect(model.today == Day(noon).adding(days: 1))
        #expect(model.stats.isAtRisk)
        #expect(model.stats.current == 1)
    }

    @Test func everyChangeReloadsWidgets() throws {
        var reloads = 0
        let model = try makeModel(clock: { self.noon }, reloads: { reloads += 1 })
        let record = try #require(model.logSolve(note: "a"))
        model.update(record.id, note: "b", solvedAt: self.noon)
        model.delete(record.id)
        #expect(reloads == 3)
    }

    @Test func missingStoreShowsErrorInsteadOfCrashing() {
        let model = AppModel(store: nil, now: { self.noon }, reloadWidgets: {})
        #expect(model.errorMessage != nil)
        #expect(model.logSolve(note: "x") == nil)
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `cd ios && make test`
Expected: FAIL — `cannot find 'AppModel' in scope`.

- [ ] **Step 3: Implement** — `ios/DSAMatrix/AppModel.swift`

```swift
import Foundation
import Observation
import OSLog
import WidgetKit

@MainActor
@Observable
final class AppModel {
    private(set) var records: [SolveRecord] = []
    private(set) var summary: Summary
    private(set) var errorMessage: String?

    @ObservationIgnored private let store: SolveStore?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let reloadWidgets: () -> Void

    init(
        store: SolveStore?,
        now: @escaping () -> Date = { Date() },
        reloadWidgets: @escaping () -> Void = { WidgetCenter.shared.reloadAllTimelines() }
    ) {
        self.store = store
        self.now = now
        self.reloadWidgets = reloadWidgets
        summary = Summary(records: [], today: Day(now()))
        if store == nil {
            errorMessage = "Couldn't open your data. Nothing was deleted — try reopening the app."
        }
        reload()
    }

    var today: Day { summary.today }
    var stats: StreakStats { summary.stats }

    func count(on day: Day) -> Int {
        summary.counts[day] ?? 0
    }

    func records(on day: Day) -> [SolveRecord] {
        records.filter { $0.day == day }
    }

    /// Re-reads the store (picks up widget writes) and recomputes "today".
    func reload() {
        if let store {
            do {
                records = try store.fetchAll()
            } catch {
                fail("load your history", error)
            }
        }
        recompute()
    }

    @discardableResult
    func logSolve(note: String, on day: Day? = nil, at date: Date? = nil) -> SolveRecord? {
        guard let store else { return nil }
        let date = date ?? now()
        do {
            let record = try store.add(day: day ?? Day(date), at: date, note: note)
            records.append(record)
            records.sort { $0.solvedAt < $1.solvedAt }
            didChange()
            return record
        } catch {
            fail("save", error)
            return nil
        }
    }

    func update(_ id: UUID, note: String, solvedAt: Date) {
        mutate { try $0.update(id: id, note: note, solvedAt: solvedAt) }
    }

    func delete(_ id: UUID) {
        mutate { try $0.delete(id: id) }
    }

    private func mutate(_ change: (SolveStore) throws -> Void) {
        guard let store else { return }
        do {
            try change(store)
            records = try store.fetchAll()
            didChange()
        } catch {
            fail("save", error)
        }
    }

    private func didChange() {
        errorMessage = nil
        recompute()
        reloadWidgets()
    }

    private func recompute() {
        summary = Summary(records: records, today: Day(now()))
    }

    private func fail(_ action: String, _ error: any Error) {
        Logger.store.error("Failed to \(action, privacy: .public): \(String(describing: error), privacy: .public)")
        errorMessage = "Couldn't \(action). \(error.localizedDescription)"
    }
}

#if DEBUG
extension AppModel {
    /// Fills ~15 weeks of varied history for simulator screenshots (`-seed` launch argument).
    func seedDemoHistory() {
        guard let store else { return }
        let notes = ["Two Sum | Hash Map", "LRU Cache | Design", "Course Schedule | Topological Sort", "", "Coin Change | DP"]
        for offset in 1..<105 {
            let wave = sin(Double(offset) * 1.7)
            guard offset <= 5 || wave > -0.2 else { continue }
            let day = today.adding(days: -offset)
            let count = wave > 0.7 ? 3 : wave > 0.3 ? 2 : 1
            for index in 0..<count {
                try? store.add(day: day, at: day.date(hour: 9 + index * 4), note: notes[(offset + index) % notes.count])
            }
        }
        reload()
        reloadWidgets()
    }
}
#endif
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ios && make test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add ios
git commit -m "Add observable app model"
```

---

### Task 7: Theme and feedback engines

**Files:**
- Create: `ios/Shared/Theme.swift`, `ios/DSAMatrix/Feedback/Haptics.swift`, `ios/DSAMatrix/Feedback/Chime.swift`, `ios/DSAMatrix/Feedback/ParticleSystem.swift`, `ios/DSAMatrix/Feedback/ParticleLayer.swift`

**Interfaces:**
- Produces:
  - `Color.oled`, `.surface`, `.surfaceBorder`, `.zincCell`, `.emerald`, `.emeraldLight`, `.emeraldDark`, `.mint`, `.amber`, `.flameRed`, `Color(hex:opacity:)`, `static func heat(_ level: Int) -> Color`
  - `Haptics.shared.prepare()`, `Haptics.shared.play(_: Haptics.Kind)` with `.success`, `.extra`, `.tick`
  - `Chime.shared.prepare()`, `Chime.shared.play(full: Bool)`
  - `@MainActor @Observable final class ParticleSystem { private(set) var bursts: [Burst]; static let lifetime: Double; func burst(at: CGPoint, big: Bool) }`
  - `struct ParticleLayer: View { let system: ParticleSystem }`
  - `extension Logger { static let feedback: Logger }`

These are sensory; there is no meaningful unit test. Verification is a clean build here and the on-device check in Task 12.

- [ ] **Step 1: Write `ios/Shared/Theme.swift`**

```swift
import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static let oled = Color(hex: 0x09090B)
    static let surface = Color(hex: 0x18181B)
    static let surfaceBorder = Color.white.opacity(0.08)
    static let zincCell = Color(hex: 0x27272A)
    static let emerald = Color(hex: 0x10B981)
    static let emeraldLight = Color(hex: 0x34D399)
    static let emeraldDark = Color(hex: 0x059669)
    static let mint = Color(hex: 0x6EE7B7)
    static let amber = Color(hex: 0xF59E0B)
    static let flameRed = Color(hex: 0xEF4444)

    /// Heatmap fill for a solve-count level from `Heatmap.level(for:)`.
    static func heat(_ level: Int) -> Color {
        switch level {
        case ...0: .zincCell
        case 1: .emeraldDark.opacity(0.55)
        case 2: .emerald.opacity(0.85)
        default: .emeraldLight
        }
    }
}
```

- [ ] **Step 2: Write `ios/DSAMatrix/Feedback/Haptics.swift`**

```swift
import CoreHaptics
import OSLog

extension Logger {
    static let feedback = Logger(subsystem: "com.shivangsingh.dsamatrix", category: "feedback")
}

/// Taptic Engine patterns. `prepare()` on touch-down so `play` on release has no start-up lag.
@MainActor
final class Haptics {
    enum Kind {
        /// First solve of the day: crisp tap, then a heavier landing (35 ms + 60 ms apart).
        case success
        /// Extra solve the same day.
        case extra
        /// Undo / delete.
        case tick
    }

    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    func prepare() {
        guard isSupported else { return }
        do {
            if engine == nil {
                let engine = try CHHapticEngine()
                engine.isAutoShutdownEnabled = true
                engine.resetHandler = {
                    Task { @MainActor in Haptics.shared.restart() }
                }
                self.engine = engine
            }
            try engine?.start()
        } catch {
            Logger.feedback.error("Haptic engine failed: \(String(describing: error), privacy: .public)")
            engine = nil
        }
    }

    func play(_ kind: Kind) {
        prepare()
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: Self.events(for: kind), parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            Logger.feedback.error("Haptic play failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func restart() {
        try? engine?.start()
    }

    private static func events(for kind: Kind) -> [CHHapticEvent] {
        func tap(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: time
            )
        }
        switch kind {
        case .success:
            return [tap(at: 0, intensity: 0.75, sharpness: 0.9), tap(at: 0.095, intensity: 1, sharpness: 0.55)]
        case .extra:
            return [tap(at: 0, intensity: 0.6, sharpness: 0.75)]
        case .tick:
            return [tap(at: 0, intensity: 0.35, sharpness: 0.5)]
        }
    }
}
```

- [ ] **Step 3: Write `ios/DSAMatrix/Feedback/Chime.swift`**

```swift
import AVFoundation
import OSLog

/// Synthesised micro-chime, no audio files. `.ambient` respects the silent switch
/// and mixes with music instead of pausing it.
@MainActor
final class Chime {
    static let shared = Chime()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isConfigured = false
    private lazy var fullBuffer = Self.render(format: format, peak: 0.22, bloom: true)
    private lazy var lightBuffer = Self.render(format: format, peak: 0.12, bloom: false)

    func prepare() {
        do {
            if !isConfigured {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                isConfigured = true
            }
            if !engine.isRunning {
                try AVAudioSession.sharedInstance().setActive(true)
                try engine.start()
            }
        } catch {
            Logger.feedback.error("Audio engine failed: \(String(describing: error), privacy: .public)")
        }
    }

    func play(full: Bool) {
        prepare()
        guard engine.isRunning, let buffer = full ? fullBuffer : lightBuffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// Sine C6 (1046.5 Hz) gliding to G6 (1567.98 Hz) over 70 ms, optional G6 bloom at 60 ms,
    /// faint octave partial, 6 ms attack and exponential decay (~250 ms full, ~150 ms light).
    private static func render(format: AVAudioFormat, peak: Float, bloom: Bool) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let decay = bloom ? 0.25 : 0.15
        let frames = AVAudioFrameCount((decay + 0.09) * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let output = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = frames

        let c6 = 1046.5, g6 = 1567.98, glide = 0.07, attack = 0.006
        func envelope(_ t: Double) -> Double {
            if t < 0 { return 0 }
            if t < attack { return t / attack }
            return exp(-(t - attack) * 7.6 / decay) // ≈ -66 dB at `decay`
        }

        var primary = 0.0, octave = 0.0, landing = 0.0
        for index in 0..<Int(frames) {
            let t = Double(index) / sampleRate
            let frequency = t < glide ? c6 * pow(g6 / c6, t / glide) : g6
            primary += 2 * .pi * frequency / sampleRate
            octave += 4 * .pi * frequency / sampleRate
            landing += 2 * .pi * g6 / sampleRate
            var sample = sin(primary) * envelope(t) + sin(octave) * envelope(t) * 0.08
            if bloom { sample += sin(landing) * envelope(t - 0.06) * 0.55 }
            output[index] = Float(sample) * peak
        }
        return buffer
    }
}
```

- [ ] **Step 4: Write `ios/DSAMatrix/Feedback/ParticleSystem.swift`**

```swift
import SwiftUI

/// Confetti bursts in the Home view's "root" coordinate space.
@MainActor
@Observable
final class ParticleSystem {
    struct Particle: Sendable {
        let velocity: CGVector
        let size: Double
        let spin: Double
        let color: Color
        let isCircle: Bool
    }

    struct Burst: Identifiable, Sendable {
        let id = UUID()
        let origin: CGPoint
        let start: Date
        let particles: [Particle]
    }

    static let lifetime = 1.3
    private(set) var bursts: [Burst] = []

    private static let palette: [Color] = [
        .emeraldLight, .emerald, .emeraldDark, .mint, .emeraldLight, .emerald, .amber, .white,
    ]

    func burst(at origin: CGPoint, big: Bool) {
        let particles = (0..<(big ? 110 : 36)).map { index in
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double.random(in: big ? 180...620 : 120...340)
            return Particle(
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed - (big ? 120 : 60)),
                size: .random(in: 3...7),
                spin: .random(in: -12...12),
                color: Self.palette.randomElement()!,
                isCircle: index % 3 == 0
            )
        }
        let burst = Burst(origin: origin, start: .now, particles: particles)
        bursts.append(burst)
        Task {
            try? await Task.sleep(for: .seconds(Self.lifetime))
            bursts.removeAll { $0.id == burst.id }
        }
    }
}
```

- [ ] **Step 5: Write `ios/DSAMatrix/Feedback/ParticleLayer.swift`**

```swift
import SwiftUI

/// Draws active bursts with simple ballistic physics: exponential drag plus gravity.
struct ParticleLayer: View {
    let system: ParticleSystem

    private let drag = 3.2
    private let gravity = 540.0

    var body: some View {
        TimelineView(.animation(paused: system.bursts.isEmpty)) { timeline in
            Canvas { context, _ in
                for burst in system.bursts {
                    let t = timeline.date.timeIntervalSince(burst.start)
                    guard t >= 0, t < ParticleSystem.lifetime else { continue }
                    let travel = (1 - exp(-drag * t)) / drag
                    let fall = 0.5 * gravity * t * t
                    for particle in burst.particles {
                        var layer = context
                        layer.opacity = 1 - t / ParticleSystem.lifetime
                        layer.translateBy(
                            x: burst.origin.x + particle.velocity.dx * travel,
                            y: burst.origin.y + particle.velocity.dy * travel + fall
                        )
                        layer.rotate(by: .radians(particle.spin * t))
                        let height = particle.isCircle ? particle.size : particle.size * 0.6
                        let rect = CGRect(x: -particle.size / 2, y: -height / 2, width: particle.size, height: height)
                        layer.fill(particle.isCircle ? Path(ellipseIn: rect) : Path(rect), with: .color(particle.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
```

- [ ] **Step 6: Build**

Run: `cd ios && make build`
Expected: `** BUILD SUCCEEDED **`, no errors. Swift 6 concurrency errors in these files must be fixed, not suppressed.

- [ ] **Step 7: Commit**

```bash
git add ios
git commit -m "Add theme, haptics, chime and particle system"
```

---

### Task 8: Home screen (top bar, hero card, undo toast)

**Files:**
- Create: `ios/DSAMatrix/Home/Prompt.swift`, `ios/DSAMatrix/Home/TopBar.swift`, `ios/DSAMatrix/Home/PressScaleStyle.swift`, `ios/DSAMatrix/Home/ButtonFace.swift`, `ios/DSAMatrix/Home/Ripple.swift`, `ios/DSAMatrix/Home/SolveRow.swift`, `ios/DSAMatrix/Home/UndoToast.swift`, `ios/DSAMatrix/Home/HeroCard.swift`, `ios/DSAMatrix/Home/HomeView.swift`, `ios/DSAMatrixTests/PromptTests.swift`
- Modify: `ios/DSAMatrix/DSAMatrixApp.swift` (full replacement)

**Interfaces:**
- Consumes: `AppModel`, `Haptics`, `Chime`, `ParticleSystem`, `ParticleLayer`, `Color` theme, `StreakStats`, `SolveRecord`.
- Produces:
  - `struct Prompt { let title: String; let subtitle: String; init(stats: StreakStats) }`
  - `struct SolveRow: View { let record: SolveRecord }` (reused by DaySheet)
  - `HomeView` with a `HeatmapCard` placeholder slot — Task 9 inserts `HeatmapCard(popDay:popCount:onSelect:)` and `.sheet(item: $selectedDay)`
  - Named coordinate space `"root"` on the Home `ScrollView`
  - Solve button accessibility identifier `"solve-button"`

- [ ] **Step 1: Write the failing test** — `ios/DSAMatrixTests/PromptTests.swift`

```swift
import Testing
@testable import DSAMatrix

struct PromptTests {
    @Test func freshStart() {
        #expect(Prompt(stats: StreakStats()).title == "One problem. Today.")
    }

    @Test func atRisk() {
        let prompt = Prompt(stats: StreakStats(current: 5, longest: 5, total: 9, todayCount: 0))
        #expect(prompt.title == "Keep the chain alive.")
        #expect(prompt.subtitle.hasPrefix("5-day streak"))
    }

    @Test func solvedToday() {
        #expect(Prompt(stats: StreakStats(current: 1, longest: 1, total: 1, todayCount: 1)).title == "Day one, done.")
        #expect(Prompt(stats: StreakStats(current: 6, longest: 6, total: 8, todayCount: 1)).subtitle == "Day 6 in the books. Rest easy.")
        #expect(Prompt(stats: StreakStats(current: 6, longest: 6, total: 9, todayCount: 2)).subtitle == "2 problems today. Greedy, in the good way.")
    }
}
```

Run: `cd ios && make test` — Expected: FAIL, `cannot find 'Prompt' in scope`.

- [ ] **Step 2: Write `ios/DSAMatrix/Home/Prompt.swift`**

```swift
struct Prompt {
    let title: String
    let subtitle: String

    init(stats: StreakStats) {
        if stats.todayCount > 0 {
            title = stats.current > 1 ? "Streak secured." : "Day one, done."
            if stats.todayCount > 1 {
                subtitle = "\(stats.todayCount) problems today. Greedy, in the good way."
            } else if stats.current >= 7 {
                subtitle = "\(stats.current) days of momentum. See you tomorrow."
            } else if stats.current > 1 {
                subtitle = "Day \(stats.current) in the books. Rest easy."
            } else {
                subtitle = "The hardest rep is the first. Come back tomorrow."
            }
        } else if stats.isAtRisk {
            title = "Keep the chain alive."
            subtitle = "\(stats.current)-day streak on the line. One problem is all it takes."
        } else {
            title = "One problem. Today."
            subtitle = "Solve it, then tap. That's the whole ritual."
        }
    }
}
```

Run: `cd ios && make test` — Expected: PASS.

- [ ] **Step 3: Write `ios/DSAMatrix/Home/TopBar.swift`**

```swift
import SwiftUI

struct TopBar: View {
    let stats: StreakStats
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.3x3.fill")
                .foregroundStyle(Color.emerald)
                .accessibilityHidden(true)
            Text("DSA \(Text("Matrix").foregroundStyle(.secondary))")
                .font(.headline)
            Spacer()
            streakPill
            totalPill
        }
        .frame(height: 52)
    }

    private var streakPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .foregroundStyle(stats.current > 0
                    ? AnyShapeStyle(LinearGradient(colors: [.amber, .flameRed], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(hex: 0x52525B)))
                .symbolEffect(.breathe, isActive: stats.current >= 3 && !reduceMotion)
                .overlay(alignment: .topTrailing) {
                    if stats.isAtRisk {
                        Circle().fill(Color.amber).frame(width: 6, height: 6).offset(x: 3, y: -2)
                    }
                }
            Text("\(stats.current)d")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(stats.current > 0 ? Color.amber : .secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .glassEffect()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current streak \(stats.current) days\(stats.isAtRisk ? ", solve today to keep it" : "")")
    }

    private var totalPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "target").foregroundStyle(Color.emeraldLight)
            Text("\(stats.total)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .glassEffect()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stats.total) problems solved")
    }
}
```

- [ ] **Step 4: Write `PressScaleStyle.swift`, `ButtonFace.swift`, `Ripple.swift`, `SolveRow.swift`, `UndoToast.swift`**

`ios/DSAMatrix/Home/PressScaleStyle.swift`:
```swift
import SwiftUI

/// Fast compression on press, overshooting spring on release.
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(
                configuration.isPressed ? .easeOut(duration: 0.1) : .spring(response: 0.42, dampingFraction: 0.55),
                value: configuration.isPressed
            )
    }
}
```

`ios/DSAMatrix/Home/ButtonFace.swift`:
```swift
import SwiftUI

struct ButtonFace: View {
    let solved: Bool
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: solved ? 52 : 46, weight: solved ? .semibold : .light))
                .foregroundStyle(solved ? Color.emeraldLight : Color(hex: 0x71717A))
                .contentTransition(.symbolEffect(.replace))
            VStack(spacing: 3) {
                Text(solved ? "\(count) SOLVED TODAY" : "TAP WHEN SOLVED")
                if solved { Text("TAP TO ADD").foregroundStyle(Color(hex: 0x71717A)) }
            }
            .font(.caption2.monospaced())
            .tracking(1.5)
            .foregroundStyle(solved ? Color.emerald : Color(hex: 0xA1A1AA))
        }
        .frame(width: 168, height: 168)
        .background {
            if solved {
                Circle().fill(Color.surface)
            } else {
                Circle().fill(RadialGradient(
                    colors: [Color(hex: 0x1F2B27), .surface, Color(hex: 0x111113)],
                    center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 100
                ))
            }
        }
        .overlay {
            Circle().strokeBorder(solved ? Color.emerald.opacity(0.3) : Color.emeraldLight.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.8), radius: 20, y: 14)
        .contentShape(.circle)
    }
}
```

`ios/DSAMatrix/Home/Ripple.swift`:
```swift
import SwiftUI

struct Ripple: Identifiable {
    let id = UUID()
    /// Centre in the card's local coordinates.
    let center: CGPoint
    let radius: CGFloat
}

/// Expanding shockwave ring plus a soft radial flash.
struct RippleView: View {
    let ripple: Ripple
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color.emerald.opacity(0.22), .clear], center: .center, startRadius: 0, endRadius: ripple.radius))
                .opacity(1 - progress)
            Circle()
                .strokeBorder(Color.emeraldLight.opacity(0.7), lineWidth: 2)
                .shadow(color: Color.emerald.opacity(0.5), radius: 12)
                .scaleEffect(progress)
                .opacity(1 - progress)
        }
        .frame(width: ripple.radius * 2, height: ripple.radius * 2)
        .position(ripple.center)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
        }
    }
}
```

`ios/DSAMatrix/Home/SolveRow.swift`:
```swift
import SwiftUI

struct SolveRow: View {
    let record: SolveRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.emeraldLight)
                .frame(width: 6, height: 6)
                .padding(.top, 7)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let pattern = record.pattern {
                    Text(pattern)
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color.emeraldLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.zincCell, in: .rect(cornerRadius: 6))
                }
            }
            Spacer(minLength: 8)
            Text(record.solvedAt, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
```

`ios/DSAMatrix/Home/UndoToast.swift`:
```swift
import SwiftUI

struct UndoToast: View {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let record: SolveRecord
    }

    let item: Item
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.emeraldLight)
            Text("Logged “\(item.record.title)”")
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.emeraldLight)
        }
        .padding(.horizontal, 18)
        .frame(height: 50)
        .glassEffect()
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
```

- [ ] **Step 5: Write `ios/DSAMatrix/Home/HeroCard.swift`**

```swift
import SwiftUI

struct HeroCard: View {
    /// Called on every solve with the raw note and the touch point in "root" space.
    let onSolve: (_ note: String, _ location: CGPoint) -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var note = ""
    @State private var lastTouch: CGPoint?
    @State private var buttonFrame = CGRect.zero
    @State private var cardFrame = CGRect.zero
    @State private var ripples: [Ripple] = []
    @FocusState private var noteFocused: Bool

    private var todayCount: Int { model.stats.todayCount }
    private var solved: Bool { todayCount > 0 }

    var body: some View {
        let prompt = Prompt(stats: model.stats)
        VStack(spacing: 0) {
            Text(model.today.startDate().formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased())
                .font(.caption.monospaced())
                .tracking(1.5)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text(prompt.title)
                    .font(.title2.weight(.semibold))
                Text(prompt.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            .id(prompt.title)
            .transition(.opacity)

            solveButton
                .padding(.vertical, 28)

            noteField

            if solved {
                VStack(spacing: 12) {
                    ForEach(model.records(on: model.today)) { SolveRow(record: $0) }
                }
                .padding(.top, 16)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.surface, in: .rect(cornerRadius: 28))
        .overlay {
            ZStack { ForEach(ripples) { RippleView(ripple: $0) } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(.rect(cornerRadius: 28))
                .allowsHitTesting(false)
        }
        .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(Color.surfaceBorder) }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("root")) } action: { cardFrame = $0 }
        .animation(.easeInOut(duration: 0.25), value: solved)
    }

    private var solveButton: some View {
        Button { fire(at: lastTouch) } label: {
            ButtonFace(solved: solved, count: todayCount)
        }
        .buttonStyle(PressScaleStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("root"))
                .onChanged { value in
                    if value.translation == .zero {
                        // Touch-down: warm up engines so release feedback is instant.
                        Haptics.shared.prepare()
                        Chime.shared.prepare()
                    }
                    lastTouch = value.location
                }
        )
        .background {
            if !solved && !reduceMotion {
                Circle()
                    .fill(Color.emerald.opacity(0.25))
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .phaseAnimator([false, true]) { glow, on in
                        glow.scaleEffect(on ? 1.06 : 0.94).opacity(on ? 0.9 : 0.35)
                    } animation: { _ in .easeInOut(duration: 1.8) }
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("root")) } action: { buttonFrame = $0 }
        .accessibilityLabel(solved ? "\(todayCount) solved today. Log another" : "Mark today's problem as solved")
        .accessibilityIdentifier("solve-button")
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Problem / pattern (optional)", text: $note)
                .focused($noteFocused)
                .submitLabel(.done)
                .onSubmit { fire(at: nil) } // Return logs a solve
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.black.opacity(0.4), in: .rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(noteFocused ? Color.emerald.opacity(0.4) : Color.white.opacity(0.07))
                }
            if !solved {
                Text("e.g. 33. Search in Rotated Sorted Array | Binary Search")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func fire(at touch: CGPoint?) {
        let location = touch ?? CGPoint(x: buttonFrame.midX, y: buttonFrame.midY)
        if !reduceMotion {
            let local = CGPoint(x: location.x - cardFrame.minX, y: location.y - cardFrame.minY)
            // Radius that reaches the farthest corner so the ring sweeps the whole card.
            let reach = hypot(max(local.x, cardFrame.width - local.x), max(local.y, cardFrame.height - local.y))
            let ripple = Ripple(center: local, radius: solved ? reach * 0.5 : reach)
            ripples.append(ripple)
            Task {
                try? await Task.sleep(for: .milliseconds(750))
                ripples.removeAll { $0.id == ripple.id }
            }
        }
        onSolve(note, location)
        note = ""
        noteFocused = false
    }
}
```

- [ ] **Step 6: Write `ios/DSAMatrix/Home/HomeView.swift`**

```swift
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles = ParticleSystem()
    @State private var toast: UndoToast.Item?
    @State private var selectedDay: Day?
    @State private var popDay: Day?
    @State private var popCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TopBar(stats: model.stats)
                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Color.amber)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HeroCard(onSolve: handleSolve)
                // Task 9: HeatmapCard goes here.
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .scrollDismissesKeyboard(.interactively)
        .coordinateSpace(.named("root"))
        .overlay { ParticleLayer(system: particles) }
        .overlay(alignment: .bottom) {
            if let toast {
                UndoToast(item: toast) {
                    model.delete(toast.record.id)
                    Haptics.shared.play(.tick)
                    self.toast = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: toast)
        .task(id: toast?.id) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { toast = nil }
        }
        .background(Color.oled.ignoresSafeArea())
    }

    /// Haptic, sound, particles and the save all happen in the same run-loop turn.
    private func handleSolve(note: String, at location: CGPoint) {
        let isFirst = model.stats.todayCount == 0
        Haptics.shared.play(isFirst ? .success : .extra)
        Chime.shared.play(full: isFirst)
        if !reduceMotion { particles.burst(at: location, big: isFirst) }
        guard let record = model.logSolve(note: note) else { return }
        if isFirst {
            popDay = record.day
            popCount += 1
        }
        toast = UndoToast.Item(record: record)
    }
}
```

- [ ] **Step 7: Replace `ios/DSAMatrix/DSAMatrixApp.swift`**

```swift
import Combine
import OSLog
import SwiftUI

@main
struct DSAMatrixApp: App {
    @State private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let store: SolveStore?
        do {
            store = try SolveStore(inMemory: arguments.contains("-inMemory"))
        } catch {
            Logger.store.critical("Store failed to open: \(String(describing: error), privacy: .public)")
            store = nil
        }
        let model = AppModel(store: store)
        #if DEBUG
        if arguments.contains("-seed") { model.seedDemoHistory() }
        #endif
        _model = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(model)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.reload() } // picks up widget "+" taps and a new day
                }
                .onReceive(dayChanges) { _ in model.reload() }
        }
    }

    private var dayChanges: AnyPublisher<Notification, Never> {
        let center = NotificationCenter.default
        return center.publisher(for: .NSCalendarDayChanged)
            .merge(with: center.publisher(for: UIApplication.significantTimeChangeNotification))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
```

- [ ] **Step 8: Run tests and launch in the simulator**

```bash
cd ios && make test
make run ARGS="-seed -inMemory"
sleep 4 && xcrun simctl io booted screenshot /tmp/dsa-home.png
```
Expected: tests PASS; screenshot shows the top bar (streak pill with amber at-risk dot, total pill), the hero card with "Keep the chain alive.", the breathing button and the note field. Open `/tmp/dsa-home.png` and check it matches the spec.

- [ ] **Step 9: Commit**

```bash
git add ios
git commit -m "Add home screen with hero card, feedback and undo"
```

---

### Task 9: Heatmap card and Day sheet

**Files:**
- Create: `ios/DSAMatrix/Heatmap/HeatCell.swift`, `ios/DSAMatrix/Heatmap/HeatmapCard.swift`, `ios/DSAMatrix/DaySheet/DaySheet.swift`, `ios/DSAMatrix/DaySheet/SolveEditor.swift`
- Modify: `ios/DSAMatrix/Home/HomeView.swift` (replace the `// Task 9` comment, add the sheet)

**Interfaces:**
- Consumes: `AppModel` (`today`, `stats`, `count(on:)`, `records(on:)`, `logSolve(note:on:at:)`, `update`, `delete`), `Heatmap`, `Color.heat`, `SolveRow`, `Haptics`.
- Produces: `HeatmapCard(popDay: Day?, popCount: Int, onSelect: (Day) -> Void)`, `DaySheet(day: Day)`, `SolveEditor(day: Day, target: EditorTarget)`, `enum EditorTarget: Identifiable { case add, edit(SolveRecord) }`. Cell accessibility identifier `"day-YYYY-MM-DD"`.

- [ ] **Step 1: Write `ios/DSAMatrix/Heatmap/HeatCell.swift`**

```swift
import SwiftUI

struct HeatCell: View {
    let level: Int
    let isToday: Bool
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.heat(level))
            .overlay {
                if level > 0 {
                    // Inner bevel highlight.
                    RoundedRectangle(cornerRadius: 3).strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                }
            }
            .shadow(color: level >= 3 ? Color.emerald.opacity(0.35) : .clear, radius: 5)
            .frame(width: size, height: size)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 4.5)
                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                        .padding(-3)
                }
            }
    }
}
```

- [ ] **Step 2: Write `ios/DSAMatrix/Heatmap/HeatmapCard.swift`**

```swift
import SwiftUI

struct HeatmapCard: View {
    let popDay: Day?
    let popCount: Int
    let onSelect: (Day) -> Void

    @Environment(AppModel.self) private var model
    private let cell: CGFloat = 14
    private let gap: CGFloat = 3

    var body: some View {
        let weeks = Heatmap.weeks(endingAt: model.today)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Last \(Heatmap.defaultWeeks) weeks").font(.subheadline.weight(.medium))
                Spacer()
                Text("best \(model.stats.longest)d")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 8) {
                weekdayLabels
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: gap) {
                            ForEach(weeks) { week in
                                Text(week.monthLabel ?? "")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                                    .frame(width: cell, alignment: .leading)
                            }
                        }
                        HStack(spacing: gap) {
                            ForEach(weeks) { week in
                                VStack(spacing: gap) {
                                    ForEach(week.cells) { cellView($0) }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.trailing, 4)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.trailing)
            }

            HStack(spacing: 4) {
                Text("Tap a day to add or edit").font(.caption).foregroundStyle(.tertiary)
                Spacer()
                Text("less").font(.caption2.monospaced()).foregroundStyle(.tertiary)
                ForEach(0..<4) { HeatCell(level: $0, isToday: false, size: 10) }
                Text("more").font(.caption2.monospaced()).foregroundStyle(.tertiary)
            }
            .accessibilityHidden(true)
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.surfaceBorder) }
    }

    private static let weekdayNames = ["", "Mon", "", "Wed", "", "Fri", ""]

    private var weekdayLabels: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(Array(Self.weekdayNames.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(height: cell)
            }
        }
        .padding(.top, 4 + 11 + 4) // month row height + spacing
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cellView(_ cellInfo: HeatmapCell) -> some View {
        if cellInfo.isFuture {
            Color.clear.frame(width: cell, height: cell)
        } else {
            let count = model.count(on: cellInfo.day)
            Button { onSelect(cellInfo.day) } label: {
                HeatCell(level: Heatmap.level(for: count), isToday: cellInfo.isToday, size: cell)
            }
            .buttonStyle(.plain)
            .keyframeAnimator(initialValue: 1.0, trigger: cellInfo.day == popDay ? popCount : 0) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.25, duration: 0.22)
                    SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                }
            }
            .accessibilityLabel("\(cellInfo.day.startDate().formatted(date: .complete, time: .omitted)), \(count) solved")
            .accessibilityIdentifier("day-\(cellInfo.day.key)")
        }
    }
}
```

- [ ] **Step 3: Write `ios/DSAMatrix/DaySheet/DaySheet.swift`**

```swift
import SwiftUI

enum EditorTarget: Identifiable {
    case add
    case edit(SolveRecord)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let record): record.id.uuidString
        }
    }
}

struct DaySheet: View {
    let day: Day

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var editor: EditorTarget?

    var body: some View {
        let records = model.records(on: day)
        NavigationStack {
            List {
                if records.isEmpty {
                    ContentUnavailableView("Nothing logged", systemImage: "square.dashed",
                                           description: Text("Tap + to add a problem you solved this day."))
                }
                ForEach(records) { record in
                    Button { editor = .edit(record) } label: { SolveRow(record: record) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { model.delete(records[index].id) }
                    Haptics.shared.play(.tick)
                }
            }
            .navigationTitle(day.startDate().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            .navigationSubtitle("\(records.count) solved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add solve", systemImage: "plus") { editor = .add }
                }
            }
            .sheet(item: $editor) { SolveEditor(day: day, target: $0) }
        }
        .presentationDetents([.medium, .large])
    }
}
```

- [ ] **Step 4: Write `ios/DSAMatrix/DaySheet/SolveEditor.swift`**

```swift
import SwiftUI

struct SolveEditor: View {
    let day: Day
    let target: EditorTarget

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var time: Date

    init(day: Day, target: EditorTarget, now: Date = .now) {
        self.day = day
        self.target = target
        switch target {
        case .add:
            _note = State(initialValue: "")
            _time = State(initialValue: day == Day(now) ? now : day.date(hour: 12))
        case .edit(let record):
            _note = State(initialValue: record.note ?? "")
            _time = State(initialValue: record.solvedAt)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Problem / pattern (optional)", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("editor-note")
                // Range keeps the time inside this day; moving a solve = delete + re-add.
                DatePicker("Time", selection: $time, in: day.timeRange(), displayedComponents: .hourAndMinute)
                if case .edit(let record) = target {
                    Section {
                        Button("Delete", role: .destructive) {
                            model.delete(record.id)
                            Haptics.shared.play(.tick)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isAdding ? "Add solve" : "Edit solve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
            }
        }
        .presentationDetents([.medium])
    }

    private var isAdding: Bool {
        if case .add = target { true } else { false }
    }

    private func save() {
        switch target {
        case .add:
            model.logSolve(note: note, on: day, at: time)
            Haptics.shared.play(.extra)
        case .edit(let record):
            model.update(record.id, note: note, solvedAt: time)
        }
        dismiss()
    }
}
```

- [ ] **Step 5: Wire into `HomeView`** — replace the line `// Task 9: HeatmapCard goes here.` with:

```swift
                HeatmapCard(popDay: popDay, popCount: popCount) { selectedDay = $0 }
```

and add after `.background(Color.oled.ignoresSafeArea())`:

```swift
        .sheet(item: $selectedDay) { DaySheet(day: $0) }
```

- [ ] **Step 6: Test and look at it**

```bash
cd ios && make test
make run ARGS="-seed -inMemory"
sleep 4 && xcrun simctl io booted screenshot /tmp/dsa-heatmap.png
```
Expected: tests PASS; screenshot shows the 16-week heatmap under the hero card with graded emerald shades, month and weekday labels, and a ring on today.

- [ ] **Step 7: Commit**

```bash
git add ios
git commit -m "Add heatmap card and day sheet editing"
```

---

### Task 10: Widgets and "+" intent

**Files:**
- Create: `ios/DSAMatrixWidget/DSAMatrixWidget.entitlements`, `ios/DSAMatrixWidget/MatrixWidgetBundle.swift`, `ios/DSAMatrixWidget/MatrixProvider.swift`, `ios/DSAMatrixWidget/MatrixWidget.swift`, `ios/DSAMatrixWidget/LogSolveIntent.swift`, `ios/DSAMatrixWidget/Views/MiniGrid.swift`, `ios/DSAMatrixWidget/Views/SmallWidgetView.swift`, `ios/DSAMatrixWidget/Views/MediumWidgetView.swift`, `ios/DSAMatrixWidget/Views/AccessoryViews.swift`
- Modify: `ios/project.yml` (add widget target, embed it in the app)

**Interfaces:**
- Consumes: `SolveStore`, `Summary`, `Heatmap`, `Day`, `StreakStats.statusText`, `Note`, theme colors.
- Produces: `MatrixEntry`, `MatrixProvider`, `MatrixWidget` (kind `"MatrixWidget"`), `LogSolveIntent`.

- [ ] **Step 1: Add the target to `ios/project.yml`**

Under `targets:` add:
```yaml
  DSAMatrixWidget:
    type: app-extension
    platform: iOS
    sources:
      - DSAMatrixWidget
      - Shared
    entitlements:
      path: DSAMatrixWidget/DSAMatrixWidget.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.shivangsingh.dsamatrix
    info:
      path: DSAMatrixWidget/Info.plist
      properties:
        CFBundleDisplayName: DSA Matrix
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.shivangsingh.dsamatrix.widget
        GENERATE_INFOPLIST_FILE: YES
```

And under the `DSAMatrix` target add:
```yaml
    dependencies:
      - target: DSAMatrixWidget
```

`DSAMatrixWidget/Info.plist` is generated by XcodeGen from `info:`; commit it.

- [ ] **Step 2: Write `ios/DSAMatrixWidget/DSAMatrixWidget.entitlements`** — identical content to `ios/DSAMatrix/DSAMatrix.entitlements` (Task 1 Step 4).

- [ ] **Step 3: Write `ios/DSAMatrixWidget/MatrixProvider.swift`**

```swift
import OSLog
import WidgetKit

struct MatrixEntry: TimelineEntry {
    let date: Date
    let summary: Summary

    static var placeholder: MatrixEntry {
        let today = Day(Date.now)
        let records = (0..<40).compactMap { offset -> SolveRecord? in
            guard offset % 5 != 3 else { return nil }
            let day = today.adding(days: -offset - 1)
            return SolveRecord(id: UUID(), day: day, solvedAt: day.date(hour: 12), note: "Two Sum | Hash Map")
        }
        return MatrixEntry(date: .now, summary: Summary(records: records, today: today))
    }
}

struct MatrixProvider: TimelineProvider {
    func placeholder(in context: Context) -> MatrixEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MatrixEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            let now = Date.now
            completion(MatrixEntry(date: now, summary: Summary(records: Self.records(), today: Day(now))))
        }
    }

    /// Current entry plus one at the next local midnight, so the widget flips to the
    /// new day (e.g. "At risk") without the app running. `.atEnd` asks again after midnight.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MatrixEntry>) -> Void) {
        let now = Date.now
        let today = Day(now)
        let tomorrow = today.adding(days: 1)
        let records = Self.records()
        let entries = [
            MatrixEntry(date: now, summary: Summary(records: records, today: today)),
            MatrixEntry(date: tomorrow.startDate(), summary: Summary(records: records, today: tomorrow)),
        ]
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private static func records() -> [SolveRecord] {
        do {
            return try SolveStore().fetchAll()
        } catch {
            Logger.store.error("Widget fetch failed: \(String(describing: error), privacy: .public)")
            return []
        }
    }
}
```

- [ ] **Step 4: Write `ios/DSAMatrixWidget/LogSolveIntent.swift`**

```swift
import AppIntents
import WidgetKit

/// The medium widget's "+" button. Runs in the widget process; no haptics, sound or particles.
struct LogSolveIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Solve"
    static var description: IntentDescription { IntentDescription("Logs a DSA problem solved today.") }

    func perform() async throws -> some IntentResult {
        let now = Date.now
        try SolveStore().add(day: Day(now), at: now, note: "")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
```

- [ ] **Step 5: Write the widget views**

`ios/DSAMatrixWidget/Views/MiniGrid.swift`:
```swift
import SwiftUI
import WidgetKit

struct MiniGrid: View {
    let summary: Summary
    let weeks: Int
    let cell: CGFloat
    let gap: CGFloat

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        HStack(spacing: gap) {
            ForEach(Heatmap.weeks(endingAt: summary.today, count: weeks)) { week in
                VStack(spacing: gap) {
                    ForEach(week.cells) { item in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fill(for: item))
                            .frame(width: cell, height: cell)
                            .overlay {
                                if item.isToday {
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                        .padding(-1.5)
                                }
                            }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func fill(for item: HeatmapCell) -> Color {
        if item.isFuture { return .clear }
        let level = Heatmap.level(for: summary.counts[item.day] ?? 0)
        if renderingMode == .fullColor { return Color.heat(level) }
        // Tinted / clear / StandBy: brightness carries the level.
        return Color.white.opacity(level == 0 ? 0.15 : 0.35 + Double(level) * 0.2)
    }
}
```

`ios/DSAMatrixWidget/Views/SmallWidgetView.swift`:
```swift
import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let summary: Summary

    var body: some View {
        let stats = summary.stats
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(stats.current)")
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                Image(systemName: "flame.fill")
                    .foregroundStyle(stats.current > 0 ? Color.amber : .secondary)
                    .widgetAccentable()
            }
            Text(stats.statusText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(stats.todayCount > 0 ? Color.emeraldLight : Color.amber)
            Spacer(minLength: 4)
            MiniGrid(summary: summary, weeks: 5, cell: 8, gap: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stats.current) day streak. \(stats.statusText)")
    }
}
```

`ios/DSAMatrixWidget/Views/MediumWidgetView.swift`:
```swift
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let summary: Summary

    var body: some View {
        let stats = summary.stats
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(stats.current)")
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())
                    Image(systemName: "flame.fill")
                        .foregroundStyle(stats.current > 0 ? Color.amber : .secondary)
                        .widgetAccentable()
                }
                Text(stats.statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(stats.todayCount > 0 ? Color.emeraldLight : Color.amber)
                Text("\(stats.total) solved")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 6)
                Button(intent: LogSolveIntent()) {
                    Label("Solved", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.emerald)
                .widgetAccentable()
            }
            Spacer(minLength: 0)
            MiniGrid(summary: summary, weeks: Heatmap.defaultWeeks, cell: 8, gap: 2)
        }
    }
}
```

`ios/DSAMatrixWidget/Views/AccessoryViews.swift`:
```swift
import SwiftUI
import WidgetKit

/// Streak in a ring; the ring is full once today is solved.
struct CircularWidgetView: View {
    let stats: StreakStats

    var body: some View {
        Gauge(value: stats.todayCount > 0 ? 1 : 0) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(stats.current)").monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .accessibilityLabel("\(stats.current) day streak. \(stats.statusText)")
    }
}

struct RectangularWidgetView: View {
    let summary: Summary

    var body: some View {
        let stats = summary.stats
        VStack(alignment: .leading, spacing: 2) {
            Text("🔥 \(stats.current)d · \(stats.todayCount) today")
                .font(.headline)
                .widgetAccentable()
            Text(summary.latestNote.map { Note.split($0).title } ?? stats.statusText)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InlineWidgetView: View {
    let stats: StreakStats

    var body: some View {
        Text("🔥 \(stats.current)d · \(stats.todayCount > 0 ? "✓ today" : stats.isAtRisk ? "at risk" : "solve today")")
    }
}
```

- [ ] **Step 6: Write the widget definition and bundle**

`ios/DSAMatrixWidget/MatrixWidget.swift`:
```swift
import SwiftUI
import WidgetKit

struct MatrixWidgetView: View {
    let entry: MatrixEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: MediumWidgetView(summary: entry.summary)
        case .accessoryCircular: CircularWidgetView(stats: entry.summary.stats)
        case .accessoryRectangular: RectangularWidgetView(summary: entry.summary)
        case .accessoryInline: InlineWidgetView(stats: entry.summary.stats)
        default: SmallWidgetView(summary: entry.summary)
        }
    }
}

struct MatrixWidget: Widget {
    let kind = "MatrixWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MatrixProvider()) { entry in
            MatrixWidgetView(entry: entry)
                .containerBackground(Color.oled, for: .widget)
        }
        .configurationDisplayName("DSA Streak")
        .description("Your streak, today's count and recent activity.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemMedium) {
    MatrixWidget()
} timeline: {
    MatrixEntry.placeholder
}

#Preview(as: .accessoryCircular) {
    MatrixWidget()
} timeline: {
    MatrixEntry.placeholder
}
```

`ios/DSAMatrixWidget/MatrixWidgetBundle.swift`:
```swift
import SwiftUI
import WidgetKit

@main
struct MatrixWidgetBundle: WidgetBundle {
    var body: some Widget {
        MatrixWidget()
    }
}
```

- [ ] **Step 7: Build and test**

Run: `cd ios && make test && make build`
Expected: both succeed. Then `make run ARGS="-seed"` (persistent store, so the widget can read it), long-press the simulator Home Screen → Edit → Add Widget → "DSA Matrix", add Small and Medium. Screenshot with `xcrun simctl io booted screenshot /tmp/dsa-widgets.png` and check the streak/heatmap match the app. Tap "+" on the medium widget; the count should go up. Lock Screen widgets are checked on the device (Task 12).

- [ ] **Step 8: Commit**

```bash
git add ios
git commit -m "Add home and lock screen widgets with log intent"
```

---

### Task 11: UI smoke test with screenshots

**Files:**
- Create: `ios/DSAMatrixUITests/SmokeTests.swift`
- Modify: `ios/project.yml` (add UI test target and scheme entry)

**Interfaces:**
- Consumes: launch arguments `-seed`, `-inMemory` (Task 8), identifiers `"solve-button"` (Task 8) and `"day-YYYY-MM-DD"` (Task 9), toast button "Undo", DaySheet "Add solve" / editor "Save".

- [ ] **Step 1: Add the target** — in `ios/project.yml` under `targets:`:

```yaml
  DSAMatrixUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - DSAMatrixUITests
    dependencies:
      - target: DSAMatrix
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.shivangsingh.dsamatrix.uitests
        GENERATE_INFOPLIST_FILE: YES
```

and change the scheme's test targets to:
```yaml
    test:
      targets:
        - DSAMatrixTests
        - DSAMatrixUITests
```

- [ ] **Step 2: Write `ios/DSAMatrixUITests/SmokeTests.swift`**

```swift
import XCTest

final class SmokeTests: XCTestCase {
    @MainActor
    func testSolveUndoAndDaySheetFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seed", "-inMemory"]
        app.launch()
        snap("1-open")

        let button = app.buttons["solve-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        snap("2-burst")
        XCTAssertTrue(app.staticTexts["Streak secured."].waitForExistence(timeout: 2)
            || app.staticTexts["Day one, done."].exists)
        sleep(2)
        snap("3-solved")

        button.tap()
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 2))
        app.buttons["Undo"].tap()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
        let cell = app.buttons["day-\(yesterday)"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.tap()
        snap("4-day-sheet")

        app.buttons["Add solve"].tap()
        let field = app.descendants(matching: .any)["editor-note"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.typeText("Coin Change | DP")
        app.buttons["Save"].tap()
        sleep(1)
        snap("5-day-sheet-after-add")
    }

    @MainActor
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

- [ ] **Step 3: Run and review screenshots**

Run: `cd ios && make shots && ls shots`
Expected: test passes; `shots/` contains five PNGs. Open each and check against the spec: breathing button before, particles + shockwave in `2-burst`, solved state with today's row in `3-solved`, Day sheet listing that day's solves before and after the add.

- [ ] **Step 4: Commit**

```bash
git add ios
git commit -m "Add UI smoke test that captures screenshots"
```

---

### Task 12: Install on the iPhone and document

**Files:**
- Modify: `ios/project.yml` (`DEVELOPMENT_TEAM`), `README.md` (iOS section)

This task needs the user at the Mac with the iPhone plugged in.

- [ ] **Step 1: User — one-time device setup**
  1. Xcode → Settings → Accounts → add Apple ID.
  2. Plug in the iPhone, unlock it, tap "Trust This Computer".
  3. iPhone: Settings → Privacy & Security → Developer Mode → On (phone restarts).

- [ ] **Step 2: Set the team** — user opens `ios/DSAMatrix.xcodeproj`, selects the DSAMatrix target → Signing & Capabilities → Team → their Personal Team. Then read the ID it wrote:

Run: `grep -m1 DEVELOPMENT_TEAM ios/DSAMatrix.xcodeproj/project.pbxproj`
Copy the 10-character value into `ios/project.yml` → `settings.base.DEVELOPMENT_TEAM` so regenerating keeps it. Re-run `cd ios && make generate`.

If signing fails with "bundle identifier not available", change `com.shivangsingh.dsamatrix` to `com.shivangsingh.dsamatrix2` (and the `.widget` / tests IDs to match) everywhere in `project.yml`, keep the App Group name, and regenerate.

- [ ] **Step 3: Run on the device** — in Xcode choose the iPhone as destination, press Run. First launch: iPhone Settings → General → VPN & Device Management → trust the developer, then open the app.

- [ ] **Step 4: User checks on the phone**
  - First solve: double-pulse haptic, chime (silent switch off), confetti from the finger, shockwave, heatmap pop.
  - Extra solve: lighter tap, short chime, small burst. Undo works.
  - Silent switch on: no sound, haptic still plays.
  - Home Screen: add Small and Medium widgets; "+" logs a solve and the app shows it on next open.
  - Lock Screen: add Circular, Rectangular, Inline widgets.

- [ ] **Step 5: Add an iOS section to `README.md`**

````markdown
## iOS app

Native SwiftUI app in `ios/` with Home and Lock Screen widgets. Local only (SwiftData in an App Group).

```bash
brew install xcodegen
cd ios
make test                         # unit tests on the iPhone 17 simulator
make run ARGS="-seed -inMemory"   # demo data in the simulator
make shots                        # UI smoke test, screenshots in ios/shots/
```

Install on your iPhone: open `ios/DSAMatrix.xcodeproj`, pick your team, choose the phone, Run.
With a free Apple ID the install lasts 7 days; plug in and Run again to renew. Data is kept.
Deleting the app deletes its history (no iCloud yet).
````

- [ ] **Step 6: Commit**

```bash
git add README.md ios/project.yml ios/DSAMatrix.xcodeproj
git commit -m "Document iOS build and set signing team"
```

---

## Spec coverage check

| Spec item | Task |
|---|---|
| Top bar, flame pulse ≥ 3, at-risk dot, total | 8 |
| Hero card prompts, breathing, press spring, release-inside fires | 8 |
| "N solved today · tap to add", today's rows | 8 |
| Note field, `|` pattern tag, Return logs | 3, 8 |
| Heatmap 16 weeks, shades 0/1/2/3+, today ring, pop, tap → sheet | 4, 9 |
| Undo toast ~4 s | 8 |
| Day sheet: list, edit, swipe delete, add (12:00 default for past days) | 9 |
| Feedback table (haptics, chime, particles, shockwave), Reduce Motion | 7, 8 |
| Data model, fresh-context store, App Group, error without crash | 5, 6, 8 |
| Streak rules | 3 |
| Day rollover / time change / foreground reload | 6, 8 |
| Widgets: small, medium + "+", circular, rectangular, inline, midnight entry, rendering modes | 10 |
| Project layout, bundle IDs, committed xcodeproj, icon | 1 |
| Testing: unit, simulator, device | 2–6, 8–12 |
| Install steps | 12 |

Deviation from spec: widgets are checked by building, Xcode previews and a manual add in the simulator (Task 10 Step 7), not by automated screenshots, because widgets can't be added to a Home Screen from the command line.
