import { FunctionsHttpError, type SupabaseClient } from "@supabase/supabase-js";

export type PatchPathAction =
  | "activate"
  | "reactivate"
  | "archive"
  | "set_unlock_width"
  | "add_skill"
  | "remove_skill"
  | "set_state"
  | "reorder"
  | "reset_progress";

export interface PatchPathBody {
  path_id: string;
  action: PatchPathAction;
  skill_id?: string;
  state?: string;
  unlock_width?: number;
  skill_ids?: string[];
}

export type PatchPathResult = { ok: true } | { ok: false; status: number; error: string };

/**
 * Client-side PATCH wrapper for the learning-path edge function. The browser
 * supabase client attaches the teacher's session JWT as `Authorization: Bearer`
 * automatically, which the function's `authenticateWriter` resolves to a
 * `teachers` row. All console mutations go through this wrapper — never direct
 * PostgREST writes (reorder_path_items and skill_progress DELETE are
 * service-role-only).
 *
 * The HTTP verb must be PATCH (functions.invoke defaults to POST, which would
 * route into the function's /generate branch and fail with "session_id fehlt").
 *
 * Error responses (401/403/409/400/500) carry a German `{ error }` body; the
 * message is surfaced verbatim so the 409 activation and 400 unlock_width
 * messages reach the teacher unchanged.
 */
export async function patchPath(
  supabase: SupabaseClient,
  body: PatchPathBody,
): Promise<PatchPathResult> {
  const { data, error } = await supabase.functions.invoke("learning-path", {
    method: "PATCH",
    body,
  });

  if (error) {
    let status = 500;
    let message = "Unbekannter Fehler";
    if (error instanceof FunctionsHttpError) {
      status = error.context.status;
      try {
        const payload = (await error.context.json()) as { error?: string };
        if (payload && typeof payload.error === "string" && payload.error.length > 0) {
          message = payload.error;
        }
      } catch {
        // response body is not JSON — keep the default message
      }
    } else if (error instanceof Error) {
      // A network-level failure ("fetch failed", DNS, ...) is English in the
      // browser; the teacher gets a neutral German message instead.
      message = "Verbindung zum Server nicht möglich. Bitte versuche es erneut.";
    }
    return { ok: false, status, error: message };
  }

  if (data && (data as { ok?: boolean }).ok === true) {
    return { ok: true };
  }

  return {
    ok: false,
    status: 200,
    error: (data as { error?: string } | null)?.error ?? "Unbekannter Fehler",
  };
}
