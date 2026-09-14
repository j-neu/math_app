import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { compareRecommendations, sortSkillIds } from "./ordering.ts";

// Rewritten 2026-09-13 for the v3/v4 taxonomy: construct membership is now
// supplied by the caller (mirroring a `skills` table lookup) instead of
// being parsed from an old dotted-ID string that no longer exists in the
// live content.
const CONSTRUCTS: Record<string, string> = {
  quantify_count_zr10: "quantify_count",
  count_forward_zr20: "count_forward",
  count_backward_zr20: "count_backward",
  double_zr10: "double",
  double_crossing_10: "double",
  derive_via_10_sub: "derive_10",
  bundling_recognition_zr100: "bundling_recognition",
};
const constructOf = (skillId: string) => CONSTRUCTS[skillId] ?? "";

Deno.test("orders by construct position, not alphabetically", () => {
  assertEquals(
    sortSkillIds(["derive_via_10_sub", "quantify_count_zr10", "bundling_recognition_zr100"], constructOf),
    ["quantify_count_zr10", "bundling_recognition_zr100", "derive_via_10_sub"],
  );
});

Deno.test("unknown skill ID falls back to itself as its own construct", () => {
  assertEquals(
    sortSkillIds(["not_a_real_skill", "quantify_count_zr10"], constructOf),
    ["quantify_count_zr10", "not_a_real_skill"],
  );
});

Deno.test("comparator is deterministic regardless of input order", () => {
  const set = ["double_crossing_10", "count_forward_zr20", "derive_via_10_sub", "double_zr10"];
  const shuffled = ["derive_via_10_sub", "double_zr10", "count_forward_zr20", "double_crossing_10"];
  assertEquals(sortSkillIds(set, constructOf), sortSkillIds(shuffled, constructOf));
});

Deno.test("sortSkillIds does not mutate its argument", () => {
  const input = ["derive_via_10_sub", "quantify_count_zr10"];
  sortSkillIds(input, constructOf);
  assertEquals(input, ["derive_via_10_sub", "quantify_count_zr10"]);
});

Deno.test("compareRecommendations ties within a construct by skill ID", () => {
  assertEquals(compareRecommendations("double_crossing_10", "double_zr10", constructOf) < 0, true);
});
