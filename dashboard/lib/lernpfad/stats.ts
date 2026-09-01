import type { SkillProgressRow } from "./types.ts";

export interface PathCounts {
  mastered: number;
  available: number;
}

export function pathCounts(items: { state: string }[]): PathCounts {
  let mastered = 0;
  let available = 0;
  for (const item of items) {
    if (item.state === "mastered") {
      mastered += 1;
    } else if (item.state === "available" || item.state === "in_progress") {
      available += 1;
    }
  }
  return { mastered, available };
}

export function levelRowsBySkill(skillProgress: SkillProgressRow[]): Record<string, SkillProgressRow[]> {
  const bySkill: Record<string, SkillProgressRow[]> = {};
  for (const row of skillProgress) {
    const bucket = bySkill[row.skill_id] ?? [];
    bucket.push(row);
    bySkill[row.skill_id] = bucket;
  }
  for (const skillId of Object.keys(bySkill)) {
    bySkill[skillId].sort((a, b) => a.level - b.level);
  }
  return bySkill;
}

export function slowSkillIds(skillProgress: { skill_id: string; slow_flag: boolean }[]): string[] {
  const ids = new Set<string>();
  for (const row of skillProgress) {
    if (row.slow_flag) ids.add(row.skill_id);
  }
  return Array.from(ids);
}
