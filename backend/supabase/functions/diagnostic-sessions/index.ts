// POST /diagnostic-sessions
// Body: { ticket_id: string }
// Validates the session ticket, creates a diagnostic_session row, marks
// ticket as consumed. Returns { session_id }.
//
// Uses service-role key (set in Supabase secrets as SUPABASE_SERVICE_ROLE_KEY).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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

  let body: { ticket_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { ticket_id } = body;
  if (!ticket_id) return json({ error: "ticket_id required" }, 400);

  // Load ticket
  const { data: ticket, error: tErr } = await supabase
    .from("session_tickets")
    .select("id, student_id, diagnostic_id, expires_at, consumed_at")
    .eq("id", ticket_id)
    .single();

  if (tErr || !ticket) return json({ error: "Ticket not found" }, 404);

  const now = new Date();
  if (new Date(ticket.expires_at) < now) {
    return json({ error: "Ticket expired" }, 410);
  }

  // Check for an existing in-progress session on this ticket (resume support)
  const { data: existing } = await supabase
    .from("diagnostic_sessions")
    .select("id, status")
    .eq("ticket_id", ticket_id)
    .in("status", ["in_progress"])
    .maybeSingle();

  if (existing) {
    return json({ session_id: existing.id, resumed: true });
  }

  // Mark ticket consumed (idempotent after first use)
  if (!ticket.consumed_at) {
    await supabase
      .from("session_tickets")
      .update({ consumed_at: now.toISOString() })
      .eq("id", ticket_id);
  }

  // Create session
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

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
