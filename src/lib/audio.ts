/**
 * Zero-asset micro-chime synthesised with the Web Audio API.
 *
 * The context is created and resumed on pointer-down (a user gesture), so by the
 * time pointer-up fires the audio graph is already hot and the chime starts on the
 * very next render quantum (~3ms) instead of paying context start-up latency.
 */

type AudioCtor = typeof AudioContext;

let ctx: AudioContext | null = null;

function getContext(): AudioContext | null {
  if (ctx) return ctx;
  const Ctor: AudioCtor | undefined =
    window.AudioContext ?? (window as unknown as { webkitAudioContext?: AudioCtor }).webkitAudioContext;
  if (!Ctor) return null;
  try {
    ctx = new Ctor({ latencyHint: "interactive" });
  } catch {
    ctx = null;
  }
  return ctx;
}

/** Call from pointerdown/keydown so the context is running before the chime is needed. */
export function primeAudio(): void {
  const c = getContext();
  if (c && c.state !== "running") void c.resume().catch(() => {});
}

const C6 = 1046.5;
const G6 = 1567.98;
const DECAY = 0.25; // seconds, exponential tail
const PEAK = 0.22;
const FLOOR = 0.0001; // exponential ramps can't target 0

/**
 * A pure sine voice that glides C6 → G6, plus a soft G6 bloom and a faint
 * octave partial for harmonic shimmer. Everything decays exponentially over 250ms.
 */
export function playChime(): void {
  const c = getContext();
  if (!c) return;
  if (c.state !== "running") void c.resume().catch(() => {});

  const t0 = c.currentTime + 0.005;
  const out = c.createGain();
  out.gain.value = 1;

  // Gentle low-pass keeps the sine tones round on small phone speakers.
  const tone = c.createBiquadFilter();
  tone.type = "lowpass";
  tone.frequency.value = 6000;
  tone.Q.value = 0.3;
  out.connect(tone).connect(c.destination);

  const voice = (
    freqStart: number,
    freqEnd: number,
    start: number,
    peak: number,
    glide: number,
    decay: number,
  ) => {
    const osc = c.createOscillator();
    const env = c.createGain();
    osc.type = "sine";
    osc.frequency.setValueAtTime(freqStart, start);
    if (freqEnd !== freqStart) osc.frequency.exponentialRampToValueAtTime(freqEnd, start + glide);

    env.gain.setValueAtTime(FLOOR, start);
    env.gain.linearRampToValueAtTime(peak, start + 0.006); // 6ms attack: click-free, still instant
    env.gain.exponentialRampToValueAtTime(FLOOR, start + decay);

    osc.connect(env).connect(out);
    osc.start(start);
    osc.stop(start + decay + 0.02);
    osc.onended = () => {
      osc.disconnect();
      env.disconnect();
    };
  };

  // 1. Primary: C6 ramping up to G6 (a perfect fifth — reads as "resolved / correct").
  voice(C6, G6, t0, PEAK, 0.07, DECAY);
  // 2. Landing bloom on G6 as the glide arrives.
  voice(G6, G6, t0 + 0.06, PEAK * 0.55, 0, DECAY);
  // 3. Octave partial (C7) — very quiet sparkle on top.
  voice(C6 * 2, G6 * 2, t0, PEAK * 0.08, 0.07, DECAY * 0.6);

  window.setTimeout(() => {
    out.disconnect();
    tone.disconnect();
  }, (DECAY + 0.2) * 1000);
}
