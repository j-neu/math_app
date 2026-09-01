import Link from "next/link";
import type { PathStatus } from "@/lib/lernpfad/types";
import { PathStatusBadge } from "@/components/PathStatusBadge";

interface PathStatusRowProps {
  studentName: string;
  path: {
    id: string;
    status: PathStatus;
    counts: { mastered: number; available: number };
  } | null;
  slowSkills: string[];
}

export function PathStatusRow({ studentName, path, slowSkills }: PathStatusRowProps) {
  return (
    <div className="flex items-center justify-between px-4 py-3 gap-3 flex-wrap">
      <div className="flex items-center gap-3 min-w-0">
        <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-sm font-medium text-gray-500 flex-shrink-0">
          {studentName.charAt(0).toUpperCase()}
        </div>
        <div className="min-w-0">
          <p className="text-sm font-medium text-gray-900">
            {path ? (
              <Link
                href={`/dashboard/lernpfade/${path.id}`}
                className="hover:text-blue-600 hover:underline"
              >
                {studentName}
              </Link>
            ) : (
              studentName
            )}
          </p>
          <p className="text-xs text-gray-400 mt-0.5">
            {path
              ? `${path.counts.mastered} gemeistert · ${path.counts.available} verfügbar`
              : "Kein Lernpfad"}
          </p>
        </div>
      </div>
      <div className="flex items-center gap-2 flex-wrap">
        {path && <PathStatusBadge status={path.status} />}
        {slowSkills.length > 0 && (
          <span
            className="inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200 font-medium"
            title="Langsame Antwortzeiten"
          >
            Langsame Antwortzeiten bei: {slowSkills.join(", ")}
          </span>
        )}
      </div>
    </div>
  );
}
