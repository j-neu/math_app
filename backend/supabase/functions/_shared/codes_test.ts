import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { hashIp, hashSecret, isValidCodeShape, normaliseCode } from "./codes.ts";

Deno.test("normalises case and strips whitespace", () => {
  assertEquals(normaliseCode(" 7k2m "), "7K2M");
});

Deno.test("rejects look-alike characters rather than guessing", () => {
  // 0/O/1/I/L are not in the alphabet, so a misread is refused, not repaired.
  assert(!isValidCodeShape("O0IL"));
});

Deno.test("accepts a well-shaped code", () => {
  assert(isValidCodeShape("7K2M"));
});

Deno.test("rejects wrong length and unknown characters", () => {
  assert(!isValidCodeShape("7K2"));
  assert(!isValidCodeShape("7K2MM"));
  assert(!isValidCodeShape("7K2!"));
});

Deno.test("hashIp is stable and salt-dependent", async () => {
  const a = await hashIp("192.0.2.1", "salt-one");
  const b = await hashIp("192.0.2.1", "salt-one");
  const c = await hashIp("192.0.2.1", "salt-two");
  assertEquals(a, b);
  assert(a !== c);
  assert(!a.includes("192.0.2.1"));
});

Deno.test("hashSecret gives different digests under different salts", async () => {
  const a = await hashSecret("1234", "salt-one");
  const b = await hashSecret("1234", "salt-two");
  assert(a !== b);
});
