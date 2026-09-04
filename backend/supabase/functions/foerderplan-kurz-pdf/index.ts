// POST /foerderplan-kurz-pdf
// Body: { session_id: string }
// Generates a two-page A4 landscape Förderplan (Kurzförderplan).
// Page 1: table with Ist / Soll / Lernweg per domain (A–D) + two fillable columns.
// Page 2: Weitere Vereinbarungen, Gesprächsdokumentation, Unterschriften.
// Ports PdfKurzFoerderplanService.dart and KurzFoerderplanService.dart
// (rewritten per tasks.md R4.3: domain-based grouping, neutral wording).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  PDFDocument,
  PDFFont,
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

const DOMAIN_PATTERN = /^([A-D])\d/;

function catColor(cat: string): [number, number, number] {
  for (const [domain, label] of Object.entries(DOMAIN_LABELS)) {
    if (label === cat) return DOMAIN_COLORS[domain]!;
  }
  return DEFAULT_COLOR;
}

// ── Date formatting (header "von" box) ────────────────────────────────────────

function formatGermanDate(value: string | Date | null | undefined): string {
  if (!value) return "";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return "";
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  return `${dd}.${mm}.${d.getFullYear()}`;
}

// ── Text wrapping helper ──────────────────────────────────────────────────────

function wrapText(text: string, maxWidth: number, fontSize: number, font: PDFFont): string[] {
  const lines: string[] = [];
  for (const para of text.split("\n")) {
    if (para === "") { lines.push(""); continue; }
    const words = para.split(" ");
    let current = "";
    for (const word of words) {
      const candidate = current ? `${current} ${word}` : word;
      if (font.widthOfTextAtSize(candidate, fontSize) > maxWidth && current) {
        lines.push(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current) lines.push(current);
  }
  return lines;
}

// ── KurzFoerderplan data assembly (port of KurzFoerderplanService.dart) ──────

interface SkillRow {
  id: string;
  category: string;
  color: string;
  title_de: string;
  description_de: string;
}

interface KurzRow {
  category: string;
  ist: string;
  soll: string;
  lernweg: string;
}

function groupLabel(s: SkillRow): string {
  const m = DOMAIN_PATTERN.exec(s.id);
  if (m) return DOMAIN_LABELS[m[1]] ?? s.category;
  return s.category;
}

function orderedGroupLabels(labels: string[]): string[] {
  const domainLabels = Object.values(DOMAIN_LABELS);
  const rank = (l: string): number => {
    const idx = domainLabels.indexOf(l);
    return idx === -1 ? domainLabels.length : idx;
  };
  return [...labels].sort((a, b) => {
    const ra = rank(a);
    const rb = rank(b);
    if (ra !== rb) return ra - rb;
    return a.localeCompare(b, "de");
  });
}

function buildKurzRows(
  recommended: SkillRow[],
  categoryStats: Record<string, { failed: number; total: number }>,
  slowResponseFlag: boolean,
): KurzRow[] {
  const byGroup = new Map<string, SkillRow[]>();
  for (const s of recommended) {
    const label = groupLabel(s);
    if (!byGroup.has(label)) byGroup.set(label, []);
    byGroup.get(label)!.push(s);
  }

  const rows: KurzRow[] = [];
  let firstRow = true;
  for (const label of orderedGroupLabels(Array.from(byGroup.keys()))) {
    const skills = byGroup.get(label)!;
    const stats = categoryStats[label];

    // Ist
    const istParts: string[] = [];
    if (stats && stats.failed > 0) {
      istParts.push(`Im Bereich ${label} wurden ${stats.failed} von ${stats.total} Aufgaben nicht gelöst.`);
    } else {
      istParts.push(`Im Bereich ${label} besteht Förderbedarf.`);
    }
    istParts.push("Beobachtete Schwierigkeiten:");
    for (const s of skills) istParts.push(`- ${s.title_de}`);
    if (firstRow && slowResponseFlag) {
      istParts.push("Hinweis: Kind löst Aufgaben zählend statt denkend (verlangsamte Antwortzeiten).");
    }

    // Soll
    const soll = skills.map((s) => `- Das Kind kann: ${s.description_de}`).join("\n");

    // Lernweg
    const lernParts = ["Fördervorschläge:"];
    for (const s of skills) {
      lernParts.push(`- ${s.title_de}`);
      lernParts.push(`  ${s.description_de}`);
    }

    rows.push({ category: label, ist: istParts.join("\n"), soll, lernweg: lernParts.join("\n") });
    firstRow = false;
  }
  return rows;
}

// ── Edge function ────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
  if (req.method !== "POST") return errJson({ error: "Method not allowed" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let body: { session_id?: string };
  try {
    body = await req.json();
  } catch {
    return errJson({ error: "Invalid JSON body" }, 400);
  }

  const { session_id } = body;
  if (!session_id) return errJson({ error: "session_id required" }, 400);

  // Check cache
  const cachedPath = `kurz/${session_id}.pdf`;
  const { data: cached } = await supabase.storage.from("pdf-cache").download(cachedPath);
  if (cached) {
    const bytes = await cached.arrayBuffer();
    return pdfResponse(new Uint8Array(bytes), "Foerderplan.pdf");
  }

  // Load plan
  const { data: plan } = await supabase
    .from("foerderplaene")
    .select("*")
    .eq("session_id", session_id)
    .single();

  if (!plan) return errJson({ error: "Förderplan not found. Generate it first." }, 404);

  // Load session and student
  const { data: session } = await supabase
    .from("diagnostic_sessions")
    .select("student_id, started_at")
    .eq("id", session_id)
    .single();

  const { data: student } = await supabase
    .from("students")
    .select("display_name")
    .eq("id", session?.student_id ?? "")
    .single();

  // Load skills
  const { data: skillsData } = await supabase
    .from("skills")
    .select("id, category, color, title_de, description_de")
    .in("id", plan.recommended_skill_ids as string[]);

  const skillMap = new Map(
    (skillsData ?? []).map((s: SkillRow) => [s.id, s]),
  );
  const recommended = (plan.recommended_skill_ids as string[])
    .map((id) => skillMap.get(id))
    .filter(Boolean) as SkillRow[];

  const kurzRows = buildKurzRows(
    recommended,
    plan.category_stats as Record<string, { failed: number; total: number }>,
    plan.slow_response_flag as boolean,
  );

  // ── Build PDF ──────────────────────────────────────────────────────────────

  const pdfDoc = await PDFDocument.create();
  const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const fontReg = await pdfDoc.embedFont(StandardFonts.Helvetica);

  // A4 landscape
  const PW = 841.89, PH = 595.28;
  const ML = 20, MR = 20, MT = 20, MB = 20;
  const contentW = PW - ML - MR; // ~801

  // Column widths
  const catW = 52;
  const flexW = contentW - catW;
  const istW = Math.floor(flexW * 0.22);
  const sollW = Math.floor(flexW * 0.20);
  const lernW = Math.floor(flexW * 0.22);
  const absW = Math.floor(flexW * 0.18);
  const refW = contentW - catW - istW - sollW - lernW - absW;

  // Column left x positions
  const catX = ML;
  const istX = catX + catW;
  const sollX = istX + istW;
  const lernX = sollX + sollW;
  const absX = lernX + lernW;
  const refX = absX + absW;

  const CELL_PAD = 4;
  const FS = 7; // base font size
  const LINE_H = FS + 2.5;

  function cellLines(text: string, colW: number): string[] {
    return wrapText(text, colW - CELL_PAD * 2, FS, fontReg);
  }

  function cellHeight(lines: string[]): number {
    return lines.length * LINE_H + CELL_PAD * 2;
  }

  // ── PAGE 1 ─────────────────────────────────────────────────────────────────
  const page1 = pdfDoc.addPage([PW, PH]);

  let y = PH - MT;

  // Title
  page1.drawText("Förderplan", { x: ML, y, size: 16, font: fontBold, color: rgb(0, 0, 0) });
  y -= 22;

  // Name row
  page1.drawText("Name der Schülerin / des Schülers:", { x: ML, y, size: 8, font: fontReg, color: rgb(0.2, 0.2, 0.2) });
  const nameVal = student?.display_name ?? "";
  if (nameVal) {
    page1.drawText(nameVal, { x: ML + 165, y, size: 8, font: fontBold, color: rgb(0, 0, 0) });
  }
  // underline box
  page1.drawRectangle({ x: ML + 162, y: y - 3, width: 200, height: 13, color: rgb(0.96, 0.96, 0.96), borderColor: rgb(0.75, 0.75, 0.75), borderWidth: 0.5 });
  y -= 18;

  // Time period row
  page1.drawText("Für die Zeit von:", { x: ML, y, size: 8, font: fontReg, color: rgb(0.2, 0.2, 0.2) });
  page1.drawRectangle({ x: ML + 85, y: y - 3, width: 90, height: 13, color: rgb(0.96, 0.96, 0.96), borderColor: rgb(0.75, 0.75, 0.75), borderWidth: 0.5 });
  const vonDate = formatGermanDate(session?.started_at as string | null | undefined);
  if (vonDate) {
    page1.drawText(vonDate, { x: ML + 89, y, size: 8, font: fontBold, color: rgb(0, 0, 0) });
  }
  page1.drawText("bis:", { x: ML + 185, y, size: 8, font: fontReg, color: rgb(0.2, 0.2, 0.2) });
  page1.drawRectangle({ x: ML + 200, y: y - 3, width: 90, height: 13, color: rgb(0.96, 0.96, 0.96), borderColor: rgb(0.75, 0.75, 0.75), borderWidth: 0.5 });
  y -= 20;

  // ── Table ──────────────────────────────────────────────────────────────────

  // Header row
  const headers = [
    { x: catX, w: catW, label: "" },
    { x: istX, w: istW, label: "Beobachtung / Bedarf\n(= Stellungnahme)" },
    { x: sollX, w: sollW, label: "Ziele" },
    { x: lernX, w: lernW, label: "Päd. Angebote /\nMaßnahmen /\nLernarrangements" },
    { x: absX, w: absW, label: "Absprachen\n(Wer? Wie?\nMit wem? Bis wann?)" },
    { x: refX, w: refW, label: "Reflexion /\nEvaluation /\nModifikation" },
  ];

  // Calculate header row height
  const headerH = headers.reduce((max, h) => {
    const ls = cellLines(h.label, h.w);
    return Math.max(max, cellHeight(ls));
  }, 22);

  // Draw header background
  page1.drawRectangle({ x: ML, y: y - headerH, width: contentW, height: headerH, color: rgb(0.88, 0.88, 0.88) });

  // Draw header text and borders
  for (const h of headers) {
    const ls = cellLines(h.label, h.w);
    let ty = y - CELL_PAD - LINE_H;
    for (const line of ls) {
      page1.drawText(line, { x: h.x + CELL_PAD, y: ty, size: FS, font: fontBold, color: rgb(0.1, 0.1, 0.1) });
      ty -= LINE_H;
    }
    // vertical divider
    page1.drawLine({ start: { x: h.x, y: y }, end: { x: h.x, y: y - headerH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
  }
  // right border
  page1.drawLine({ start: { x: ML + contentW, y }, end: { x: ML + contentW, y: y - headerH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
  // top border
  page1.drawLine({ start: { x: ML, y }, end: { x: ML + contentW, y }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
  // bottom border
  page1.drawLine({ start: { x: ML, y: y - headerH }, end: { x: ML + contentW, y: y - headerH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
  y -= headerH;

  if (kurzRows.length === 0) {
    // empty state
    const emptyH = 30;
    page1.drawText("Keine Förderschwerpunkte erkannt – herzlichen Glückwunsch!", {
      x: ML + CELL_PAD,
      y: y - CELL_PAD - FS,
      size: 9,
      font: fontReg,
      color: rgb(0.4, 0.4, 0.4),
    });
    page1.drawLine({ start: { x: ML, y: y - emptyH }, end: { x: ML + contentW, y: y - emptyH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
    y -= emptyH;
  } else {
    for (const row of kurzRows) {
      const cc = catColor(row.category);

      // Pre-compute all cell lines to determine row height
      const catTextLines = wrapText(row.category, catW - 8, FS - 0.5, fontBold);
      const istLines = cellLines(row.ist, istW);
      const sollLines = cellLines(row.soll, sollW);
      const lernLines = cellLines(row.lernweg, lernW);
      const fillLines = ["Hier eintragen …"];
      const rowH = Math.max(
        cellHeight(catTextLines),
        cellHeight(istLines),
        cellHeight(sollLines),
        cellHeight(lernLines),
        cellHeight(fillLines),
        30,
      );

      // Category colored left border
      page1.drawRectangle({ x: catX, y: y - rowH, width: 3, height: rowH, color: rgb(...cc) });

      // Category label
      let ty = y - CELL_PAD - LINE_H;
      for (const line of catTextLines) {
        page1.drawText(line, { x: catX + 5, y: ty, size: FS - 0.5, font: fontBold, color: rgb(...cc) });
        ty -= LINE_H;
      }

      // Ist
      ty = y - CELL_PAD - LINE_H;
      for (const line of istLines) {
        page1.drawText(line, { x: istX + CELL_PAD, y: ty, size: FS, font: fontReg, color: rgb(0.1, 0.1, 0.1) });
        ty -= LINE_H;
      }

      // Soll
      ty = y - CELL_PAD - LINE_H;
      for (const line of sollLines) {
        page1.drawText(line, { x: sollX + CELL_PAD, y: ty, size: FS, font: fontReg, color: rgb(0.1, 0.1, 0.1) });
        ty -= LINE_H;
      }

      // Lernweg
      ty = y - CELL_PAD - LINE_H;
      for (const line of lernLines) {
        page1.drawText(line, { x: lernX + CELL_PAD, y: ty, size: FS, font: fontReg, color: rgb(0.1, 0.1, 0.1) });
        ty -= LINE_H;
      }

      // Fillable cells (grey background + placeholder)
      for (const [colX, colW] of [[absX, absW], [refX, refW]] as [number, number][]) {
        page1.drawRectangle({ x: colX, y: y - rowH, width: colW, height: rowH, color: rgb(0.97, 0.97, 0.97) });
        page1.drawText("Hier eintragen …", {
          x: colX + CELL_PAD,
          y: y - CELL_PAD - FS,
          size: FS - 0.5,
          font: fontReg,
          color: rgb(0.7, 0.7, 0.7),
        });
      }

      // Row borders
      for (const colX of [catX, istX, sollX, lernX, absX, refX]) {
        page1.drawLine({ start: { x: colX, y }, end: { x: colX, y: y - rowH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
      }
      page1.drawLine({ start: { x: ML + contentW, y }, end: { x: ML + contentW, y: y - rowH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });
      page1.drawLine({ start: { x: ML, y: y - rowH }, end: { x: ML + contentW, y: y - rowH }, thickness: 0.5, color: rgb(0.6, 0.6, 0.6) });

      y -= rowH;
    }
  }

  // Footer page 1
  page1.drawText("Wissenschaftliche Grundlagen: Padberg & Benz (2021); Wartha & Schulz (2019)", {
    x: ML,
    y: MB,
    size: 7,
    font: fontReg,
    color: rgb(0.7, 0.7, 0.7),
  });
  page1.drawText("Erstellt mit Numeris", {
    x: PW - MR - 80,
    y: MB,
    size: 7,
    font: fontReg,
    color: rgb(0.7, 0.7, 0.7),
  });

  // ── PAGE 2 ─────────────────────────────────────────────────────────────────
  const page2 = pdfDoc.addPage([PW, PH]);
  y = PH - MT;

  function p2Text(text: string, x: number, yy: number, size: number, bold = false) {
    page2.drawText(text, { x, y: yy, size, font: bold ? fontBold : fontReg, color: rgb(0, 0, 0) });
  }

  function p2Box(x: number, yy: number, w: number, h: number, filled = true) {
    page2.drawRectangle({
      x, y: yy, width: w, height: h,
      color: filled ? rgb(0.96, 0.96, 0.96) : undefined,
      borderColor: rgb(0.7, 0.7, 0.7),
      borderWidth: 0.5,
    });
  }

  // Weitere Vereinbarungen
  p2Text("Weitere Vereinbarungen", ML, y, 12, true);
  y -= 16;
  p2Box(ML, y - 120, contentW, 120);
  page2.drawText("Hier eintragen …", { x: ML + 6, y: y - 14, size: 8, font: fontReg, color: rgb(0.7, 0.7, 0.7) });
  y -= 136;

  // Gesprächsdokumentation
  p2Text("Gesprächsdokumentation", ML, y, 12, true);
  y -= 18;
  p2Text("Gespräch wurde durchgeführt am:", ML, y, 9);
  p2Box(ML + 155, y - 3, 90, 14);
  p2Text("mit:", ML + 255, y, 9);
  p2Box(ML + 275, y - 3, 200, 14);
  y -= 30;

  // Unterschriften
  p2Text("Unterschrift der Anwesenden", ML, y, 12, true);
  y -= 24;
  const sigW = (contentW - 32) / 2;
  page2.drawLine({ start: { x: ML, y }, end: { x: ML + sigW, y }, thickness: 0.5, color: rgb(0.5, 0.5, 0.5) });
  page2.drawLine({ start: { x: ML + sigW + 32, y }, end: { x: ML + contentW, y }, thickness: 0.5, color: rgb(0.5, 0.5, 0.5) });
  y -= 8;
  p2Text("Unterschrift Lehrkraft", ML + sigW / 2 - 45, y, 7.5);
  p2Text("Unterschrift Eltern/Erziehungsberechtigte", ML + sigW + 32 + sigW / 2 - 65, y, 7.5);
  y -= 30;

  // Information der Erziehungsberechtigten
  p2Text("Information der Erziehungsberechtigten", ML, y, 12, true);
  y -= 12;
  p2Text("Wenn nicht anwesend, Information an die Erziehungsberechtigten.", ML, y, 8.5);
  y -= 18;
  p2Text("Datum:", ML, y, 9);
  p2Box(ML + 42, y - 3, 90, 14);
  const sigX2 = ML + 170;
  page2.drawLine({ start: { x: sigX2, y }, end: { x: ML + contentW, y }, thickness: 0.5, color: rgb(0.5, 0.5, 0.5) });
  y -= 10;
  p2Text("Unterschrift Erziehungsberechtigte/r", sigX2 + (contentW - 170) / 2 - 60, y, 7.5);

  // Footer page 2
  page2.drawText("Wissenschaftliche Grundlagen: Padberg & Benz (2021); Wartha & Schulz (2019)", {
    x: ML,
    y: MB,
    size: 7,
    font: fontReg,
    color: rgb(0.7, 0.7, 0.7),
  });
  page2.drawText("Erstellt mit Numeris", {
    x: PW - MR - 80,
    y: MB,
    size: 7,
    font: fontReg,
    color: rgb(0.7, 0.7, 0.7),
  });

  // ── Save and cache ──────────────────────────────────────────────────────────
  const pdfBytes = await pdfDoc.save();

  await supabase.storage
    .from("pdf-cache")
    .upload(cachedPath, pdfBytes, { contentType: "application/pdf", upsert: true });

  return pdfResponse(pdfBytes, "Foerderplan.pdf");
});

function pdfResponse(bytes: Uint8Array, filename: string) {
  // Copy into a plain ArrayBuffer (see foerderplan-pdf): Deno's newer TS libs
  // reject Uint8Array<ArrayBufferLike> as a Response body; the copy preserves
  // exactly the byte range of `bytes`.
  const body = new Uint8Array(bytes).buffer;
  return new Response(body, {
    headers: {
      ...corsHeaders,
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="${filename}"`,
    },
  });
}

function errJson(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
