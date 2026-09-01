import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { archiveTransitionError, unlockWindowStates } from "./path_actions.ts";

Deno.test("unlockWindowStates opens exactly the first unlock_width items by position", () => {
  const items = [
    { id: "a", position: 0 },
    { id: "b", position: 1 },
    { id: "c", position: 2 },
    { id: "d", position: 3 },
    { id: "e", position: 4 },
  ];
  assertEquals(unlockWindowStates(items, 3), [
    { id: "a", state: "available" },
    { id: "b", state: "available" },
    { id: "c", state: "available" },
    { id: "d", state: "locked" },
    { id: "e", state: "locked" },
  ]);
});

Deno.test("unlockWindowStates orders by position, not input order", () => {
  const items = [
    { id: "c", position: 2 },
    { id: "a", position: 0 },
    { id: "b", position: 1 },
  ];
  assertEquals(unlockWindowStates(items, 2), [
    { id: "a", state: "available" },
    { id: "b", state: "available" },
    { id: "c", state: "locked" },
  ]);
});

Deno.test("unlockWindowStates opens every item when unlock_width exceeds the count", () => {
  const items = [
    { id: "a", position: 0 },
    { id: "b", position: 1 },
  ];
  assertEquals(unlockWindowStates(items, 5), [
    { id: "a", state: "available" },
    { id: "b", state: "available" },
  ]);
});

Deno.test("unlockWindowStates locks everything at width 0 and returns [] for no items", () => {
  assertEquals(unlockWindowStates([
    { id: "a", position: 0 },
    { id: "b", position: 1 },
  ], 0), [
    { id: "a", state: "locked" },
    { id: "b", state: "locked" },
  ]);
  assertEquals(unlockWindowStates([], 3), []);
});

Deno.test("unlockWindowStates does not mutate its argument", () => {
  const items = [
    { id: "b", position: 1 },
    { id: "a", position: 0 },
  ];
  unlockWindowStates(items, 1);
  assertEquals(items[0], { id: "b", position: 1 });
  assertEquals(items[1], { id: "a", position: 0 });
});

Deno.test("archive is allowed from every schema status incl. archived (idempotent no-op)", () => {
  for (const status of ["draft", "active", "completed", "archived"]) {
    assertEquals(archiveTransitionError(status), null);
  }
});

Deno.test("archive rejects an unknown current status", () => {
  assertEquals(
    archiveTransitionError("published"),
    "Lernpfad kann nicht archiviert werden",
  );
});
