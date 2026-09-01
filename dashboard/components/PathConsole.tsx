"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { patchPath, type PatchPathBody } from "@/lib/lernpfad/api";
import type { PathDetailResult } from "@/lib/lernpfad/queries";
import type { PathItemState } from "@/lib/lernpfad/types";
import { levelRowsBySkill, slowSkillIds } from "@/lib/lernpfad/stats";
import { PathStatusBadge } from "@/components/PathStatusBadge";

const ITEM_STATE_META: Record<PathItemState, { label: string; className: string; icon: string }> = {
  locked: { label: "Gesperrt", className: "text-gray-500 bg-gray-100", icon: "▣" },
  available: { label: "Freigeschaltet", className: "text-green-700 bg-green-50", icon: "▶" },
  in_progress: { label: "In Bearbeitung", className: "text-yellow-700 bg-yellow-50", icon: "…" },
  mastered: { label: "Gemeistert", className: "text-blue-700 bg-blue-50", icon: "✓" },
  skipped: { label: "Übersprungen", className: "text-gray-500 bg-gray-50", icon: "⏭" },
};

export function PathConsole({ path, items, progress, allSkills }: PathDetailResult) {
  const router = useRouter();
  const supabase = createClient();

  const [busy, setBusy] = useState(false);
  const [errorBox, setErrorBox] = useState<string | null>(null);
  const [errorHint, setErrorHint] = useState<string | null>(null);
  const [expandedSkillId, setExpandedSkillId] = useState<string | null>(null);
  const [unlockWidth, setUnlockWidth] = useState("");
  const [unlockWidthError, setUnlockWidthError] = useState<string | null>(null);
  const [addSkillId, setAddSkillId] = useState("");

  const bySkill = levelRowsBySkill(progress);
  const slow = new Set(slowSkillIds(progress));

  useEffect(() => {
    setUnlockWidth(String(path?.unlock_width ?? ""));
  }, [path?.unlock_width]);

  if (!path) return null;

  async function runAction(body: PatchPathBody, confirmText?: string): Promise<boolean> {
    if (busy) return false;
    if (confirmText && !window.confirm(confirmText)) return false;
    setBusy(true);
    setErrorBox(null);
    setErrorHint(null);
    const result = await patchPath(supabase, body);
    setBusy(false);
    if (result.ok) {
      router.refresh();
      return true;
    }
    if (result.status === 401) {
      router.refresh();
      return false;
    }
    setErrorBox(result.error);
    if (result.status === 409 && body.action === "activate") {
      setErrorHint(
        "Hinweis: Möglicherweise hat das Kind bereits einen aktiven Lernpfad. Archivieren Sie zuerst den aktiven Lernpfad.",
      );
    }
    return false;
  }

  function activate() {
    void runAction(
      { path_id: path!.id, action: "activate" },
      "Lernpfad aktivieren? Das Kind sieht den Lernpfad ab sofort und kann die freigeschalteten Kompetenzen üben.",
    );
  }

  function archive() {
    void runAction(
      { path_id: path!.id, action: "archive" },
      "Archivieren? Der Lernpfad wird für das Kind unsichtbar.",
    );
  }

  function saveUnlockWidth() {
    const value = Number(unlockWidth);
    if (!Number.isInteger(value) || value < 1 || value > 10) {
      setUnlockWidthError("Bitte gib eine ganze Zahl zwischen 1 und 10 ein.");
      return;
    }
    setUnlockWidthError(null);
    void runAction({ path_id: path!.id, action: "set_unlock_width", unlock_width: value });
  }

  function addSkill() {
    if (!addSkillId) return;
    void runAction({ path_id: path!.id, action: "add_skill", skill_id: addSkillId });
  }

  function removeSkill(skillId: string, title: string) {
    void runAction(
      { path_id: path!.id, action: "remove_skill", skill_id: skillId },
      `Kompetenz „${title}“ aus dem Lernpfad entfernen? Sie wird nicht wiederhergestellt.`,
    );
  }

  function setItemState(skillId: string, state: "skipped" | "available", confirmText?: string) {
    void runAction({ path_id: path!.id, action: "set_state", skill_id: skillId, state }, confirmText);
  }

  function moveItem(index: number, direction: -1 | 1) {
    const next = [...items];
    const target = index + direction;
    if (target < 0 || target >= next.length) return;
    [next[index], next[target]] = [next[target], next[index]];
    void runAction({
      path_id: path!.id,
      action: "reorder",
      skill_ids: next.map((item) => item.skill_id),
    });
  }

  function resetProgress() {
    const n = path!.unlock_width;
    if (
      !window.confirm(
        `Fortschritt zurücksetzen? Alle Versuche und Meisterungen dieses Kindes in diesem Lernpfad werden gelöscht. Die ersten ${n} Kompetenzen werden wieder freigeschaltet.`,
      )
    ) {
      return;
    }
    if (
      !window.confirm(
        "Wirklich zurücksetzen? Alle Fortschritte werden gelöscht und der Lernpfad neu geöffnet. Diese Aktion kann nicht rückgängig gemacht werden.",
      )
    ) {
      return;
    }
    void runAction({ path_id: path!.id, action: "reset_progress" });
  }

  const actionButtonClass =
    "min-h-[44px] inline-flex items-center gap-1.5 text-sm font-medium px-3 py-2 rounded-lg border transition-colors";

  return (
    <div className="space-y-6">
      {errorBox && (
        <div role="alert" className="bg-red-50 border border-red-200 text-red-800 rounded-xl px-4 py-3 text-sm space-y-1">
          <p className="font-medium">Aktion fehlgeschlagen.</p>
          <p>{errorBox}</p>
          {errorHint && <p className="text-red-700">{errorHint}</p>}
        </div>
      )}

      {busy && (
        <p role="status" className="text-sm text-gray-500">
          Wird gespeichert…
        </p>
      )}

      {/* Status */}
      <div className="flex items-center gap-2 text-sm">
        <span className="text-gray-500">Status:</span>
        <PathStatusBadge status={path.status} />
        <span className="text-gray-400">
          {path.unlock_width} Kompetenzen freigeschaltet
        </span>
      </div>

      {/* Lifecycle actions */}
      {(path.status === "draft" || path.status === "active") && (
        <div className="flex gap-2 flex-wrap">
          {path.status === "draft" && (
            <button
              type="button"
              onClick={activate}
              disabled={busy}
              className={`${actionButtonClass} bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white border-transparent`}
            >
              Aktivieren
            </button>
          )}
          <button
            type="button"
            onClick={archive}
            disabled={busy}
            className={`${actionButtonClass} bg-white hover:bg-gray-50 disabled:opacity-50 text-gray-700 border-gray-300`}
          >
            Archivieren
          </button>
        </div>
      )}

      {/* Unlock width */}
      <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-2">
        <div className="flex items-end gap-3 flex-wrap">
          <div className="space-y-1">
            <label htmlFor="unlock-width" className="block text-sm font-medium text-gray-700">
              Freigeschaltete Kompetenzen
            </label>
            <input
              id="unlock-width"
              type="number"
              min={1}
              max={10}
              value={unlockWidth}
              onChange={(e) => setUnlockWidth(e.target.value)}
              className="w-24 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            type="button"
            onClick={saveUnlockWidth}
            disabled={busy}
            className={`${actionButtonClass} bg-gray-900 hover:bg-gray-700 disabled:opacity-50 text-white border-transparent`}
          >
            Speichern
          </button>
        </div>
        {unlockWidthError && <p className="text-sm text-red-700">{unlockWidthError}</p>}
        <p className="text-xs text-gray-500">
          Legt fest, wie viele Kompetenzen für das Kind gleichzeitig geöffnet sind (1–10).
        </p>
      </div>

      {/* Add skill */}
      <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-2">
        <label htmlFor="add-skill" className="block text-sm font-medium text-gray-700">
          Kompetenz aus dem Katalog
        </label>
        <div className="flex gap-3 flex-wrap items-center">
          <select
            id="add-skill"
            value={addSkillId}
            onChange={(e) => setAddSkillId(e.target.value)}
            className="flex-1 min-w-52 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Bitte wählen…</option>
            {allSkills.map((skill) => (
              <option key={skill.id} value={skill.id}>
                {skill.title_de}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={addSkill}
            disabled={busy || !addSkillId}
            className={`${actionButtonClass} bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white border-transparent`}
          >
            Kompetenz hinzufügen
          </button>
        </div>
        {allSkills.length === 0 && (
          <p className="text-sm text-gray-500">
            Alle Kompetenzen sind bereits im Lernpfad enthalten.
          </p>
        )}
        <p className="text-xs text-gray-500">
          Die hinzugefügte Kompetenz wird ans Ende gestellt und ist zunächst gesperrt.
        </p>
      </div>

      {/* Reset */}
      <button
        type="button"
        onClick={resetProgress}
        disabled={busy}
        className={`${actionButtonClass} bg-red-50 hover:bg-red-100 disabled:opacity-50 text-red-700 border-red-200`}
      >
        Fortschritt zurücksetzen
      </button>

      {/* Item list */}
      <div className="space-y-3">
        <h2 className="text-lg font-semibold">Kompetenzen</h2>
        {items.length === 0 ? (
          <p className="text-gray-400 text-sm py-6 text-center">
            Dieser Lernpfad hat noch keine Kompetenzen.
          </p>
        ) : (
          <ol className="bg-white border border-gray-200 rounded-xl overflow-hidden divide-y divide-gray-100">
            {items.map((item, index) => {
              const expanded = expandedSkillId === item.skill_id;
              const levelRows = bySkill[item.skill_id] ?? [];
              const isSlow = slow.has(item.skill_id);
              const stateMeta = ITEM_STATE_META[item.state] ?? ITEM_STATE_META.locked;
              return (
                <li key={item.id} className="px-4 py-3 space-y-2">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-gray-400 text-sm w-6 flex-shrink-0 tabular-nums">
                      {index + 1}.
                    </span>
                    <span
                      aria-hidden="true"
                      className="w-3 h-3 rounded-full flex-shrink-0"
                      style={{ backgroundColor: item.skills.color || "#d1d5db" }}
                    />
                    <button
                      type="button"
                      onClick={() =>
                        setExpandedSkillId(expanded ? null : item.skill_id)
                      }
                      aria-expanded={expanded}
                      aria-label={`${item.skills.title_de} ${expanded ? "einklappen" : "erweitern"}`}
                      className="flex-1 min-w-52 text-left"
                    >
                      <span className="font-medium text-gray-900">{item.skills.title_de}</span>
                    </button>
                    {item.origin === "teacher_added" && (
                      <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded bg-purple-50 text-purple-700 border border-purple-200 font-medium">
                        Hinzugefügt
                      </span>
                    )}
                    {isSlow && (
                      <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200 font-medium">
                        Langsames Bearbeiten
                      </span>
                    )}
                    <span
                      className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded font-medium ${stateMeta.className}`}
                    >
                      <span aria-hidden="true">{stateMeta.icon}</span>
                      {stateMeta.label}
                    </span>
                  </div>

                  {expanded && (
                    <div className="pl-9 space-y-2">
                      {item.skills.description_de && (
                        <p className="text-sm text-gray-600">{item.skills.description_de}</p>
                      )}
                      <div className="space-y-1.5">
                        {[1, 2, 3].map((level) => {
                          const row = levelRows.find((r) => r.level === level);
                          return (
                            <div
                              key={level}
                              className="flex items-center gap-2 text-sm flex-wrap"
                            >
                              <span className="w-16 text-gray-500 flex-shrink-0">
                                Stufe {level}
                              </span>
                              {row ? (
                                <>
                                  <span className="text-gray-800 tabular-nums">
                                    {row.attempts} Versuche, {row.correct} richtig
                                  </span>
                                  {row.mastered_at && (
                                    <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-200 font-medium">
                                      Gemeistert
                                    </span>
                                  )}
                                  {row.slow_flag && (
                                    <span className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200 font-medium">
                                      Langsames Bearbeiten
                                    </span>
                                  )}
                                </>
                              ) : (
                                <span className="text-gray-400 italic">
                                  Noch nicht bearbeitet
                                </span>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}

                  <div className="flex items-center gap-1.5 flex-wrap pl-9">
                    <button
                      type="button"
                      onClick={() => moveItem(index, -1)}
                      disabled={busy || index === 0}
                      className="min-h-[44px] inline-flex items-center gap-1 text-sm px-3 py-1.5 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-40 disabled:hover:bg-white"
                    >
                      Nach oben
                    </button>
                    <button
                      type="button"
                      onClick={() => moveItem(index, 1)}
                      disabled={busy || index === items.length - 1}
                      className="min-h-[44px] inline-flex items-center gap-1 text-sm px-3 py-1.5 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-40 disabled:hover:bg-white"
                    >
                      Nach unten
                    </button>
                    {item.state === "skipped" ? (
                      <button
                        type="button"
                        onClick={() => setItemState(item.skill_id, "available")}
                        disabled={busy}
                        className="min-h-[44px] inline-flex items-center gap-1 text-sm px-3 py-1.5 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-40"
                      >
                        Wieder freigeben
                      </button>
                    ) : (
                      item.state !== "mastered" && (
                        <button
                          type="button"
                          onClick={() =>
                            item.state === "locked"
                              ? setItemState(item.skill_id, "available")
                              : setItemState(
                                  item.skill_id,
                                  "skipped",
                                  "Als übersprungen markieren?",
                                )
                          }
                          disabled={busy}
                          className="min-h-[44px] inline-flex items-center gap-1 text-sm px-3 py-1.5 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-40"
                        >
                          {item.state === "locked" ? "Freischalten" : "Überspringen"}
                        </button>
                      )
                    )}
                    <button
                      type="button"
                      onClick={() => removeSkill(item.skill_id, item.skills.title_de)}
                      disabled={busy}
                      className="min-h-[44px] inline-flex items-center gap-1 text-sm px-3 py-1.5 rounded-lg border border-red-200 text-red-700 hover:bg-red-50 disabled:opacity-40"
                    >
                      Entfernen
                    </button>
                  </div>
                </li>
              );
            })}
          </ol>
        )}
      </div>
    </div>
  );
}
