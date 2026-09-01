import { test, expect, type Page } from "@playwright/test";
import fs from "node:fs";
import path from "node:path";

interface Fixture {
  teacher: { id: string; email: string; password: string };
  class: { id: string; name: string };
  student: { id: string; display_name: string };
  skills: { id: string; title_de: string }[];
  pathA: { id: string };
  pathB: { id: string };
}

function loadFixture(): Fixture {
  const fixturePath = path.join(process.cwd(), "e2e", ".fixture.json");
  if (!fs.existsSync(fixturePath)) {
    throw new Error("e2e/.fixture.json fehlt — globalSetup (Seed) muss vorher laufen");
  }
  return JSON.parse(fs.readFileSync(fixturePath, "utf8")) as Fixture;
}

let fixture: Fixture;

test.beforeAll(() => {
  fixture = loadFixture();
});

async function login(page: Page) {
  await page.goto("/login");
  await page.getByLabel("E-Mail-Adresse").fill(fixture.teacher.email);
  await page.getByLabel("Passwort").fill(fixture.teacher.password);
  await page.getByRole("button", { name: "Anmelden" }).click();
  await page.waitForURL("**/dashboard");
}

async function openClassPage(page: Page) {
  await page.goto("/dashboard");
  await page.getByRole("link", { name: new RegExp(fixture.class.name) }).click();
  await page.waitForURL("**/dashboard/klassen/**");
}

function statusBadge(page: Page, text: string | RegExp) {
  return page.getByRole("status").filter({ hasText: text }).first();
}

test("Klasse zeigt den Entwurf-Lernpfad mit Status und Langsam-Warnung", async ({ page }) => {
  await login(page);
  await openClassPage(page);

  await expect(page.getByRole("heading", { name: "Lernpfade" })).toBeVisible();
  await expect(page.getByText(fixture.student.display_name).first()).toBeVisible();
  await expect(statusBadge(page, "Entwurf")).toBeVisible();
  await expect(page.getByText(/Langsame Antwortzeiten bei/)).toBeVisible();
});

test("Konsole rendert Kompetenzen und Fortschrittsdetails", async ({ page }) => {
  await login(page);
  await page.goto(`/dashboard/lernpfade/${fixture.pathA.id}`);

  await expect(page.getByRole("heading", { name: /— Lernpfad/ })).toBeVisible();

  const first = fixture.skills[0].title_de;
  const row = page.locator("li", { hasText: first });
  await expect(row).toBeVisible();
  await expect(row.getByText("Freigeschaltet")).toBeVisible();

  await row.getByRole("button", { name: /erweitern/ }).click();
  await expect(page.getByText("Stufe 1")).toBeVisible();
  await expect(page.getByText("8 Versuche, 7 richtig")).toBeVisible();
  await expect(page.getByText("Stufe 2")).toBeVisible();
  await expect(page.getByText("Noch nicht bearbeitet")).toBeVisible();
  await expect(page.getByText("Langsames Bearbeiten").first()).toBeVisible();
});

test("Schreibaktionen: Freischaltbreite, Überspringen, Reihenfolge, Aktivieren", async ({ page }) => {
  await login(page);
  await page.goto(`/dashboard/lernpfade/${fixture.pathA.id}`);

  await expect(statusBadge(page, "Entwurf")).toBeVisible();
  await expect(page.getByText(/Dieser Lernpfad ist für das Kind noch nicht sichtbar/)).toBeVisible();

  // Freischaltbreite auf 2 setzen
  await page.getByLabel("Freigeschaltete Kompetenzen").fill("2");
  await page.getByRole("button", { name: "Speichern" }).click();
  await expect(page.getByText("2 Kompetenzen freigeschaltet").first()).toBeVisible();

  // Zweite Kompetenz überspringen (mit Bestätigung)
  const second = page.locator("li", { hasText: fixture.skills[1].title_de });
  page.once("dialog", (dialog) => dialog.accept());
  await second.getByRole("button", { name: "Überspringen" }).click();
  await expect(second.getByText("Übersprungen")).toBeVisible();

  // Letzte Kompetenz nach oben verschieben → Reihenfolge [0,1,3,2]
  const last = page.locator("li", { hasText: fixture.skills[3].title_de });
  await last.getByRole("button", { name: "Nach oben" }).click();
  const positions = page.locator("ol li");
  await expect(positions.nth(2)).toContainText(fixture.skills[3].title_de);
  await expect(positions.nth(3)).toContainText(fixture.skills[2].title_de);

  // Aktivieren → Badge "Aktiv", Entwurf-Banner verschwindet
  page.once("dialog", (dialog) => dialog.accept());
  await page.getByRole("button", { name: "Aktivieren" }).click();
  await expect(statusBadge(page, "Aktiv")).toBeVisible();
  await expect(page.getByText(/Dieser Lernpfad ist für das Kind noch nicht sichtbar/)).toHaveCount(0);
});

test("Zweites Aktivieren zeigt die exakte 409-Meldung", async ({ page }) => {
  await login(page);
  await page.goto(`/dashboard/lernpfade/${fixture.pathB.id}`);

  await expect(statusBadge(page, "Entwurf")).toBeVisible();
  page.once("dialog", (dialog) => dialog.accept());
  await page.getByRole("button", { name: "Aktivieren" }).click();
  await expect(page.getByText(/Dieses Kind hat bereits einen aktiven Lernpfad/)).toBeVisible();
});

test("Archivieren bestätigt und setzt den Status auf Archiviert", async ({ page }) => {
  await login(page);
  await page.goto(`/dashboard/lernpfade/${fixture.pathA.id}`);

  await expect(statusBadge(page, "Aktiv")).toBeVisible();
  page.once("dialog", (dialog) => dialog.accept());
  await page.getByRole("button", { name: "Archivieren" }).click();
  await expect(statusBadge(page, "Archiviert")).toBeVisible();
});
