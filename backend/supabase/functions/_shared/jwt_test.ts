import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { signStudentToken, verifyStudentToken } from "./jwt.ts";

const SECRET = "test-secret-at-least-32-characters-long!!";
const STUDENT = "aaaaaaaa-0000-0000-0000-000000000001";

Deno.test("round-trips the student_id claim", async () => {
  const token = await signStudentToken(STUDENT, SECRET);
  assertEquals(await verifyStudentToken(token, SECRET), STUDENT);
});

Deno.test("rejects a token signed with a different secret", async () => {
  const token = await signStudentToken(STUDENT, SECRET);
  assertEquals(await verifyStudentToken(token, "another-secret-also-32-characters!!!"), null);
});

Deno.test("rejects an expired token", async () => {
  const token = await signStudentToken(STUDENT, SECRET, -10);
  assertEquals(await verifyStudentToken(token, SECRET), null);
});

Deno.test("rejects malformed input without throwing", async () => {
  assertEquals(await verifyStudentToken("not-a-jwt", SECRET), null);
  assertEquals(await verifyStudentToken("", SECRET), null);
});

Deno.test("carries the claims PostgREST requires", async () => {
  const token = await signStudentToken(STUDENT, SECRET);
  const payload = JSON.parse(atob(token.split(".")[1]!));
  assertEquals(payload.role, "authenticated");
  assertEquals(payload.aud, "authenticated");
  assertEquals(payload.sub, STUDENT);
  assert(payload.exp > Math.floor(Date.now() / 1000));
});
