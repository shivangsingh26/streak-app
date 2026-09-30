import { memo, useLayoutEffect, useMemo, useRef, useState } from "react";
import { keyToLocalDate, type DateKey } from "../lib/date";
import { buildHeatmap, HEATMAP_WEEKS } from "../lib/grid";
import type { DailyLog } from "../lib/storage";

const CELL = 14;
const GAP = 3;
const DAY_LABELS = ["", "Mon", "", "Wed", "", "Fri", ""];

const longDate = new Intl.DateTimeFormat(undefined, { weekday: "short", month: "short", day: "numeric" });

interface HeatmapProps {
  log: DailyLog;
  today: DateKey;
  /** Key of the cell that was just completed — plays the pop animation once. */
  poppedKey: DateKey | null;
  longest: number;
}

export const Heatmap = memo(function Heatmap({ log, today, poppedKey, longest }: HeatmapProps) {
  const weeks = useMemo(() => buildHeatmap(today), [today]);
  const scroller = useRef<HTMLDivElement>(null);
  const [selected, setSelected] = useState<DateKey | null>(null);

  // Anchor the scroll position on "now" (right edge) when the grid is built/rebuilt.
  useLayoutEffect(() => {
    const el = scroller.current;
    if (el) el.scrollLeft = el.scrollWidth;
  }, [weeks]);

  const solvedInWindow = useMemo(
    () => weeks.reduce((sum, w) => sum + w.days.filter((d) => !d.isFuture && log[d.key]?.completed).length, 0),
    [weeks, log],
  );

  const selectedEntry = selected ? log[selected] : undefined;

  return (
    <section className="surface animate-rise rounded-2xl p-4 [animation-delay:120ms]" aria-label="Activity heatmap">
      <header className="mb-3 flex items-baseline justify-between">
        <h2 className="text-[13px] font-medium tracking-tight text-zinc-300">Last {HEATMAP_WEEKS} weeks</h2>
        <p className="font-mono text-[11px] text-zinc-500 tabular-nums">
          {solvedInWindow} solved · best <span className="text-zinc-300">{longest}d</span>
        </p>
      </header>

      <div className="flex">
        {/* Weekday labels */}
        <div
          className="mr-2 grid shrink-0 pt-[18px] font-mono text-[9px] leading-none text-zinc-600"
          style={{ gridTemplateRows: `repeat(7, ${CELL}px)`, rowGap: GAP }}
          aria-hidden
        >
          {DAY_LABELS.map((l, i) => (
            <span key={i} className="flex items-center">
              {l}
            </span>
          ))}
        </div>

        <div ref={scroller} className="no-scrollbar -my-2 min-w-0 flex-1 overflow-x-auto overflow-y-hidden py-2">
          <div className="mx-auto w-max">
            {/* Month labels */}
            <div
              className="mb-1 grid h-[14px] font-mono text-[9px] leading-none text-zinc-500"
              style={{ gridTemplateColumns: `repeat(${weeks.length}, ${CELL}px)`, columnGap: GAP }}
              aria-hidden
            >
              {weeks.map((w, i) => (
                <span key={i} className="overflow-visible whitespace-nowrap">
                  {w.monthLabel}
                </span>
              ))}
            </div>

            <div
              role="group"
              aria-label="Daily completion grid"
              className="grid grid-flow-col"
              style={{
                gridTemplateRows: `repeat(7, ${CELL}px)`,
                gridAutoColumns: `${CELL}px`,
                gap: GAP,
              }}
            >
              {weeks.flatMap((w) =>
                w.days.map((d) => {
                  if (d.isFuture) return <span key={d.key} aria-hidden className="size-[14px]" />;
                  const solved = log[d.key]?.completed === true;
                  const popping = d.key === poppedKey;
                  const isSelected = d.key === selected;
                  const label = `${longDate.format(keyToLocalDate(d.key))}: ${solved ? log[d.key]?.note ?? "Solved" : "Not solved"}`;
                  return (
                    <button
                      key={d.key}
                      type="button"
                      aria-label={label}
                      title={label}
                      onClick={() => setSelected((s) => (s === d.key ? null : d.key))}
                      className={[
                        "cell relative size-[14px] rounded-[3px] outline-none focus-visible:ring-2 focus-visible:ring-emerald-400/70",
                        solved ? "cell-solved" : "bg-zinc-800/60",
                        popping ? "animate-cell-pop z-10" : "",
                        isSelected ? "ring-1 ring-zinc-300/80" : "",
                      ].join(" ")}
                    >
                      {d.isToday && (
                        <span
                          aria-hidden
                          className="animate-today-ring pointer-events-none absolute inset-0 rounded-[3px]"
                        />
                      )}
                    </button>
                  );
                }),
              )}
            </div>
          </div>
        </div>
      </div>

      <footer className="mt-3 flex min-h-[18px] items-center justify-between gap-3 text-[11px]">
        {selected ? (
          <p key={selected} className="animate-rise min-w-0 truncate text-zinc-400">
            <span className="font-mono text-zinc-500">{longDate.format(keyToLocalDate(selected))}</span>
            <span className="mx-1.5 text-zinc-700">·</span>
            {selectedEntry?.completed ? (
              <span className="text-emerald-300">{selectedEntry.note ?? "Solved"}</span>
            ) : (
              <span className="text-zinc-600">No problem logged</span>
            )}
          </p>
        ) : (
          <p className="text-zinc-600">Tap a day for details</p>
        )}
        <div className="flex shrink-0 items-center gap-1.5 font-mono text-[10px] text-zinc-600" aria-hidden>
          <span className="size-2.5 rounded-[2px] bg-zinc-800/60" />
          <span>miss</span>
          <span className="cell-solved ml-1 size-2.5 rounded-[2px]" />
          <span>solved</span>
        </div>
      </footer>
    </section>
  );
});
