import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  AlignmentType,
  BorderStyle,
  Document,
  HeadingLevel,
  Packer,
  PageOrientation,
  Paragraph,
  ShadingType,
  Table,
  TableCell,
  TableRow,
  TextRun,
  VerticalAlign,
  WidthType,
} from "docx";

const CATEGORY_ORDER = [
  "Zählen",
  "Zahlzerlegung / Schnelles Sehen",
  "Stellenwerte verstehen",
  "Grundstrategien",
  "Kombinierte Strategien",
];

// DXA width in twips for A4 landscape: 16838 twips usable - margins
// Using 6 columns; total ~12000 twips after margins
const COL_WIDTHS_PCT = [6, 19, 17, 19, 19, 20]; // roughly matching Flutter

function shadingFill(hex: string) {
  return { type: ShadingType.CLEAR, color: hex, fill: hex };
}

const FILLABLE_SHADE = shadingFill("F5F5F5");

function headerCell(text: string) {
  return new TableCell({
    shading: shadingFill("DDDDDD"),
    verticalAlign: VerticalAlign.TOP,
    children: [new Paragraph({
      children: [new TextRun({ text, size: 14, bold: true })],
    })],
  });
}

function contentCell(text: string) {
  return new TableCell({
    verticalAlign: VerticalAlign.TOP,
    children: text.split("\n").map((line) =>
      new Paragraph({
        children: [new TextRun({ text: line, size: 14 })],
      })
    ),
  });
}

function fillableCell(placeholder = "Hier eintragen …") {
  return new TableCell({
    shading: FILLABLE_SHADE,
    verticalAlign: VerticalAlign.TOP,
    children: [new Paragraph({
      children: [new TextRun({ text: placeholder, size: 14, color: "AAAAAA", italics: true })],
    })],
  });
}

function categoryCell(label: string) {
  return new TableCell({
    verticalAlign: VerticalAlign.TOP,
    children: [new Paragraph({
      children: [new TextRun({ text: label, size: 12, bold: true, color: "444444" })],
    })],
  });
}

interface SkillRow {
  id: string;
  category: string;
  color: string;
  card_number: number;
  title_de: string;
  description_de: string;
}

function buildKurzRows(
  recommended: SkillRow[],
  categoryStats: Record<string, { failed: number; total: number }>,
  slowResponseFlag: boolean,
) {
  const byCategory = new Map<string, SkillRow[]>();
  for (const s of recommended) {
    if (!byCategory.has(s.category)) byCategory.set(s.category, []);
    byCategory.get(s.category)!.push(s);
  }

  const rows: { category: string; ist: string; soll: string; lernweg: string }[] = [];
  let firstRow = true;
  for (const cat of CATEGORY_ORDER) {
    const skills = byCategory.get(cat);
    if (!skills || skills.length === 0) continue;
    const stats = categoryStats[cat];

    const istParts: string[] = [];
    if (stats && stats.failed > 0) {
      istParts.push(`Im Bereich ${cat} wurden ${stats.failed} von ${stats.total} Aufgaben nicht gelöst.`);
    } else {
      istParts.push(`Im Bereich ${cat} besteht Förderbedarf.`);
    }
    istParts.push("Beobachtete Schwierigkeiten:");
    for (const s of skills) istParts.push(`- ${s.title_de}`);
    if (firstRow && slowResponseFlag) {
      istParts.push("Hinweis: Kind löst Aufgaben zählend statt denkend (verlangsamte Antwortzeiten).");
    }

    const soll = skills.map((s) => `- Das Kind kann: ${s.description_de}`).join("\n");
    const lernParts = ["Fördervorschläge:"];
    for (const s of skills) {
      lernParts.push(`- ${s.title_de}`);
      lernParts.push(`  ${s.description_de}`);
    }

    rows.push({ category: cat, ist: istParts.join("\n"), soll, lernweg: lernParts.join("\n") });
    firstRow = false;
  }
  return rows;
}

function inputRow(label: string, boxWidth = 40) {
  return new Paragraph({
    children: [
      new TextRun({ text: `${label}: `, size: 18 }),
      new TextRun({
        text: "___".repeat(boxWidth / 3),
        size: 18,
        underline: {},
        color: "AAAAAA",
      }),
    ],
    spacing: { after: 200 },
  });
}

function sectionTitle(text: string) {
  return new Paragraph({
    text,
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 400, after: 120 },
  });
}

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Nicht angemeldet" }, { status: 401 });

  const sessionId = request.nextUrl.searchParams.get("session_id");
  if (!sessionId) return NextResponse.json({ error: "session_id fehlt" }, { status: 400 });

  const { data: plan } = await supabase
    .from("foerderplaene")
    .select("*")
    .eq("session_id", sessionId)
    .single();

  if (!plan) return NextResponse.json({ error: "Förderplan nicht gefunden." }, { status: 404 });

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

  const { data: skillsData } = await supabase
    .from("skills")
    .select("id, category, color, card_number, title_de, description_de")
    .in("id", plan.recommended_skill_ids as string[]);

  const skillMap = new Map((skillsData ?? []).map((s: SkillRow) => [s.id, s]));
  const recommended = (plan.recommended_skill_ids as string[])
    .map((id) => skillMap.get(id))
    .filter(Boolean) as SkillRow[];

  const kurzRows = buildKurzRows(
    recommended,
    plan.category_stats as Record<string, { failed: number; total: number }>,
    plan.slow_response_flag as boolean,
  );

  const studentName = student?.display_name ?? "";

  // ── Build table rows ──────────────────────────────────────────────────────

  const tableRows: TableRow[] = [
    // Header
    new TableRow({
      tableHeader: true,
      children: [
        headerCell(""),
        headerCell("Beobachtung / Bedarf\n(= Stellungnahme)"),
        headerCell("Ziele"),
        headerCell("Päd. Angebote /\nMaßnahmen /\nLernarrangements"),
        headerCell("Absprachen\n(Wer? Wie?\nMit wem? Bis wann?)"),
        headerCell("Reflexion /\nEvaluation /\nModifikation"),
      ],
    }),
  ];

  if (kurzRows.length === 0) {
    tableRows.push(
      new TableRow({
        children: [
          new TableCell({
            columnSpan: 6,
            children: [new Paragraph({
              children: [new TextRun({
                text: "Keine Förderschwerpunkte erkannt – herzlichen Glückwunsch!",
                size: 18,
                italics: true,
                color: "888888",
              })],
              alignment: AlignmentType.CENTER,
            })],
          }),
        ],
      }),
    );
  } else {
    for (const row of kurzRows) {
      tableRows.push(
        new TableRow({
          children: [
            categoryCell(row.category),
            contentCell(row.ist),
            contentCell(row.soll),
            contentCell(row.lernweg),
            fillableCell(),
            fillableCell(),
          ],
        }),
      );
    }
  }

  // ── Build document ────────────────────────────────────────────────────────

  const doc = new Document({
    sections: [
      // Page 1 — Förderplan table
      {
        properties: {
          page: {
            size: { orientation: PageOrientation.LANDSCAPE },
            margin: { top: 720, bottom: 720, left: 720, right: 720 },
          },
        },
        children: [
          new Paragraph({
            children: [new TextRun({ text: "Förderplan", size: 36, bold: true })],
            spacing: { after: 200 },
          }),
          new Paragraph({
            children: [
              new TextRun({ text: "Name der Schülerin / des Schülers: ", size: 18 }),
              new TextRun({ text: studentName || "___________________________", size: 18, underline: {} }),
            ],
            spacing: { after: 120 },
          }),
          new Paragraph({
            children: [
              new TextRun({ text: "Für die Zeit von: ", size: 18 }),
              new TextRun({ text: "________________", size: 18, underline: {}, color: "AAAAAA" }),
              new TextRun({ text: "  bis: ", size: 18 }),
              new TextRun({ text: "________________", size: 18, underline: {}, color: "AAAAAA" }),
            ],
            spacing: { after: 240 },
          }),
          new Table({
            width: { size: 100, type: WidthType.PERCENTAGE },
            borders: {
              top: { style: BorderStyle.SINGLE, size: 4, color: "999999" },
              bottom: { style: BorderStyle.SINGLE, size: 4, color: "999999" },
              left: { style: BorderStyle.SINGLE, size: 4, color: "999999" },
              right: { style: BorderStyle.SINGLE, size: 4, color: "999999" },
              insideHorizontal: { style: BorderStyle.SINGLE, size: 4, color: "999999" },
              insideVertical: { style: BorderStyle.SINGLE, size: 4, color: "999999" },
            },
            columnWidths: COL_WIDTHS_PCT.map((p) => Math.round(p * 120)), // relative twips
            rows: tableRows,
          }),
          new Paragraph({
            children: [new TextRun({ text: "Erstellt mit Numeris", size: 12, color: "AAAAAA" })],
            alignment: AlignmentType.RIGHT,
            spacing: { before: 200 },
          }),
        ],
      },

      // Page 2 — Vereinbarungen / Gesprächsdokumentation
      {
        properties: {
          page: {
            size: { orientation: PageOrientation.LANDSCAPE },
            margin: { top: 720, bottom: 720, left: 720, right: 720 },
          },
        },
        children: [
          sectionTitle("Weitere Vereinbarungen"),
          new Paragraph({
            children: [new TextRun({ text: "", size: 18 })],
            shading: FILLABLE_SHADE,
            spacing: { before: 0, after: 0, line: 320 },
          }),
          // large empty box via repeated empty paragraphs
          ...Array.from({ length: 8 }, () =>
            new Paragraph({
              children: [new TextRun({ text: "", size: 28 })],
              shading: FILLABLE_SHADE,
            })
          ),
          sectionTitle("Gesprächsdokumentation"),
          inputRow("Gespräch wurde durchgeführt am", 30),
          inputRow("mit", 60),
          sectionTitle("Unterschrift der Anwesenden"),
          new Paragraph({
            children: [
              new TextRun({ text: "___________________________", size: 18, underline: {} }),
              new TextRun({ text: "          ", size: 18 }),
              new TextRun({ text: "___________________________", size: 18, underline: {} }),
            ],
            spacing: { before: 400, after: 60 },
          }),
          new Paragraph({
            children: [
              new TextRun({ text: "Unterschrift", size: 14, color: "888888" }),
              new TextRun({ text: "                              ", size: 14 }),
              new TextRun({ text: "Unterschrift", size: 14, color: "888888" }),
            ],
            spacing: { after: 400 },
          }),
          sectionTitle("Information der Erziehungsberechtigten"),
          new Paragraph({
            children: [
              new TextRun({ text: "Wenn nicht anwesend, Information an die Erziehungsberechtigten.", size: 18 }),
            ],
            spacing: { after: 200 },
          }),
          inputRow("Datum", 30),
          new Paragraph({
            children: [new TextRun({ text: "Unterschrift Erziehungsberechtigte/r: ___________________________", size: 18 })],
            spacing: { before: 300 },
          }),
          new Paragraph({
            children: [new TextRun({ text: "Erstellt mit Numeris", size: 12, color: "AAAAAA" })],
            alignment: AlignmentType.RIGHT,
            spacing: { before: 600 },
          }),
        ],
      },
    ],
  });

  const buffer = await Packer.toBuffer(doc);
  const bytes = new Uint8Array(buffer);

  const safeName = (studentName || "Schueler").replace(/\s+/g, "_");
  return new NextResponse(bytes, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "Content-Disposition": `attachment; filename="Foerderplan_${safeName}.docx"`,
    },
  });
}
