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
