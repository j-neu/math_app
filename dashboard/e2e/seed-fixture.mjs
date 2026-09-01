// Seed the P4 e2e fixture through the Supabase REST + Auth admin APIs using
// the service role key from dashboard/.env.local (no psql needed).
//
// Creates: a dedicated e2e teacher, a school, a class, a student, a DRAFT
// learning path with 4 path_items and 2 skill_progress rows, plus a second
// DRAFT path (for the second-activate 409 check). Writes every created id to
// e2e/.fixture.json so the spec and cleanup can reference it.
//
// Usage:  node e2e/seed-fixture.mjs   (also run by Playwright globalSetup)

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { randomUUID } from "node:crypto";

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

export async function run() {
  const env = loadEnv();
  const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRole = env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceRole) {
    throw new Error(
      "NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY fehlen in dashboard/.env.local",
    );
  }

  const base = supabaseUrl.replace(/\/$/, "");
  const headers = {
    apikey: serviceRole,
    Authorization: `Bearer ${serviceRole}`,
    "Content-Type": "application/json",
    Prefer: "return=representation",
  };

  async function post(path, body) {
    const res = await fetch(`${base}${path}`, { method: "POST", headers, body: JSON.stringify(body) });
    if (!res.ok) throw new Error(`POST ${path} → ${res.status}: ${await res.text()}`);
    const data = await res.json();
    return Array.isArray(data) ? data[0] : data;
  }

  async function get(path) {
    const res = await fetch(`${base}${path}`, { headers });
    if (!res.ok) throw new Error(`GET ${path} → ${res.status}: ${await res.text()}`);
    return res.json();
  }

  async function del(path) {
    const res = await fetch(`${base}${path}`, { method: "DELETE", headers });
    if (!res.ok && res.status !== 404) {
      throw new Error(`DELETE ${path} → ${res.status}: ${await res.text()}`);
    }
  }

  // Remove leftovers from an earlier aborted run so re-seeding is idempotent.
  async function purgePreviousFixtures() {
    const adminRes = await fetch(`${base}/auth/v1/admin/users?per_page=200`, {
      headers: { apikey: serviceRole, Authorization: `Bearer ${serviceRole}` },
    });
    if (adminRes.ok) {
      const { users = [] } = await adminRes.json();
      for (const user of users) {
        if (typeof user.email === "string" && user.email.startsWith("e2e-teacher-")) {
          await del(`/auth/v1/admin/users/${user.id}`);
        }
      }
    }
    const schools = await get("/rest/v1/schools?select=id,name&name=ilike.E2E%20Schule%20*");
    for (const school of schools) {
      await del(`/rest/v1/schools?id=eq.${school.id}`);
    }
  }

  await purgePreviousFixtures();

  const suffix = randomUUID().slice(0, 8);
  const email = `e2e-teacher-${suffix}@numeris.example`;
  const password = `E2ePass-${suffix}!2026`;

  // 1. auth user (confirmed, so the UI password login works)
  const adminRes = await fetch(`${base}/auth/v1/admin/users`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, email_confirm: true }),
  });
  if (!adminRes.ok) throw new Error(`POST /auth/v1/admin/users → ${adminRes.status}: ${await adminRes.text()}`);
  const authUser = await adminRes.json();
  const teacherId = authUser.id;

  // 2. school (slug must be globally unique)
  const school = await post("/rest/v1/schools", {
    id: randomUUID(),
    name: `E2E Schule ${suffix}`,
    region: "",
    slug: `e2e-${suffix}`,
  });

  // 3. teachers row linking the auth user to the school
  await post("/rest/v1/teachers", {
    id: teacherId,
    school_id: school.id,
    display_name: "E2E Lehrkraft",
    role: "teacher",
  });

  // 4. class
  const klass = await post("/rest/v1/classes", {
    id: randomUUID(),
    school_id: school.id,
    teacher_id: teacherId,
    name: "E2E Klasse",
    grade: 2,
  });

  // 5. student
  const student = await post("/rest/v1/students", {
    id: randomUUID(),
    class_id: klass.id,
    display_name: "E2E Kind",
  });

  // 6. skills from the live catalog (real data, never hardcoded)
  const skills = await get("/rest/v1/skills?select=id,title_de&limit=4&order=id");
  if (skills.length < 4) throw new Error(`Mindestens 4 Kompetenzen nötig, habe ${skills.length}`);

  // 7. draft path A: 4 items (mirrors /generate: first unlock_width available),
  //    progress level 1 (8 Versuche, 7 richtig, slow) + level 3 (not slow);
  //    level 2 is deliberately absent → "Noch nicht bearbeitet".
  const pathA = await post("/rest/v1/learning_paths", {
    id: randomUUID(),
    student_id: student.id,
    status: "draft",
    unlock_width: 3,
  });
  for (let i = 0; i < 4; i++) {
    await post("/rest/v1/path_items", {
      id: randomUUID(),
      path_id: pathA.id,
      skill_id: skills[i].id,
      position: i,
      origin: "diagnostic",
      state: i < 3 ? "available" : "locked",
    });
  }
  await post("/rest/v1/skill_progress", {
    id: randomUUID(),
    student_id: student.id,
    skill_id: skills[0].id,
    level: 1,
    attempts: 8,
    correct: 7,
    best_streak: 0,
    slow_flag: true,
  });
  await post("/rest/v1/skill_progress", {
    id: randomUUID(),
    student_id: student.id,
    skill_id: skills[0].id,
    level: 3,
    attempts: 5,
    correct: 4,
    best_streak: 0,
    slow_flag: false,
  });

  // 8. second draft path B for the second-activate 409 check
  const pathB = await post("/rest/v1/learning_paths", {
    id: randomUUID(),
    student_id: student.id,
    status: "draft",
    unlock_width: 2,
  });
  await post("/rest/v1/path_items", {
    id: randomUUID(),
    path_id: pathB.id,
    skill_id: skills[2].id,
    position: 0,
    origin: "diagnostic",
    state: "available",
  });
  await post("/rest/v1/path_items", {
    id: randomUUID(),
    path_id: pathB.id,
    skill_id: skills[3].id,
    position: 1,
    origin: "diagnostic",
    state: "locked",
  });

  const fixture = {
    supabaseUrl: base,
    teacher: { id: teacherId, email, password },
    school: { id: school.id, name: school.name },
    class: { id: klass.id, name: klass.name },
    student: { id: student.id, display_name: student.display_name },
    skills: skills.map((s) => ({ id: s.id, title_de: s.title_de })),
    pathA: { id: pathA.id },
    pathB: { id: pathB.id },
  };

  writeFileSync(join(__dirname, ".fixture.json"), JSON.stringify(fixture, null, 2));
  console.log(
    `Fixture angelegt → e2e/.fixture.json (Lehrkraft ${email}, Klasse ${klass.id}, Pfad A ${pathA.id}, Pfad B ${pathB.id})`,
  );
  return fixture;
}

const isMain =
  process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url;
if (isMain) {
  run().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
