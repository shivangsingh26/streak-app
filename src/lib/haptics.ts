/**
 * Cross-platform haptics.
 *
 * - Android / Chromium: the Vibration API with a crisp dual-pulse pattern.
 * - iOS WebKit (no Vibration API): Safari 17.4+ renders `<input type="checkbox" switch>`
 *   as a native UISwitch and plays the system "selection" haptic whenever it toggles.
 *   Clicking a hidden label bound to such a switch inside a user gesture triggers that
 *   haptic. We fire it twice to echo the dual-pulse shape.
 */

export const SUCCESS_PATTERN: number[] = [35, 60, 100];

let iosSwitch: { label: HTMLLabelElement; input: HTMLInputElement } | null = null;

function ensureIosSwitch() {
  if (iosSwitch || typeof document === "undefined") return iosSwitch;
  const id = "haptic-switch";
  const input = document.createElement("input");
  input.type = "checkbox";
  input.id = id;
  input.setAttribute("switch", "");
  input.tabIndex = -1;
  input.setAttribute("aria-hidden", "true");

  const label = document.createElement("label");
  label.htmlFor = id;
  label.setAttribute("aria-hidden", "true");

  for (const el of [input, label]) {
    Object.assign(el.style, {
      position: "fixed",
      left: "-9999px",
      top: "0",
      width: "1px",
      height: "1px",
      opacity: "0",
      pointerEvents: "none",
    } satisfies Partial<CSSStyleDeclaration>);
  }
  document.body.append(input, label);
  iosSwitch = { label, input };
  return iosSwitch;
}

const canVibrate = () => typeof navigator !== "undefined" && typeof navigator.vibrate === "function";

/** Pre-create the hidden switch so the first tap doesn't pay DOM insertion cost. */
export function primeHaptics(): void {
  if (!canVibrate()) ensureIosSwitch();
}

function iosTick() {
  ensureIosSwitch()?.label.click();
}

export function hapticSuccess(): void {
  if (canVibrate()) {
    try {
      if (navigator.vibrate(SUCCESS_PATTERN)) return;
    } catch {
      /* fall through */
    }
  }
  // iOS fallback: two ticks spaced like the vibration pattern's gap. The second tick
  // is best-effort — WebKit may drop it since it lands outside the original gesture.
  iosTick();
  window.setTimeout(iosTick, SUCCESS_PATTERN[0] + SUCCESS_PATTERN[1]);
}

export function hapticTap(): void {
  if (canVibrate()) {
    try {
      if (navigator.vibrate(8)) return;
    } catch {
      /* fall through */
    }
  }
  iosTick();
}
