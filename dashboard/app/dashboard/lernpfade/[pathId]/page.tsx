import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getTeacherSchoolId, getPathDetail } from "@/lib/lernpfad/queries";
import { PathConsole } from "@/components/PathConsole";
import { PathStatusBadge } from "@/components/PathStatusBadge";

interface Props {
  params: { pathId: string };
}

export default async function LernpfadDetailPage({ params }: Props) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const teacherSchoolId = await getTeacherSchoolId(supabase);
  const { path, items, progress, allSkills } = await getPathDetail(supabase, params.pathId);

  const student = path?.student ?? null;
  const hasAccess = Boolean(
    path && student && teacherSchoolId && teacherSchoolId === student.school_id,
  );

  if (!hasAccess) {
    return (
      <div className="text-center py-16 space-y-4">
        <p className="text-gray-500 text-sm">Kein Zugriff auf diesen Lernpfad.</p>
        <Link
          href="/dashboard"
          className="inline-block text-sm text-blue-600 hover:underline"
        >
          Zurück zur Übersicht
        </Link>
      </div>
    );
  }

  const currentPath = path!;
  const currentStudent = student!;
  const sourceDate = new Date(
    currentPath.activated_at ?? currentPath.created_at,
  ).toLocaleDateString("de-DE");
  // Only a path that really came from a diagnostic gets the "aus Diagnostik"
  // label; a manually created path has no source session and would otherwise
  // be mislabelled (integration-critic F6).
  const sourceLabel = currentPath.source_session_id
    ? ` · aus Diagnostik vom ${sourceDate}`
    : " · manuell erstellt";

  return (
    <div className="space-y-6 max-w-3xl">
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <Link href="/dashboard" className="hover:text-gray-900">Klassen</Link>
        <span>›</span>
        <Link
          href={`/dashboard/klassen/${currentStudent.class_id}`}
          className="hover:text-gray-900"
        >
          {currentStudent.class_name ?? "Klasse"}
        </Link>
        <span>›</span>
        <span className="text-gray-900 font-medium">{currentStudent.display_name}</span>
      </div>

      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div>
          <h1 className="text-2xl font-bold">{currentStudent.display_name} — Lernpfad</h1>
          <p className="text-sm text-gray-500 mt-1">
            {currentPath.unlock_width} Kompetenzen freigeschaltet{sourceLabel}
          </p>
        </div>
        <PathStatusBadge status={currentPath.status} />
      </div>

      {currentPath.status === "draft" && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-sm text-amber-900">
          Dieser Lernpfad ist für das Kind noch nicht sichtbar. Er wird erst nach dem Aktivieren
          angezeigt.
        </div>
      )}

      {currentPath.status === "archived" && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-sm text-amber-900">
          Dieser Lernpfad ist archiviert und für das Kind nicht mehr sichtbar. Reaktivieren Sie
          ihn, damit das Kind ihn wieder üben kann.
        </div>
      )}

      <PathConsole path={path} items={items} progress={progress} allSkills={allSkills} />
    </div>
  );
}
