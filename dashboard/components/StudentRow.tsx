"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import QRCode from "react-qr-code";
import { createClient } from "@/lib/supabase/client";

interface DiagnosticSession {
  id: string;
  status: string;
  completed_at: string;
  started_at: string;
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
}

const STATUS_LABEL: Record<string, { label: string; className: string }> = {
  in_progress: { label: "In Bearbeitung", className: "text-yellow-700 bg-yellow-50" },
  completed: { label: "Abgeschlossen", className: "text-green-700 bg-green-50" },
  abandoned: { label: "Abgebrochen", className: "text-gray-500 bg-gray-50" },
};

export function StudentRow({ student, diagnosticId }: Props) {
  const [ticketUrl, setTicketUrl] = useState<string | null>(null);
  const [generating, setGenerating] = useState(false);
  const [showQr, setShowQr] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const router = useRouter();

  const sessions = student.diagnostic_sessions ?? [];
  const latest = sessions
    .slice()
    .sort((a, b) => new Date(b.started_at).getTime() - new Date(a.started_at).getTime())[0];

  async function generateTicket() {
    setGenerating(true);
    const supabase = createClient();
    const expires = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    const { data, error } = await supabase
      .from("session_tickets")
      .insert({
        student_id: student.id,
        diagnostic_id: diagnosticId,
        expires_at: expires,
      })
      .select("id")
      .single();

    if (data) {
      // The student client URL will be /s/<ticket_id> — base URL from env
      const base = process.env.NEXT_PUBLIC_STUDENT_APP_URL ?? window.location.origin;
      setTicketUrl(`${base}/s/${data.id}`);
      setShowQr(true);
    }
    setGenerating(false);
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
            <p className="font-medium text-sm">{student.display_name}</p>
            {latest && (
              <div className="flex items-center gap-2 mt-0.5">
                <span className={`text-xs px-1.5 py-0.5 rounded ${STATUS_LABEL[latest.status]?.className ?? ""}`}>
                  {STATUS_LABEL[latest.status]?.label ?? latest.status}
                </span>
                {latest.status === "completed" && (
                  <Link
                    href={`/dashboard/foerderplan/${latest.id}`}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    Förderplan ansehen
                  </Link>
                )}
              </div>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={generateTicket}
            disabled={generating}
            className="text-sm bg-gray-900 hover:bg-gray-700 disabled:opacity-50 text-white px-3 py-1.5 rounded-lg transition-colors"
          >
            {generating ? "…" : "Diagnostik starten"}
          </button>
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
              <h3 className="text-lg font-semibold">Diagnostik starten</h3>
              <p className="text-sm text-gray-500 mt-1">
                {student.display_name} — QR-Code scannen oder Link öffnen
              </p>
            </div>

            <div className="bg-white p-4 border border-gray-200 rounded-xl inline-block">
              <QRCode value={ticketUrl} size={200} />
            </div>

            <div className="bg-gray-50 rounded-lg px-3 py-2">
              <p className="text-xs text-gray-400 break-all font-mono">{ticketUrl}</p>
            </div>

            <p className="text-xs text-gray-400">
              Gültig für 24 Stunden · Einmalige Nutzung
            </p>

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
