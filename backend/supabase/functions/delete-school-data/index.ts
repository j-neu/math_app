// DELETE /delete-school-data
// Body: { school_id: string }
//
// Erases all data for a school: classes, students, session tickets,
// diagnostic sessions, results, Förderplaene, and the teacher auth accounts.
// Caller must be authenticated as a school_admin for that school.
//
// Cascade chain (enforced by FK on delete cascade in schema):
//   schools → teachers, classes
//   classes → students
//   students → session_tickets, diagnostic_sessions
//   diagnostic_sessions → diagnostic_results, foerderplaene
//
// Auth.users rows for teachers are NOT covered by the school cascade and
// are deleted explicitly after the school row is removed.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "DELETE" && req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Verify caller is an authenticated teacher
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

  // Use anon client to verify the caller's JWT
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authErr } = await userClient.auth.getUser();
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  let body: { school_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  const { school_id } = body;
  if (!school_id) return json({ error: "school_id required" }, 400);

  // Service-role client for privileged operations
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify caller is a school_admin for this school
  const { data: teacher } = await admin
    .from("teachers")
    .select("id, role")
    .eq("id", user.id)
    .eq("school_id", school_id)
    .single();

  if (!teacher || teacher.role !== "school_admin") {
    return json({ error: "Forbidden: school_admin role required" }, 403);
  }

  // Collect all teacher auth user IDs before deletion (they cascade away with the school row)
  const { data: teachers } = await admin
    .from("teachers")
    .select("id")
    .eq("school_id", school_id);

  const teacherIds = (teachers ?? []).map((t: { id: string }) => t.id);

  // Delete the school — cascades to all associated rows
  const { error: deleteErr } = await admin
    .from("schools")
    .delete()
    .eq("id", school_id);

  if (deleteErr) {
    return json({ error: "Failed to delete school", detail: deleteErr.message }, 500);
  }

  // Delete orphaned auth.users for the former teachers
  const authDeleteErrors: string[] = [];
  for (const id of teacherIds) {
    const { error } = await admin.auth.admin.deleteUser(id);
    if (error) authDeleteErrors.push(`${id}: ${error.message}`);
  }

  return json({
    ok: true,
    school_id,
    teachers_deleted: teacherIds.length,
    auth_errors: authDeleteErrors.length > 0 ? authDeleteErrors : undefined,
  });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
