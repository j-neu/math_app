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

  // ── Rate limit: count recent failures from this IP ─────────────────────────
  const since = new Date(Date.now() - WINDOW_MINUTES * 60_000).toISOString();
  const { count: failures } = await supabase
    .from("login_attempts")
    .select("id", { count: "exact", head: true })
    .eq("ip_hash", ipHash)
    .eq("succeeded", false)
    .gte("attempted_at", since);

  if ((failures ?? 0) >= MAX_FAILURES_PER_WINDOW) {
    return json({ error: "Zu viele Versuche. Bitte später noch einmal probieren." }, 429);
  }

  const record = (succeeded: boolean) =>
    supabase.from("login_attempts").insert({
      ip_hash: ipHash,
      school_slug: body.school_slug ?? null,
      succeeded,
    });

  // ── /roster ────────────────────────────────────────────────────────────────
  if (path === "roster") {
    if (!body.school_slug || !body.class_code || !isValidCodeShape(body.class_code)) {
      await record(false);
      return json({ error: "Code nicht gefunden" }, 404);
    }

    const { data: school } = await supabase
      .from("schools").select("id").eq("slug", body.school_slug).maybeSingle();

    if (!school) {
      await record(false);
      return json({ error: "Code nicht gefunden" }, 404);
    }

    const { data: klass } = await supabase
      .from("classes")
      .select("id, require_pin")
      .eq("school_id", school.id)
      .eq("class_code", normaliseCode(body.class_code))
      .maybeSingle();

    if (!klass) {
      await record(false);
      return json({ error: "Code nicht gefunden" }, 404);
    }

    const { data: students } = await supabase
      .from("students")
      .select("id, display_name, avatar")
      .eq("class_id", klass.id)
      .order("display_name");

    await record(true);
    return json({
      class_id: klass.id,
      require_pin: klass.require_pin ?? false,
      students: students ?? [],
    });
  }

  // ── /login ─────────────────────────────────────────────────────────────────
  if (path === "login") {
    if (!body.student_id) {
      await record(false);
      return json({ error: "Anmeldung nicht möglich" }, 400);
    }

    const { data: student } = await supabase
      .from("students")
      .select("id, display_name, pin_hash, classes!inner(require_pin)")
      .eq("id", body.student_id)
      .maybeSingle();

    if (!student) {
      await record(false);
      return json({ error: "Anmeldung nicht möglich" }, 404);
    }

    // deno-lint-ignore no-explicit-any
    const klass = Array.isArray(student.classes) ? student.classes[0] : (student.classes as any);
    if (klass?.require_pin) {
      const salt2 = Deno.env.get("PIN_HASH_SALT") ?? "unsalted";
      const supplied = body.pin ? await hashSecret(body.pin, salt2) : null;
      if (!supplied || supplied !== student.pin_hash) {
        await record(false);
        return json({ error: "Bildfolge stimmt nicht" }, 401);
      }
    }

    const token = await signStudentToken(student.id, Deno.env.get("STUDENT_JWT_SECRET")!);
    await record(true);
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
