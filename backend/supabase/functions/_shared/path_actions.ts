// Pure helpers for the learning-path PATCH actions, unit-tested in
// path_actions_test.ts. index.ts wires them to the edge function.

// Schema values for learning_paths.status (20260830000000_learning_path.sql).
export const PATH_STATUSES = ["draft", "active", "completed", "archived"] as const;

// Schema values for path_items.state.
export const PATH_ITEM_STATES = ["locked", "available", "in_progress", "mastered", "skipped"] as const;

export interface PathItemPosition {
  id: string;
  position: number;
}

/**
 * The states path items should have after a reset: the first `unlockWidth`
 * items by position become `available`, every other item stays `locked` —
 * mirroring `/generate`'s `idx < unlock_width → available` rule so a reset
 * path is immediately playable. Pure and side-effect free: the input is
 * never mutated and the result is ordered by position regardless of the
 * input order.
 */
export function unlockWindowStates(
  items: PathItemPosition[],
  unlockWidth: number,
): { id: string; state: "available" | "locked" }[] {
  return [...items]
    .sort((a, b) => a.position - b.position)
    .map((item, idx) => ({
      id: item.id,
      state: idx < unlockWidth ? "available" : "locked",
    }));
}

/**
 * Whether the `archive` action may run against a path whose current status
 * is `status`. Every schema-legal status is archivable; archiving an already
 * archived path is the idempotent no-op. Returns null when allowed, a German
 * error string otherwise.
 */
export function archiveTransitionError(status: string): string | null {
  if ((PATH_STATUSES as readonly string[]).includes(status)) return null;
  return "Lernpfad kann nicht archiviert werden";
}

/**
 * Whether the `reactivate` action (archive → active) may run against a path
 * whose current status is `status`. Any schema-legal status can be
 * reactivated; reactivating an already active path is the idempotent no-op.
 * Returns null when allowed, a German error string otherwise.
 */
export function reactivateTransitionError(status: string): string | null {
  if ((PATH_STATUSES as readonly string[]).includes(status)) return null;
  return "Lernpfad kann nicht reaktiviert werden";
}
