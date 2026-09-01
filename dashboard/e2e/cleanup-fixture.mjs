// Remove every row the seed created (see seed-fixture.mjs) so a Playwright
// run leaves the live project as it was. Reads e2e/.fixture.json; safe to run
// when no fixture exists.
//
// Usage:  node e2e/cleanup-fixture.mjs   (also run by Playwright globalTeardown)

import { readFileSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadEnv() {
  const raw = readFileSync(join(__dirname, "..", ".env.local"), "utf8");
  const env = {};
  for (const line of raw.split(/\r?\n/)) {
    const match = /^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/.exec(line);
    if (match) env[match[1]] = match[2];
  }
  return env;
}

export async function cleanup() {
  const env = loadEnv();
  const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRole = env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceRole) {
    console.log("Keine Zugangsdaten in .env.local → nichts zu bereinigen");
    return;
  }

  const fixturePath = join(__dirname, ".fixture.json");
  let fixture;
  try {
    fixture = JSON.parse(readFileSync(fixturePath, "utf8"));
  } catch {
    console.log("Keine Fixture-Datei → nichts zu bereinigen");
    return;
  }

  const base = supabaseUrl.replace(/\/$/, "");
  const headers = {
    apikey: serviceRole,
    Authorization: `Bearer ${serviceRole}`,
  };

  async function del(path) {
    const res = await fetch(`${base}${path}`, { method: "DELETE", headers });
    if (!res.ok && res.status !== 404) {
      console.warn(`Bereinigung ${path} → ${res.status}: ${await res.text()}`);
    }
  }

  // FK order: paths → student → class → teacher → school → auth user.
  await del(`/rest/v1/learning_paths?student_id=eq.${fixture.student.id}`);
  await del(`/rest/v1/students?id=eq.${fixture.student.id}`);
  await del(`/rest/v1/classes?id=eq.${fixture.class.id}`);
  await del(`/rest/v1/teachers?id=eq.${fixture.teacher.id}`);
  await del(`/rest/v1/schools?id=eq.${fixture.school.id}`);
  await del(`/auth/v1/admin/users/${fixture.teacher.id}`);

  rmSync(fixturePath, { force: true });
  console.log("Fixture bereinigt (e2e/.fixture.json entfernt)");
}

const isMain =
  process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url;
if (isMain) {
  cleanup().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
