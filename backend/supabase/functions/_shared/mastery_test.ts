import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { isLevelMastered, isSlow, medianMs, nextUnlock } from "./mastery.ts";

Deno.test("median of odd and even counts", () => {
  assertEquals(medianMs([100, 300, 200]), 200);
  assertEquals(medianMs([100, 200, 300, 400]), 250);
  assertEquals(medianMs([]), null);
});

Deno.test("mastery needs 7 of 8", () => {
  assert(isLevelMastered(7, 8));
  assert(isLevelMastered(8, 8));
  assert(!isLevelMastered(6, 8));
});

Deno.test("mastery scales to other problem counts", () => {
  assert(isLevelMastered(9, 10));   // 90% ≥ 87.5%
  assert(!isLevelMastered(8, 10));  // 80% < 87.5%
});

Deno.test("slow is a flag, never a gate", () => {
  assert(isSlow(9000, 6000));
  assert(!isSlow(4000, 6000));
  assert(!isSlow(null, 6000));
});

Deno.test("unlock window refills to width, in order", () => {
  // mastered, available, locked, locked → unlock index 2 to hold width 2
  assertEquals(nextUnlock(["mastered", "available", "locked", "locked"], 2), [2]);
});

Deno.test("unlock window never exceeds the number of locked items", () => {
  assertEquals(nextUnlock(["mastered", "mastered"], 3), []);
});

Deno.test("skipped items count as done, not as occupying the window", () => {
  assertEquals(nextUnlock(["skipped", "available", "locked", "locked"], 2), [2]);
});
