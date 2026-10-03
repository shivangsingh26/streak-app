# DSA Daily Matrix

A single-screen, local-first PWA for keeping a daily Data Structures & Algorithms streak.
Open it, see your streak, tap once, feel it, leave.

## Run

```bash
npm install
npm run dev        # http://localhost:5173
npm run build      # typecheck + production build → dist/
npm run preview    # serve the build (service worker is active here)
npm test           # streak / date / grid / storage unit tests
```

`dist/` is fully static and uses relative paths, so it can be deployed to any static host or sub-path
(GitHub Pages, Netlify, Vercel, S3). Install to the home screen from Safari ("Add to Home Screen")
or Chrome ("Install app") to run standalone and offline.

## How it works

| Concern | Where |
| --- | --- |
| Press → release state machine, shockwave ripple, inline note | `src/components/HeroCard.tsx` |
| Haptics (`navigator.vibrate([35, 60, 100])` + iOS `<input switch>` fallback) | `src/lib/haptics.ts` |
| Synthesised chime (sine C6 → G6 glide, 250 ms exponential decay, no audio files) | `src/lib/audio.ts` |
| Origin-mapped `canvas-confetti` burst (off-main-thread canvas) | `src/lib/particles.ts` |
| 16-week heatmap, today ring, completion pop | `src/components/Heatmap.tsx`, `src/lib/grid.ts` |
| Current / longest / total streak derivation | `src/lib/streak.ts` |
| `localStorage` persistence + schema sanitising + cross-tab sync | `src/lib/storage.ts`, `src/hooks/useDailyLog.ts` |
| Midnight / resume-from-background day rollover | `src/hooks/useToday.ts` |
| Offline shell + hashed-asset precache | `public/sw.js` |

### Latency

The `AudioContext`, iOS haptic switch and confetti canvas are created on **pointer-down**, so on
pointer-up the haptic, chime, particle burst, shockwave and state change all run synchronously in
the same event task and land on the same frame. Dragging off the button before lifting cancels,
as with a native control. Keyboard users get the same payoff via Enter/Space, and typing a note then
pressing Enter completes the day from the button's centre.

### Streak rules

- Days are keyed by the **local** calendar date (`YYYY-MM-DD`); arithmetic uses integer day numbers,
  so DST and time of day can never shift a key.
- If today isn't done yet, the current streak is yesterday's run. It only drops to 0 once a whole
  day passes without a completion. The flame pill shows an amber dot while the streak is at risk.
- Longest streak is derived from the full log; total counts every completed day.

### Storage schema

```ts
// localStorage["dsa-daily-matrix:log:v1"]
interface DailyLog {
  [dateKey: string]: { completed: boolean; note?: string; timestamp: number };
}
```

A blank note is stored as `"Problem Solved"`. Anything after a `|` in the note appears as a pattern tag.

### Icons

The PNG icons are generated from `public/icons/icon.svg` with `npm run icons`, which needs Playwright + Chromium.

## iOS app

A native SwiftUI version lives in `ios/`, with Home Screen and Lock Screen widgets. Data stays on
the phone: SwiftData in an App Group shared by the app and the widget. There is no iCloud sync yet.

```bash
brew install xcodegen
cd ios
make test                         # unit tests on the iPhone 17 simulator
make run ARGS="-seed -inMemory"   # demo data in the simulator
make shots                        # UI smoke test; screenshots land in ios/shots/
```

The Xcode project is generated from `ios/project.yml`. Every `make` target regenerates it, so change
build settings (including the signing team, `DEVELOPMENT_TEAM`) in `project.yml`, never only in Xcode.

### Installing on an iPhone

1. Add your Apple ID in Xcode → Settings → Accounts, and set `DEVELOPMENT_TEAM` in `ios/project.yml`.
2. Connect the phone and turn on Settings → Privacy & Security → Developer Mode.
3. Build and install:
   ```bash
   cd ios
   xcodebuild -project DSAMatrix.xcodeproj -scheme DSAMatrix -destination 'id=<UDID>' \
     -derivedDataPath build -allowProvisioningUpdates build
   xcrun devicectl device install app --device <UDID> build/Build/Products/Debug-iphoneos/DSAMatrix.app
   ```
   `xcrun devicectl list devices` shows the UDID. You can also open `ios/DSAMatrix.xcodeproj` and press Run.
4. On first launch, trust the developer: Settings → General → VPN & Device Management.

With a free Apple ID the install expires after 7 days; repeat step 3 to renew it. Your data is kept.
Deleting the app deletes its history.
