import { isDateKey, type DateKey } from "./date";

export interface DayEntry {
  completed: boolean;
  note?: string;
  timestamp: number;
}

export interface DailyLog {
  [dateKey: DateKey]: DayEntry;
}

export const STORAGE_KEY = "dsa-daily-matrix:log:v1";
export const DEFAULT_NOTE = "Problem Solved";
export const MAX_NOTE_LENGTH = 140;

/** Drops anything that doesn't match the schema instead of trusting stored JSON. */
export function sanitizeLog(raw: unknown): DailyLog {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return {};
  const log: DailyLog = {};
  for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
    if (!isDateKey(key) || !value || typeof value !== "object") continue;
    const v = value as Record<string, unknown>;
    if (typeof v.completed !== "boolean") continue;
    const entry: DayEntry = {
      completed: v.completed,
      timestamp: typeof v.timestamp === "number" && Number.isFinite(v.timestamp) ? v.timestamp : 0,
    };
    if (typeof v.note === "string" && v.note.trim()) entry.note = v.note.slice(0, MAX_NOTE_LENGTH);
    log[key] = entry;
  }
  return log;
}

export function parseLog(json: string | null): DailyLog {
  if (!json) return {};
  try {
    return sanitizeLog(JSON.parse(json));
  } catch {
    return {};
  }
}

export function loadLog(): DailyLog {
  try {
    return parseLog(window.localStorage.getItem(STORAGE_KEY));
  } catch {
    // Private mode / blocked storage: run in-memory for this session.
    return {};
  }
}

export function saveLog(log: DailyLog): boolean {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(log));
    return true;
  } catch {
    return false;
  }
}

export function normalizeNote(input: string): string {
  const trimmed = input.replace(/\s+/g, " ").trim().slice(0, MAX_NOTE_LENGTH);
  return trimmed || DEFAULT_NOTE;
}
