"use client";

import type { PathDetailResult } from "@/lib/lernpfad/queries";

export function PathConsole({ items }: PathDetailResult) {
  return (
    <div className="space-y-4">
      <h2 className="text-lg font-semibold">Kompetenzen</h2>
      {items.length === 0 ? (
        <p className="text-gray-400 text-sm py-6 text-center">
          Dieser Lernpfad hat noch keine Kompetenzen.
        </p>
      ) : (
        <ol className="bg-white border border-gray-200 rounded-xl overflow-hidden divide-y divide-gray-100">
          {items.map((item) => (
            <li key={item.id} className="flex items-center gap-3 px-4 py-3 text-sm">
              <span className="text-gray-400 w-6 flex-shrink-0">{item.position}.</span>
              <span className="font-medium text-gray-800">{item.skills.title_de}</span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
