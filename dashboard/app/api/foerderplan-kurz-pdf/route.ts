import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

const SB_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Nicht angemeldet" }, { status: 401 });

  const sessionId = request.nextUrl.searchParams.get("session_id");
  if (!sessionId) return NextResponse.json({ error: "session_id fehlt" }, { status: 400 });

  const { data: session } = await supabase
    .from("diagnostic_sessions")
    .select("student_id")
    .eq("id", sessionId)
    .single();

  const { data: student } = await supabase
    .from("students")
    .select("display_name")
    .eq("id", session?.student_id ?? "")
    .single();

  const resp = await fetch(`${SB_URL}/functions/v1/foerderplan-kurz-pdf`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ session_id: sessionId }),
  });

  if (!resp.ok) {
    const text = await resp.text();
    return NextResponse.json({ error: text }, { status: resp.status });
  }

  const pdfBytes = await resp.arrayBuffer();
  const safeName = (student?.display_name ?? "").replace(/[\\/:*?"<>|]/g, "").replace(/\s+/g, "_");
  const filename = safeName ? `Foerderplan_${safeName}.pdf` : "Foerderplan.pdf";
  return new NextResponse(pdfBytes, {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="${filename}"`,
    },
  });
}
