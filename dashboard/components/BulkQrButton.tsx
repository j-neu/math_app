"use client";

import { useState } from "react";

interface Props {
  classId: string;
  className: string;
  studentCount: number;
}

export function BulkQrButton({ classId, className, studentCount }: Props) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleClick() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/bulk-qr-pdf", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ class_id: classId }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        setError(data.error ?? "Unbekannter Fehler");
        return;
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `QR-Codes_${className}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      setError("Netzwerkfehler. Bitte erneut versuchen.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        onClick={handleClick}
        disabled={loading || studentCount === 0}
        title={studentCount === 0 ? "Keine Schüler/innen vorhanden" : "Alle QR-Codes als PDF herunterladen"}
        className="text-sm border border-gray-200 hover:bg-gray-50 disabled:opacity-40 text-gray-700 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap"
      >
        {loading ? "Erstelle PDF…" : "Alle QR-Codes drucken"}
      </button>
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  );
}
