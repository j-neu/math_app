"use client";

import { useEffect, useState, type ReactNode } from "react";

interface Props {
  open: boolean;
  title: string;
  body: ReactNode;
  confirmLabel: string;
  busyLabel?: string;
  danger?: boolean;
  onConfirm: () => Promise<void>;
  onCancel: () => void;
}

/** Shared destructive-action confirmation dialog (German, danger styling). */
export function ConfirmDialog({
  open,
  title,
  body,
  confirmLabel,
  busyLabel = "Wird gelöscht…",
  danger = true,
  onConfirm,
  onCancel,
}: Props) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setBusy(false);
      setError(null);
    }
  }, [open]);

  if (!open) return null;

  async function handleConfirm() {
    setBusy(true);
    setError(null);
    try {
      await onConfirm();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Das hat leider nicht geklappt.");
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-xl space-y-4">
        <h2 className="text-lg font-semibold">{title}</h2>
        <div className="text-sm text-gray-600 leading-relaxed">{body}</div>
        {error && (
          <p className="text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
            {error}
          </p>
        )}
        <div className="flex gap-3 justify-end">
          <button
            type="button"
            onClick={onCancel}
            disabled={busy}
            className="text-sm text-gray-500 hover:text-gray-900 px-4 py-2"
          >
            Abbrechen
          </button>
          <button
            type="button"
            onClick={handleConfirm}
            disabled={busy}
            className={
              danger
                ? "bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
                : "bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
            }
          >
            {busy ? busyLabel : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
