"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { ConfirmDialog } from "@/components/ConfirmDialog";

interface Props {
  classId: string;
  className: string;
  studentCount?: number;
  /** Navigate here after a successful delete (e.g. "/dashboard"). */
  redirectAfter?: string;
  /** Compact icon-only variant for class cards. */
  compact?: boolean;
}

/**
 * Teacher-facing class deletion. Deleting a class permanently removes the
 * class and — via DB cascade — every student with all sessions, results,
 * Förderpläne, tickets and Lernpfade. The delete runs through the Supabase
 * client under RLS; ownership is enforced by the "teacher delete classes"
 * policy.
 */
export function DeleteClassButton({
  classId,
  className,
  studentCount,
  redirectAfter,
  compact,
}: Props) {
  const [open, setOpen] = useState(false);
  const router = useRouter();

  async function handleDelete() {
    const supabase = createClient();
    const { error } = await supabase.from("classes").delete().eq("id", classId);
    if (error) {
      throw new Error(
        error.message.includes("row-level security") ||
          error.message.includes("permission denied")
          ? "Sie haben keine Berechtigung, diese Klasse zu löschen."
          : error.message,
      );
    }
    setOpen(false);
    if (redirectAfter) {
      router.push(redirectAfter);
      router.refresh();
    } else {
      router.refresh();
    }
  }

  return (
    <>
      {compact ? (
        <button
          type="button"
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            setOpen(true);
          }}
          aria-label={`Klasse ${className} löschen`}
          title="Klasse löschen"
          className="text-gray-300 hover:text-red-600 transition-colors p-1"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M3 6h18" />
            <path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
            <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
            <path d="M10 11v6M14 11v6" />
          </svg>
        </button>
      ) : (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="text-sm border border-red-200 hover:border-red-400 text-red-600 hover:bg-red-50 px-3 py-1.5 rounded-lg transition-colors"
        >
          Klasse löschen
        </button>
      )}

      <ConfirmDialog
        open={open}
        title={`Klasse „${className}“ löschen?`}
        body={
          <>
            <p>
              Die Klasse und alle ihre Schüler/innen werden dauerhaft gelöscht.
            </p>
            {studentCount !== undefined && studentCount > 0 && (
              <p className="mt-1 font-medium">
                Betroffen: {studentCount}{" "}
                {studentCount === 1 ? "Schüler/in" : "Schüler/innen"} mit allen
                Diagnose-Ergebnissen, Förderplänen und Lernpfaden.
              </p>
            )}
            <p className="mt-1">
              Das kann nicht rückgängig gemacht werden.
            </p>
          </>
        }
        confirmLabel="Klasse löschen"
        onConfirm={handleDelete}
        onCancel={() => setOpen(false)}
      />
    </>
  );
}
