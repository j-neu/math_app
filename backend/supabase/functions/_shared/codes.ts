// Class codes avoid 0/O/1/I/L so a seven-year-old reading them off a board
// cannot pick the wrong character.
export const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

/** Upper-cases and strips surrounding whitespace. Does not repair bad input. */
export function normaliseCode(raw: string): string {
  return raw.trim().toUpperCase();
}

/** True when the code is exactly 4 characters, all from CODE_ALPHABET. */
export function isValidCodeShape(raw: string): boolean {
  const code = normaliseCode(raw);
  if (code.length !== 4) return false;
  return [...code].every((ch) => CODE_ALPHABET.includes(ch));
}

/** Salted SHA-256 of an arbitrary secret value (IP address, child PIN, ...).
 *  Callers each use their own salt so the two secret types stay unlinkable. */
export async function hashSecret(value: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(`${salt}:${value}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** Salted SHA-256 of a client IP. Stored instead of the address itself. */
export async function hashIp(ip: string, salt: string): Promise<string> {
  return hashSecret(ip, salt);
}
