import type { PathStatus } from "@/lib/lernpfad/types";

const STATUS_META: Record<PathStatus, { label: string; className: string; icon: string }> = {
  draft: { label: "Entwurf", className: "text-gray-700 bg-gray-100", icon: "✎" },
  active: { label: "Aktiv", className: "text-green-700 bg-green-50", icon: "▶" },
  completed: { label: "Abgeschlossen", className: "text-blue-700 bg-blue-50", icon: "✓" },
  archived: { label: "Archiviert", className: "text-gray-500 bg-gray-50", icon: "▣" },
};

export function PathStatusBadge({ status }: { status: PathStatus }) {
  const meta = STATUS_META[status] ?? STATUS_META.draft;
  return (
    <span
      className={`inline-flex items-center gap-1 text-sm px-2 py-0.5 rounded font-medium ${meta.className}`}
      role="status"
    >
      <span aria-hidden="true" className="text-current">{meta.icon}</span>
      {meta.label}
    </span>
  );
}
