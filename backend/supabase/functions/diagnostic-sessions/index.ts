// POST /diagnostic-sessions
//
// Accepts ONE of two body shapes:
//   { ticket_id: string }                       — QR-code flow
//   { school_slug: string, short_code: string } — keyboard-code flow
//
// Validates the ticket, creates (or resumes) a diagnostic_session, marks
// ticket as consumed on first real use.  Returns { session_id, resumed, results? }.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let body: { ticket_id?: string; school_slug?: string; short_code?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  // ── Resolve ticket ID ────────────────────────────────────────────────────────
  let ticket_id: string;

  if (body.ticket_id) {
    ticket_id = body.ticket_id;
  } else if (body.school_slug && body.short_code) {
    const resolved = await resolveShortCode(supabase, body.school_slug, body.short_code.toUpperCase());
    if (!resolved) return json({ error: "Code nicht gefunden" }, 404);
    ticket_id = resolved;
  } else {
    return json({ error: "ticket_id or {school_slug, short_code} required" }, 400);
  }

  // ── Load ticket ──────────────────────────────────────────────────────────────
  const { data: ticket, error: tErr } = await supabase
    .from("session_tickets")
    .select("id, student_id, diagnostic_id, expires_at, consumed_at")
    .eq("id", ticket_id)
    .single();

  if (tErr || !ticket) return json({ error: "Ticket not found" }, 404);

  // Expiry only applies when expires_at is set (NULL = no expiry)
  if (ticket.expires_at && new Date(ticket.expires_at) < new Date()) {
    return json({ error: "Ticket expired" }, 410);
  }

  // ── Resume in-progress session ───────────────────────────────────────────────
  const { data: existing } = await supabase
    .from("diagnostic_sessions")
    .select("id, status")
    .eq("ticket_id", ticket_id)
    .eq("status", "in_progress")
    .maybeSingle();

  if (existing) {
    const { data: priorResults } = await supabase
      .from("diagnostic_results")
      .select(
        "question_id, was_correct, response_time_seconds, status, user_answer, " +
        "diagnostic_questions!inner(question_number)",
      )
      .eq("session_id", existing.id);

    const results = (priorResults ?? []).map((r) => ({
      // deno-lint-ignore no-explicit-any
      question_number: (r.diagnostic_questions as any).question_number as number,
      was_correct: r.was_correct as boolean,
      response_time_seconds: r.response_time_seconds as number | null,
      status: r.status as string,
      user_answer: r.user_answer as string | null,
    }));

    return json({ session_id: existing.id, resumed: true, results });
  }

  // ── Mark ticket consumed (idempotent) ────────────────────────────────────────
  if (!ticket.consumed_at) {
    await supabase
      .from("session_tickets")
      .update({ consumed_at: new Date().toISOString() })
      .eq("id", ticket_id);
  }

  // ── Create session ───────────────────────────────────────────────────────────
  const { data: session, error: sErr } = await supabase
    .from("diagnostic_sessions")
    .insert({
      student_id: ticket.student_id,
      diagnostic_id: ticket.diagnostic_id,
      ticket_id: ticket.id,
      status: "in_progress",
    })
    .select("id")
    .single();

  if (sErr || !session) {
    return json({ error: "Failed to create session", detail: sErr?.message }, 500);
  }

  return json({ session_id: session.id, resumed: false });
});

// ── Helpers ──────────────────────────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
async function resolveShortCode(supabase: any, schoolSlug: string, shortCode: string): Promise<string | null> {
  const { data: school } = await supabase
    .from("schools")
    .select("id")
    .eq("slug", schoolSlug)
    .single();

  if (!school) return null;

  // Find ticket by short_code
  const { data: ticket } = await supabase
    .from("session_tickets")
    .select("id, student_id")
    .eq("short_code", shortCode)
    .single();

  if (!ticket) return null;

  // Verify ticket belongs to this school (via student → class → school)
  const { data: student } = await supabase
    .from("students")
    .select("id, class_id, classes!inner(school_id)")
    .eq("id", ticket.student_id)
    .single();

  // deno-lint-ignore no-explicit-any
  const classRow = Array.isArray(student?.classes) ? student.classes[0] : (student?.classes as any);
  if (classRow?.school_id !== school.id) return null;

  return ticket.id as string;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
