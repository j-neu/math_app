# Documentation Index

One stop for every `.md` file in this repo. Read this first; jump from here.

**Legend:** ⭐ start here · 🟢 current & reliable · 🟡 partly stale (verify before trusting) · 🔴 historical / verworfen — do not build on it · ⚪ boilerplate, skip

> **Stand 2026-09-07.** Der erste Clean-Room-Durchlauf (`cleanroom-v1`) ist inhaltlich **verworfen**.
> Alles, was unten 🔴 markiert ist, ist Protokoll und keine Arbeitsgrundlage mehr. Die einzige aktuelle
> inhaltliche Grundlage ist der v2-Entwurf.

---

## ⭐ Start here

- [docs/clean-room/v2/10-deckungsmatrix.md](docs/clean-room/v2/10-deckungsmatrix.md) — 🟢 **DAS WURZELARTEFAKT.** 20 Stränge × ZR10/ZR20/ZR100 × enaktiv/ikonisch/symbolisch, 152 lebende Zellen mit Quelle und Fehlerbild, 28 begründete Ausnahmen. Von Jakob am 2026-09-07 freigegeben (Gate 1). **Bei jeder inhaltlichen Frage gilt sie.**
- [docs/clean-room/v2/11-konstruktkarte.md](docs/clean-room/v2/11-konstruktkarte.md) — 🟢 54 Konstrukte (Strang × Zahlenraum), aus der Matrix erzeugt. Ersetzt `01-construct-map.md`.
- [docs/clean-room/v2/12-blueprint.md](docs/clean-room/v2/12-blueprint.md) — 🟢 86 Items, Reihenfolge, Abkürzung, Blitz-Items. Aus der Konstruktkarte erzeugt. Ersetzt `02-blueprint.md`.
- [docs/clean-room/v2/14-itemregeln.md](docs/clean-room/v2/14-itemregeln.md) — 🟢 Abnahmekriterien I1–I12 für ein Item, je Regel der v1-Defekt dahinter.
- [docs/clean-room/v2/15-darstellungen.md](docs/clean-room/v2/15-darstellungen.md) — 🟢 Darstellungsschlüssel → Widget-Klasse → Manipulativ.
- [docs/clean-room/v2/README.md](docs/clean-room/v2/README.md) — 🟢 Was im v2-Baum liegt, welche Gates laufen und in welcher Reihenfolge.
- [docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md](docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md) — 🟢 **DER AKTUELLE PLAN.** Neuaufbau von Diagnostik und Übungsinhalten: Deckungsmatrix als Wurzelartefakt, Itemregeln, Rückkehr der handgebauten Übungs-Engine, Gates, Reihenfolge.
- [docs/clean-room/00-v1-assessment.md](docs/clean-room/00-v1-assessment.md) — 🟢 Warum v1 verworfen wurde. Die Befunde, gegen die CSVs und die Konstruktkarte verifiziert.
- [STATUS.md](STATUS.md) — 🟢 Was läuft, was steht, was abgelöst ist. Der Kopfstatus.
- [README.md](README.md) — 🟢 Projektüberblick in einer Seite.
- [rewrite.md](rewrite.md) — 🟢 Die rechtliche Begründung des Clean-Room-Ansatzes. Unverändert gültig — verworfen wurde die Ausführung, nicht die Doktrin.
- [TERMINOLOGY.md](TERMINOLOGY.md) — 🟢 Skill / Level / Problem. Einmal lesen und "Übung" vs. "Skill" ist geklärt.
- [phase1_school_platform.md](phase1_school_platform.md) — 🟢 Plattform-Plan (Backend, Dashboard, Flutter Web, Pilot). Phase D/E offen; Infrastruktur-Teil weiterhin korrekt.

## Übungs-Engine — wieder in Kraft

Die handgebaute, mehrstufige, manipulativ-basierte Engine kommt als kindseitiges Modell zurück
(v2-Entwurf §6). Diese Dokumente steuern sie und sind **nicht mehr pausiert**:

- [adhd guidelines.md](adhd%20guidelines.md) — 🟢 Sieben Gestaltungsprinzipien aus der ADHS-Forschung. Trägt Diagnostik- wie Übungsentscheidungen.
- [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md) — 🟢 Leicht→schwer→leicht innerhalb einer Stufe.
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) — 🟢 "Finished" vs. "Completed", Zeitgrenzen, Wertung.
- [EXERCISE_DESIGN_SYSTEM.md](EXERCISE_DESIGN_SYSTEM.md) — 🟢 Visuelle Spezifikation der Skill-Screens. (Nutzt im Fließtext noch "exercise"; `TERMINOLOGY.md` ist maßgeblich.)
- [COMMON_PITFALLS.md](COMMON_PITFALLS.md) — 🟢 Konkrete Fehlerrezepte aus der Übungsentwicklung.
- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) + [Research/REWARDS_SYSTEM.md](Research/REWARDS_SYSTEM.md) — 🟢 Die drei Belohnungsauslöser.
- [practice_skill_plan.md](practice_skill_plan.md) — 🟡 Aufgeschobener Plan für einen Skill zur Automatisierung der Übungserstellung (drei Blocker). Offen, aber ohne Priorität.

## Clean-Room — Rechtsrahmen und Prüfspur (gültig)

- [docs/clean-room/00-charter.md](docs/clean-room/00-charter.md) — 🟢 Die Charta des Clean-Room-Vorgehens.
- [docs/clean-room/03-bibliography.md](docs/clean-room/03-bibliography.md) — 🟢 Die Bibliographie; erscheint im Produkt als Seite "Wissenschaftliche Grundlagen".
- [docs/clean-room/decisions/](docs/clean-room/decisions/) — 🟢 ADRs 0001–0009. Fortlaufend nummeriert; ADR 0010 wird das iMINT-Deckungsaudit.
- [docs/clean-room/provenance.csv](docs/clean-room/provenance.csv) — 🟢 Prüfspur: Autor, Quellen, Reviewer je Artefakt. Bleibt in Betrieb, in v2 auf vier Felder verschlankt.
- [tasks.md](tasks.md) — 🟡 Ausführungsliste des **ersten** Durchlaufs. Trägt einen Nachtrag: die Haken beschreiben, *was getan wurde*, nicht dass das Ergebnis trägt. Weiterhin die Heimat der offenen Rechtsaufgaben (Phase R9: Fachanwalt, externe Fachprüfung, kommerzieller Schalter) und der Impressum/Datenschutz-Platzhalter.

## Clean-Room v1 — verworfen, nur noch Protokoll

Nicht löschen (sie sind die Prüfspur), aber nichts davon fortschreiben und nichts darauf berechnen:

- [docs/clean-room/01-construct-map.md](docs/clean-room/01-construct-map.md) — 🔴 Konstruktkarte v1 (31 Konstrukte). Abgelöst durch die Deckungsmatrix.
- [docs/clean-room/02-blueprint.md](docs/clean-room/02-blueprint.md) — 🔴 Blueprint v1 (59 Kern + 32 Deep-Dive).
- [docs/clean-room/items/](docs/clean-room/items/) — 🔴 Itembank v1 mit Provenance je Item.
- [docs/clean-room/skills/](docs/clean-room/skills/) — 🔴 36-Skill-Taxonomie v1 inkl. `specs/` (die generierten Übungs-Specs).
- [docs/clean-room/foerderplan/mapping-rationale.md](docs/clean-room/foerderplan/mapping-rationale.md) — 🔴 Item→Skill-Zuordnung v1.
- `math_app/Research/diagnostic_core_v1.csv` + `diagnostic_deepdive_v1.csv` — 🔴 die laufende Bank. Bleibt technisch in Betrieb (nur Jakob nutzt sie), gilt intern als unbrauchbar.
- [docs/clean-room/foerderplan/form-mapping.md](docs/clean-room/foerderplan/form-mapping.md) + [ordering-rule.md](docs/clean-room/foerderplan/ordering-rule.md) — 🟡 Spaltenlogik und Empfehlungsreihenfolge des Förderplans. Mechanik bleibt brauchbar, die Taxonomie darunter wird ersetzt.

## Archiv (historisch, nicht bearbeiten, kann dem aktuellen Stand widersprechen)

- [Archive/GAUNTLET_PROGRESS.md](Archive/GAUNTLET_PROGRESS.md) — 🔴 Evidenz-Log des Gauntlets (P1–P4, Integration, drei §3a-Kind-Runden). Loop am 2026-09-06 geschlossen. Die §3a-Befunde sind weiterhin lesenswert: sie zeigen, wie kindseitige Defekte gefunden werden.
- [docs/superpowers/gauntlet-loop.md](docs/superpowers/gauntlet-loop.md) — 🔴 Die Betriebsanleitung des geschlossenen Loops.
- [Archive/phase1.1_fixes.md](Archive/phase1.1_fixes.md) — 🔴 Elf Diagnostik-/Dashboard-Fixes, alle 2026-05-23 ausgeliefert.
- [Archive/phase0_tasks.md](Archive/phase0_tasks.md) · [Archive/phase0.5_german_pivot.md](Archive/phase0.5_german_pivot.md) — 🔴 Diagnostik→Förderplan-MVP und der deutsche UI-Pivot. Beide ausgeliefert.
- [Archive/tasks_2026-05.md](Archive/tasks_2026-05.md) · [Archive/tasks_full.md](Archive/tasks_full.md) · [Archive/tasks_old.md](Archive/tasks_old.md) — 🔴 Ältere Aufgabenlisten.
- [Archive/COMPLETED_TASKS.md](Archive/COMPLETED_TASKS.md) · [Archive/COMPLETED_TASKS_PHASE2.md](Archive/COMPLETED_TASKS_PHASE2.md) — 🔴 Fortschrittsprotokolle Phase 1 / 2.
- [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) · [Archive/C1.1_FINALE_PATTERN.md](Archive/C1.1_FINALE_PATTERN.md) · [Archive/LEVEL5_COMPLETION_FIX.md](Archive/LEVEL5_COMPLETION_FIX.md) — 🔴 Implementierungsnotizen der alten Engine. Beim Wiederaufbau als Referenz brauchbar, nicht als Vorgabe.
- [Archive/replace_diagnostic_images.md](Archive/replace_diagnostic_images.md) — 🔴 Einmalige Umstellung von Fotos auf Flutter-Widgets. Erledigt.
- `_sources_private/` — nicht im Git. Referenzmaterial (iMINT, PIKAS, Schulz, Altbestände). **Nie Grundlage eines ausgelieferten Artefakts**; beim Entwerfen nicht öffnen. Einzige zulässige Ausnahme: das einmalige, einseitige iMINT-Deckungsaudit nach v2-Entwurf §8, protokolliert als ADR 0010.

## Boilerplate / generiert

- [math_app/README.md](math_app/README.md) · [dashboard/README.md](dashboard/README.md) · `math_app/ios/.../LaunchImage.imageset/README.md` — ⚪ Framework-Boilerplate. Überspringen.

---

## Vorrangregel

Bei Widersprüchen gilt in dieser Reihenfolge:

**Deckungsmatrix** > **Konstruktkarte** > **Blueprint** > **v2-Entwurf** > `docs/clean-room/00-v1-assessment.md` > `STATUS.md` > `rewrite.md` (rechtlich) > `phase1_school_platform.md` (Infrastruktur) > `TERMINOLOGY.md` > Rest.

Die Deckungsmatrix (`docs/clean-room/v2/10-deckungsmatrix.md`) ist seit ihrer Freigabe am 2026-09-07 die
Quelle der Wahrheit für **alle inhaltlichen Fragen**: welche Konstrukte es gibt, in welchen Zahlenräumen
und Repräsentationen sie geprüft werden und welches Fehlerbild dahintersteht. Der v2-Entwurf beschreibt
nur noch, wie sie zustande kam und wie sie in Items, Übungen und Laufzeit übersetzt wird. Widerspricht
ein späteres Artefakt der Matrix, ist das Artefakt falsch — nicht die Matrix.
Konstruktkarte und Blueprint stehen über dem v2-Entwurf, weil sie aus der Matrix erzeugt
werden und der Entwurf nur noch beschreibt, wie das zustande kam.
