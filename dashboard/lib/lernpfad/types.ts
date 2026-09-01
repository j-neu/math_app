export type PathStatus = "draft" | "active" | "completed" | "archived";

export type PathItemState = "locked" | "available" | "in_progress" | "mastered" | "skipped";

export type PathItemOrigin = "diagnostic" | "teacher_added";

export interface LearningPathRow {
  id: string;
  student_id: string;
  source_session_id: string | null;
  status: PathStatus;
  unlock_width: number;
  created_by: string | null;
  created_at: string;
  activated_at: string | null;
  completed_at: string | null;
}

export interface PathItemRow {
  id: string;
  path_id: string;
  skill_id: string;
  position: number;
  origin: PathItemOrigin;
  state: PathItemState;
  updated_at: string;
}

export interface SkillProgressRow {
  id: string;
  student_id: string;
  skill_id: string;
  level: number;
  attempts: number;
  correct: number;
  best_streak: number;
  slow_flag: boolean;
  mastered_at: string | null;
  last_seen_at: string | null;
}

export type PathPatchResult = { ok: true } | { error: string };

export interface SkillRow {
  id: string;
  title_de: string;
  description_de: string;
  color: string;
}

/// The 36 skill ids that have a child-facing practice spec
/// (docs/clean-room/skills/specs/*.json). Every other `skills` row is a
/// legacy/retired skill the child app cannot run — adding one to a learning
/// path dead-ends the child ("Für diese Übung gibt es noch keine Aufgaben").
/// The add-skill picker must never offer them (integration-critic F1).
export const SPEC_BACKED_SKILL_IDS: ReadonlySet<string> = new Set([
  "A1.1a",
  "A1.1b",
  "A1.2a",
  "A1.2b",
  "A1.3",
  "A1.4",
  "A1.5",
  "A2.1",
  "A2.2",
  "A2.3",
  "A3.1",
  "A3.2",
  "A3.3",
  "B1.1",
  "B1.2",
  "B1.3",
  "B2.1",
  "B2.2",
  "B2.3",
  "C1.1a",
  "C1.1b",
  "C1.2",
  "C1.3",
  "C2.1",
  "C2.2",
  "C2.3",
  "C3.1a",
  "C3.1b",
  "C3.2",
  "C3.3",
  "C3.4a",
  "C3.4b",
  "C4.1",
  "C4.2",
  "D1.1",
  "D1.2",
]);

export interface AddSkillOption {
  id: string;
  title_de: string;
  color: string;
}

export interface PathItemWithSkill extends PathItemRow {
  skills: SkillRow;
}
