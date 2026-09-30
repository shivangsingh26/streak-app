/**
 * Calendar-day helpers. Everything is keyed by the user's *local* calendar day
 * (YYYY-MM-DD) and all arithmetic goes through an integer "day number" so DST
 * transitions and time-of-day can never shift a key.
 */

export type DateKey = string; // YYYY-MM-DD

const MS_PER_DAY = 86_400_000;
const KEY_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

const pad = (n: number) => String(n).padStart(2, "0");

/** Local calendar key for a Date (defaults to now). */
export function toDateKey(date: Date = new Date()): DateKey {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function isDateKey(value: string): value is DateKey {
  const m = KEY_RE.exec(value);
  if (!m) return false;
  const [, y, mo, d] = m.map(Number);
  const probe = new Date(Date.UTC(y, mo - 1, d));
  return probe.getUTCFullYear() === y && probe.getUTCMonth() === mo - 1 && probe.getUTCDate() === d;
}

/** Days since the Unix epoch for a calendar key — timezone-free. */
export function dayNumber(key: DateKey): number {
  const [y, m, d] = key.split("-").map(Number);
  return Math.round(Date.UTC(y, m - 1, d) / MS_PER_DAY);
}

export function fromDayNumber(n: number): DateKey {
  const date = new Date(n * MS_PER_DAY);
  return `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(date.getUTCDate())}`;
}

export function addDays(key: DateKey, days: number): DateKey {
  return fromDayNumber(dayNumber(key) + days);
}

/** 0 = Sunday … 6 = Saturday. */
export function weekday(key: DateKey): number {
  // 1970-01-01 was a Thursday (4).
  return (((dayNumber(key) + 4) % 7) + 7) % 7;
}

/** A local Date at noon on the given day — safe for display formatting. */
export function keyToLocalDate(key: DateKey): Date {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d, 12);
}

/** Milliseconds until the next local midnight (plus a small buffer). */
export function msUntilNextLocalMidnight(now: Date = new Date()): number {
  const next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 250);
  return Math.max(1_000, next.getTime() - now.getTime());
}
