"use client";

export default function LernpfadeError({ reset }: { reset: () => void }) {
  return (
    <div className="text-center py-16 space-y-4">
      <p className="text-gray-500 text-sm">Da ist etwas schiefgelaufen.</p>
      <button
        onClick={reset}
        className="text-sm bg-gray-900 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition-colors"
      >
        Erneut versuchen
      </button>
    </div>
  );
}
