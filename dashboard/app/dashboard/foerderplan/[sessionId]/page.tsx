import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";

const SB_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;

async function generateFoerderplan(sessionId: string): Promise<void> {
  const resp = await fetch(`${SB_URL}/functions/v1/foerderplan-generate`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${SERVICE_KEY}`,
      apikey: SERVICE_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ session_id: sessionId }),
    cache: "no-store",
  });
  if (!resp.ok) {
    console.error("foerderplan-generate failed", resp.status, await resp.text());
  }
}

const CATEGORY_COLORS: Record<string, string> = {
  "Zählen": "bg-green-500",
  "Zahlzerlegung / Schnelles Sehen": "bg-yellow-400",
  "Stellenwerte verstehen": "bg-blue-500",
  "Grundstrategien": "bg-red-500",
  "Kombinierte Strategien": "bg-purple-500",
};

const CATEGORY_TEXT: Record<string, string> = {
  "Zählen": "text-green-700 bg-green-50 border-green-200",
  "Zahlzerlegung / Schnelles Sehen": "text-yellow-700 bg-yellow-50 border-yellow-200",
  "Stellenwerte verstehen": "text-blue-700 bg-blue-50 border-blue-200",
  "Grundstrategien": "text-red-700 bg-red-50 border-red-200",
  "Kombinierte Strategien": "text-purple-700 bg-purple-50 border-purple-200",
};

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
    await generateFoerderplan(params.sessionId);
    const retry = await supabase
      .from("foerderplaene")
      .select("*")
      .eq("session_id", params.sessionId)
      .maybeSingle();
    plan = retry.data;
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
    .select("id, category, color, card_number, title_de, description_de")
    .in("id", plan.recommended_skill_ids as string[]);

  const skillMap = new Map((skills ?? []).map((s) => [s.id, s]));
  const recommended = (plan.recommended_skill_ids as string[])
    .map((id) => skillMap.get(id))
    .filter(Boolean) as { id: string; category: string; color: string; card_number: number; title_de: string; description_de: string }[];

  const brief = recommended.slice(0, 3);
  const categoryStats = plan.category_stats as Record<string, { failed: number; total: number }>;

  const sessionDate = session?.completed_at
    ? new Date(session.completed_at).toLocaleDateString("de-DE")
    : "—";

  const pdfUrl = `/api/foerderplan-pdf?session_id=${params.sessionId}`;

  return (
    <div className="space-y-8 max-w-3xl">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <Link href="/dashboard" className="text-sm text-gray-400 hover:text-gray-600">
            ← Zurück zur Übersicht
          </Link>
          <h1 className="text-2xl font-bold mt-2">Individueller Förderplan</h1>
          <p className="text-gray-500 text-sm mt-1">
            {student?.display_name ?? "—"} · {sessionDate}
          </p>
        </div>
        <a
          href={pdfUrl}
          target="_blank"
          className="inline-flex items-center gap-2 bg-gray-900 hover:bg-gray-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
        >
          Als PDF exportieren
        </a>
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
        <p className="text-sm text-gray-500">Die drei wichtigsten Förderempfehlungen:</p>
        <div className="space-y-3">
          {brief.map((skill, i) => {
            const border = CATEGORY_TEXT[skill.category] ?? "text-gray-700 bg-gray-50 border-gray-200";
            const dot = CATEGORY_COLORS[skill.category] ?? "bg-gray-400";
            return (
              <div key={skill.id} className={`border rounded-xl p-4 ${border}`}>
                <div className="flex items-start gap-3">
                  <span className="text-lg font-bold opacity-30">{i + 1}</span>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className={`inline-block w-2.5 h-2.5 rounded-full ${dot} flex-shrink-0`} />
                      <p className="font-semibold">{skill.title_de}</p>
                    </div>
                    <p className="text-sm mt-1 opacity-80">{skill.description_de}</p>
                    <p className="text-xs mt-2 opacity-60">{skill.category} · Karte {skill.card_number}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Kategorie-Übersicht */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Kategorie-Übersicht</h2>
        <div className="bg-white border border-gray-200 rounded-xl overflow-hidden divide-y divide-gray-50">
          {Object.entries(categoryStats).map(([cat, stat]) => {
            const pct = stat.total > 0 ? stat.failed / stat.total : 0;
            const barColor = CATEGORY_COLORS[cat] ?? "bg-gray-400";
            return (
              <div key={cat} className="flex items-center gap-4 px-4 py-3">
                <span className="text-sm w-52 flex-shrink-0 text-gray-700">{cat}</span>
                <div className="flex-1 bg-gray-100 rounded-full h-2">
                  <div
                    className={`${barColor} h-2 rounded-full transition-all`}
                    style={{ width: `${pct * 100}%` }}
                  />
                </div>
                <span className="text-xs text-gray-500 w-24 text-right flex-shrink-0">
                  {stat.failed}/{stat.total} falsch
                </span>
              </div>
            );
          })}
        </div>
      </section>

      {/* Vollständiger Förderplan */}
      <details className="group">
        <summary className="text-lg font-semibold cursor-pointer select-none list-none flex items-center gap-2">
          <span className="text-gray-400 group-open:rotate-90 transition-transform inline-block">›</span>
          Vollständiger Förderplan
          <span className="text-sm font-normal text-gray-400">({recommended.length} Empfehlungen)</span>
        </summary>
        <div className="mt-4 space-y-2">
          {recommended.map((skill, i) => {
            const dot = CATEGORY_COLORS[skill.category] ?? "bg-gray-400";
            return (
              <div key={skill.id} className="flex items-start gap-3 bg-white border border-gray-200 rounded-lg px-4 py-3">
                <span className="text-sm text-gray-300 font-mono w-5 flex-shrink-0">{i + 1}</span>
                <span className={`inline-block w-2.5 h-2.5 rounded-full ${dot} mt-1 flex-shrink-0`} />
                <div>
                  <p className="text-sm font-medium">{skill.title_de}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{skill.description_de}</p>
                  <p className="text-xs text-gray-400 mt-1">{skill.category} · Karte {skill.card_number}</p>
                </div>
              </div>
            );
          })}
        </div>
      </details>

      {/* Detail table */}
      <details className="group">
        <summary className="text-lg font-semibold cursor-pointer select-none list-none flex items-center gap-2">
          <span className="text-gray-400 group-open:rotate-90 transition-transform inline-block">›</span>
          Detail-Tabelle
        </summary>
        <div className="mt-4 bg-white border border-gray-200 rounded-xl overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left px-4 py-3 font-medium text-gray-500">#</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">Fertigkeit</th>
                <th className="text-left px-4 py-3 font-medium text-gray-500">Kategorie</th>
                <th className="text-center px-4 py-3 font-medium text-gray-500">Karte</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {recommended.map((skill, i) => {
                const tag = CATEGORY_TEXT[skill.category] ?? "text-gray-700 bg-gray-50 border-gray-200";
                return (
                  <tr key={skill.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-400 font-mono text-xs">{i + 1}</td>
                    <td className="px-4 py-3">
                      <p className="font-medium">{skill.title_de}</p>
                      <p className="text-xs text-gray-500 mt-0.5">{skill.description_de}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`text-xs px-2 py-0.5 rounded border ${tag}`}>
                        {skill.category}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-center text-gray-500">{skill.card_number}</td>
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
