import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { compareRecommendations, sortSkillIds } from "./ordering.ts";

Deno.test("orders by construct position, not alphabetically", () => {
  assertEquals(sortSkillIds(["C2.1", "A1.1", "B1.2"]), ["A1.1", "B1.2", "C2.1"]);
});

Deno.test("unsuffixed skill sorts before its suffixed siblings", () => {
  assertEquals(sortSkillIds(["A1.1b", "A1.1a", "A1.1"]), ["A1.1", "A1.1a", "A1.1b"]);
});

Deno.test("unknown construct sorts after every known one", () => {
  assertEquals(sortSkillIds(["Z9.9", "D1.2"]), ["D1.2", "Z9.9"]);
});

Deno.test("comparator is deterministic regardless of input order", () => {
  const a = sortSkillIds(["C3.2", "A3.1", "C1.1", "A3.1a"]);
  const b = sortSkillIds(["A3.1a", "C1.1", "C3.2", "A3.1"]);
  assertEquals(a, b);
});

Deno.test("sortSkillIds does not mutate its argument", () => {
  const input = ["C2.1", "A1.1"];
  sortSkillIds(input);
  assertEquals(input, ["C2.1", "A1.1"]);
});
