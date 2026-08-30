// backend/supabase/functions/practice-session/index.ts
//
// POST /practice-session/start  child token → { practice_session_id, seed }
// POST /practice-session/sync   child token → idempotent attempt batch
// POST /practice-session/end    child token → mastery + unlock evaluation

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { verifyStudentToken } from "../_shared/jwt.ts";
import { isLevelMastered, isSlow, medianMs, nextUnlock } from "../_shared/mastery.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-student-token",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Methode nicht erlaubt" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const studentId = await verifyStudentToken(
    req.headers.get("x-student-token") ?? "",
    Deno.env.get("STUDENT_JWT_SECRET")!,
  );
  if (!studentId) return json({ error: "Nicht angemeldet" }, 401);

  const path = new URL(req.url).pathname.split("/").pop();
  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── /start ─────────────────────────────────────────────────────────────────
  if (path === "start") {
    const { skill_id, level } = body;
    if (!skill_id || ![1, 2, 3].includes(level)) {
      return json({ error: "skill_id und level (1–3) erforderlich" }, 400);
    }

    // The child may only practise a skill that is open on their active path.
    const { data: item } = await supabase
      .from("path_items")
      .select("id, state, learning_paths!inner(student_id, status)")
      .eq("skill_id", skill_id)
      .eq("learning_paths.student_id", studentId)
      .eq("learning_paths.status", "active")
      .maybeSingle();

    if (!item || !["available", "in_progress"].includes(item.state)) {
      return json({ error: "Diese Aufgabe ist noch nicht freigeschaltet" }, 403);
    }

    const seed = Date.now() % 2147483647;
    const { data: ps, error } = await supabase
      .from("practice_sessions")
      .insert({ student_id: studentId, path_item_id: item.id, skill_id, level, seed })
      .select("id")
      .single();

    if (error || !ps) return json({ error: "Übung konnte nicht gestartet werden" }, 500);

    await supabase.from("path_items")
      .update({ state: "in_progress", updated_at: new Date().toISOString() })
      .eq("id", item.id);

    return json({ practice_session_id: ps.id, seed });
  }

  // ── /sync: idempotent on (practice_session_id, problem_index) ──────────────
  if (path === "sync") {
    const { practice_session_id, attempts } = body;
    if (!practice_session_id || !Array.isArray(attempts)) {
      return json({ error: "practice_session_id und attempts erforderlich" }, 400);
    }

    const { data: owned } = await supabase
      .from("practice_sessions").select("id")
      .eq("id", practice_session_id).eq("student_id", studentId).maybeSingle();
    if (!owned) return json({ error: "Übung nicht gefunden" }, 404);

    // deno-lint-ignore no-explicit-any
    const rows = attempts.map((a: any) => ({
      practice_session_id,
      problem_index: a.problem_index,
      problem: a.problem ?? {},
      answer: a.answer ?? null,
      was_correct: !!a.was_correct,
      response_ms: a.response_ms ?? null,
      error_code: a.error_code ?? null,
    }));

    const { error } = await supabase
      .from("practice_attempts")
      .upsert(rows, { onConflict: "practice_session_id,problem_index", ignoreDuplicates: true });

    if (error) {
      console.error("practice-session/sync: upsert failed:", error);
      return json({ error: "Speichern fehlgeschlagen" }, 500);
    }
    return json({ accepted: rows.length });
  }

  // ── /end ───────────────────────────────────────────────────────────────────
  if (path === "end") {
    const { practice_session_id, slow_band_ms } = body;
    if (!practice_session_id) return json({ error: "practice_session_id fehlt" }, 400);

    const { data: ps } = await supabase
      .from("practice_sessions")
      .select("id, skill_id, level, path_item_id")
      .eq("id", practice_session_id).eq("student_id", studentId).maybeSingle();
    if (!ps) return json({ error: "Übung nicht gefunden" }, 404);

    const { data: attempts } = await supabase
      .from("practice_attempts")
      .select("was_correct, response_ms")
      .eq("practice_session_id", practice_session_id);

    const total = attempts?.length ?? 0;
    const correct = (attempts ?? []).filter((a) => a.was_correct).length;
    const median = medianMs(
      (attempts ?? []).map((a) => a.response_ms).filter((v): v is number => typeof v === "number"),
    );
    const mastered = isLevelMastered(correct, total);
    const slow = isSlow(median, Number(slow_band_ms) || 999_999);

    await supabase.from("practice_sessions").update({
      ended_at: new Date().toISOString(),
      problems_total: total,
      problems_correct: correct,
      median_response_ms: median === null ? null : Math.round(median),
    }).eq("id", ps.id);

    // Progress row per (student, skill, level)
    const { data: existing } = await supabase
      .from("skill_progress").select("id, attempts, correct, best_streak")
      .eq("student_id", studentId).eq("skill_id", ps.skill_id).eq("level", ps.level).maybeSingle();

    const progressRow = {
      student_id: studentId,
      skill_id: ps.skill_id,
      level: ps.level,
      attempts: (existing?.attempts ?? 0) + total,
      correct: (existing?.correct ?? 0) + correct,
      best_streak: Math.max(existing?.best_streak ?? 0, correct),
      slow_flag: slow,
      mastered_at: mastered ? new Date().toISOString() : null,
      last_seen_at: new Date().toISOString(),
    };

    await supabase.from("skill_progress")
      .upsert(progressRow, { onConflict: "student_id,skill_id,level" });

    // A skill is mastered when levels 1–3 all are.
    const { data: allLevels } = await supabase
      .from("skill_progress").select("level, mastered_at")
      .eq("student_id", studentId).eq("skill_id", ps.skill_id);

    const skillMastered = [1, 2, 3].every(
      (lv) => (allLevels ?? []).some((r) => r.level === lv && r.mastered_at !== null),
    );

    let unlocked: string[] = [];
    if (skillMastered && ps.path_item_id) {
      await supabase.from("path_items")
        .update({ state: "mastered", updated_at: new Date().toISOString() })
        .eq("id", ps.path_item_id);

      const { data: item } = await supabase
        .from("path_items").select("path_id").eq("id", ps.path_item_id).maybeSingle();

      if (item) {
        const { data: pathRow } = await supabase
          .from("learning_paths").select("unlock_width").eq("id", item.path_id).maybeSingle();
        const { data: siblings } = await supabase
          .from("path_items").select("id, skill_id, state, position")
          .eq("path_id", item.path_id).order("position");

        const indices = nextUnlock(
          (siblings ?? []).map((s) => s.state),
          pathRow?.unlock_width ?? 3,
        );

        for (const idx of indices) {
          const target = siblings![idx]!;
          await supabase.from("path_items")
            .update({ state: "available", updated_at: new Date().toISOString() })
            .eq("id", target.id);
          unlocked.push(target.skill_id);
        }
      }
    } else if (ps.path_item_id) {
      await supabase.from("path_items")
        .update({ state: "available", updated_at: new Date().toISOString() })
        .eq("id", ps.path_item_id);
    }

    return json({ mastered, skill_mastered: skillMastered, slow_flag: slow, unlocked_skill_ids: unlocked });
  }

  return json({ error: "Unbekannter Pfad" }, 404);
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
