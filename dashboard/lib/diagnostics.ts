// The diagnostic bank new sessions run.
//
// Clean-room rebuild ("cleanroom-v1", 59 core + 32 deep-dive items, Domains A-D,
// 36-skill taxonomy) inserted by backend/supabase/migrations/
// 20260829000000_cleanroom_v1_bank.sql. The legacy iMINT row
// (00000000-0000-0000-0000-000000000001) stays in the database so old pilot
// sessions keep rendering; no new ticket or session may be created against it.
export const ACTIVE_DIAG_ID = "00000000-0000-0000-0000-000000000002";
