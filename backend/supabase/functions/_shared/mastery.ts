// Spec §4.5: mastery is accuracy only. Response time raises a teacher-visible
// flag and never blocks, slows, or is shown to the child.

const MASTERY_RATIO = 7 / 8;

export function medianMs(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1
    ? sorted[mid]!
    : (sorted[mid - 1]! + sorted[mid]!) / 2;
}

export function isLevelMastered(correct: number, total: number): boolean {
  if (total <= 0) return false;
  return correct / total >= MASTERY_RATIO;
}

export function isSlow(median: number | null, bandMs: number): boolean {
  if (median === null) return false;
  return median > bandMs;
}

const OPEN_STATES = new Set(["available", "in_progress"]);
const DONE_STATES = new Set(["mastered", "skipped"]);

/** Indices of `locked` items to flip to `available` so the open window
 *  returns to `unlockWidth`. Earliest positions first. */
export function nextUnlock(states: string[], unlockWidth: number): number[] {
  const open = states.filter((s) => OPEN_STATES.has(s)).length;
  let need = unlockWidth - open;
  if (need <= 0) return [];

  const out: number[] = [];
  for (let i = 0; i < states.length && need > 0; i++) {
    if (states[i] === "locked") {
      out.push(i);
      need--;
    }
  }
  return out;
}

export { DONE_STATES, OPEN_STATES };
