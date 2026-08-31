// backend/supabase/functions/student-auth/index.ts
//
// POST /student-auth/roster  { school_slug, class_code } → class roster
// POST /student-auth/login   { student_id, pin? }        → student JWT
//
// Rate limited per hashed client IP. Never returns anything about a child
// beyond display_name and avatar.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hashIp, hashSecret, isValidCodeShape, normaliseCode } from "../_shared/codes.ts";
import { signStudentToken } from "../_shared/jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_FAILURES_PER_WINDOW = 10;
const WINDOW_MINUTES = 15;

// deno-lint-ignore no-explicit-any
type Db = any;

// Records this attempt as a provisional failure FIRST, then evaluates the
// failure count against it — so a concurrent burst cannot all read a stale
// count before any of them has recorded itself (the previous count-then-
// insert order let parallel requests all observe the same stale zero).
// Because this request's own row is already counted, the threshold compares
// with `>` rather than `>=` to keep the same effective cap of 10.
async function checkRateLimit(
  supabase: Db,
  ipHash: string,
  schoolSlug: string | null,
): Promise<{ blocked: true } | { blocked: false; markSucceeded: () => Promise<unknown> }> {
  const { data: attemptRow } = await supabase
    .from("login_attempts")
    .insert({ ip_hash: ipHash, school_slug: schoolSlug, succeeded: false })
    .select("id")
    .single();

  const since = new Date(Date.now() - WINDOW_MINUTES * 60_000).toISOString();
  const { count: failures } = await supabase
    .from("login_attempts")
    .select("id", { count: "exact", head: true })
    .eq("ip_hash", ipHash)
    .eq("succeeded", false)
    .gte("attempted_at", since);

  if ((failures ?? 0) > MAX_FAILURES_PER_WINDOW) {
    return { blocked: true };
  }

  return {
    blocked: false,
    markSucceeded: () => {
      if (!attemptRow) return Promise.resolve();
      return supabase.from("login_attempts").update({ succeeded: true }).eq("id", attemptRow.id);
    },
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Methode nicht erlaubt" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const salt = Deno.env.get("IP_HASH_SALT") ?? "unsalted";
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const ipHash = await hashIp(ip, salt);

  const path = new URL(req.url).pathname.split("/").pop();

  let body: { school_slug?: string; class_code?: string; student_id?: string; pin?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── /roster ────────────────────────────────────────────────────────────────
  if (path === "roster") {
    const limit = await checkRateLimit(supabase, ipHash, body.school_slug ?? null);
    if (limit.blocked) {
      return json({ error: "Zu viele Versuche. Bitte später noch einmal probieren." }, 429);
    }

    if (!body.school_slug || !body.class_code || !isValidCodeShape(body.class_code)) {
      return json({ error: "Diesen Code gibt es nicht. Schau noch mal auf die Tafel." }, 404);
    }

    const { data: school } = await supabase
      .from("schools").select("id").eq("slug", body.school_slug).maybeSingle();

    if (!school) {
      return json({ error: "Diesen Code gibt es nicht. Schau noch mal auf die Tafel." }, 404);
    }

    const { data: klass } = await supabase
      .from("classes")
      .select("id, require_pin")
      .eq("school_id", school.id)
      .eq("class_code", normaliseCode(body.class_code))
      .maybeSingle();

    if (!klass) {
      return json({ error: "Diesen Code gibt es nicht. Schau noch mal auf die Tafel." }, 404);
    }

    const { data: students } = await supabase
      .from("students")
      .select("id, display_name, avatar")
      .eq("class_id", klass.id)
      .order("display_name")
      // `display_name` has no unique constraint (two children named "Max" in
      // the same class is ordinary), so Postgres does not guarantee a stable
      // relative order between equal-name rows across queries. `id` is the
      // primary key, so this makes the roster order fully deterministic —
      // which both the tile grid position and `_assignAvatarColours`'
      // collision resolution depend on staying stable between sessions.
      .order("id");

    await limit.markSucceeded();
    return json({
      class_id: klass.id,
      require_pin: klass.require_pin ?? false,
      students: students ?? [],
    });
  }

  // ── /login ─────────────────────────────────────────────────────────────────
  if (path === "login") {
    const limit = await checkRateLimit(supabase, ipHash, null);
    if (limit.blocked) {
      return json({ error: "Zu viele Versuche. Bitte später noch einmal probieren." }, 429);
    }

    if (!body.student_id) {
      return json({ error: "Anmeldung nicht möglich" }, 400);
    }

    const { data: student } = await supabase
      .from("students")
      .select("id, display_name, classes!inner(require_pin)")
      .eq("id", body.student_id)
      .maybeSingle();

    if (!student) {
      return json({ error: "Anmeldung nicht möglich" }, 404);
    }

    // deno-lint-ignore no-explicit-any
    const klass = Array.isArray(student.classes) ? student.classes[0] : (student.classes as any);
    if (klass?.require_pin) {
      // I5: the PIN hash lives in student_pins (service-role only, RLS
      // enabled with no policies), not on students — a teacher's ordinary
      // `select *` on students must never be able to read it.
      const { data: pinRow } = await supabase
        .from("student_pins")
        .select("pin_hash")
        .eq("student_id", student.id)
        .maybeSingle();

      const salt2 = Deno.env.get("PIN_HASH_SALT") ?? "unsalted";
      const supplied = body.pin ? await hashSecret(body.pin, salt2) : null;
      if (!supplied || !pinRow || supplied !== pinRow.pin_hash) {
        return json(
          { error: "Diese Bilder passen noch nicht zusammen. Versuch es noch einmal." },
          401,
        );
      }
    }

    const token = await signStudentToken(student.id, Deno.env.get("STUDENT_JWT_SECRET")!);
    await limit.markSucceeded();
    return json({ token, student_id: student.id, display_name: student.display_name });
  }

  return json({ error: "Unbekannter Pfad" }, 404);
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
