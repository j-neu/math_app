// backend/supabase/functions/learning-path/index.ts
//
// GET    /learning-path             child token  → the active path + progress
// POST   /learning-path/generate    teacher      → draft path from a session
// PATCH  /learning-path             teacher      → reorder/add/remove/skip/
//                                                  activate/unlock_width/reset/
//                                                  archive
//
// POST and PATCH are teacher-only, scoped to the teacher's own school, OR
// the service role — foerderplan-generate calls /generate server-to-server
// using the service-role key as its bearer token (see commit ff6d26f).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { timingSafeEqual } from "https://deno.land/std@0.224.0/crypto/timing_safe_equal.ts";
import { sortSkillIds } from "../_shared/ordering.ts";
import { archiveTransitionError, unlockWindowStates } from "../_shared/path_actions.ts";
import { verifyStudentToken } from "../_shared/jwt.ts";
import { requireEnv } from "../_shared/env.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-student-token",
  "Access-Control-Allow-Methods": "POST, GET, PUT, PATCH, DELETE, OPTIONS",
};

// Custom, developer-managed secret (unlike SUPABASE_URL/SUPABASE_*_KEY,
// which the platform guarantees). Read once at module scope; the GET
// handler below fails closed if this is missing rather than falling back
// to a non-null assertion that guarantees nothing at runtime.
const STUDENT_JWT_SECRET = requireEnv("STUDENT_JWT_SECRET");

const enc = new TextEncoder();

// `===` on strings short-circuits at the first differing byte, so its
// timing leaks how many leading bytes of the service-role key a guess got
// right. Defence in depth, not an exploitable hole at this key's length —
// but cheap to close. timingSafeEqual requires equal-length inputs, so a
// length mismatch (the common case for a wrong guess) is handled directly
// without ever comparing byte-for-byte.
function constantTimeEquals(a: string, b: string): boolean {
  const aBytes = enc.encode(a);
  const bBytes = enc.encode(b);
  if (aBytes.length !== bBytes.length) return false;
  return timingSafeEqual(aBytes, bBytes);
}

// deno-lint-ignore no-explicit-any
type Db = any;

type WriterAuth =
  | { ok: true; isService: boolean; schoolId: string | null }
  | { ok: false; status: number; error: string };

// Authenticates the caller of POST /generate and every PATCH action.
// Accepts either the service role (server-to-server, e.g. foerderplan-generate)
// or a teacher, following delete-school-data's established pattern: read the
// bearer JWT, resolve the user via the anon client, then look up their
// teachers row.
async function authenticateWriter(req: Request): Promise<WriterAuth> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return { ok: false, status: 401, error: "Nicht angemeldet" };

  const bearer = authHeader.replace(/^Bearer\s+/i, "").trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (constantTimeEquals(bearer, serviceRoleKey)) {
    return { ok: true, isService: true, schoolId: null };
  }

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authErr } = await userClient.auth.getUser();
  if (authErr || !user) return { ok: false, status: 401, error: "Nicht angemeldet" };

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: teacher } = await admin
    .from("teachers")
    .select("school_id")
    .eq("id", user.id)
    .maybeSingle();

  if (!teacher) return { ok: false, status: 401, error: "Nicht angemeldet" };

  return { ok: true, isService: false, schoolId: teacher.school_id };
}

// The school_id a given student belongs to, via students → classes → school.
async function studentSchoolId(supabase: Db, studentId: string): Promise<string | null> {
  const { data } = await supabase
    .from("students")
    .select("classes!inner(school_id)")
    .eq("id", studentId)
    .maybeSingle();
  if (!data) return null;
  // deno-lint-ignore no-explicit-any
  const klass = Array.isArray(data.classes) ? data.classes[0] : (data.classes as any);
  return klass?.school_id ?? null;
}

// The student_id a given learning path belongs to.
async function pathStudentId(supabase: Db, pathId: string): Promise<string | null> {
  const { data } = await supabase
    .from("learning_paths")
    .select("student_id")
    .eq("id", pathId)
    .maybeSingle();
  return data?.student_id ?? null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── GET: the child's own active path ───────────────────────────────────────
  if (req.method === "GET") {
    // Fail closed: a missing secret must stop this path from serving, never
    // fall back to a non-null assertion that guarantees nothing at runtime.
    if (STUDENT_JWT_SECRET === null) {
      return json(
        { error: "Das geht gerade nicht. Bitte versuch es später noch einmal." },
        500,
      );
    }

    const token = req.headers.get("x-student-token") ?? "";
    const studentId = await verifyStudentToken(token, STUDENT_JWT_SECRET);
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

  // Both POST /generate and every PATCH action are teacher-only (or the
  // service role). Authenticate before doing anything else.
  const auth = await authenticateWriter(req);
  if (!auth.ok) return json({ error: auth.error }, auth.status);

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

    if (!auth.isService) {
      const schoolId = await studentSchoolId(supabase, session.student_id);
      if (!schoolId || schoolId !== auth.schoolId) {
        return json({ error: "Kein Zugriff auf diese Klasse" }, 403);
      }
    }

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
    if (iErr) {
      console.error("learning-path/generate: path_items insert failed:", iErr);
      return json({ error: "Pfad-Einträge fehlgeschlagen" }, 500);
    }

    return json({ path_id: path.id, item_count: rows.length });
  }

  // ── PATCH: teacher edits ───────────────────────────────────────────────────
  const { path_id, action } = body;
  if (!path_id || !action) return json({ error: "path_id und action erforderlich" }, 400);

  if (!auth.isService) {
    const targetStudentId = await pathStudentId(supabase, path_id);
    const schoolId = targetStudentId ? await studentSchoolId(supabase, targetStudentId) : null;
    if (!schoolId || schoolId !== auth.schoolId) {
      return json({ error: "Kein Zugriff auf diese Klasse" }, 403);
    }
  }

  switch (action) {
    case "activate": {
      const { error } = await supabase.from("learning_paths")
        .update({ status: "active", activated_at: new Date().toISOString() })
        .eq("id", path_id);
      if (error) {
        // 23505 = unique_violation. The partial unique index added in
        // 20260831000001_single_active_learning_path.sql allows at most one
        // 'active' learning_paths row per student — a teacher trying to
        // activate a second path for a child who already has one active is
        // an expected, reachable condition, not an internal failure.
        if (error.code === "23505") {
          console.error("learning-path/activate: unique violation:", error);
          return json(
            {
              error:
                "Dieses Kind hat bereits einen aktiven Lernpfad. Bitte zuerst den aktiven Lernpfad abschließen oder deaktivieren, bevor ein neuer aktiviert wird.",
            },
            409,
          );
        }
        console.error("learning-path/activate failed:", error);
        return json({ error: "Lernpfad konnte nicht aktiviert werden" }, 500);
      }
      return json({ ok: true });
    }

    case "set_unlock_width": {
      const width = Number(body.unlock_width);
      if (!Number.isInteger(width) || width < 1 || width > 10) {
        return json({ error: "unlock_width muss zwischen 1 und 10 liegen" }, 400);
      }
      const { error } = await supabase.from("learning_paths")
        .update({ unlock_width: width }).eq("id", path_id);
      if (error) {
        console.error("learning-path/set_unlock_width failed:", error);
        return json({ error: "Freischaltbreite konnte nicht gespeichert werden" }, 500);
      }
      return json({ ok: true });
    }

    case "add_skill": {
      const { count } = await supabase
        .from("path_items").select("id", { count: "exact", head: true }).eq("path_id", path_id);
      const { error } = await supabase.from("path_items").insert({
        path_id, skill_id: body.skill_id, position: count ?? 0,
        origin: "teacher_added", state: "locked",
      });
      if (error) {
        console.error("learning-path/add_skill failed:", error);
        return json({ error: "Kompetenz konnte nicht ergänzt werden" }, 400);
      }
      return json({ ok: true });
    }

    case "remove_skill": {
      const { error } = await supabase.from("path_items").delete()
        .eq("path_id", path_id).eq("skill_id", body.skill_id);
      if (error) {
        console.error("learning-path/remove_skill failed:", error);
        return json({ error: "Kompetenz konnte nicht entfernt werden" }, 500);
      }
      return json({ ok: true });
    }

    case "set_state": {
      const { error } = await supabase.from("path_items")
        .update({ state: body.state, updated_at: new Date().toISOString() })
        .eq("path_id", path_id).eq("skill_id", body.skill_id);
      if (error) {
        console.error("learning-path/set_state failed:", error);
        return json({ error: "Status konnte nicht gespeichert werden" }, 500);
      }
      return json({ ok: true });
    }

    case "reorder": {
      const order: string[] = body.skill_ids ?? [];
      const { error } = await supabase.rpc("reorder_path_items", {
        p_path_id: path_id,
        p_skill_ids: order,
      });
      if (error) {
        console.error("learning-path/reorder failed:", error);
        return json({ error: "Reihenfolge konnte nicht gespeichert werden" }, 400);
      }
      return json({ ok: true });
    }

    case "reset_progress": {
      const { data: p } = await supabase
        .from("learning_paths").select("student_id, unlock_width").eq("id", path_id).maybeSingle();
      if (p) {
        const { error: spErr } = await supabase.from("skill_progress")
          .delete().eq("student_id", p.student_id);
        if (spErr) {
          console.error("learning-path/reset_progress: skill_progress delete failed:", spErr);
          return json({ error: "Fortschritt konnte nicht zurückgesetzt werden" }, 500);
        }
      }
      const { error: piErr } = await supabase.from("path_items")
        .update({ state: "locked" }).eq("path_id", path_id);
      if (piErr) {
        console.error("learning-path/reset_progress: path_items update failed:", piErr);
        return json({ error: "Fortschritt konnte nicht zurückgesetzt werden" }, 500);
      }
      // Re-open the unlock window, mirroring /generate's
      // `idx < unlock_width → available` rule, so a reset path is immediately
      // playable by the child instead of stranding every item locked.
      if (p) {
        const { data: items } = await supabase
          .from("path_items").select("id, position").eq("path_id", path_id);
        const reopen = unlockWindowStates(items ?? [], p.unlock_width)
          .filter((r) => r.state === "available");
        if (reopen.length > 0) {
          const { error: rErr } = await supabase.from("path_items")
            .update({ state: "available" }).in("id", reopen.map((r) => r.id));
          if (rErr) {
            console.error("learning-path/reset_progress: re-open update failed:", rErr);
            return json({ error: "Fortschritt konnte nicht zurückgesetzt werden" }, 500);
          }
        }
      }
      return json({ ok: true });
    }

    case "archive": {
      const { data: path } = await supabase
        .from("learning_paths").select("status").eq("id", path_id).maybeSingle();
      const transitionError = path ? archiveTransitionError(path.status) : null;
      if (transitionError) return json({ error: transitionError }, 400);
      const { error } = await supabase.from("learning_paths")
        .update({ status: "archived" }).eq("id", path_id);
      if (error) {
        console.error("learning-path/archive failed:", error);
        return json({ error: "Lernpfad konnte nicht archiviert werden" }, 500);
      }
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
