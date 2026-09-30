import { describe, expect, it } from "vitest";
import { addDays, dayNumber, isDateKey, toDateKey, weekday } from "./date";
import { buildHeatmap } from "./grid";
import { normalizeNote, parseLog, type DailyLog } from "./storage";
import { computeStats, currentStreak, longestStreak } from "./streak";

const TODAY = "2026-09-30"; // a Wednesday

function logOf(...keys: string[]): DailyLog {
  return Object.fromEntries(keys.map((k) => [k, { completed: true, note: "x", timestamp: 1 }]));
}
const back = (n: number) => addDays(TODAY, -n);

describe("currentStreak", () => {
  it("is 0 for an empty log", () => {
    expect(currentStreak({}, TODAY)).toBe(0);
  });

  it("counts today and the unbroken run before it", () => {
    expect(currentStreak(logOf(TODAY, back(1), back(2)), TODAY)).toBe(3);
  });

  it("keeps yesterday's streak alive while today is still open", () => {
    expect(currentStreak(logOf(back(1), back(2), back(3)), TODAY)).toBe(3);
  });

  it("resets once a full day has passed without completion", () => {
    expect(currentStreak(logOf(back(2), back(3)), TODAY)).toBe(0);
  });

  it("stops at the first gap", () => {
    expect(currentStreak(logOf(TODAY, back(1), back(3), back(4)), TODAY)).toBe(2);
  });

  it("ignores entries explicitly marked incomplete", () => {
    const log = logOf(back(1));
    log[TODAY] = { completed: false, timestamp: 1 };
    expect(currentStreak(log, TODAY)).toBe(1);
  });

  it("spans month, year and leap-day boundaries", () => {
    const today = "2024-03-01";
    const log = logOf("2024-03-01", "2024-02-29", "2024-02-28");
    expect(currentStreak(log, today)).toBe(3);
    expect(currentStreak(logOf("2026-01-01", "2025-12-31", "2025-12-30"), "2026-01-01")).toBe(3);
  });

  it("is unaffected by DST transitions", () => {
    // US DST starts 2026-03-08, EU 2026-03-29; the math is calendar-based so neither matters.
    const log = logOf("2026-03-07", "2026-03-08", "2026-03-09", "2026-03-28", "2026-03-29", "2026-03-30");
    expect(currentStreak(log, "2026-03-09")).toBe(3);
    expect(currentStreak(log, "2026-03-30")).toBe(3);
  });
});

describe("longestStreak", () => {
  it("finds the longest historical run regardless of key order", () => {
    const log = logOf(back(20), back(1), back(10), back(11), back(12), back(13), TODAY);
    expect(longestStreak(log)).toBe(4);
  });

  it("is 0 when nothing is completed", () => {
    expect(longestStreak({ [TODAY]: { completed: false, timestamp: 0 } })).toBe(0);
  });
});

describe("computeStats", () => {
  it("derives all readouts together", () => {
    const stats = computeStats(logOf(back(1), back(2), back(5)), TODAY);
    expect(stats).toEqual({ current: 2, longest: 2, total: 3, completedToday: false, pending: true });
  });

  it("is not pending after today is logged", () => {
    const stats = computeStats(logOf(TODAY, back(1)), TODAY);
    expect(stats.pending).toBe(false);
    expect(stats.completedToday).toBe(true);
    expect(stats.current).toBe(2);
  });
});

describe("date helpers", () => {
  it("round-trips keys through day numbers", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
    expect(dayNumber("1970-01-02")).toBe(1);
  });

  it("computes weekdays", () => {
    expect(weekday("2026-09-30")).toBe(3); // Wed
    expect(weekday("2026-09-27")).toBe(0); // Sun
  });

  it("formats local dates", () => {
    expect(toDateKey(new Date(2026, 0, 5, 23, 59))).toBe("2026-01-05");
  });

  it("validates keys", () => {
    expect(isDateKey("2026-02-29")).toBe(false);
    expect(isDateKey("2024-02-29")).toBe(true);
    expect(isDateKey("2026-9-30")).toBe(false);
  });
});

describe("storage", () => {
  it("sanitizes corrupt or foreign data", () => {
    expect(parseLog("not json")).toEqual({});
    expect(parseLog("[1,2]")).toEqual({});
    const log = parseLog(
      JSON.stringify({
        "2026-09-30": { completed: true, note: "Two Sum", timestamp: 5 },
        "2026-13-01": { completed: true, timestamp: 5 },
        "2026-09-29": { completed: "yes" },
        "2026-09-28": { completed: true },
      }),
    );
    expect(log).toEqual({
      "2026-09-30": { completed: true, note: "Two Sum", timestamp: 5 },
      "2026-09-28": { completed: true, timestamp: 0 },
    });
  });

  it("defaults blank notes", () => {
    expect(normalizeNote("   ")).toBe("Problem Solved");
    expect(normalizeNote("  33.  Search |  Binary ")).toBe("33. Search | Binary");
  });
});

describe("buildHeatmap", () => {
  const grid = buildHeatmap(TODAY);

  it("has 16 full weeks ending on the current week", () => {
    expect(grid).toHaveLength(16);
    expect(grid.every((w) => w.days.length === 7)).toBe(true);
    expect(grid.every((w) => weekday(w.days[0].key) === 0)).toBe(true);
    expect(grid[15].days.some((d) => d.key === TODAY)).toBe(true);
  });

  it("flags exactly one today and only days after it as future", () => {
    const days = grid.flatMap((w) => w.days);
    expect(days.filter((d) => d.isToday).map((d) => d.key)).toEqual([TODAY]);
    expect(days.filter((d) => d.isFuture).map((d) => d.key)).toEqual(["2026-10-01", "2026-10-02", "2026-10-03"]);
  });

  it("is contiguous", () => {
    const days = grid.flatMap((w) => w.days).map((d) => dayNumber(d.key));
    days.forEach((n, i) => i > 0 && expect(n - days[i - 1]).toBe(1));
  });
});
