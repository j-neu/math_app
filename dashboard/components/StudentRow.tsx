"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import QRCode from "react-qr-code";
import { createClient } from "@/lib/supabase/client";

// 32-char charset: uppercase letters + digits, no 0/O/1/I/L to avoid misreads
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
function generateShortCode(): string {
  return Array.from({ length: 4 }, () => CODE_CHARS[Math.floor(Math.random() * 32)]).join("");
}

interface DiagnosticSession {
  id: string;
  status: string;
  completed_at: string;
  started_at: string;
  ticket_id: string | null;
  diagnostic_results: { id: string }[];
}

interface Student {
  id: string;
  display_name: string;
  age: number | null;
  external_ref: string | null;
  diagnostic_sessions: DiagnosticSession[];
}

interface Props {
  student: Student;
  diagnosticId: string;
  totalQuestions?: number;
}

const STATUS_LABEL: Record<string, { label: string; className: string }> = {
  in_progress: { label: "In Bearbeitung", className: "text-yellow-700 bg-yellow-50" },
  completed: { label: "Abgeschlossen", className: "text-green-700 bg-green-50" },
  abandoned: { label: "Abgebrochen", className: "text-gray-500 bg-gray-50" },
};

export function StudentRow({ student, diagnosticId, totalQuestions }: Props) {
  const [ticketUrl, setTicketUrl] = useState<string | null>(null);
  const [shortCode, setShortCode] = useState<string | null>(null);
  const [generating, setGenerating] = useState(false);
  const [generatingRetry, setGeneratingRetry] = useState(false);
  const [showQr, setShowQr] = useState(false);
  const [isRetryTicket, setIsRetryTicket] = useState(false);
  const [abbreviatedMode, setAbbreviatedMode] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const router = useRouter();

  const sessions = student.diagnostic_sessions ?? [];
  // Discard ghost sessions: in_progress with 0 results (created by page-refresh before fix).
  // Keep completed sessions (always real) and in_progress sessions that have ≥1 answer.
  const realSessions = sessions
    .slice()
    .sort((a, b) => new Date(b.started_at ?? 0).getTime() - new Date(a.started_at ?? 0).getTime())
    .filter((s) => s.status === "completed" || (s.diagnostic_results?.length ?? 0) > 0);
  const latest = realSessions[0];
  const answeredCount = latest?.diagnostic_results?.length ?? 0;
  const latestCompleted = realSessions.find((s) => s.status === "completed");

  async function generateTicket() {
    setGenerating(true);
    setIsRetryTicket(false);
    const supabase = createClient();

    // Priority 1: If there is an active in_progress session (with answers), reuse its
    // ticket so the student can resume using the same code they already have.
    const inProgressSession = realSessions.find((s) => s.status === "in_progress");
    if (inProgressSession?.ticket_id) {
      const { data: ticket } = await supabase
        .from("session_tickets")
        .select("id, short_code")
        .eq("id", inProgressSession.ticket_id)
        .single();
      if (ticket) {
        const base = process.env.NEXT_PUBLIC_STUDENT_APP_URL ?? window.location.origin;
        setTicketUrl(`${base}/s/${ticket.id}`);
        setShortCode(ticket.short_code ?? "");
        setShowQr(true);
        setGenerating(false);
        return;
      }
    }

    // Priority 2: Unconsumed ticket (session not yet started) — reuse it.
    const { data: unconsumed } = await supabase
      .from("session_tickets")
      .select("id, short_code")
      .eq("student_id", student.id)
      .eq("diagnostic_id", diagnosticId)
      .is("consumed_at", null)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    let ticketId: string;
    let code: string;

    if (unconsumed) {
      ticketId = unconsumed.id;
      code = unconsumed.short_code ?? "";
    } else {
      // Priority 3: No active session, no unconsumed ticket — create a fresh one.
      const newCode = generateShortCode();
      const { data } = await supabase
        .from("session_tickets")
        .insert({
          student_id: student.id,
          diagnostic_id: diagnosticId,
          short_code: newCode,
          abbreviated_mode: abbreviatedMode,
        })
        .select("id, short_code")
        .single();
      if (!data) { setGenerating(false); return; }
      ticketId = data.id;
      code = data.short_code ?? newCode;
    }

    const base = process.env.NEXT_PUBLIC_STUDENT_APP_URL ?? window.location.origin;
    setTicketUrl(`${base}/s/${ticketId}`);
    setShortCode(code);
    setShowQr(true);
    setGenerating(false);
  }

  async function generateRetryTicket() {
    if (!latestCompleted) return;
    setGeneratingRetry(true);
    setIsRetryTicket(true);
    const supabase = createClient();

    const newCode = generateShortCode();
    const { data } = await supabase
      .from("session_tickets")
      .insert({
        student_id: student.id,
        diagnostic_id: diagnosticId,
        short_code: newCode,
        retry_mode: true,
        retry_session_id: latestCompleted.id,
      })
      .select("id, short_code")
      .single();

    if (!data) { setGeneratingRetry(false); return; }

    const base = process.env.NEXT_PUBLIC_STUDENT_APP_URL ?? window.location.origin;
    setTicketUrl(`${base}/s/${data.id}`);
    setShortCode(data.short_code ?? newCode);
    setShowQr(true);
    setGeneratingRetry(false);
  }

  async function deleteStudent() {
    if (!confirm(`Schüler/in "${student.display_name}" wirklich löschen?`)) return;
    setDeleting(true);
    const supabase = createClient();
    await supabase.from("students").delete().eq("id", student.id);
    router.refresh();
  }

  return (
    <>
      <div className="flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-sm font-medium text-gray-500">
            {student.display_name.charAt(0).toUpperCase()}
          </div>
          <div>
            <Link href={`/dashboard/students/${student.id}`} className="font-medium text-sm hover:text-blue-600 hover:underline">
              {student.display_name}
            </Link>
            {latest && (
              <div className="flex items-center gap-2 mt-0.5">
                <span className={`text-xs px-1.5 py-0.5 rounded ${STATUS_LABEL[latest.status]?.className ?? ""}`}>
                  {STATUS_LABEL[latest.status]?.label ?? latest.status}
                </span>
                {latest.status === "in_progress" && answeredCount > 0 && (
                  <span className="text-xs text-gray-400">
                    {answeredCount}{totalQuestions ? ` / ${totalQuestions}` : ""} Fragen
                  </span>
                )}
                {answeredCount > 0 && (
                  <Link
                    href={`/dashboard/foerderplan/${latest.id}`}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    {latest.status === "in_progress" ? "Vorläufiger Förderplan" : "Förderplan ansehen"}
                  </Link>
                )}
              </div>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Abbreviated mode toggle — only relevant when creating a fresh ticket */}
          <label className="flex items-center gap-1.5 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={abbreviatedMode}
              onChange={(e) => setAbbreviatedMode(e.target.checked)}
              className="w-3.5 h-3.5 rounded"
            />
            <span className="text-xs text-gray-500">Verkürzt</span>
          </label>

          <button
            onClick={generateTicket}
            disabled={generating || generatingRetry}
            className="text-sm bg-gray-900 hover:bg-gray-700 disabled:opacity-50 text-white px-3 py-1.5 rounded-lg transition-colors"
          >
            {generating ? "…" : "Diagnostik starten"}
          </button>

          {/* Retry button — only visible when there is a completed session */}
          {latestCompleted && (
            <button
              onClick={generateRetryTicket}
              disabled={generating || generatingRetry}
              className="text-sm border border-gray-300 hover:border-gray-400 text-gray-700 disabled:opacity-50 px-3 py-1.5 rounded-lg transition-colors"
              title="Nur falsche Antworten wiederholen"
            >
              {generatingRetry ? "…" : "Falsche wiederholen"}
            </button>
          )}

          <button
            onClick={deleteStudent}
            disabled={deleting}
            className="text-sm text-gray-400 hover:text-red-600 px-2 py-1.5 transition-colors"
            title="Schüler/in löschen"
          >
            ✕
          </button>
        </div>
      </div>

      {/* QR code modal */}
      {showQr && ticketUrl && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-8 w-full max-w-sm shadow-2xl text-center space-y-6">
            <div>
              <h3 className="text-lg font-semibold">
                {isRetryTicket ? "Falsche Antworten wiederholen" : "Diagnostik starten"}
              </h3>
              <p className="text-sm text-gray-500 mt-1">
                {student.display_name} — QR-Code scannen oder Link öffnen
              </p>
              {isRetryTicket && (
                <p className="text-xs text-amber-600 mt-1">
                  Nur falsch beantwortete Fragen der letzten Diagnostik
                </p>
              )}
            </div>

            <div className="bg-white p-4 border border-gray-200 rounded-xl inline-block">
              <QRCode value={ticketUrl} size={200} />
            </div>

            <div className="bg-gray-50 rounded-lg px-3 py-2">
              <p className="text-xs text-gray-400 break-all font-mono">{ticketUrl}</p>
            </div>

            {shortCode && (
              <div className="bg-gray-50 rounded-lg px-3 py-3">
                <p className="text-xs text-gray-400 mb-1">Oder: Code eingeben unter <span className="font-mono text-gray-600">/s/&lt;schulname&gt;</span></p>
                <p className="text-3xl font-mono font-bold tracking-widest text-gray-800">{shortCode}</p>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => window.print()}
                className="flex-1 border border-gray-200 text-gray-700 text-sm font-medium py-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Drucken
              </button>
              <button
                onClick={() => setShowQr(false)}
                className="flex-1 bg-gray-900 text-white text-sm font-medium py-2 rounded-lg hover:bg-gray-700 transition-colors"
              >
                Schließen
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
