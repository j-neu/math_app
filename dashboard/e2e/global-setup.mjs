import { run } from "./seed-fixture.mjs";

export default async function globalSetup() {
  await run();
}
