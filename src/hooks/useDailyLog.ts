import { useCallback, useEffect, useMemo, useState } from "react";
import type { DateKey } from "../lib/date";
import { loadLog, normalizeNote, parseLog, saveLog, STORAGE_KEY, type DailyLog } from "../lib/storage";
import { computeStats } from "../lib/streak";

export function useDailyLog(today: DateKey) {
  const [log, setLog] = useState<DailyLog>(loadLog);

  // Persist every change. Initial load writes back the sanitized log, which is harmless.
  useEffect(() => {
    saveLog(log);
  }, [log]);

  // Keep multiple open tabs / an installed PWA + browser tab in sync.
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY) setLog(parseLog(e.newValue));
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  const completeToday = useCallback(
    (note: string) => {
      setLog((prev) =>
        prev[today]?.completed
          ? prev
          : { ...prev, [today]: { completed: true, note: normalizeNote(note), timestamp: Date.now() } },
      );
    },
    [today],
  );

  const undoToday = useCallback(() => {
    setLog((prev) => {
      if (!prev[today]) return prev;
      const next = { ...prev };
      delete next[today];
      return next;
    });
  }, [today]);

  const stats = useMemo(() => computeStats(log, today), [log, today]);

  return { log, stats, completeToday, undoToday };
}
