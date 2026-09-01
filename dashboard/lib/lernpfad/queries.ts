import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  AddSkillOption,
  LearningPathRow,
  PathItemState,
  PathItemWithSkill,
  PathStatus,
  SkillProgressRow,
} from "./types.ts";

export interface PathDetailStudent {
  id: string;
  display_name: string;
  class_id: string;
  school_id: string | null;
  class_name: string | null;
}

export interface PathDetailResult {
  path: (LearningPathRow & { student: PathDetailStudent | null }) | null;
  items: PathItemWithSkill[];
  progress: SkillProgressRow[];
  allSkills: AddSkillOption[];
}

export interface ClassPathRow {
  id: string;
  student_id: string;
  status: PathStatus;
  unlock_width: number;
  created_at: string;
  activated_at: string | null;
  path_items: { skill_id: string; state: PathItemState }[];
}

export interface ClassProgressRow {
  student_id: string;
  skill_id: string;
  slow_flag: boolean;
}

export interface ClassLearningPaths {
  students: { id: string; display_name: string }[];
  paths: ClassPathRow[];
  progress: ClassProgressRow[];
}

type StudentRow = {
  id: string;
  display_name: string;
  class_id: string;
  classes:
    | { id: string; school_id: string; name: string }
    | { id: string; school_id: string; name: string }[]
    | null;
};

function asClassRow(
  classes: StudentRow["classes"],
): { id: string; school_id: string; name: string } | null {
  if (Array.isArray(classes)) return classes[0] ?? null;
  return classes;
}

function normalizeStudent(raw: unknown): PathDetailStudent | null {
  if (!raw || typeof raw !== "object") return null;
  const s = raw as StudentRow;
  if (!s.id || !s.display_name || !s.class_id) return null;
  const klass = asClassRow(s.classes);
  return {
    id: s.id,
    display_name: s.display_name,
    class_id: s.class_id,
    school_id: klass?.school_id ?? null,
    class_name: klass?.name ?? null,
  };
}

export async function getTeacherSchoolId(supabase: SupabaseClient): Promise<string | null> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;
  const { data: teacher } = await supabase
    .from("teachers")
    .select("school_id")
    .eq("id", user.id)
    .single();
  return teacher?.school_id ?? null;
}

export async function getClassLearningPaths(
  supabase: SupabaseClient,
  classId: string,
): Promise<ClassLearningPaths> {
  const { data: students } = await supabase
    .from("students")
    .select("id, display_name")
    .eq("class_id", classId)
    .order("display_name");

  const studentIds = (students ?? []).map((s) => s.id as string);
  if (studentIds.length === 0) {
    return { students: students ?? [], paths: [], progress: [] };
  }

  const { data: paths } = await supabase
    .from("learning_paths")
    .select(
      "id, student_id, status, unlock_width, created_at, activated_at, path_items(skill_id, state)",
    )
    .in("student_id", studentIds);

  const { data: progress } = await supabase
    .from("skill_progress")
    .select("student_id, skill_id, slow_flag")
    .in("student_id", studentIds);

  return {
    students: students ?? [],
    paths: (paths ?? []) as ClassPathRow[],
    progress: (progress ?? []) as ClassProgressRow[],
  };
}

export async function getPathDetail(
  supabase: SupabaseClient,
  pathId: string,
): Promise<PathDetailResult> {
  const { data: path } = await supabase
    .from("learning_paths")
    .select("*, students(id, display_name, class_id, classes!inner(id, school_id, name))")
    .eq("id", pathId)
    .single();

  if (!path) {
    return { path: null, items: [], progress: [], allSkills: [] };
  }

  const student = normalizeStudent((path as { students: unknown }).students);

  const { data: items } = await supabase
    .from("path_items")
    .select("*, skills!inner(id, title_de, description_de, color)")
    .eq("path_id", pathId)
    .order("position");

  const { data: progress } = student
    ? await supabase
        .from("skill_progress")
        .select(
          "id, student_id, skill_id, level, attempts, correct, best_streak, slow_flag, mastered_at, last_seen_at",
        )
        .eq("student_id", student.id)
    : { data: null };

  const { data: catalog } = await supabase
    .from("skills")
    .select("id, title_de, color");

  const onPath = new Set((items ?? []).map((item) => item.skill_id as string));
  const allSkills = (catalog ?? []).filter((skill) => !onPath.has(skill.id as string));

  return {
    path: { ...(path as LearningPathRow), student },
    items: (items ?? []) as PathItemWithSkill[],
    progress: (progress ?? []) as SkillProgressRow[],
    allSkills: allSkills as AddSkillOption[],
  };
}

export async function getStudentOverviewLink(
  supabase: SupabaseClient,
  studentId: string,
): Promise<{ id: string } | null> {
  const { data } = await supabase
    .from("learning_paths")
    .select("id")
    .eq("student_id", studentId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  return data ?? null;
}
