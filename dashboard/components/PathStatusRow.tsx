import Link from "next/link";
import type { PathStatus } from "@/lib/lernpfad/types";
import { PathStatusBadge } from "@/components/PathStatusBadge";

interface PathSummary {
  id: string;
  status: PathStatus;
  counts: { mastered: number; available: number };
}

interface PathStatusRowProps {
  studentId: string;
  studentName: string;
  paths: PathSummary[];
  slowSkills: string[];
}

export function PathStatusRow({ studentId, studentName, paths, slowSkills }: PathStatusRowProps) {
  return (
    <div className="flex items-center justify-between px-4 py-3 gap-3 flex-wrap">
      <div className="flex items-center gap-3 min-w-0">
        <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-sm font-medium text-gray-500 flex-shrink-0">
          {studentName.charAt(0).toUpperCase()}
        </div>
        <div className="min-w-0">
          <Link
            href={`/dashboard/students/${studentId}`}
            className="min-h-[44px] inline-flex items-center text-sm font-medium text-gray-900 hover:text-blue-600 hover:underline"
          >
            {studentName}
          </Link>
          {paths.length === 0 ? (
            <p className="text-sm text-gray-400">Kein Lernpfad</p>
          ) : (
            <div className="flex flex-col gap-0.5">
              {paths.map((path) => (
                <Link
                  key={path.id}
                  href={`/dashboard/lernpfade/${path.id}`}
                  className="min-h-[44px] inline-flex items-center gap-2 pr-2 hover:bg-gray-50 rounded-lg"
                >
                  <PathStatusBadge status={path.status} />
                  <span className="text-sm text-gray-600">
                    {path.counts.mastered} gemeistert · {path.counts.available} verfügbar
                  </span>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
      <div className="flex items-center gap-2 flex-wrap">
        {slowSkills.length > 0 && (
          <span
            className="inline-flex items-center gap-1 text-sm px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200 font-medium"
            title="Langsame Antwortzeiten"
          >
            Langsame Antwortzeiten bei: {slowSkills.join(", ")}
          </span>
        )}
      </div>
    </div>
  );
}
