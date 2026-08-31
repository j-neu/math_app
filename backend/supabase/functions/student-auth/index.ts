// backend/supabase/functions/student-auth/index.ts
//
// POST /student-auth/roster  { school_slug, class_code } → class roster
// POST /student-auth/login   { student_id, pin? }        → student JWT
//
// Rate limited per hashed client IP, AND per a second, IP-independent
// dimension (class_code for /roster, student_id for /login) — see
// checkRateLimit. Never returns anything about a child beyond
// display_name and avatar.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hashIp, hashSecret, isValidCodeShape, normaliseCode } from "../_shared/codes.ts";
import { signStudentToken } from "../_shared/jwt.ts";
import { requireEnv } from "../_shared/env.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_FAILURES_PER_WINDOW = 10;
const WINDOW_MINUTES = 15;

// ── Required secrets ─────────────────────────────────────────────────────
// Read once at module scope. These are custom, developer-managed secrets
// (via `supabase secrets set`) — unlike SUPABASE_URL/SUPABASE_*_KEY, the
// platform does not guarantee they are set. A missing value must never
// silently degrade (e.g. to a hardcoded salt); it must stop the endpoint
// from serving. See _shared/env.ts and the guard at the top of Deno.serve.
const IP_HASH_SALT = requireEnv("IP_HASH_SALT");
const PIN_HASH_SALT = requireEnv("PIN_HASH_SALT");
const STUDENT_JWT_SECRET = requireEnv("STUDENT_JWT_SECRET");

// deno-lint-ignore no-explicit-any
type Db = any;

// One of the two dimensions checkRateLimit throttles on, in addition to the
// IP hash: the /roster class_code being guessed, or the /login student_id
// being PIN-guessed. Absent when the request didn't supply enough to key on
// (e.g. no class_code at all) — such requests still fail their own
// validation moments later, so skipping the secondary check for them loses
// nothing.
type SecondaryKey = { column: "class_code" | "student_id"; value: string } | null;

async function countFailures(
  supabase: Db,
  column: "ip_hash" | "class_code" | "student_id",
  value: string,
  since: string,
): Promise<number> {
  const { count } = await supabase
    .from("login_attempts")
    .select("id", { count: "exact", head: true })
    .eq(column, value)
    .eq("succeeded", false)
    .gte("attempted_at", since);
  return count ?? 0;
}

// Records this attempt as a provisional failure FIRST, then evaluates the
// failure count against it — so a concurrent burst cannot all read a stale
// count before any of them has recorded itself (the previous count-then-
// insert order let parallel requests all observe the same stale zero).
// Because this request's own row is already counted, the threshold compares
// with `>` rather than `>=` to keep the same effective cap of 10.
//
// Checks TWO independent dimensions and blocks if either trips:
//   - ip_hash, as before.
//   - `secondary` (class_code or student_id), which does not depend on any
//     client-supplied network header. The IP-hash check is correct today
//     (see the doc comment on the x-forwarded-for line below) but that
//     correctness rests entirely on undocumented gateway behaviour; this is
//     the backstop for the day that assumption stops holding, or for a
//     client that reaches this function by some other path entirely.
async function checkRateLimit(
  supabase: Db,
  ipHash: string,
  schoolSlug: string | null,
  secondary: SecondaryKey,
): Promise<{ blocked: true } | { blocked: false; markSucceeded: () => Promise<unknown> }> {
  const { data: attemptRow } = await supabase
    .from("login_attempts")
    .insert({
      ip_hash: ipHash,
      school_slug: schoolSlug,
      class_code: secondary?.column === "class_code" ? secondary.value : null,
      student_id: secondary?.column === "student_id" ? secondary.value : null,
      succeeded: false,
    })
    .select("id")
    .single();

  const since = new Date(Date.now() - WINDOW_MINUTES * 60_000).toISOString();

  const ipFailures = await countFailures(supabase, "ip_hash", ipHash, since);
  const secondaryFailures = secondary
    ? await countFailures(supabase, secondary.column, secondary.value, since)
    : 0;

  if (ipFailures > MAX_FAILURES_PER_WINDOW || secondaryFailures > MAX_FAILURES_PER_WINDOW) {
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

  // Fail closed: a missing secret must stop this endpoint from serving,
  // never fall back to a default. Checked on every request (cheap — these
  // are already-resolved module-scope constants) rather than only at
  // startup, since Deno.serve keeps the isolate running and we want every
  // single request to be refused, not just the first.
  if (IP_HASH_SALT === null || PIN_HASH_SALT === null || STUDENT_JWT_SECRET === null) {
    return json(
      { error: "Die Anmeldung ist gerade nicht möglich. Bitte sag es einem Erwachsenen." },
      500,
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // The gateway in front of this function prepends its own trusted value as
  // the FIRST hop of x-forwarded-for, so the leftmost entry is the genuine
  // client IP, not attacker-controlled — verified empirically 2026-08-31 by
  // forging x-forwarded-for (and omitting it) against the live deployed
  // function: the rate limiter still tripped correctly in every case.
  // Do NOT "fix" this to read the rightmost hop or add proxy-count logic;
  // that would break the correct behaviour this comment is protecting.
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const ipHash = await hashIp(ip, IP_HASH_SALT);

  const path = new URL(req.url).pathname.split("/").pop();

  let body: { school_slug?: string; class_code?: string; student_id?: string; pin?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Ungültige Anfrage" }, 400);
  }

  // ── /roster ────────────────────────────────────────────────────────────────
  if (path === "roster") {
    // Keyed on the class_code being attempted, not just the caller's IP —
    // 31^4 = 923,521 possible codes makes this the actual brute-force
    // target. Only set when a code was supplied at all; a request missing
    // one fails validation two lines down regardless.
    const classCode = body.class_code ? normaliseCode(body.class_code) : null;
    const secondary: SecondaryKey = classCode ? { column: "class_code", value: classCode } : null;

    const limit = await checkRateLimit(supabase, ipHash, body.school_slug ?? null, secondary);
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
    // Keyed on the student_id being PIN-guessed, not just the caller's IP —
    // a 4-symbol picture PIN drawn from 8 glyphs is at most 4096
    // combinations, so this is the actual brute-force target. student_id is
    // an unguessable UUID obtainable only via the separately rate-limited
    // /roster endpoint, so keying on it (even before we know it's real)
    // correctly throttles guesses against one real, discovered student.
    const studentIdKey = body.student_id ? String(body.student_id) : null;
    const secondary: SecondaryKey = studentIdKey
      ? { column: "student_id", value: studentIdKey }
      : null;

    const limit = await checkRateLimit(supabase, ipHash, null, secondary);
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

      const supplied = body.pin ? await hashSecret(body.pin, PIN_HASH_SALT) : null;
      if (!supplied || !pinRow || supplied !== pinRow.pin_hash) {
        return json(
          { error: "Diese Bilder passen noch nicht zusammen. Versuch es noch einmal." },
          401,
        );
      }
    }

    const token = await signStudentToken(student.id, STUDENT_JWT_SECRET);
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
