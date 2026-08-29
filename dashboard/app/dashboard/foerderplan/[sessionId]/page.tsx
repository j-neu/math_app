import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";

// New taxonomy (tasks.md R4.3): domain label per skill ID prefix.
const DOMAIN_LABELS: Record<string, string> = {
  A: "Domäne A — Zahlbegriff",
  B: "Domäne B — Stellenwertverständnis",
  C: "Domäne C — Rechenstrategien",
  D: "Domäne D — Sachsituationen",
};

const DOMAIN_STYLES: Record<string, { bar: string; badge: string }> = {
  A: { bar: "bg-emerald-500", badge: "text-emerald-700 bg-emerald-50 border-emerald-200" },
  B: { bar: "bg-blue-500", badge: "text-blue-700 bg-blue-50 border-blue-200" },
  C: { bar: "bg-red-500", badge: "text-red-700 bg-red-50 border-red-200" },
  D: { bar: "bg-purple-500", badge: "text-purple-700 bg-purple-50 border-purple-200" },
};

const DOMAIN_PREFIX_PATTERN = /^([A-D])\d/;

const DEFAULT_STYLE = { bar: "bg-gray-400", badge: "text-gray-700 bg-gray-50 border-gray-200" };

function domainStyle(label: string): { bar: string; badge: string } {
  for (const [letter, domainLabel] of Object.entries(DOMAIN_LABELS)) {
    if (domainLabel === label) return DOMAIN_STYLES[letter]!;
  }
  const m = DOMAIN_PREFIX_PATTERN.exec(label);
  if (m && DOMAIN_STYLES[m[1]!]) return DOMAIN_STYLES[m[1]!];
  return DEFAULT_STYLE;
}

interface Props {
  params: { sessionId: string };
}

export default async function FoerderplanPage({ params }: Props) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: sessionMeta } = await supabase
    .from("diagnostic_sessions")
    .select("status")
    .eq("id", params.sessionId)
    .single();

  const isPartial = sessionMeta?.status !== "completed";

  // Always (re)generate for in-progress sessions so the plan reflects the latest answers.
  // For completed sessions, only generate if no plan exists yet.
  let { data: plan } = await supabase
    .from("foerderplaene")
    .select("*")
    .eq("session_id", params.sessionId)
    .maybeSingle();

  if (!plan || isPartial) {
    const { data: generated, error: fnErr } = await supabase.functions.invoke("foerderplan-generate", {
      body: { session_id: params.sessionId },
    });
    if (fnErr) console.error("foerderplan-generate failed:", fnErr);
    else if (generated) plan = generated;
  }

  if (!plan) {
    return (
      <div className="text-center py-16 text-gray-400">
        <p>Kein Förderplan konnte erstellt werden.</p>
        <p className="text-sm mt-1">Möglicherweise wurden noch keine Fragen beantwortet.</p>
        <Link href="/dashboard" className="text-blue-600 text-sm mt-4 inline-block hover:underline">
          Zurück zur Übersicht
        </Link>
      </div>
    );
  }

  const { data: session } = await supabase
    .from("diagnostic_sessions")
    .select("student_id, completed_at, started_at")
    .eq("id", params.sessionId)
    .single();

  const { data: student } = await supabase
    .from("students")
    .select("display_name, class_id")
    .eq("id", session?.student_id ?? "")
    .single();

  const { data: skills } = await supabase
    .from("skills")
    .select("id, category, color, title_de, description_de")
    .in("id", plan.recommended_skill_ids as string[]);

  const skillMap = new Map((skills ?? []).map((s) => [s.id, s]));
  const recommended = (plan.recommended_skill_ids as string[])
    .map((id) => skillMap.get(id))
    .filter(Boolean) as { id: string; category: string; color: string; title_de: string; description_de: string }[];

  const brief = recommended.slice(0, 3);
  const categoryStats = plan.category_stats as Record<string, { failed: number; total: number }>;

  // Group full plan by category (Flutter-style)
  const recommendedByCategory = new Map<string, typeof recommended>();
  for (const s of recommended) {
    if (!recommendedByCategory.has(s.category)) recommendedByCategory.set(s.category, []);
    recommendedByCategory.get(s.category)!.push(s);
  }

  // Per-question detail rows
  const { data: results } = await supabase
    .from("diagnostic_results")
    .select("question_id, was_correct, response_time_seconds, status, user_answer")
    .eq("session_id", params.sessionId);

  const questionIds = (results ?? []).map((r) => r.question_id);
  const { data: questions } = questionIds.length
    ? await supabase
        .from("diagnostic_questions")
        .select("id, question_number, prompt_de, correct_answer")
        .in("id", questionIds)
    : { data: [] as { id: string; question_number: number; prompt_de: string; correct_answer: unknown }[] };

  const questionById = new Map((questions ?? []).map((q) => [q.id, q]));
  const detailRows = (results ?? [])
    .map((r) => {
      const q = questionById.get(r.question_id);
      return q ? { ...r, question_number: q.question_number, prompt_de: q.prompt_de, correct_answer: q.correct_answer } : null;
    })
    .filter(Boolean) as Array<{
      question_id: string;
      was_correct: boolean;
      response_time_seconds: number | null;
      status: string;
      user_answer: string | null;
      question_number: number;
      prompt_de: string;
      correct_answer: unknown;
    }>;
  detailRows.sort((a, b) => a.question_number - b.question_number);

  function formatAnswer(value: unknown): string {
    if (value === null || value === undefined) return "—";
    if (typeof value === "string") {
      try { return JSON.parse(value) as string; } catch { return value; }
    }
    return String(value);
  }

  const sessionDate = session?.completed_at
    ? new Date(session.completed_at).toLocaleDateString("de-DE")
    : "—";

  const pdfUrl = `/api/foerderplan-pdf?session_id=${params.sessionId}`;
  const kurzPdfUrl = `/api/foerderplan-kurz-pdf?session_id=${params.sessionId}`;
  const kurzDocxUrl = `/api/foerderplan-kurz-docx?session_id=${params.sessionId}`;

  return (
    <div className="space-y-8 max-w-3xl">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <Link href="/dashboard" className="text-sm text-gray-400 hover:text-gray-600">
            ← Zurück zur Übersicht
          </Link>
          <h1 className="text-2xl font-bold mt-2">Individueller Förderplan</h1>
          <p className="text-gray-500 text-sm mt-1">
            {student?.display_name ?? "—"} · {sessionDate}
          </p>
        </div>
        <div className="flex flex-col items-end gap-2 flex-shrink-0">
          <a
            href={pdfUrl}
            target="_blank"
            className="inline-flex items-center gap-2 bg-gray-900 hover:bg-gray-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
          >
            Als PDF exportieren
          </a>
          <a
            href={kurzPdfUrl}
            target="_blank"
            className="inline-flex items-center gap-2 border border-gray-300 hover:border-gray-400 text-gray-700 text-sm font-medium px-4 py-2 rounded-lg transition-colors"
          >
            Förderplan (PDF)
          </a>
          <a
            href={kurzDocxUrl}
            className="inline-flex items-center gap-2 border border-gray-300 hover:border-gray-400 text-gray-700 text-sm font-medium px-4 py-2 rounded-lg transition-colors"
          >
            Förderplan (Word)
          </a>
        </div>
      </div>

      {/* Partial-plan warning */}
      {isPartial && (
        <div className="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded-lg text-sm">
          <strong>Hinweis:</strong> Die Diagnostik ist noch nicht abgeschlossen. Dieser Förderplan basiert auf den bisher gegebenen Antworten und wird beim erneuten Aufrufen aktualisiert.
        </div>
      )}

      {/* Slow response warning */}
      {plan.slow_response_flag && (
        <div className="bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-lg text-sm">
          <strong>Hinweis:</strong> Das Kind zeigt bei korrekten Antworten häufig lange Reaktionszeiten — mögliches Zeichen für zählendes Rechnen.
        </div>
      )}

      {/* Kurzer Förderplan */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Kurzer Förderplan</h2>
        <p className="text-sm text-gray-500">Die nächsten drei Übungs-Schwerpunkte.</p>
        {brief.length === 0 ? (
          <div className="border border-gray-200 rounded-xl p-6 text-center text-gray-500 italic">
            Keine Förderschwerpunkte erkannt — herzlichen Glückwunsch!
          </div>
        ) : (
          <div className="space-y-3">
            {brief.map((skill) => {
              const style = domainStyle(skill.category);
              return (
                <div key={skill.id} className="border border-gray-200 rounded-xl p-4 bg-white flex items-stretch gap-3">
                  <div className={`w-1 rounded-full ${style.bar} flex-shrink-0`} />
                  <div className="flex-1">
                    <p className="font-semibold">{skill.title_de}</p>
                    <p className="text-sm text-gray-600 mt-1">{skill.description_de}</p>
                    <span className={`inline-block text-xs px-2 py-0.5 rounded-full border mt-2 ${style.badge}`}>
                      {skill.category}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      {/* Domänen-Übersicht */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Domänen-Übersicht</h2>
        <div className="bg-white border border-gray-200 rounded-xl overflow-hidden divide-y divide-gray-50">
          {Object.entries(categoryStats).map(([cat, stat]) => {
            const allCorrect = stat.failed === 0;
            return (
              <div key={cat} className="flex items-center gap-4 px-4 py-3">
                <span className="text-sm flex-1 text-gray-700">{cat}</span>
                <span className={`text-sm font-semibold tabular-nums ${allCorrect ? "text-green-700" : "text-gray-800"}`}>
                  {stat.failed} / {stat.total} falsch
                </span>
              </div>
            );
          })}
        </div>
      </section>

      {/* Vollständiger Förderplan — grouped by category */}
      <details className="group">
        <summary className="text-lg font-semibold cursor-pointer select-none list-none flex items-center gap-2">
          <span className="text-gray-400 group-open:rotate-90 transition-transform inline-block">›</span>
          Vollständiger Förderplan
          <span className="text-sm font-normal text-gray-400">({recommended.length} empfohlene Übungen)</span>
        </summary>
        <div className="mt-4 space-y-5">
          {Array.from(recommendedByCategory.entries()).map(([cat, items]) => {
            const style = domainStyle(cat);
            return (
              <div key={cat} className="space-y-2">
                <span className={`inline-block text-xs px-2 py-0.5 rounded-full border ${style.badge}`}>
                  {cat}
                </span>
                <div className="space-y-1 pl-1">
                  {items.map((skill) => (
                    <div key={skill.id} className="py-1">
                      <p className="text-sm font-medium">{skill.title_de}</p>
                      <p className="text-xs text-gray-500">{skill.description_de}</p>
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </details>

      {/* Detail-Tabelle — per-question results */}
      <details className="group">
        <summary className="text-lg font-semibold cursor-pointer select-none list-none flex items-center gap-2">
          <span className="text-gray-400 group-open:rotate-90 transition-transform inline-block">›</span>
          Detail-Tabelle
          <span className="text-sm font-normal text-gray-400">({detailRows.length} Fragen)</span>
        </summary>
        <div className="mt-4 bg-white border border-gray-200 rounded-xl overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left px-3 py-2 font-medium text-gray-500 w-10">Q#</th>
                <th className="text-left px-3 py-2 font-medium text-gray-500">Frage</th>
                <th className="text-left px-3 py-2 font-medium text-gray-500">Richtig</th>
                <th className="text-left px-3 py-2 font-medium text-gray-500">Antwort</th>
                <th className="text-left px-3 py-2 font-medium text-gray-500 w-20">Zeit</th>
                <th className="text-left px-3 py-2 font-medium text-gray-500 w-24">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {detailRows.map((row, index) => {
                let statusLabel = "Falsch";
                let statusClass = "text-red-700 bg-red-50 border-red-200";
                if (row.status === "skipped") {
                  statusLabel = "Übersprungen";
                  statusClass = "text-gray-500 bg-gray-50 border-gray-200";
                } else if (row.status === "leer") {
                  statusLabel = "Leer";
                  statusClass = "text-amber-700 bg-amber-50 border-amber-200";
                } else if (row.status === "timeout") {
                  statusLabel = "Timeout";
                  statusClass = "text-orange-700 bg-orange-50 border-orange-200";
                } else if (row.was_correct) {
                  statusLabel = "Richtig";
                  statusClass = "text-green-700 bg-green-50 border-green-200";
                }
                return (
                  <tr key={row.question_id} className="hover:bg-gray-50 align-top">
                    <td className="px-3 py-2 text-gray-400 font-mono text-xs">{index + 1}</td>
                    <td className="px-3 py-2 text-gray-700 max-w-xs">{row.prompt_de}</td>
                    <td className="px-3 py-2 text-gray-600">{formatAnswer(row.correct_answer)}</td>
                    <td className="px-3 py-2 text-gray-600">{row.user_answer ?? "—"}</td>
                    <td className="px-3 py-2 text-gray-500 tabular-nums">
                      {row.response_time_seconds != null ? `${row.response_time_seconds.toFixed(1)} s` : "—"}
                    </td>
                    <td className="px-3 py-2">
                      <span className={`text-xs px-2 py-0.5 rounded-full border ${statusClass}`}>
                        {statusLabel}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </details>
    </div>
  );
}
