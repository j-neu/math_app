import { cleanup } from "./cleanup-fixture.mjs";

export default async function globalTeardown() {
  await cleanup();
}
