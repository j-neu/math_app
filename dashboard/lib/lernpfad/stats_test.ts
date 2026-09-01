/// <reference lib="deno.ns" />

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { pathCounts, levelRowsBySkill, slowSkillIds } from "./stats.ts";
import type { SkillProgressRow } from "./types.ts";

function progressRow(
  skillId: string,
  level: number,
  overrides: Partial<Pick<SkillProgressRow, "attempts" | "correct" | "best_streak" | "slow_flag" | "mastered_at" | "last_seen_at">> = {},
): SkillProgressRow {
  return {
    id: `id-${skillId}-${level}`,
    student_id: "student-1",
    skill_id: skillId,
    level,
    attempts: 0,
    correct: 0,
    best_streak: 0,
    slow_flag: false,
    mastered_at: null,
    last_seen_at: null,
    ...overrides,
  };
}

// ---- pathCounts ----

Deno.test("pathCounts: mastered + available/in_progress, skipped/locked excluded", () => {
  const counts = pathCounts([
    { state: "mastered" },
    { state: "available" },
    { state: "in_progress" },
    { state: "skipped" },
    { state: "locked" },
  ]);
  assertEquals(counts, { mastered: 1, available: 2 });
});

Deno.test("pathCounts: empty array yields zero counts", () => {
  assertEquals(pathCounts([]), { mastered: 0, available: 0 });
});

Deno.test("pathCounts: all-mastered yields available 0", () => {
  const counts = pathCounts([
    { state: "mastered" },
    { state: "mastered" },
    { state: "mastered" },
  ]);
  assertEquals(counts, { mastered: 3, available: 0 });
});

Deno.test("pathCounts: locked/skipped-only yields both zero", () => {
  const counts = pathCounts([{ state: "locked" }, { state: "skipped" }]);
  assertEquals(counts, { mastered: 0, available: 0 });
});

// ---- levelRowsBySkill ----

Deno.test("levelRowsBySkill: buckets by skill_id and preserves fields in level order", () => {
  const rows = [
    progressRow("s1", 3, { attempts: 5, correct: 4, best_streak: 3, slow_flag: true, mastered_at: "2026-01-03", last_seen_at: "2026-01-09" }),
    progressRow("s1", 1, { attempts: 8, correct: 7, best_streak: 4, slow_flag: false, mastered_at: "2026-01-01", last_seen_at: "2026-01-07" }),
    progressRow("s2", 1, { attempts: 2, correct: 2, best_streak: 2, slow_flag: false, mastered_at: "2026-01-02", last_seen_at: "2026-01-08" }),
  ];
  const buckets = levelRowsBySkill(rows);
  assertEquals(Object.keys(buckets).sort(), ["s1", "s2"]);
  assertEquals(buckets.s1!.map((r) => r.level), [1, 3]);
  assertEquals(buckets.s1![0], {
    id: "id-s1-1",
    student_id: "student-1",
    skill_id: "s1",
    level: 1,
    attempts: 8,
    correct: 7,
    best_streak: 4,
    slow_flag: false,
    mastered_at: "2026-01-01",
    last_seen_at: "2026-01-07",
  });
  assertEquals(buckets.s2!.length, 1);
});

Deno.test("levelRowsBySkill: empty input yields empty record", () => {
  assertEquals(levelRowsBySkill([]), {});
});

Deno.test("levelRowsBySkill: rows already in level order stay ordered", () => {
  const rows = [
    progressRow("s1", 1),
    progressRow("s1", 2),
    progressRow("s1", 3),
  ];
  const buckets = levelRowsBySkill(rows);
  assertEquals(buckets.s1!.map((r) => r.level), [1, 2, 3]);
});

// ---- slowSkillIds ----

Deno.test("slowSkillIds: distinct ids where any level has slow_flag true", () => {
  const ids = slowSkillIds([
    { skill_id: "s1", slow_flag: false },
    { skill_id: "s1", slow_flag: true },
    { skill_id: "s2", slow_flag: false },
    { skill_id: "s3", slow_flag: true },
    { skill_id: "s3", slow_flag: true },
  ]);
  assertEquals(ids.sort(), ["s1", "s3"]);
});

Deno.test("slowSkillIds: slow flag on level 2 only still flags the skill", () => {
  const ids = slowSkillIds([
    { skill_id: "s1", slow_flag: false },
    { skill_id: "s1", slow_flag: true },
  ]);
  assertEquals(ids, ["s1"]);
});

Deno.test("slowSkillIds: empty input yields empty array", () => {
  assertEquals(slowSkillIds([]), []);
});

Deno.test("slowSkillIds: no slow flags yields empty array", () => {
  const ids = slowSkillIds([
    { skill_id: "s1", slow_flag: false },
    { skill_id: "s2", slow_flag: false },
  ]);
  assertEquals(ids, []);
});
