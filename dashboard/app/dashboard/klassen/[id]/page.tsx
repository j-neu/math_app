import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { StudentRow } from "@/components/StudentRow";
import { AddStudentForm } from "@/components/AddStudentForm";
import { BulkQrButton } from "@/components/BulkQrButton";

interface Props {
  params: { id: string };
}

export default async function KlasseDetailPage({ params }: Props) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: klass } = await supabase
    .from("classes")
    .select("id, name, grade, school_id, schools(slug)")
    .eq("id", params.id)
    .single();

  if (!klass) redirect("/dashboard");

  // Verify teacher owns this class's school
  const { data: teacher } = await supabase
    .from("teachers")
    .select("school_id")
    .eq("id", user.id)
    .single();

  if (teacher?.school_id !== klass.school_id) redirect("/dashboard");

  const DIAG_ID = "00000000-0000-0000-0000-000000000001";

  // Fetch students with their sessions and per-session result counts
  const { data: students } = await supabase
    .from("students")
    .select(`
      id, display_name, age, external_ref,
      diagnostic_sessions(id, status, completed_at, started_at, ticket_id,
        diagnostic_results(id))
    `)
    .eq("class_id", params.id)
    .order("display_name");

  const { count: totalQuestions } = await supabase
    .from("diagnostic_questions")
    .select("id", { count: "exact", head: true })
    .eq("diagnostic_id", DIAG_ID);

  // Category stats for aggregate view
  const sessionIds = (students ?? [])
    .flatMap((s) => (s.diagnostic_sessions as { id: string; status: string }[]))
    .filter((s) => s.status === "completed")
    .map((s) => s.id);

  let aggregateRows: { studentName: string; stats: Record<string, { failed: number; total: number }> }[] = [];
  if (sessionIds.length > 0) {
    const { data: plans } = await supabase
      .from("foerderplaene")
      .select("session_id, category_stats")
      .in("session_id", sessionIds);

    const planBySession = new Map((plans ?? []).map((p) => [p.session_id, p.category_stats]));

    aggregateRows = (students ?? []).map((s) => {
      const latestCompleted = (s.diagnostic_sessions as { id: string; status: string; completed_at: string }[])
        .filter((ds) => ds.status === "completed")
        .sort((a, b) => new Date(b.completed_at).getTime() - new Date(a.completed_at).getTime())[0];
      return {
        studentName: s.display_name,
        stats: latestCompleted ? (planBySession.get(latestCompleted.id) ?? {}) : {},
      };
    }).filter((r) => Object.keys(r.stats).length > 0);
  }

  const allCategories = Array.from(
    new Set(aggregateRows.flatMap((r) => Object.keys(r.stats)))
  ).sort();
  const schoolSlug = (klass as { schools?: { slug?: string | null } | null }).schools?.slug ?? null;
  const studentAppBase = process.env.NEXT_PUBLIC_STUDENT_APP_URL ?? "";
  const shortLoginUrl = schoolSlug ? `${studentAppBase}/s/${schoolSlug}` : null;

  return (
    <div className="space-y-10">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link href="/dashboard" className="hover:text-gray-900">Klassen</Link>
        <span>›</span>
        <span className="text-gray-900 font-medium">{klass.name}</span>
      </div>

      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{klass.name}</h1>
        <div className="flex items-center gap-2">
          <BulkQrButton
            classId={params.id}
            className={klass.name}
            studentCount={students?.length ?? 0}
          />
          <AddStudentForm classId={params.id} />
        </div>
      </div>

      {/* Short-URL info banner */}
      {shortLoginUrl && (
        <div className="bg-blue-50 border border-blue-100 rounded-xl px-4 py-3 flex items-center gap-3">
          <span className="text-blue-400 text-xl">🔗</span>
          <div>
            <p className="text-sm font-medium text-blue-900">Kurzlink für Schüler/innen (ohne QR-Scanner)</p>
            <p className="text-sm font-mono text-blue-700 mt-0.5">{shortLoginUrl}</p>
            <p className="text-xs text-blue-500 mt-0.5">Schreibe diese Adresse an die Tafel. Jede/r Schüler/in gibt dann ihren/seinen 4-stelligen Code ein.</p>
          </div>
        </div>
      )}

      {/* Student list */}
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Schüler/innen</h2>
        {(!students || students.length === 0) ? (
          <p className="text-gray-400 text-sm py-6 text-center">
            Noch keine Schüler/innen. Fügen Sie Schüler/innen über den Button hinzu.
          </p>
        ) : (
          <div className="bg-white border border-gray-200 rounded-xl overflow-hidden divide-y divide-gray-100">
            {students.map((s) => (
              <StudentRow
                key={s.id}
                student={s as {
                  id: string;
                  display_name: string;
                  age: number | null;
                  external_ref: string | null;
                  diagnostic_sessions: {
                    id: string;
                    status: string;
                    completed_at: string;
                    started_at: string;
                    ticket_id: string | null;
                    diagnostic_results: { id: string }[];
                  }[];
                }}
                diagnosticId={DIAG_ID}
                totalQuestions={totalQuestions ?? undefined}
              />
            ))}
          </div>
        )}
      </section>

      {/* Aggregate overview */}
      {aggregateRows.length > 0 && (
        <section className="space-y-3">
          <h2 className="text-lg font-semibold">Klassen-Übersicht</h2>
          <div className="bg-white border border-gray-200 rounded-xl overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100">
                  <th className="text-left px-4 py-3 font-medium text-gray-500">Schüler/in</th>
                  {allCategories.map((cat) => (
                    <th key={cat} className="text-center px-3 py-3 font-medium text-gray-500 whitespace-nowrap">
                      {cat}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {aggregateRows.map((row) => (
                  <tr key={row.studentName} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium">{row.studentName}</td>
                    {allCategories.map((cat) => {
                      const stat = row.stats[cat];
                      if (!stat) return <td key={cat} className="text-center px-3 py-3 text-gray-300">—</td>;
                      const pct = stat.total > 0 ? Math.round((stat.failed / stat.total) * 100) : 0;
                      const color = pct === 0 ? "text-green-600 bg-green-50" : pct < 50 ? "text-yellow-700 bg-yellow-50" : "text-red-700 bg-red-50";
                      return (
                        <td key={cat} className="text-center px-3 py-3">
                          <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${color}`}>
                            {pct}%
                          </span>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="text-xs text-gray-400">% der Aufgaben in dieser Domäne falsch beantwortet</p>
        </section>
      )}
    </div>
  );
}
