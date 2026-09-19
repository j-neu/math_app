# Documentation Index

One stop for every `.md` file in this repo. Read this first; jump from here.

**Legend:** ⭐ start here · 🟢 current & reliable · 🟡 partly stale (verify before trusting) · 🔴 historical / verworfen — do not build on it · ⚪ boilerplate, skip

> **Stand 2026-09-17.** Content is on **v4** (the iMINT/PIKAS legacy reversion, decided 2026-09-12,
> shipped 2026-09-13) plus a practice-pipeline layer on top of it, merged 2026-09-17
> (`exercise-plan-foundation`). Both the v1 clean-room rewrite AND the v2 Deckungsmatrix rebuild are
> **fully superseded** — everything marked 🔴 below is protocol, not a working basis. See `STATUS.md`
> for the full account of how we got here.

---

## ⭐ Start here

- [STATUS.md](STATUS.md) — 🟢 What's shipped, active, paused. The one-screen header status — read this first.
- [tasks.md](tasks.md) — 🟢 **Live task list**, revived 2026-09-19. What's next and who owns it: the practice-content build-out queue, and the legal/pilot-readiness backlog. The old Clean-Room R0–R9 list this file used to hold is archived at [Archive/tasks_cleanroom_r0-r9.md](Archive/tasks_cleanroom_r0-r9.md).
- [math_app/Research/diagnostic_v4_master.csv](math_app/Research/diagnostic_v4_master.csv) — 🟢 The live diagnostic, 108 items, the sole source `DiagnosticService` serves.
- [math_app/Research/skills_taxonomy.csv](math_app/Research/skills_taxonomy.csv) — 🟢 The 93-skill taxonomy every diagnosed skill and practice level is keyed to.
- [docs/superpowers/specs/2026-09-15-exercise-plan-design.md](docs/superpowers/specs/2026-09-15-exercise-plan-design.md) — 🟢 **The practice-content plan.** Maps all 93 taxonomy skills to an archetype tier (Reused/Extended/New-widget-exists/New-from-scratch) against the 24 original hand-built exercises. §5 is the per-skill authority (manipulative, old archetype, level structure) for anyone authoring a new skill.
- [docs/skill_spec_authoring_guide.md](docs/skill_spec_authoring_guide.md) — 🟢 **How to author one skill's practice spec**, step by step, proven on 2 real skills (`double_zr10`, `halve_zr10`). Read this before writing a new `docs/clean-room/v4/skills/specs/*.json`.
- [docs/clean-room/v4/skills/BUILD_ORDER.md](docs/clean-room/v4/skills/BUILD_ORDER.md) — 🟢 All 93 skills classified into archetype tiers and batched by shared manipulative — the backlog every follow-on plan slices a batch from. 2/93 shipped so far.
- [docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md](docs/superpowers/plans/2026-09-15-exercise-plan-foundation.md) — 🟢 The plan that built the practice pipeline itself (sync script, coverage checker, the two proof-of-pattern skills). Merged to `main` 2026-09-17. Reference for *how* a follow-on batch plan should look, not a source of open work anymore.
- `scripts/check_skill_spec_coverage.py` — 🟢 Run this, not a doc, to see live status: which of the 93 skills are actually playable right now.
- [README.md](README.md) — 🟢 Projektüberblick in einer Seite.
- [phase1_school_platform.md](phase1_school_platform.md) — 🟢 Plattform-Plan (Backend, Dashboard, Flutter Web, Pilot). Phase D/E offen; Infrastruktur-Teil weiterhin korrekt.
- [TERMINOLOGY.md](TERMINOLOGY.md) — 🟢 Skill / Level / Problem. Einmal lesen und "Übung" vs. "Skill" ist geklärt.
- [rewrite.md](rewrite.md) — 🟡 Die rechtliche Begründung des ursprünglichen Clean-Room-Ansatzes. Seit 2026-09-12 ein historisches Dokument, keine aktive Vorgabe mehr (rechtliche Erwägungen wurden für die v4-Inhalte ausdrücklich ausgeklammert) — bei Bedarf lesen, nicht als Handlungsanweisung.

## Übungs-Engine — real im Code, nicht mehr nur geplant

Die handgebaute, mehrstufige, manipulativ-basierte Engine ist zurück und tatsächlich gebaut
(`exercise-plan-foundation`, 2026-09-17) — nicht mehr nur als Entwurf. Diese Dokumente steuern sie
und sind **in Kraft**:

- [adhd guidelines.md](adhd%20guidelines.md) — 🟢 Sieben Gestaltungsprinzipien aus der ADHS-Forschung. Trägt Diagnostik- wie Übungsentscheidungen.
- [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md) — 🟢 Leicht→schwer→leicht innerhalb einer Stufe.
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) — 🟢 "Finished" vs. "Completed", Zeitgrenzen, Wertung.
- [EXERCISE_DESIGN_SYSTEM.md](EXERCISE_DESIGN_SYSTEM.md) — 🟢 Visuelle Spezifikation der Skill-Screens. (Nutzt im Fließtext noch "exercise"; `TERMINOLOGY.md` ist maßgeblich.)
- [COMMON_PITFALLS.md](COMMON_PITFALLS.md) — 🟢 Konkrete Fehlerrezepte aus der Übungsentwicklung.
- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) + [Research/REWARDS_SYSTEM.md](Research/REWARDS_SYSTEM.md) — 🟢 Die drei Belohnungsauslöser.
- [practice_skill_plan.md](practice_skill_plan.md) — 🟡 Aufgeschobener Plan für einen Skill zur Automatisierung der Übungserstellung (drei Blocker). Offen, aber ohne Priorität.

## v2 Deckungsmatrix — verworfen, nur noch Protokoll

Der gesamte v2-Neuaufbau (Rahmenlehrplan/KMK-abgeleitete Konstruktkarte statt der alten
iMINT/PIKAS-Skill-Liste) ist seit 2026-09-12 eingestellt — nicht auf eine spätere Diagnostik-Version
anzuwenden, nichts davon fortschreiben:

- [docs/clean-room/v2/10-deckungsmatrix.md](docs/clean-room/v2/10-deckungsmatrix.md) — 🔴 Die Deckungsmatrix (20 Stränge × ZR10/20/100 × Repräsentation). War das Wurzelartefakt von v2, jetzt Protokoll.
- [docs/clean-room/v2/11-konstruktkarte.md](docs/clean-room/v2/11-konstruktkarte.md) · [12-blueprint.md](docs/clean-room/v2/12-blueprint.md) · [14-itemregeln.md](docs/clean-room/v2/14-itemregeln.md) · [15-darstellungen.md](docs/clean-room/v2/15-darstellungen.md) — 🔴 Konstruktkarte, Blueprint, Itemregeln, Darstellungsschlüssel von v2.
- [docs/clean-room/v2/wortlaut-review-core.md](docs/clean-room/v2/wortlaut-review-core.md) — 🟡 Die Itemwortlaut-Regel selbst (ein einfacher Satz, kein verratenes Verfahren) gilt inhaltlich weiter und wurde für v4 neu angewendet — aber diese Datei prüft gegen die v2-Konstruktkarte, nicht gegen die v4-Taxonomie. Nur als Regel-Referenz lesen, nicht als Statusbericht.
- [docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md](docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md) — 🔴 Der v2-Plan. Abgelöst durch [2026-09-15-exercise-plan-design.md](docs/superpowers/specs/2026-09-15-exercise-plan-design.md).
- [docs/clean-room/00-v1-assessment.md](docs/clean-room/00-v1-assessment.md) — 🔴 Warum v1 verworfen wurde. Historisch wertvoll als Befund, aber die Diagnostik, gegen die es verglichen hat, gibt es nicht mehr.

## Clean-Room — Rechtsrahmen und Prüfspur v1 (historisch)

Rechtliche Erwägungen wurden für v4 auf Jakobs ausdrückliche Anweisung ausgeklammert (`STATUS.md`
Rechtlicher Status, 2026-09-12). Diese Dokumente bleiben als Protokoll des ursprünglichen
Clean-Room-Vorgehens stehen, sind aber keine aktive Vorgabe für die heutigen Inhalte:

- [docs/clean-room/00-charter.md](docs/clean-room/00-charter.md) — 🔴 Die Charta des Clean-Room-Vorgehens.
- [docs/clean-room/03-bibliography.md](docs/clean-room/03-bibliography.md) — 🔴 Die Bibliographie; erscheint weiterhin im Produkt als Seite "Wissenschaftliche Grundlagen" (Infrastruktur bleibt, die Herleitung ist historisch).
- [docs/clean-room/decisions/](docs/clean-room/decisions/) — 🔴 ADRs 0001–0009, Clean-Room-Ära.
- [docs/clean-room/provenance.csv](docs/clean-room/provenance.csv) — 🔴 Prüfspur v1/v2. Kein Äquivalent für v4 — v4 hat stattdessen `scripts/check_skill_spec_coverage.py` und `docs/skill_spec_authoring_guide.md`.
- [Archive/tasks_cleanroom_r0-r9.md](Archive/tasks_cleanroom_r0-r9.md) — 🔴 Ausführungsliste des Clean-Room-Durchlaufs (R0–R9), archiviert 2026-09-19. Vollständig historisch für Inhalte; ihre einzige noch reale Restarbeit (Phase-R9-Rechtsaufgaben, Impressum/Datenschutz-Platzhalter) wurde ins neue `tasks.md` übernommen.
- [docs/clean-room/01-construct-map.md](docs/clean-room/01-construct-map.md) · [02-blueprint.md](docs/clean-room/02-blueprint.md) · [docs/clean-room/items/](docs/clean-room/items/) · [docs/clean-room/skills/](docs/clean-room/skills/) · [docs/clean-room/foerderplan/mapping-rationale.md](docs/clean-room/foerderplan/mapping-rationale.md) — 🔴 v1-Konstruktkarte, -Blueprint, -Itembank, -36-Skill-Taxonomie, -Zuordnung. Reine Prüfspur.
- [docs/clean-room/foerderplan/form-mapping.md](docs/clean-room/foerderplan/form-mapping.md) + [ordering-rule.md](docs/clean-room/foerderplan/ordering-rule.md) — 🟡 Spaltenlogik und Empfehlungsreihenfolge des Förderplans. Die Mechanik läuft weiter im Code (jetzt gegen die v4-Taxonomie), diese Dokumente beschreiben aber noch die v1-Herleitung.
- `math_app/Research/diagnostic_core_v1.csv` + `diagnostic_deepdive_v1.csv` — 🔴 Gelöscht aus der Laufzeit (`content(v4)`, 2026-09-13). Existieren nicht mehr im Baum.
- `docs/archive/skill_specs_pre_v4/v1/` — 🔴 Die 36 archivierten v1-Übungs-Specs (`git mv` aus `docs/clean-room/skills/specs/`, 2026-09-15). Bleiben als Testfixtures in Betrieb (`all_specs_smoke_test.dart` u. a.), sind aber keine Inhaltsgrundlage mehr.

## Archiv (historisch, nicht bearbeiten, kann dem aktuellen Stand widersprechen)

- [Archive/GAUNTLET_PROGRESS.md](Archive/GAUNTLET_PROGRESS.md) — 🔴 Evidenz-Log des Gauntlets (P1–P4, Integration, drei §3a-Kind-Runden). Loop am 2026-09-06 geschlossen. Die §3a-Befunde sind weiterhin lesenswert: sie zeigen, wie kindseitige Defekte gefunden werden.
- [docs/superpowers/gauntlet-loop.md](docs/superpowers/gauntlet-loop.md) — 🔴 Die Betriebsanleitung des geschlossenen Loops.
- [Archive/phase1.1_fixes.md](Archive/phase1.1_fixes.md) — 🔴 Elf Diagnostik-/Dashboard-Fixes, alle 2026-05-23 ausgeliefert.
- [Archive/phase0_tasks.md](Archive/phase0_tasks.md) · [Archive/phase0.5_german_pivot.md](Archive/phase0.5_german_pivot.md) — 🔴 Diagnostik→Förderplan-MVP und der deutsche UI-Pivot. Beide ausgeliefert.
- [Archive/tasks_2026-05.md](Archive/tasks_2026-05.md) · [Archive/tasks_full.md](Archive/tasks_full.md) · [Archive/tasks_old.md](Archive/tasks_old.md) — 🔴 Ältere Aufgabenlisten.
- [Archive/COMPLETED_TASKS.md](Archive/COMPLETED_TASKS.md) · [Archive/COMPLETED_TASKS_PHASE2.md](Archive/COMPLETED_TASKS_PHASE2.md) — 🔴 Fortschrittsprotokolle Phase 1 / 2.
- [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) · [Archive/C1.1_FINALE_PATTERN.md](Archive/C1.1_FINALE_PATTERN.md) · [Archive/LEVEL5_COMPLETION_FIX.md](Archive/LEVEL5_COMPLETION_FIX.md) — 🔴 Implementierungsnotizen der alten Engine. Beim Wiederaufbau als Referenz brauchbar, nicht als Vorgabe.
- [Archive/replace_diagnostic_images.md](Archive/replace_diagnostic_images.md) — 🔴 Einmalige Umstellung von Fotos auf Flutter-Widgets. Erledigt.
- `_sources_private/` — nicht im Git. Referenzmaterial (iMINT, PIKAS, Schulz, Altbestände). Seit 2026-09-12 die direkte, offen genutzte Grundlage der v4-Inhalte (`MathApp_Diagnostic_with_skills.csv`, `skills_taxonomy_legacy.csv`) — rechtliche Vorbehalte gegen ihre Nutzung wurden auf Jakobs Anweisung ausdrücklich aufgehoben, siehe `STATUS.md` Rechtlicher Status.

## Boilerplate / generiert

- [math_app/README.md](math_app/README.md) · [dashboard/README.md](dashboard/README.md) · `math_app/ios/.../LaunchImage.imageset/README.md` — ⚪ Framework-Boilerplate. Überspringen.

---

## Vorrangregel

Bei inhaltlichen Widersprüchen gilt in dieser Reihenfolge:

**`math_app/Research/skills_taxonomy.csv` + `diagnostic_v4_master.csv`** (die Laufzeit-Wahrheit) >
**`docs/superpowers/specs/2026-09-15-exercise-plan-design.md` §5** (Archetyp/Manipulativ je Skill) >
**`docs/skill_spec_authoring_guide.md`** (wie ein Skill gebaut wird) >
**`docs/clean-room/v4/skills/BUILD_ORDER.md`** (Reihenfolge) > `STATUS.md` (Status) >
`phase1_school_platform.md` (Infrastruktur) > `TERMINOLOGY.md` > Rest.

Widerspricht ein Dokument der Laufzeit-CSV oder der Taxonomie, ist das Dokument falsch — nicht die
CSV. Alles unter "v2 Deckungsmatrix" oder "Clean-Room ... v1" oben ist 🔴 und steht außerhalb dieser
Regel: es entscheidet nichts mehr, ganz gleich was es behauptet.
