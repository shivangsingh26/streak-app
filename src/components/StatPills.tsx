import { Flame, Target } from "lucide-react";
import type { StreakStats } from "../lib/streak";

export function StatPills({ stats }: { stats: StreakStats }) {
  const { current, total, pending } = stats;
  const onFire = current >= 3;
  const lit = current > 0;

  return (
    <div className="flex items-center gap-2">
      <div
        className="glass-pill flex h-9 items-center gap-1.5 rounded-full pr-3.5 pl-2.5"
        aria-label={`Current streak: ${current} ${current === 1 ? "day" : "days"}${pending ? ", solve today to keep it" : ""}`}
        title={pending ? "Solve today to extend your streak" : "Current streak"}
      >
        <span className={`relative flex ${onFire ? "animate-flame" : ""}`}>
          <Flame
            aria-hidden
            className={`size-4 transition-colors duration-500 ${lit ? "text-amber-500" : "text-zinc-600"} ${pending ? "opacity-60" : ""}`}
            strokeWidth={1.75}
            fill={lit ? "url(#flame-gradient)" : "none"}
          />
          {pending && (
            <span className="absolute -top-0.5 -right-0.5 size-1.5 rounded-full bg-amber-400 ring-2 ring-zinc-900" />
          )}
        </span>
        <span
          className={`font-mono text-[13px] font-semibold tabular-nums tracking-tight ${lit ? "flame-text" : "text-zinc-500"}`}
        >
          {current}d
        </span>
      </div>

      <div
        className="glass-pill flex h-9 items-center gap-1.5 rounded-full pr-3.5 pl-2.5"
        aria-label={`Total problems solved: ${total}`}
        title="Total problems solved"
      >
        <Target aria-hidden className="size-4 text-emerald-400" strokeWidth={1.75} />
        <span className="font-mono text-[13px] font-semibold text-zinc-100 tabular-nums tracking-tight">{total}</span>
      </div>

      {/* Shared gradient for the flame fill. */}
      <svg width="0" height="0" className="absolute" aria-hidden>
        <defs>
          <linearGradient id="flame-gradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#F59E0B" stopOpacity="0.9" />
            <stop offset="100%" stopColor="#EF4444" stopOpacity="0.9" />
          </linearGradient>
        </defs>
      </svg>
    </div>
  );
}
