import { addDays, dayNumber, keyToLocalDate, weekday, type DateKey } from "./date";

export const HEATMAP_WEEKS = 16;

export interface GridCell {
  key: DateKey;
  isToday: boolean;
  isFuture: boolean;
}

export interface GridWeek {
  /** Short month label when a new month begins in this column, else null. */
  monthLabel: string | null;
  days: GridCell[]; // always 7, Sunday → Saturday
}

const monthFmt = new Intl.DateTimeFormat(undefined, { month: "short" });

/**
 * Builds a GitHub-style grid: columns are weeks (Sun→Sat), the last column is the
 * current week, and days after today are flagged `isFuture` so they render empty.
 */
export function buildHeatmap(today: DateKey, weeks: number = HEATMAP_WEEKS): GridWeek[] {
  const lastSaturday = addDays(today, 6 - weekday(today));
  const firstSunday = addDays(lastSaturday, -(weeks * 7 - 1));
  const todayN = dayNumber(today);

  const grid: GridWeek[] = [];
  let prevMonth = -1;

  for (let w = 0; w < weeks; w++) {
    const days: GridCell[] = [];
    for (let d = 0; d < 7; d++) {
      const key = addDays(firstSunday, w * 7 + d);
      const n = dayNumber(key);
      days.push({ key, isToday: n === todayN, isFuture: n > todayN });
    }

    // Label a column by the month of its first day; skip the very first column when
    // the next month starts within a week or two so labels never collide.
    const month = Number(days[0].key.slice(5, 7));
    let monthLabel: string | null = null;
    if (month !== prevMonth) {
      const dayOfMonth = Number(days[0].key.slice(8, 10));
      const crampedFirstColumn = w === 0 && dayOfMonth > 17;
      if (!crampedFirstColumn) monthLabel = monthFmt.format(keyToLocalDate(days[0].key));
      prevMonth = month;
    }
    grid.push({ monthLabel, days });
  }
  return grid;
}
