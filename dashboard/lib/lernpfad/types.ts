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

export interface AddSkillOption {
  id: string;
  title_de: string;
  color: string;
}

export interface PathItemWithSkill extends PathItemRow {
  skills: SkillRow;
}
