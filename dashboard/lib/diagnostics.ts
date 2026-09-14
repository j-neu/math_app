// The diagnostic bank new sessions run.
//
// iMINT/PIKAS legacy-reversion bank ("imint-pikas-v4", 111 items, v3/v4 flat
// skill ids, current since 2026-09-13) inserted by backend/supabase/migrations/
// 20260913000000_v4_imint_pikas_bank.sql. Matches the content the Flutter
// client actually serves from Research/diagnostic_v4_master.csv.
//
// Both predecessors stay in the database, frozen, so their old sessions keep
// rendering; no new ticket or session may be created against either:
//   - "cleanroom-v1" (00000000-0000-0000-0000-000000000002): the clean-room
//     rebuild (59 core + 32 deep-dive items, 36-skill dotted taxonomy),
//     abandoned 2026-09-12 in favor of rebuilding on the original iMINT/PIKAS
//     CSVs. This was still ACTIVE_DIAG_ID until this change -- ticket/session/
//     result bookkeeping had been silently running against this stale 67-item
//     bank ever since the pivot, wholly disconnected from the new content the
//     child actually saw on screen.
//   - the legacy iMINT row (00000000-0000-0000-0000-000000000001): predates
//     the clean-room rebuild.
export const ACTIVE_DIAG_ID = "00000000-0000-0000-0000-000000000003";
