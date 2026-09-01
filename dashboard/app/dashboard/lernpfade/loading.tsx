export default function Loading() {
  return (
    <div className="space-y-6 max-w-3xl" role="status" aria-label="Wird geladen" aria-busy="true">
      <div className="h-4 w-1/3 bg-gray-100 rounded animate-pulse" />
      <div className="h-8 w-1/2 bg-gray-100 rounded animate-pulse" />
      <div className="bg-white border border-gray-200 rounded-xl p-6 space-y-3">
        <div className="h-4 w-1/2 bg-gray-100 rounded animate-pulse" />
        <div className="h-4 w-2/3 bg-gray-100 rounded animate-pulse" />
        <div className="h-4 w-1/3 bg-gray-100 rounded animate-pulse" />
      </div>
    </div>
  );
}
