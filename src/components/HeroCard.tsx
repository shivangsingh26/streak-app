import { Check, CornerDownLeft, RotateCcw } from "lucide-react";
import { useCallback, useRef, useState, type KeyboardEvent, type PointerEvent } from "react";
import { playChime, primeAudio } from "../lib/audio";
import { keyToLocalDate, type DateKey } from "../lib/date";
import { hapticSuccess, primeHaptics } from "../lib/haptics";
import { burstAt, primeParticles } from "../lib/particles";
import { MAX_NOTE_LENGTH, type DayEntry } from "../lib/storage";
import type { StreakStats } from "../lib/streak";

interface Ripple {
  id: number;
  x: number;
  y: number;
  size: number;
}

interface HeroCardProps {
  today: DateKey;
  entry: DayEntry | undefined;
  stats: StreakStats;
  onComplete: (note: string) => void;
  onUndo: () => void;
}

const headerDate = new Intl.DateTimeFormat(undefined, { weekday: "long", month: "short", day: "numeric" });

function prompt(stats: StreakStats) {
  if (stats.completedToday) {
    if (stats.current >= 7) return { title: "Streak secured.", sub: `${stats.current} days of momentum. See you tomorrow.` };
    if (stats.current > 1) return { title: "Streak secured.", sub: `Day ${stats.current} in the books. Rest easy.` };
    return { title: "Day one, done.", sub: "The hardest rep is the first. Come back tomorrow." };
  }
  if (stats.pending) {
    return {
      title: "Keep the chain alive.",
      sub: `${stats.current}-day streak on the line. One problem is all it takes.`,
    };
  }
  return { title: "One problem. Today.", sub: "Solve it, then tap. That's the whole ritual." };
}

/** Splits "33. Search in Rotated Sorted Array | Modified Binary Search" into title + pattern. */
function splitNote(note: string | undefined) {
  if (!note) return { title: "Problem Solved", pattern: null as string | null };
  const [title, ...rest] = note.split("|");
  const pattern = rest.join("|").trim();
  return { title: title.trim() || note, pattern: pattern || null };
}

export function HeroCard({ today, entry, stats, onComplete, onUndo }: HeroCardProps) {
  const completed = entry?.completed === true;
  const [note, setNote] = useState("");
  const [pressed, setPressed] = useState(false);
  const [ripples, setRipples] = useState<Ripple[]>([]);
  const cardRef = useRef<HTMLElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const primed = useRef(false);
  // Mirrors `pressed` synchronously so pointer-up never reads a stale render.
  const pressedRef = useRef(false);

  const setPress = useCallback((value: boolean) => {
    pressedRef.current = value;
    setPressed(value);
  }, []);

  const prime = useCallback(() => {
    primeAudio();
    if (!primed.current) {
      primed.current = true;
      primeHaptics();
      primeParticles();
    }
  }, []);

  /**
   * The payoff. Everything here runs synchronously inside the same input event
   * task, so haptic, audio, particles, shockwave and state change land together
   * on the next frame.
   */
  const execute = useCallback(
    (clientX: number, clientY: number) => {
      if (completed) return;
      hapticSuccess();
      playChime();
      burstAt(clientX, clientY);

      const card = cardRef.current;
      if (card) {
        const r = card.getBoundingClientRect();
        const x = clientX - r.left;
        const y = clientY - r.top;
        // Radius that reaches the farthest card corner so the ring sweeps the whole surface.
        const size = Math.hypot(Math.max(x, r.width - x), Math.max(y, r.height - y));
        setRipples((rs) => [...rs, { id: performance.now(), x, y, size }]);
      }

      onComplete(note);
      setNote("");
      (document.activeElement as HTMLElement | null)?.blur?.();
    },
    [completed, note, onComplete],
  );

  const executeFromCenter = useCallback(() => {
    const b = buttonRef.current?.getBoundingClientRect();
    if (!b) return;
    execute(b.left + b.width / 2, b.top + b.height / 2);
  }, [execute]);

  // ── Pointer lifecycle ─────────────────────────────────────────────
  const onPointerDown = (e: PointerEvent<HTMLButtonElement>) => {
    if (completed || e.button !== 0) return;
    prime();
    setPress(true);
    e.currentTarget.setPointerCapture?.(e.pointerId);
  };

  const onPointerUp = (e: PointerEvent<HTMLButtonElement>) => {
    if (!pressedRef.current) return;
    setPress(false);
    const r = e.currentTarget.getBoundingClientRect();
    const inside = e.clientX >= r.left && e.clientX <= r.right && e.clientY >= r.top && e.clientY <= r.bottom;
    // Dragging off the button before lifting cancels, like a native control.
    if (inside) execute(e.clientX, e.clientY);
  };

  const cancelPress = () => setPress(false);

  // Keyboard: show the compression on key-down, fire via the native click (detail === 0).
  const onKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (completed) return;
    if (e.key === " " || e.key === "Enter") {
      prime();
      if (!e.repeat) setPress(true);
    }
  };

  const { title, sub } = prompt(stats);
  const parsed = splitNote(entry?.note);

  return (
    <section
      ref={cardRef}
      className="surface animate-rise relative isolate overflow-hidden rounded-[28px] px-5 pt-6 pb-5"
      aria-label="Today's problem"
    >
      {/* Shockwave layer */}
      <div aria-hidden className="pointer-events-none absolute inset-0 -z-10">
        {ripples.map((r) => (
          <span key={r.id}>
            <span
              className="animate-flash absolute inset-0"
              style={{
                background: `radial-gradient(circle at ${r.x}px ${r.y}px, rgb(16 185 129 / 0.22), transparent 55%)`,
              }}
            />
            <span
              className="animate-shockwave absolute rounded-full border-2 border-emerald-400/70"
              style={{
                left: r.x,
                top: r.y,
                width: r.size * 2,
                height: r.size * 2,
                boxShadow: "0 0 24px rgb(16 185 129 / 0.45), inset 0 0 24px rgb(16 185 129 / 0.25)",
              }}
              onAnimationEnd={() => setRipples((rs) => rs.filter((x) => x.id !== r.id))}
            />
          </span>
        ))}
      </div>

      <p className="text-center font-mono text-[11px] tracking-[0.14em] text-zinc-500 uppercase">
        {headerDate.format(keyToLocalDate(today))}
      </p>

      <div key={completed ? "done" : "open"} className="animate-rise mt-2 text-center">
        <h1 className="text-[22px] leading-tight font-semibold tracking-[-0.02em] text-zinc-50">{title}</h1>
        <p className="mx-auto mt-1.5 max-w-[30ch] text-[13px] leading-snug text-zinc-400">{sub}</p>
      </div>

      {/* ── Central trigger ───────────────────────────────────────── */}
      <div className="relative mx-auto my-7 grid size-44 place-items-center">
        {!completed && (
          <span aria-hidden className="animate-breathe absolute inset-0 rounded-full bg-emerald-500/25 blur-2xl" />
        )}
        {completed && (
          <span aria-hidden className="absolute inset-4 rounded-full bg-emerald-500/10 blur-2xl" />
        )}

        <button
          ref={buttonRef}
          type="button"
          data-pressed={pressed}
          disabled={completed}
          aria-pressed={completed}
          aria-label={completed ? "Solved today" : "Mark today's problem as solved"}
          onPointerDown={onPointerDown}
          onPointerUp={onPointerUp}
          onPointerCancel={cancelPress}
          onLostPointerCapture={cancelPress}
          onKeyDown={onKeyDown}
          onKeyUp={cancelPress}
          onBlur={cancelPress}
          onClick={(e) => {
            // Pointer activations are handled on pointer-up; this path is keyboard / AT only.
            if (e.detail === 0) executeFromCenter();
          }}
          onContextMenu={(e) => e.preventDefault()}
          className={[
            "spring-press relative grid size-40 touch-manipulation place-items-center rounded-full border outline-none select-none",
            "focus-visible:ring-2 focus-visible:ring-emerald-400/60 focus-visible:ring-offset-4 focus-visible:ring-offset-zinc-900",
            completed
              ? "animate-settle cursor-default border-emerald-500/30 bg-zinc-900 shadow-[inset_0_1px_0_rgb(255_255_255/0.04),0_0_0_6px_rgb(16_185_129/0.05)]"
              : "cursor-pointer border-emerald-400/35 bg-[radial-gradient(circle_at_50%_30%,#1f2b27_0%,#18181b_55%,#111113_100%)] shadow-[inset_0_1px_0_rgb(255_255_255/0.09),inset_0_-10px_24px_rgb(0_0_0/0.45),0_18px_40px_-12px_rgb(0_0_0/0.9),0_0_0_1px_rgb(0_0_0/0.6)] hover:border-emerald-400/55",
          ].join(" ")}
        >
          {completed ? (
            <span className="flex flex-col items-center gap-1.5">
              <Check aria-hidden className="check-draw size-14 text-emerald-400" strokeWidth={2.25} />
              <span className="font-mono text-[10px] tracking-[0.18em] text-emerald-400/70 uppercase">Solved</span>
            </span>
          ) : (
            <span className="flex flex-col items-center gap-2">
              <Check aria-hidden className="size-12 text-zinc-500" strokeWidth={1.5} />
              <span className="font-mono text-[10px] tracking-[0.18em] text-zinc-400 uppercase">Tap when solved</span>
            </span>
          )}
        </button>
      </div>

      {/* ── Optional note / completed readout ──────────────────────── */}
      {completed ? (
        <div className="animate-rise flex flex-col items-center gap-3 [animation-delay:80ms]">
          <div className="flex max-w-full items-start gap-2.5 rounded-xl border border-emerald-500/15 bg-emerald-500/[0.06] px-3.5 py-2.5">
            <span aria-hidden className="mt-[7px] size-1.5 shrink-0 rounded-full bg-emerald-400 shadow-[0_0_8px_rgb(52_211_153/0.8)]" />
            <div className="flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1">
            <p className="line-clamp-2 min-w-0 text-[13px] leading-5 text-zinc-200">{parsed.title}</p>
            {parsed.pattern && (
              <span className="max-w-full truncate rounded-md bg-zinc-800/80 px-1.5 py-0.5 font-mono text-[10px] text-emerald-300/90">
                {parsed.pattern}
              </span>
            )}
            </div>
          </div>
          <button
            type="button"
            onClick={onUndo}
            className="flex items-center gap-1 rounded-md px-2 py-1 text-[11px] text-zinc-600 transition-colors hover:text-zinc-400 focus-visible:text-zinc-300 focus-visible:outline-none"
          >
            <RotateCcw aria-hidden className="size-3" strokeWidth={2} />
            Undo
          </button>
        </div>
      ) : (
        <form
          className="group"
          onSubmit={(e) => {
            e.preventDefault();
            prime();
            executeFromCenter();
          }}
        >
          <div className="relative">
          <label htmlFor="note" className="sr-only">
            Problem name or core pattern (optional)
          </label>
          <input
            id="note"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            onFocus={prime}
            maxLength={MAX_NOTE_LENGTH}
            autoComplete="off"
            autoCorrect="off"
            spellCheck={false}
            enterKeyHint="done"
            placeholder="Problem / pattern (optional)"
            className="h-12 w-full rounded-xl border border-white/[0.07] bg-black/40 pr-11 pl-4 text-[16px] text-zinc-100 shadow-[inset_0_1px_2px_rgb(0_0_0/0.5)] transition-colors outline-none placeholder:text-zinc-600 focus:border-emerald-500/40 focus:bg-black/60"
          />
          <CornerDownLeft
            aria-hidden
            className="pointer-events-none absolute top-1/2 right-4 size-4 -translate-y-1/2 text-zinc-700 transition-colors group-focus-within:text-emerald-500/70"
            strokeWidth={1.75}
          />
          </div>
          <p className="mt-2 px-1 text-[11px] text-zinc-600">
            e.g. <span className="text-zinc-500">33. Search in Rotated Sorted Array | Modified Binary Search</span>
          </p>
        </form>
      )}
    </section>
  );
}
