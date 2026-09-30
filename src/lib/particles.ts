import confetti from "canvas-confetti";

/**
 * Origin-mapped micro-confetti. A dedicated full-viewport canvas (rendered off the
 * main thread when OffscreenCanvas is available) so the burst never janks the
 * button's spring animation.
 */

type Fire = ReturnType<typeof confetti.create>;
let fire: Fire | null = null;

const EMERALD = ["#34D399", "#10B981", "#059669", "#6EE7B7"];
const ACCENT = ["#F59E0B", "#FAFAFA"];

function getFire(): Fire {
  if (fire) return fire;
  const canvas = document.createElement("canvas");
  canvas.setAttribute("aria-hidden", "true");
  Object.assign(canvas.style, {
    position: "fixed",
    inset: "0",
    width: "100%",
    height: "100%",
    pointerEvents: "none",
    zIndex: "60",
  } satisfies Partial<CSSStyleDeclaration>);
  document.body.appendChild(canvas);
  fire = confetti.create(canvas, { resize: true, useWorker: true, disableForReducedMotion: true });
  return fire;
}

/** Warm the canvas + worker ahead of the first burst. */
export function primeParticles(): void {
  getFire();
}

/**
 * Radial burst from viewport coordinates (clientX/clientY).
 * Three layers: a dense 360° ring of tiny emerald squares, a slower sparkle halo
 * of circles, and a short upward plume so it reads as an explosion, not a spray.
 */
export function burstAt(clientX: number, clientY: number, intensity = 1): void {
  const f = getFire();
  const origin = {
    x: Math.min(1, Math.max(0, clientX / window.innerWidth)),
    y: Math.min(1, Math.max(0, clientY / window.innerHeight)),
  };
  const n = (count: number) => Math.round(count * intensity);

  void f({
    origin,
    particleCount: n(70),
    spread: 360,
    startVelocity: 28,
    decay: 0.9,
    gravity: 0.9,
    ticks: 110,
    scalar: 0.62,
    shapes: ["square"],
    colors: EMERALD,
  });
  void f({
    origin,
    particleCount: n(36),
    spread: 360,
    startVelocity: 14,
    decay: 0.92,
    gravity: 0.55,
    ticks: 140,
    scalar: 0.45,
    shapes: ["circle"],
    colors: [...EMERALD, ...ACCENT],
  });
  void f({
    origin,
    particleCount: n(24),
    angle: 90,
    spread: 55,
    startVelocity: 38,
    decay: 0.9,
    gravity: 1.1,
    ticks: 120,
    scalar: 0.55,
    colors: [...EMERALD, ACCENT[0]],
  });
}
