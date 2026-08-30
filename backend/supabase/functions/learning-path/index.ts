// backend/supabase/functions/learning-path/index.ts
//
// GET    /learning-path             child token  → the active path + progress
// POST   /learning-path/generate    teacher      → draft path from a session
// PATCH  /learning-path             teacher      → reorder/add/remove/skip/
//                                                  activate/unlock_width/reset

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { sortSkillIds } from "../_shared/ordering.ts";
import { verifyStudentToken } from "../_shared/jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── GET: the child's own active path ───────────────────────────────────────
  if (req.method === "GET") {
    const token = req.headers.get("x-student-token") ?? "";
    const studentId = await verifyStudentToken(token, Deno.env.get("STUDENT_JWT_SECRET")!);
    if (!studentId) return json({ error: "Nicht angemeldet" }, 401);

    const { data: path } = await supabase
      .from("learning_paths")
      .select("id, unlock_width")
      .eq("student_id", studentId)
      .eq("status", "active")
      .maybeSingle();

    if (!path) return json({ path_id: null, items: [] });

    const { data: items } = await supabase
      .from("path_items")
      .select("skill_id, position, state, skills!inner(title_de, description_de, color)")
      .eq("path_id", path.id)
      .order("position");

    const { data: progress } = await supabase
      .from("skill_progress")
      .select("skill_id, level, attempts, correct, mastered_at")
      .eq("student_id", studentId);

    const bySkill = new Map<string, unknown[]>();
    for (const p of progress ?? []) {
      const list = bySkill.get(p.skill_id) ?? [];
      list.push(p);
      bySkill.set(p.skill_id, list);
    }

    return json({
      path_id: path.id,
      unlock_width: path.unlock_width,
      items: (items ?? []).map((i) => {
        // deno-lint-ignore no-explicit-any
        const skill = Array.isArray(i.skills) ? i.skills[0] : (i.skills as any);
        return {
          skill_id: i.skill_id,
          position: i.position,
          state: i.state,
          title_de: skill?.title_de ?? i.skill_id,
          description_de: skill?.description_de ?? "",
          color: skill?.color ?? "gray",
          progress: bySkill.get(i.skill_id) ?? [],
        };
      }),
    });
  }

  if (req.method !== "POST" && req.method !== "PATCH") {
    return json({ error: "Methode nicht erlaubt" }, 405);
  }

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── POST /generate: build a draft path from a completed session ────────────
  if (req.method === "POST") {
    if (!body.session_id) return json({ error: "session_id fehlt" }, 400);

    const { data: session } = await supabase
      .from("diagnostic_sessions")
      .select("id, student_id")
      .eq("id", body.session_id)
      .maybeSingle();

    if (!session) return json({ error: "Sitzung nicht gefunden" }, 404);

    const { data: plan } = await supabase
      .from("foerderplaene")
      .select("recommended_skill_ids")
      .eq("session_id", session.id)
      .maybeSingle();

    const skillIds: string[] = plan?.recommended_skill_ids ?? [];
    if (skillIds.length === 0) {
      return json({ error: "Kein Förderplan vorhanden" }, 409);
    }

    // Re-use an existing draft for this session rather than stacking duplicates.
    const { data: existing } = await supabase
      .from("learning_paths")
      .select("id")
      .eq("source_session_id", session.id)
      .maybeSingle();
    if (existing) return json({ path_id: existing.id, item_count: skillIds.length, reused: true });

    const { data: path, error: pErr } = await supabase
      .from("learning_paths")
      .insert({ student_id: session.student_id, source_session_id: session.id, status: "draft" })
      .select("id, unlock_width")
      .single();

    if (pErr || !path) return json({ error: "Pfad konnte nicht angelegt werden" }, 500);

    const ordered = sortSkillIds(skillIds);
    const rows = ordered.map((skill_id, idx) => ({
      path_id: path.id,
      skill_id,
      position: idx,
      origin: "diagnostic",
      state: idx < path.unlock_width ? "available" : "locked",
    }));

    const { error: iErr } = await supabase.from("path_items").insert(rows);
    if (iErr) return json({ error: "Pfad-Einträge fehlgeschlagen", detail: iErr.message }, 500);

    return json({ path_id: path.id, item_count: rows.length });
  }

  // ── PATCH: teacher edits ───────────────────────────────────────────────────
  const { path_id, action } = body;
  if (!path_id || !action) return json({ error: "path_id und action erforderlich" }, 400);

  switch (action) {
    case "activate":
      await supabase.from("learning_paths")
        .update({ status: "active", activated_at: new Date().toISOString() })
        .eq("id", path_id);
      return json({ ok: true });

    case "set_unlock_width": {
      const width = Number(body.unlock_width);
      if (!Number.isInteger(width) || width < 1 || width > 10) {
        return json({ error: "unlock_width muss zwischen 1 und 10 liegen" }, 400);
      }
      await supabase.from("learning_paths").update({ unlock_width: width }).eq("id", path_id);
      return json({ ok: true });
    }

    case "add_skill": {
      const { count } = await supabase
        .from("path_items").select("id", { count: "exact", head: true }).eq("path_id", path_id);
      const { error } = await supabase.from("path_items").insert({
        path_id, skill_id: body.skill_id, position: count ?? 0,
        origin: "teacher_added", state: "locked",
      });
      if (error) return json({ error: "Skill konnte nicht ergänzt werden", detail: error.message }, 400);
      return json({ ok: true });
    }

    case "remove_skill":
      await supabase.from("path_items").delete()
        .eq("path_id", path_id).eq("skill_id", body.skill_id);
      return json({ ok: true });

    case "set_state":
      await supabase.from("path_items")
        .update({ state: body.state, updated_at: new Date().toISOString() })
        .eq("path_id", path_id).eq("skill_id", body.skill_id);
      return json({ ok: true });

    case "reorder": {
      const order: string[] = body.skill_ids ?? [];
      for (let i = 0; i < order.length; i++) {
        await supabase.from("path_items")
          .update({ position: i, updated_at: new Date().toISOString() })
          .eq("path_id", path_id).eq("skill_id", order[i]);
      }
      return json({ ok: true });
    }

    case "reset_progress": {
      const { data: p } = await supabase
        .from("learning_paths").select("student_id").eq("id", path_id).maybeSingle();
      if (p) {
        await supabase.from("skill_progress").delete().eq("student_id", p.student_id);
      }
      await supabase.from("path_items").update({ state: "locked" }).eq("path_id", path_id);
      return json({ ok: true });
    }

    default:
      return json({ error: "Unbekannte Aktion" }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
