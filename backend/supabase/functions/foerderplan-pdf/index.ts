// GET /foerderplan-pdf?session_id=<uuid>
// Generates and returns a PDF Förderplan for a completed diagnostic session.
// Mirrors the layout of DiagnosticReportScreen:
//   1. Header (student name, date)
//   2. Kurzer Förderplan (top 3 skills)
//   3. Domänen-Übersicht (per-domain pass/fail bar)
//   4. Vollständiger Förderplan (all skills)
//
// Returns PDF bytes (application/pdf).
// Caches the result path in foerderplaene.pdf_storage_path.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  PDFDocument,
  rgb,
  StandardFonts,
} from "https://esm.sh/pdf-lib@1.17.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// New taxonomy (tasks.md R4.3): domain label per skill ID prefix.
const DOMAIN_LABELS: Record<string, string> = {
  A: "Domäne A — Zahlbegriff",
  B: "Domäne B — Stellenwertverständnis",
  C: "Domäne C — Rechenstrategien",
  D: "Domäne D — Sachsituationen",
};

// Row colour derived from the domain for new-taxonomy rows.
const DOMAIN_COLORS: Record<string, [number, number, number]> = {
  A: [0.18, 0.65, 0.35], // emerald
  B: [0.20, 0.46, 0.82], // blue
  C: [0.75, 0.22, 0.17], // red
  D: [0.54, 0.17, 0.65], // purple
};
const DEFAULT_COLOR: [number, number, number] = [0.4, 0.4, 0.4];

// The columns `foerderplan-pdf` reads off a `skills` row. New-taxonomy skills
// carry a `domain` letter (A–D); legacy skills leave it NULL.
interface SkillRow {
  id: string;
  category: string;
  domain: string | null;
  title_de: string;
  description_de: string;
}

function catColor(cat: string): [number, number, number] {
  for (const [domain, label] of Object.entries(DOMAIN_LABELS)) {
    if (label === cat) return DOMAIN_COLORS[domain]!;
  }
  return DEFAULT_COLOR;
}

// Recommendation rows store the short category ("Domäne A") that never equals a
// DOMAIN_LABELS value, so catColor alone renders them all gray. Colour new
// taxonomy rows by their domain letter instead; legacy rows (domain NULL) keep
// the catColor fallback.
function rowColor(s: SkillRow): [number, number, number] {
  if (s.domain) return DOMAIN_COLORS[s.domain] ?? DEFAULT_COLOR;
  return catColor(s.category);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "GET") {
    return errJson({ error: "Method not allowed" }, 405);
  }

  const url = new URL(req.url);
  const session_id = url.searchParams.get("session_id");
  if (!session_id) return errJson({ error: "session_id query parameter required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Load foerderplan
  const { data: plan } = await supabase
    .from("foerderplaene")
    .select("*")
    .eq("session_id", session_id)
    .single();

  if (!plan) return errJson({ error: "Förderplan not found. Generate it first." }, 404);

  // Load session → student name + date
  const { data: session } = await supabase
    .from("diagnostic_sessions")
    .select("started_at, completed_at, student_id")
    .eq("id", session_id)
    .single();

  const { data: student } = await supabase
    .from("students")
    .select("display_name")
    .eq("id", session?.student_id)
    .single();

  // Load skill details for recommended skills
  const { data: skillsData } = await supabase
    .from("skills")
    .select("id, category, domain, title_de, description_de")
    .in("id", plan.recommended_skill_ids as string[]);

  const skillMap = new Map<string, SkillRow>(
    (skillsData ?? []).map((s: SkillRow) => [s.id, s]),
  );
  const recommended = (plan.recommended_skill_ids as string[])
    .map((id: string) => skillMap.get(id))
    .filter((s): s is SkillRow => s !== undefined);
  const brief = recommended.slice(0, 3);

  const studentName = student?.display_name ?? "Unbekannt";
  const sessionDate = session?.completed_at
    ? new Date(session.completed_at).toLocaleDateString("de-DE")
    : new Date().toLocaleDateString("de-DE");

  // Build PDF
  const pdfDoc = await PDFDocument.create();
  const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const fontReg = await pdfDoc.embedFont(StandardFonts.Helvetica);

  const W = 595, H = 842; // A4 points
  const MARGIN = 50;
  const LINE = 16;

  let page = pdfDoc.addPage([W, H]);
  let y = H - MARGIN;

  function newPageIfNeeded(needed = 80) {
    if (y < needed) {
      page = pdfDoc.addPage([W, H]);
      y = H - MARGIN;
    }
  }

  function drawText(
    text: string,
    x: number,
    fontSize: number,
    bold = false,
    color: [number, number, number] = [0, 0, 0],
  ) {
    page.drawText(text, {
      x,
      y,
      size: fontSize,
      font: bold ? fontBold : fontReg,
      color: rgb(...color),
      maxWidth: W - x - MARGIN,
    });
    y -= fontSize + 4;
  }

  function drawHRule(color: [number, number, number] = [0.85, 0.85, 0.85]) {
    page.drawLine({
      start: { x: MARGIN, y },
      end: { x: W - MARGIN, y },
      thickness: 0.5,
      color: rgb(...color),
    });
    y -= 8;
  }

  // ── Header ──────────────────────────────────────────────────────
  drawText("Individueller Förderplan", MARGIN, 20, true);
  drawText(`Schüler/in: ${studentName}`, MARGIN, 11);
  drawText(`Datum: ${sessionDate}`, MARGIN, 11);
  y -= 8;
  drawHRule([0.3, 0.3, 0.3]);
  y -= 4;

  // ── Kurzer Förderplan ────────────────────────────────────────────
  drawText("Kurzer Förderplan (Top 3 Empfehlungen)", MARGIN, 14, true);
  y -= 4;

  if (brief.length === 0) {
    drawText("Keine spezifischen Fördermaßnahmen erforderlich.", MARGIN, 11);
  } else {
    for (let i = 0; i < brief.length; i++) {
      const s = brief[i];
      newPageIfNeeded(60);
      const c = rowColor(s);
      page.drawRectangle({ x: MARGIN, y: y - 2, width: 4, height: 14, color: rgb(...c) });
      drawText(`${i + 1}. ${s.title_de}`, MARGIN + 10, 11, true);
      drawText(s.description_de, MARGIN + 10, 10);
      drawText(`${s.category}`, MARGIN + 10, 9, false, [0.5, 0.5, 0.5]);
      y -= 4;
    }
  }

  y -= 8;
  drawHRule();

  // ── Domänen-Übersicht ─────────────────────────────────────────────
  newPageIfNeeded(100);
  drawText("Domänen-Übersicht", MARGIN, 14, true);
  y -= 4;

  const categoryStats = plan.category_stats as Record<string, { failed: number; total: number }>;
  for (const [cat, stat] of Object.entries(categoryStats)) {
    newPageIfNeeded(40);
    const pct = stat.total > 0 ? (stat.failed / stat.total) : 0;
    const barW = (W - MARGIN * 2 - 180);
    const c = catColor(cat);

    page.drawText(cat, { x: MARGIN, y, size: 10, font: fontReg, color: rgb(0, 0, 0) });
    // background bar
    page.drawRectangle({ x: MARGIN + 180, y: y - 2, width: barW, height: 12, color: rgb(0.9, 0.9, 0.9) });
    // filled portion
    if (pct > 0) {
      page.drawRectangle({ x: MARGIN + 180, y: y - 2, width: barW * pct, height: 12, color: rgb(...c) });
    }
    const pctLabel = `${stat.failed}/${stat.total} falsch`;
    page.drawText(pctLabel, { x: MARGIN + 180 + barW + 6, y, size: 9, font: fontReg, color: rgb(0.4, 0.4, 0.4) });
    y -= 20;
  }

  if (plan.slow_response_flag) {
    y -= 4;
    drawText("⚠ Hinweis: Das Kind zeigt bei korrekten Antworten häufig lange Reaktionszeiten. Mögliches Zeichen für zählendes Rechnen.", MARGIN, 9, false, [0.7, 0.4, 0.0]);
  }

  y -= 8;
  drawHRule();

  // ── Vollständiger Förderplan ──────────────────────────────────────
  newPageIfNeeded(80);
  drawText("Vollständiger Förderplan", MARGIN, 14, true);
  y -= 4;

  if (recommended.length === 0) {
    drawText("Sehr gut! Keine weiteren Fördermaßnahmen notwendig.", MARGIN, 11);
  } else {
    for (let i = 0; i < recommended.length; i++) {
      const s = recommended[i];
      newPageIfNeeded(55);
      const c = rowColor(s);
      page.drawRectangle({ x: MARGIN, y: y - 2, width: 4, height: 14, color: rgb(...c) });
      drawText(`${i + 1}. ${s.title_de}`, MARGIN + 10, 10, true);
      drawText(s.description_de, MARGIN + 10, 9);
      drawText(`${s.category}`, MARGIN + 10, 8, false, [0.5, 0.5, 0.5]);
      y -= 2;
    }
  }

  // Footer on last page
  y = 30;
  page.drawText("Erstellt mit Math App — Individuelle Förderdiagnostik", {
    x: MARGIN,
    y,
    size: 8,
    font: fontReg,
    color: rgb(0.6, 0.6, 0.6),
  });
  y = 20;
  page.drawText("Wissenschaftliche Grundlagen: Padberg & Benz (2021); Wartha & Schulz (2019)", {
    x: MARGIN,
    y,
    size: 7,
    font: fontReg,
    color: rgb(0.6, 0.6, 0.6),
  });

  const pdfBytes = await pdfDoc.save();

  // Cache in Supabase Storage
  const storagePath = `foerderplaene/${session_id}.pdf`;
  await supabase.storage
    .from("pdf-cache")
    .upload(storagePath, pdfBytes, { contentType: "application/pdf", upsert: true });

  await supabase
    .from("foerderplaene")
    .update({ pdf_storage_path: storagePath })
    .eq("session_id", session_id);

  // Copy into a plain ArrayBuffer: Deno's newer TypeScript libs no longer accept
  // a Uint8Array<ArrayBufferLike> view as Response body. `new Uint8Array(bytes)`
  // yields exactly the PDF bytes (offset 0, byteLength = bytes.length).
  const body = new Uint8Array(pdfBytes).buffer;

  return new Response(body, {
    headers: {
      ...corsHeaders,
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="foerderplan-${studentName.replace(/\s+/g, "_")}.pdf"`,
    },
  });
});

function errJson(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
