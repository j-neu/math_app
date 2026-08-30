// Mints the student-scoped token that activates the ticket_student_id()
// RLS policies. Signed with the project's JWT secret so PostgREST accepts it.
import { create, getNumericDate, verify } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const DEFAULT_TTL_SECONDS = 60 * 60 * 8; // one school day

async function key(secret: string): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

export async function signStudentToken(
  studentId: string,
  secret: string,
  ttlSeconds: number = DEFAULT_TTL_SECONDS,
): Promise<string> {
  return await create(
    { alg: "HS256", typ: "JWT" },
    {
      role: "authenticated",
      aud: "authenticated",
      sub: studentId,
      student_id: studentId,
      exp: getNumericDate(ttlSeconds),
    },
    await key(secret),
  );
}

/** Returns the student_id claim, or null for any invalid or expired token. */
export async function verifyStudentToken(
  token: string,
  secret: string,
): Promise<string | null> {
  try {
    const payload = await verify(token, await key(secret));
    const id = payload.student_id;
    return typeof id === "string" ? id : null;
  } catch {
    return null;
  }
}
