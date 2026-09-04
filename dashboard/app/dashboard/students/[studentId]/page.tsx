import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getStudentLearningPaths } from "@/lib/lernpfad/queries";
import { pathCounts } from "@/lib/lernpfad/stats";
import { PathStatusBadge } from "@/components/PathStatusBadge";

const STATUS_LABEL: Record<string, { label: string; className: string }> = {
  in_progress: { label: "In Bearbeitung", className: "text-yellow-700 bg-yellow-50" },
  completed: { label: "Abgeschlossen", className: "text-green-700 bg-green-50" },
  abandoned: { label: "Abgebrochen", className: "text-gray-500 bg-gray-50" },
};

interface Props {
  params: { studentId: string };
}

export default async function StudentHistoryPage({ params }: Props) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: student } = await supabase
    .from("students")
    .select("id, display_name, class_id, classes!inner(id, name, school_id)")
    .eq("id", params.studentId)
    .single();

  if (!student) redirect("/dashboard");

  const { data: teacher } = await supabase
    .from("teachers")
    .select("school_id")
    .eq("id", user.id)
    .single();

  const classRow = Array.isArray(student.classes)
    ? (student.classes[0] as { id: string; name: string; school_id: string })
    : (student.classes as unknown as { id: string; name: string; school_id: string } | null);

  if (teacher?.school_id !== classRow?.school_id) redirect("/dashboard");

  const { data: sessions } = await supabase
    .from("diagnostic_sessions")
    .select(`
      id, status, started_at, completed_at, diagnostic_id,
      diagnostic_results(count),
      foerderplaene(brief_skill_ids, category_stats)
    `)
    .eq("student_id", params.studentId)
    .order("started_at", { ascending: false });

  // Session totals are per-bank: legacy iMINT sessions had 92 items, the active
  // clean-room diagnostic has 60 core (+ 32 deep-dive). Read question_count from
  // each session's own diagnostic so old and new sessions display correctly.
  const sessionDiagIds = Array.from(
    new Set(
      (sessions ?? [])
        .map((s) => (s as { diagnostic_id?: string | null }).diagnostic_id)
        .filter((id): id is string => !!id),
    ),
  );
  let totalByDiagnostic = new Map<string, number>();
  if (sessionDiagIds.length > 0) {
    const { data: diagnostics } = await supabase
      .from("diagnostics")
      .select("id, question_count")
      .in("id", sessionDiagIds);
    totalByDiagnostic = new Map(
      (diagnostics ?? []).map((d) => [d.id, d.question_count]),
    );
  }

  const learningPaths = await getStudentLearningPaths(supabase, params.studentId);

  return (
    <div className="space-y-8 max-w-2xl">
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link href="/dashboard" className="hover:text-gray-900">Klassen</Link>
        <span>›</span>
        <Link href={`/dashboard/klassen/${classRow?.id}`} className="hover:text-gray-900">
          {classRow?.name}
        </Link>
        <span>›</span>
        <span className="text-gray-900 font-medium">{student.display_name}</span>
      </div>

      <h1 className="text-2xl font-bold">{student.display_name} — Verlauf</h1>

      {/* Lernpfade */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Lernpfade</h2>
        {learningPaths.length === 0 ? (
          <p className="text-gray-400 text-sm py-6 text-center">
            Noch keine Lernpfade. Nach einer abgeschlossenen Diagnostik wird automatisch ein
            Entwurf angelegt.
          </p>
        ) : (
          <div className="bg-white border border-gray-200 rounded-xl overflow-hidden divide-y divide-gray-100">
            {learningPaths.map((path) => {
              const counts = pathCounts(path.path_items);
              const sourceDate = new Date(
                path.activated_at ?? path.created_at,
              ).toLocaleDateString("de-DE");
              return (
                <Link
                  key={path.id}
                  href={`/dashboard/lernpfade/${path.id}`}
                  className="min-h-[44px] flex items-center gap-2 px-4 py-3 hover:bg-gray-50"
                >
                  <PathStatusBadge status={path.status} />
                  <span className="text-sm text-gray-600">
                    {counts.mastered} gemeistert · {counts.available} verfügbar
                  </span>
                  <span className="text-sm text-gray-400 ml-auto">
                    aus {sourceDate}
                  </span>
                  <span aria-hidden="true" className="text-gray-400">›</span>
                </Link>
              );
            })}
          </div>
        )}
      </section>

      {(!sessions || sessions.length === 0) ? (
        <p className="text-gray-400 text-sm py-6 text-center">Noch keine Diagnostik durchgeführt.</p>
      ) : (
        <div className="space-y-3">
          {sessions.map((session) => {
            const answered =
              (session.diagnostic_results as { count: number }[])?.[0]?.count ?? 0;
            const sessionDiagId = (session as { diagnostic_id?: string | null }).diagnostic_id;
            const sessionTotal = sessionDiagId ? (totalByDiagnostic.get(sessionDiagId) ?? null) : null;
            const plan = Array.isArray(session.foerderplaene)
              ? session.foerderplaene[0]
              : session.foerderplaene;
            const catStats = (plan as { category_stats?: Record<string, { failed: number; total: number }> } | null)?.category_stats ?? null;
            const date = session.completed_at
              ? new Date(session.completed_at).toLocaleDateString("de-DE")
              : new Date(session.started_at).toLocaleDateString("de-DE");
            const statusInfo =
              STATUS_LABEL[session.status] ?? { label: session.status, className: "text-gray-500 bg-gray-50" };

            return (
              <div key={session.id} className="bg-white border border-gray-200 rounded-xl px-4 py-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3 flex-wrap">
                    <span className="text-sm font-medium text-gray-800">{date}</span>
                    <span className={`text-sm px-2 py-0.5 rounded ${statusInfo.className}`}>
                      {statusInfo.label}
                    </span>
                    <span className="text-xs text-gray-400">
                      {answered}{sessionTotal ? ` / ${sessionTotal}` : ""} Fragen
                    </span>
                  </div>
                  {answered > 0 && (
                    <Link
                      href={`/dashboard/foerderplan/${session.id}`}
                      className="text-xs text-blue-600 hover:underline flex-shrink-0"
                    >
                      Förderplan ansehen →
                    </Link>
                  )}
                </div>

                {catStats && Object.keys(catStats).length > 0 && (
                  <div className="flex flex-wrap gap-1.5">
                    {Object.entries(catStats).map(([cat, stat]) => {
                      const pct = stat.total > 0 ? Math.round((stat.failed / stat.total) * 100) : 0;
                      const color =
                        pct === 0
                          ? "text-green-700 bg-green-50"
                          : pct < 50
                          ? "text-yellow-700 bg-yellow-50"
                          : "text-red-700 bg-red-50";
                      return (
                        <span key={cat} className={`text-xs px-2 py-0.5 rounded ${color}`}>
                          {cat}: {pct}%
                        </span>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
