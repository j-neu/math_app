import { createClient } from "@/lib/supabase/server";
import Link from "next/link";
import { redirect } from "next/navigation";
import { NewClassForm } from "@/components/NewClassForm";

export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: teacher } = await supabase
    .from("teachers")
    .select("school_id")
    .eq("id", user.id)
    .single();

  const { data: classes } = await supabase
    .from("classes")
    .select("id, name, grade, students(count)")
    .eq("school_id", teacher?.school_id ?? "")
    .order("grade")
    .order("name");

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Meine Klassen</h1>
        <NewClassForm schoolId={teacher?.school_id ?? ""} />
      </div>

      {(!classes || classes.length === 0) ? (
        <div className="text-center py-16 text-gray-400">
          <p className="text-lg">Noch keine Klassen angelegt.</p>
          <p className="text-sm mt-1">Erstellen Sie Ihre erste Klasse mit dem Button oben.</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {classes.map((c) => {
            const studentCount = (c.students as unknown as { count: number }[])[0]?.count ?? 0;
            return (
              <Link
                key={c.id}
                href={`/dashboard/klassen/${c.id}`}
                className="bg-white border border-gray-200 rounded-xl p-5 hover:border-blue-300 hover:shadow-sm transition-all group"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-semibold text-lg group-hover:text-blue-600 transition-colors">{c.name}</p>
                    {c.grade && <p className="text-sm text-gray-500">Klasse {c.grade}</p>}
                  </div>
                  <span className="text-xs text-gray-400 bg-gray-100 px-2 py-1 rounded-full">
                    {studentCount} {studentCount === 1 ? "Schüler/in" : "Schüler/innen"}
                  </span>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
