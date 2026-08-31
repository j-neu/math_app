// Reads a required secret from the environment.
//
// A missing custom secret (salt, signing key, ...) must never fall back to
// a hardcoded default: a default salt produces hashes that look correctly
// salted but aren't, and a default signing secret produces tokens that look
// correctly signed but aren't. Both are worse than refusing to serve, so
// callers of this function are expected to fail closed when it returns null
// — see each function's module-scope secret block for the concrete guard.
//
// Logs the missing variable's name server-side (for whoever is watching the
// function logs) but callers must never repeat that name back to the client.
export function requireEnv(name: string): string | null {
  const value = Deno.env.get(name);
  if (!value) {
    console.error(`[config] Missing required secret: ${name}. Refusing to serve until it is set.`);
    return null;
  }
  return value;
}
