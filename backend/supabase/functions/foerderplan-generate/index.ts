// POST /foerderplan-generate
// Body: { session_id: string }
// Ports DiagnosticReportGenerator (Dart) to TypeScript.
// Reads completed diagnostic_results, builds a Foerderplan, persists it.
// Returns the full foerderplan row.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { compareRecommendations, splitSkillId } from "../_shared/ordering.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// New taxonomy (tasks.md R4.2/R4.3): domain label per skill.
const DOMAIN_LABELS: Record<string, string> = {
  A: "Domäne A — Zahlbegriff",
  B: "Domäne B — Stellenwertverständnis",
  C: "Domäne C — Rechenstrategien",
  D: "Domäne D — Sachsituationen",
};

const DOMAIN_PREFIX_PATTERN = /^([A-D])\d/;

// ≥30% of correct answers exceeding threshold → slowResponseFlag
const SLOW_RESPONSE_FRACTION = 0.30;

// Per-answer-format slow threshold (seconds)
function slowThreshold(answerFormat: string): number {
  if (answerFormat === "single") return 15;
  return 30; // multiple, sort
}

interface DbQuestion {
  id: string;
  question_number: number;
  answer_format: string;
  if_wrong_practice_skills: string[];
}

interface DbResult {
  question_id: string;
  was_correct: boolean;
  response_time_seconds: number | null;
  status: string;
}

interface SkillMeta {
  id: string;
  category: string;
  color: string;
  card_number: number;
  domain?: string | null;
  construct_id?: string | null;
  title_de: string;
  description_de: string;
}

// Domain label for a skill: new taxonomy `domain` column (A–D), else derived
// from the skill ID prefix, else the legacy `category` value.
function domainLabel(meta: SkillMeta): string {
  if (meta.domain && DOMAIN_LABELS[meta.domain]) return DOMAIN_LABELS[meta.domain];
  const m = DOMAIN_PREFIX_PATTERN.exec(meta.id);
  if (m && DOMAIN_LABELS[m[1]!]) return DOMAIN_LABELS[m[1]!];
  return meta.category;
}

interface SkillRecommendation {
  skill_id: string;
  title_de: string;
  description_de: string;
  category: string;
  category_color: string;
  card_number: number;
  triggering_question_numbers: number[];
}

interface CategoryStat {
  failed: number;
  total: number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let body: { session_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { session_id } = body;
  if (!session_id) return json({ error: "session_id required" }, 400);

  // Load session
  const { data: session } = await supabase
    .from("diagnostic_sessions")
    .select("id, diagnostic_id, status, student_id")
    .eq("id", session_id)
    .single();

  if (!session) return json({ error: "Session not found" }, 404);
  // Allow generation from in_progress sessions too — teacher may want a partial plan.
  // Caller (dashboard) tags the plan as partial via the session status it sees.

  // For completed sessions: return cached plan if one exists.
  // For in_progress sessions: always regenerate so the plan reflects the latest answers.
  if (session.status === "completed") {
    const { data: existing } = await supabase
      .from("foerderplaene")
      .select("*")
      .eq("session_id", session_id)
      .maybeSingle();
    if (existing) return json(existing);
  }

  // Load all questions for this diagnostic
  const { data: questions, error: qErr } = await supabase
    .from("diagnostic_questions")
    .select("id, question_number, answer_format, if_wrong_practice_skills")
    .eq("diagnostic_id", session.diagnostic_id);

  if (qErr || !questions) return json({ error: "Failed to load questions" }, 500);

  const questionsByUuid = new Map<string, DbQuestion>(questions.map((q) => [q.id, q]));
  const questionsByNumber = new Map<number, DbQuestion>(questions.map((q) => [q.question_number, q]));

  // Load all results
  const { data: results, error: rErr } = await supabase
    .from("diagnostic_results")
    .select("question_id, was_correct, response_time_seconds, status")
    .eq("session_id", session_id);

  if (rErr || !results) return json({ error: "Failed to load results" }, 500);

  // Load skill catalog
  const { data: skillsData } = await supabase
    .from("skills")
    .select("id, category, color, card_number, title_de, description_de, domain, construct_id");

  const skillCatalog = new Map<string, SkillMeta>(
    (skillsData ?? []).map((s) => [s.id, s]),
  );

  // --- 1. Collect triggers from failed questions ---
  const triggersBySkill = new Map<string, number[]>(); // skillId → [questionNumbers]

  for (const result of results as DbResult[]) {
    if (result.was_correct) continue;
    const q = questionsByUuid.get(result.question_id);
    if (!q) continue;
    for (const skillId of q.if_wrong_practice_skills) {
      if (!triggersBySkill.has(skillId)) triggersBySkill.set(skillId, []);
      triggersBySkill.get(skillId)!.push(q.question_number);
    }
  }

  // --- 2. Build recommendations ---
  const recommendations: SkillRecommendation[] = [];
  for (const [skillId, qNums] of triggersBySkill) {
    const meta = skillCatalog.get(skillId);
    if (!meta) continue;
    recommendations.push({
      skill_id: skillId,
      title_de: meta.title_de,
      description_de: meta.description_de,
      category: domainLabel(meta),
      category_color: meta.color,
      card_number: 0,
      triggering_question_numbers: qNums,
    });
  }

  // --- 3. Pedagogical sort ---
  recommendations.sort((a, b) => compareRecommendations(a.skill_id, b.skill_id));

  const briefSkillIds = recommendations.slice(0, 3).map((r) => r.skill_id);
  const recommendedSkillIds = recommendations.map((r) => r.skill_id);

  // --- 4. Category stats ---
  const categoryFailed = new Map<string, number>();
  const categoryTotal = new Map<string, number>();

  for (const result of results as DbResult[]) {
    const q = questionsByUuid.get(result.question_id);
    if (!q) continue;
    const categories = new Set<string>();
    for (const skillId of q.if_wrong_practice_skills) {
      const meta = skillCatalog.get(skillId);
      if (meta) categories.add(domainLabel(meta));
    }
    for (const cat of categories) {
      categoryTotal.set(cat, (categoryTotal.get(cat) ?? 0) + 1);
      if (!result.was_correct) {
        categoryFailed.set(cat, (categoryFailed.get(cat) ?? 0) + 1);
      }
    }
  }

  const categoryStats: Record<string, CategoryStat> = {};
  for (const [cat, total] of categoryTotal) {
    categoryStats[cat] = { failed: categoryFailed.get(cat) ?? 0, total };
  }

  // --- 5. Slow response flag ---
  let correctCount = 0;
  let slowCount = 0;
  for (const result of results as DbResult[]) {
    if (!result.was_correct) continue;
    correctCount++;
    const q = questionsByUuid.get(result.question_id);
    const threshold = slowThreshold(q?.answer_format ?? "single");
    if ((result.response_time_seconds ?? 0) > threshold) slowCount++;
  }
  const slowResponseFlag = correctCount > 0 && slowCount / correctCount >= SLOW_RESPONSE_FRACTION;

  // --- 6. Persist (upsert so in-progress regenerations overwrite the previous partial plan) ---
  const { data: plan, error: pErr } = await supabase
    .from("foerderplaene")
    .upsert({
      session_id,
      brief_skill_ids: briefSkillIds,
      recommended_skill_ids: recommendedSkillIds,
      category_stats: categoryStats,
      slow_response_flag: slowResponseFlag,
      generated_at: new Date().toISOString(),
      pdf_storage_path: null,
    }, { onConflict: "session_id" })
    .select()
    .single();

  if (pErr || !plan) {
    return json({ error: "Failed to persist Förderplan", detail: pErr?.message }, 500);
  }

  // Create the draft Lernpfad so the teacher finds one waiting rather than
  // having to ask for it. A failure here must never fail the Förderplan.
  let learning_path_id: string | null = null;
  try {
    const resp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/learning-path/generate`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
        },
        body: JSON.stringify({ session_id }),
        // Guard against a hung downstream call: never let this stall the
        // Förderplan response, which must return regardless of path outcome.
        signal: AbortSignal.timeout(5000),
      },
    );
    if (resp.ok) learning_path_id = (await resp.json()).path_id ?? null;
  } catch (_e) {
    learning_path_id = null;
  }

  // Return enriched response with full recommendation objects
  return json({ ...plan, recommendations, learning_path_id });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
