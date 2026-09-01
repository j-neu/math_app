// POST /diagnostic-results
// Body: { session_id, question_number, was_correct, response_time_seconds, status?, user_answer? }
// Appends one answer to a session. When all questions are answered,
// marks the session as completed.
//
// Also accepts PATCH /diagnostic-results to update an existing answer (resume).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ResultPayload {
  session_id: string;
  question_number: number;
  was_correct: boolean;
  response_time_seconds?: number;
  status?: "attempted" | "skipped" | "timeout";
  user_answer?: string;
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

  let body: ResultPayload;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { session_id, question_number, was_correct, response_time_seconds, user_answer } = body;
  const status = body.status ?? "attempted";

  if (!session_id || question_number == null || was_correct == null) {
    return json({ error: "session_id, question_number and was_correct are required" }, 400);
  }

  // Verify session exists and is in progress
  const { data: session } = await supabase
    .from("diagnostic_sessions")
    .select("id, diagnostic_id, status")
    .eq("id", session_id)
    .single();

  if (!session) return json({ error: "Session not found" }, 404);
  if (session.status !== "in_progress") return json({ error: "Session is not in progress" }, 409);

  // Resolve question UUID from question_number
  const { data: question } = await supabase
    .from("diagnostic_questions")
    .select("id")
    .eq("diagnostic_id", session.diagnostic_id)
    .eq("question_number", question_number)
    .single();

  if (!question) return json({ error: `Question ${question_number} not found` }, 404);

  // Upsert result (handles resume / re-submission)
  const { error: rErr } = await supabase
    .from("diagnostic_results")
    .upsert({
      session_id,
      question_id: question.id,
      was_correct,
      response_time_seconds: response_time_seconds ?? null,
      status,
      user_answer: user_answer ?? null,
      answered_at: new Date().toISOString(),
    }, { onConflict: "session_id,question_id" });

  if (rErr) return json({ error: "Failed to save result", detail: rErr.message }, 500);

  // Check if all questions answered → complete session.
  // The total is the diagnostic's question_count (the core items the child
  // actually answers), NOT the count of rows in diagnostic_questions: the
  // cleanroom bank stores the 32 deep-dive items in the same table (61..92),
  // and the child never answers those in the standard flow. Counting rows
  // would demand 92 answers for a 60-item run and the session would never
  // auto-complete (previously masked by the app's explicit completeSession).
  const { data: diag } = await supabase
    .from("diagnostics")
    .select("question_count")
    .eq("id", session.diagnostic_id)
    .maybeSingle();
  const totalQuestions = diag?.question_count ?? 0;

  const { count: answeredCount } = await supabase
    .from("diagnostic_results")
    .select("id", { count: "exact", head: true })
    .eq("session_id", session_id);

  const completed = (answeredCount ?? 0) >= totalQuestions;
  if (completed) {
    const { error: completeErr } = await supabase
      .from("diagnostic_sessions")
      .update({ status: "completed", completed_at: new Date().toISOString() })
      .eq("id", session_id);
    if (completeErr) {
      console.error("diagnostic-results: session completion update failed:", completeErr);
    }
  }

  return json({ ok: true, session_completed: completed });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
