import { useCallback, useEffect, useRef, useState } from "react";
import { Heatmap } from "./components/Heatmap";
import { HeroCard } from "./components/HeroCard";
import { StatPills } from "./components/StatPills";
import type { DateKey } from "./lib/date";
import { useDailyLog } from "./hooks/useDailyLog";
import { useToday } from "./hooks/useToday";

function Wordmark() {
  return (
    <div className="flex items-center gap-2">
      <svg viewBox="0 0 16 16" className="size-[18px]" aria-hidden>
        {[0, 1, 2].flatMap((r) =>
          [0, 1, 2].map((c) => {
            const on = (r + c) % 2 === 0 || (r === 2 && c === 1);
            return (
              <rect
                key={`${r}${c}`}
                x={c * 5.5}
                y={r * 5.5}
                width="4.5"
                height="4.5"
                rx="1"
                fill={on ? "#10B981" : "#27272A"}
              />
            );
          }),
        )}
      </svg>
      <span className="text-[14px] font-semibold tracking-[-0.01em] text-zinc-100">
        DSA <span className="text-zinc-500">Daily Matrix</span>
      </span>
    </div>
  );
}

export default function App() {
  const today = useToday();
  const { log, stats, completeToday, undoToday } = useDailyLog(today);
  const [poppedKey, setPoppedKey] = useState<DateKey | null>(null);
  const popTimer = useRef<number | undefined>(undefined);

  const handleComplete = useCallback(
    (note: string) => {
      completeToday(note);
      setPoppedKey(today);
      window.clearTimeout(popTimer.current);
      popTimer.current = window.setTimeout(() => setPoppedKey(null), 700);
    },
    [completeToday, today],
  );

  useEffect(() => () => window.clearTimeout(popTimer.current), []);

  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-[440px] flex-col px-4 pt-[max(env(safe-area-inset-top),14px)] pb-[max(env(safe-area-inset-bottom),16px)]">
      <header className="flex h-14 items-center justify-between">
        <Wordmark />
        <StatPills stats={stats} />
      </header>

      <main className="flex flex-1 flex-col gap-4 pt-[max(2vh,8px)] pb-3">
        <HeroCard
          today={today}
          entry={log[today]}
          stats={stats}
          onComplete={handleComplete}
          onUndo={undoToday}
        />
        <Heatmap log={log} today={today} poppedKey={poppedKey} longest={stats.longest} />
      </main>
    </div>
  );
}
