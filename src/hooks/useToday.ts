import { useEffect, useState } from "react";
import { msUntilNextLocalMidnight, toDateKey, type DateKey } from "../lib/date";

/**
 * The current local calendar day, kept correct if the app stays open past midnight
 * or is resumed from the background on a later day (timers are frozen while a PWA
 * is suspended, so visibility/focus changes re-check too).
 */
export function useToday(): DateKey {
  const [today, setToday] = useState<DateKey>(() => toDateKey());

  useEffect(() => {
    let timer: number | undefined;
    const sync = () => {
      setToday(toDateKey());
      window.clearTimeout(timer);
      timer = window.setTimeout(sync, msUntilNextLocalMidnight());
    };
    const onVisible = () => {
      if (document.visibilityState === "visible") sync();
    };

    sync();
    document.addEventListener("visibilitychange", onVisible);
    window.addEventListener("focus", sync);
    window.addEventListener("pageshow", sync);
    return () => {
      window.clearTimeout(timer);
      document.removeEventListener("visibilitychange", onVisible);
      window.removeEventListener("focus", sync);
      window.removeEventListener("pageshow", sync);
    };
  }, []);

  return today;
}
