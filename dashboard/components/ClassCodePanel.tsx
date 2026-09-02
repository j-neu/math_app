"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

interface Props {
  classId: string;
  classCode: string | null;
  practiceUrl: string | null;
}

export function ClassCodePanel({ classId, classCode, practiceUrl }: Props) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  async function rotate() {
    setBusy(true);
    setError(null);
    const supabase = createClient();
    const { error: rpcError } = await supabase.rpc("rotate_class_code", {
      p_class_id: classId,
    });
    if (rpcError) {
      setError("Code konnte nicht erneuert werden. Bitte erneut versuchen.");
      setBusy(false);
      return;
    }
    router.refresh();
    setBusy(false);
  }

  return (
    <div className="bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-3 space-y-2">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div>
          <p className="text-sm font-semibold text-emerald-900">
            Anmelden zum Üben (Lernpfad)
          </p>
          {practiceUrl && (
            <p className="text-xs text-emerald-700 mt-0.5">
              Kinder öffnen{" "}
              <span className="font-mono">{practiceUrl}</span> und geben diesen
              Code ein.
            </p>
          )}
        </div>
        <div className="flex items-center gap-3">
          {classCode && (
            <span
              className="text-2xl font-bold tracking-[0.3em] text-emerald-900 tabular-nums"
              aria-label={`Klassencode ${classCode}`}
            >
              {classCode}
            </span>
          )}
          {!classCode && (
            <span className="text-sm text-emerald-700 italic">
              Noch kein Code — bitte einen Code erzeugen.
            </span>
          )}
          <button
            onClick={rotate}
            disabled={busy}
            className="min-h-[44px] inline-flex items-center gap-1.5 text-sm font-medium px-3 py-2 rounded-lg border border-emerald-300 bg-white text-emerald-800 hover:bg-emerald-100 disabled:opacity-50"
          >
            {busy ? "…" : "Neuer Code"}
          </button>
        </div>
      </div>
      {error && (
        <p role="alert" className="text-sm text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}
