// POST /api/bulk-qr-pdf
// Body: { class_id: string }
// Creates permanent session tickets for every student in the class, renders one
// printable A4 PDF with two cards per page (QR code + short entry code), and
// returns it as application/pdf.

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { PDFDocument, rgb, StandardFonts } from "pdf-lib";
import QRCode from "qrcode";

const DIAG_ID = "00000000-0000-0000-0000-000000000001";
const QR_SIZE = 160;
const W = 595;
const H = 842;
const MARGIN = 40;

// 32-char charset: uppercase + digits, no 0/O/1/I/L
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
function generateCode(): string {
  return Array.from({ length: 4 }, () => CODE_CHARS[Math.floor(Math.random() * 32)]).join("");
}
function generateUniqueCodes(count: number): string[] {
  const seen: Record<string, true> = {};
  const codes: string[] = [];
  while (codes.length < count) {
    const c = generateCode();
    if (!seen[c]) { seen[c] = true; codes.push(c); }
  }
  return codes;
}

export async function POST(req: NextRequest) {
  const supabase = await createClient();

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return errJson("Nicht angemeldet", 401);

  const { class_id } = await req.json();
  if (!class_id) return errJson("class_id required", 400);

  // Verify teacher owns this class's school
  const [{ data: klass }, { data: teacher }] = await Promise.all([
    supabase.from("classes").select("id, name, school_id").eq("id", class_id).single(),
    supabase.from("teachers").select("school_id").eq("id", user.id).single(),
  ]);

  if (!klass) return errJson("Klasse nicht gefunden", 404);
  if (teacher?.school_id !== klass.school_id) return errJson("Keine Berechtigung", 403);

  // Fetch school slug for the short-URL display
  const { data: school } = await supabase
    .from("schools")
    .select("slug")
    .eq("id", klass.school_id)
    .single();
  const schoolSlug = school?.slug ?? null;

  const { data: students } = await supabase
    .from("students")
    .select("id, display_name")
    .eq("class_id", class_id)
    .order("display_name");

  if (!students || students.length === 0) {
    return errJson("Keine Schüler/innen in dieser Klasse", 400);
  }

  const baseUrl = process.env.NEXT_PUBLIC_STUDENT_APP_URL ?? "http://localhost:3000";
  const nameById = new Map(students.map((s) => [s.id, s.display_name]));

  // Reuse existing unconsumed tickets so codes stay stable across PDF regenerations
  const { data: existingTickets } = await supabase
    .from("session_tickets")
    .select("id, student_id, short_code")
    .in("student_id", students.map((s) => s.id))
    .eq("diagnostic_id", DIAG_ID)
    .is("consumed_at", null)
    .order("created_at", { ascending: false });

  // Keep only the most-recent active ticket per student
  const activeByStudent = new Map<string, { id: string; short_code: string }>();
  for (const t of existingTickets ?? []) {
    if (!activeByStudent.has(t.student_id)) activeByStudent.set(t.student_id, t);
  }

  // Create tickets only for students who don't have one yet
  const needTicket = students.filter((s) => !activeByStudent.has(s.id));
  if (needTicket.length > 0) {
    const codes = generateUniqueCodes(needTicket.length);
    const { data: newTickets, error: ticketErr } = await supabase
      .from("session_tickets")
      .insert(needTicket.map((s, i) => ({ student_id: s.id, diagnostic_id: DIAG_ID, short_code: codes[i] })))
      .select("id, student_id, short_code");

    if (ticketErr || !newTickets) {
      console.error("ticket insert error", ticketErr);
      return errJson("Fehler beim Erstellen der Tickets", 500);
    }
    for (const t of newTickets) activeByStudent.set(t.student_id, t);
  }

  const entries: { name: string; url: string; code: string }[] = students.map((s) => {
    const t = activeByStudent.get(s.id)!;
    return { name: s.display_name, url: `${baseUrl}/s/${t.id}`, code: t.short_code ?? "" };
  });

  // ── Build PDF ──────────────────────────────────────────────────────────────
  const pdfDoc = await PDFDocument.create();
  const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const fontReg = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const fontMono = await pdfDoc.embedFont(StandardFonts.Courier);

  const today = new Date().toLocaleDateString("de-DE");
  const totalPages = Math.ceil(entries.length / 2);

  for (let i = 0; i < entries.length; i += 2) {
    const page = pdfDoc.addPage([W, H]);
    const batch = entries.slice(i, i + 2);

    if (batch.length === 2) {
      page.drawLine({
        start: { x: MARGIN, y: H / 2 },
        end: { x: W - MARGIN, y: H / 2 },
        thickness: 0.5,
        color: rgb(0.78, 0.78, 0.78),
        dashArray: [5, 4],
      });
    }

    for (let j = 0; j < batch.length; j++) {
      const { name, url, code } = batch[j];
      const sectionTop = j === 0 ? H : H / 2;

      const qrBuf = await QRCode.toBuffer(url, { width: QR_SIZE * 2, margin: 1 });
      const qrImage = await pdfDoc.embedPng(qrBuf);

      // ── Class + date header ─────────────────────────────────────────────────
      page.drawText(`${klass.name}  ·  ${today}`, {
        x: MARGIN,
        y: sectionTop - 24,
        size: 9,
        font: fontReg,
        color: rgb(0.55, 0.55, 0.55),
      });

      // ── Student name ────────────────────────────────────────────────────────
      page.drawText(name, {
        x: MARGIN,
        y: sectionTop - 48,
        size: 20,
        font: fontBold,
        color: rgb(0, 0, 0),
      });

      // ── Left column: QR code ────────────────────────────────────────────────
      const qrX = MARGIN;
      const qrTopY = sectionTop - 70;
      page.drawImage(qrImage, {
        x: qrX,
        y: qrTopY - QR_SIZE,
        width: QR_SIZE,
        height: QR_SIZE,
      });

      // Small label under QR
      page.drawText("QR-Code scannen", {
        x: qrX,
        y: qrTopY - QR_SIZE - 12,
        size: 8,
        font: fontReg,
        color: rgb(0.55, 0.55, 0.55),
      });

      // ── Right column: short code ─────────────────────────────────────────────
      const rightX = MARGIN + QR_SIZE + 30;
      const midY = qrTopY - QR_SIZE / 2;  // vertical centre of QR area

      page.drawText("Oder: Code eingeben", {
        x: rightX,
        y: midY + 46,
        size: 9,
        font: fontReg,
        color: rgb(0.4, 0.4, 0.4),
      });

      if (schoolSlug) {
        const shortUrl = `${baseUrl.replace(/^https?:\/\//, "")}/s/${schoolSlug}`;
        page.drawText(shortUrl, {
          x: rightX,
          y: midY + 28,
          size: 8,
          font: fontMono,
          color: rgb(0.3, 0.3, 0.3),
          maxWidth: W - rightX - MARGIN,
        });
      }

      // Big short code
      page.drawRectangle({
        x: rightX - 4,
        y: midY - 14,
        width: 110,
        height: 38,
        color: rgb(0.95, 0.95, 0.95),
        borderColor: rgb(0.8, 0.8, 0.8),
        borderWidth: 1,
      });
      page.drawText(code, {
        x: rightX + 4,
        y: midY - 4,
        size: 28,
        font: fontMono,
        color: rgb(0, 0, 0),
      });

      // URL (tiny, below QR)
      page.drawText(url, {
        x: MARGIN,
        y: qrTopY - QR_SIZE - 24,
        size: 6.5,
        font: fontReg,
        color: rgb(0.55, 0.55, 0.55),
        maxWidth: W - MARGIN * 2,
      });
    }

    // Page footer
    const pageNum = Math.floor(i / 2) + 1;
    page.drawText(`Seite ${pageNum} von ${totalPages}  ·  Prozedia Diagnostik`, {
      x: W / 2 - 70,
      y: 12,
      size: 7,
      font: fontReg,
      color: rgb(0.72, 0.72, 0.72),
    });
  }

  const pdfBytes = Buffer.from(await pdfDoc.save());
  const safeName = klass.name.replace(/[^a-zA-Z0-9_\-äöüÄÖÜß ]/g, "").replace(/\s+/g, "_");

  return new NextResponse(pdfBytes, {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="QR-Codes_${safeName}.pdf"`,
    },
  });
}

function errJson(msg: string, status: number) {
  return NextResponse.json({ error: msg }, { status });
}
