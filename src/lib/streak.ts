import { addDays, dayNumber, type DateKey } from "./date";
import type { DailyLog } from "./storage";

export interface StreakStats {
  /** Consecutive completed days ending today, or ending yesterday if today is still open. */
  current: number;
  longest: number;
  total: number;
  completedToday: boolean;
  /** True when today is still open but yesterday's run is alive — the streak is "at risk". */
  pending: boolean;
}

const isDone = (log: DailyLog, key: DateKey) => log[key]?.completed === true;

export function currentStreak(log: DailyLog, today: DateKey): number {
  // Today not done yet ≠ broken: the streak only resets once today passes empty.
  let cursor = isDone(log, today) ? today : addDays(today, -1);
  let count = 0;
  while (isDone(log, cursor)) {
    count++;
    cursor = addDays(cursor, -1);
  }
  return count;
}

export function longestStreak(log: DailyLog): number {
  const days = Object.keys(log)
    .filter((k) => isDone(log, k))
    .map(dayNumber)
    .sort((a, b) => a - b);

  let longest = 0;
  let run = 0;
  let prev = Number.NaN;
  for (const d of days) {
    run = d === prev + 1 ? run + 1 : 1;
    if (run > longest) longest = run;
    prev = d;
  }
  return longest;
}

export function totalSolved(log: DailyLog): number {
  let total = 0;
  for (const key in log) if (log[key].completed) total++;
  return total;
}

export function computeStats(log: DailyLog, today: DateKey): StreakStats {
  const current = currentStreak(log, today);
  const completedToday = isDone(log, today);
  return {
    current,
    // The live run is always ≤ longest, but guard anyway so the UI can never contradict itself.
    longest: Math.max(longestStreak(log), current),
    total: totalSolved(log),
    completedToday,
    pending: !completedToday && current > 0,
  };
}
