# Ableitungen aus der Deckungsmatrix (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the signed Deckungsmatrix into the two artifacts everything downstream reads — a Konstruktkarte and a Blueprint that are *generated* from it and can never drift — plus the written item acceptance criteria and the machine gate (`check_item_quality.py`) that enforces their mechanical half.

**Architecture:** The matrix stays the only hand-authored source. `scripts/derive_ableitungen.py` reads it and writes the body of `11-konstruktkarte.md` and `12-blueprint.md` between `AUTOGEN` markers; with `--check` it fails when those files no longer match what the matrix yields. That is the direct fix for v1's worst mechanical defect — a derived artifact (the runtime CSV) drifting from its source unnoticed (v2-Entwurf §7). Alongside them, three hand-authored documents define what an item file must contain (`14-itemregeln.md`, `15-darstellungen.md`, `items/TEMPLATE.md`), and `scripts/check_item_quality.py` enforces every part of that contract a machine can decide.

**Tech Stack:** Python 3.12 stdlib only (no pyyaml, no pytest — matching the existing `scripts/check_*.py` convention). Tests use stdlib `unittest`. All content artifacts and all script output are German.

**Spec:** `docs/superpowers/specs/2026-09-07-diagnostik-v2-design.md` — Phase 2 is §9 line 193; the substance is §3 (Artefakt-Architektur), §5.1 (Itemregeln), §5.3 (Abkürzung), §5.5 (Umfang), §7 (Generator/Drift) and §8 (Gates).

**Vorgänger:** `docs/superpowers/plans/2026-09-07-deckungsmatrix-phase1.md` (abgeschlossen; Matrix von Jakob am 2026-09-07 an Gate 1 freigegeben).

## Global Constraints

- **Python stdlib only.** No third-party imports in `scripts/`. Matches `check_provenance.py`, `check_mapping.py`, `check_deckung.py`, `check_item_independence.py`, `check_specs.py`, `check_skill_descriptions.py`.
- **Checker contract:** exit `0` on success printing a German `OK: …` line; exit `1` on failure printing one `FAIL: …` line per problem. The module docstring names the spec section it enforces.
- **No characters outside cp1252 in script output.** The Windows console this repo is developed on is cp1252: umlauts, `×` (U+00D7), `–` (U+2013) and `—` (U+2014) print fine, but an arrow `→` (U+2192) crashes the script on print. Write `->`.
- **German** for every artifact under `docs/clean-room/v2/` and for all script output. Python identifiers stay ASCII (`uebung`, not `übung`); the Markdown field label *is* `übung`.
- **The Deckungsmatrix is read-only in this phase.** `docs/clean-room/v2/10-deckungsmatrix.md` is signed. The only permitted edit is Task 6 Step 6, which adds one sentence to its preamble pointing at the derived documents — no cell, no status, no exemption, no vocabulary entry changes. If a task appears to need a matrix change, stop and ask Jakob; a matrix change re-opens Gate 1.
- **No diagnostic items are authored in this phase.** Items are Phase 3 content and each one needs Jakob's Gate 1 for its cell. Phase 2 delivers the *rules* and the *checker*; the only item files that exist at the end of it are test fixtures under `scripts/tests/fixtures/`, which are never in `docs/`.
- **No parallel bank-drafting** (v2-Entwurf §8). Applies to Phase 3 onward; named here so it is not forgotten.
- **Never commit, push or deploy without Jakob's explicit authorization for that specific action.** The commit steps below are written out but are **gated**: run them only after he says so in that session. A push to `main` auto-deploys the child client.
- **Do not open `_sources_private/`.** The single exception is the one-directional iMINT coverage audit, which is Phase 6.
- **Do not modify any v1 artifact.** `docs/clean-room/01-construct-map.md`, `02-blueprint.md`, `items/`, `skills/`, `foerderplan/mapping-rationale.md` and both runtime CSVs are frozen records. This plan *reads* two v1 items to build regression fixtures (Task 5) and writes nothing back.
- **Closed vocabulary:** Stränge (20 IDs), Zahlenräume (`ZR10`, `ZR20`, `ZR100`), Repräsentationen (`enaktiv`, `ikonisch`, `symbolisch`), Zellstatus (`offen`, `entworfen`, `freigegeben`, `–`). All come from the matrix's `## Vokabular`; anything else is a hard failure.

---

## The two design decisions this phase locks

Both change what everything downstream looks like. They are written here so the executing engineer does not re-invent them, and so Jakob can reject them at one place (Task 7's Gate 1) rather than after 86 items exist.

### Decision A — a Konstrukt is a (Strang × Zahlenraum) pair

The matrix has 152 live cells over three axes. A **Konstrukt** collapses the representation axis: it is one Strang in one Zahlenraum, and its live representations are the *evidence levels* inside it.

- **Why not the cell?** 152 constructs is not a report a teacher can read, and the representation is a property of *how* you probe an ability, not a separate ability. A child who cannot halve 50 cannot halve 50; whether they failed at the Dienes tray or on paper is diagnostic detail inside that finding, not a second finding.
- **Why not the Strang?** That is exactly v1's error — Verdoppeln existed as one construct and ZR100 vanished inside it.
- **Count:** 60 (Strang × ZR) pairs, of which **6 are entirely exempted** (`anzahl-simultan × ZR20`, `anzahl-simultan × ZR100`, `addition-mit-uebergang × ZR10`, `subtraktion-mit-uebergang × ZR10`, `flexibles-rechnen × ZR10`, `stellenwerttafel × ZR10`), leaving **54 Konstrukte**.
- **ID form:** `<strang>.<ZR>` — e.g. `verdoppeln-halbieren.ZR20`. Long but unambiguous, and derivable from the matrix without a lookup table.

### Decision B — the diagnostic tests constructs, the practice engine covers cells

The matrix's `check_deckung.py` currently demands a `diagnostik:` entry on every cell before it may be `freigegeben`. Taken literally that is ≥152 items, against the spec's own target of ~70–90 (§5.5). One of the two has to give, and it should be the per-cell item requirement:

- **`übung:` stays per cell.** Practice is where the representation genuinely matters — a child who cannot bundle at the tray needs the tray, not a worksheet. 152 cells, 152 exercise obligations.
- **`diagnostik:` becomes per construct.** A cell is `freigegeben` when its Konstrukt has at least one item and the cell itself has an exercise. Task 6 implements this as a change to `check_deckung.py`.

**Item allocation rule (Blueprint):**

- Every live Konstrukt gets **one Kern-Item**, at its **leitende Repräsentation** = the most symbolic live one (`symbolisch` > `ikonisch` > `enaktiv`). That is where a strategy shows itself and it is the cheapest to administer to a child alone at a device.
- A Konstrukt gets a **second item** when it has **all three representations live** *and* lies in **ZR20 or ZR100**, at its **stützende Repräsentation** = the most enactive live one (`enaktiv` > `ikonisch`). That is where the counting fingerprint shows. ZR10 is excluded because one probe per construct suffices where the numbers are small; ZR20/ZR100 is where strategies branch and a single symbolic item cannot tell retrieval from a fast procedure.
- **Result: 54 + 32 = 86 items.** Inside §5.5's 70–90, without a target length having been chosen first.

Both decisions are re-checkable at any time by running `python scripts/derive_ableitungen.py --check`.

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/derive_ableitungen.py` | Read the matrix; emit the Konstruktkarte and Blueprint AUTOGEN bodies. `--check` fails on drift. The *only* place the two derivation rules live in code. |
| `docs/clean-room/v2/11-konstruktkarte.md` | 54 Konstrukte. Hand-written preamble, generated body. Read by the Blueprint, the item files and (Phase 5) the Förderplan. |
| `docs/clean-room/v2/12-blueprint.md` | Item allocation, administration order, Abkürzung, Blitz-Items. Hand-written rules, generated allocation table. |
| `docs/clean-room/v2/14-itemregeln.md` | The acceptance criteria: v2-Entwurf §5.1 rules 1–12 restated as numbered, testable criteria, each labelled *maschinell* or *Gate 1*. The prose the checker implements. |
| `docs/clean-room/v2/15-darstellungen.md` | Registry: `darstellung`-key -> Dart widget class -> which manipulative it is. Closes v1's "prompt says Stäbchen, screen shows Würfel" defect by making the pairing a checked table. |
| `docs/clean-room/v2/items/TEMPLATE.md` | The v2 item file format. Every field the checker parses, with a filled example. |
| `scripts/check_item_quality.py` | Parse item files; enforce rules I1–I12. |
| `scripts/tests/test_derive_ableitungen.py` | Unit tests for the derivation rules. |
| `scripts/tests/test_check_item_quality.py` | Unit tests for the parser and each rule, including the v1 regression corpus. |
| `scripts/tests/fixtures/items/` | Item fixtures: one clean item, plus four transcribed v1 defects. Never under `docs/`. |
| `scripts/check_deckung.py` | Modified: Decision B (construct-level `diagnostik`), plus new rule R9. |
| `docs/clean-room/v2/README.md` | Modified: the new files, the new gate, the new command list. |
| `DOCS_INDEX.md`, `STATUS.md`, `docs/clean-room/provenance.csv` | Modified: index entries, status, audit rows. |

### AUTOGEN marker convention (Tasks 1, 2 and 6 all depend on it)

A generated body sits between two HTML comments. Everything outside them is hand-written and the generator never touches it.

```markdown
Hand-written preamble stays here.

<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, nicht von Hand bearbeiten -->

… generated content …

<!-- AUTOGEN:ENDE -->

Hand-written trailer stays here.
```

### Item file format (authoritative — Tasks 3, 4 and 5 all depend on it)

```markdown
# Item verdoppeln-halbieren.ZR20-01

- **item-id:** verdoppeln-halbieren.ZR20-01
- **konstrukt:** verdoppeln-halbieren.ZR20
- **zelle:** verdoppeln-halbieren × ZR20 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Rechne: 8 + 8
- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3
- **antwortfelder:**
  - `ergebnis` — Ergebnis
- **erwartete-antwort:**
  - `ergebnis` = 16
- **fehlersignatur:**
  - `15` — ±1 nach unten: zählend gerechnet, ein Schritt zu wenig
  - `17` — ±1 nach oben: zählend gerechnet, ein Schritt zu viel
  - `10` — die Verdopplung wird als Ergänzung zur Zehn missdeutet
- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Gaidoschik, Automatisierung der Kernaufgaben
- **eigenstaendigkeit:** Zahlenpaar, Wortlaut und Antwortlayout eigenständig gewählt; kein bestehendes Instrument als Vorlage.
- **reviewer:** —
```

Field semantics the checker relies on:

- `item-id` equals the filename stem and begins with `<konstrukt>-`.
- `zelle` uses the matrix's exact `strang × ZR × rep` spelling, with U+00D7 `×` and single spaces.
- `darstellung` is a key from `15-darstellungen.md`, or the literal `keine`.
- `darstellung-konfiguration` is free text, or `—` (U+2014) when `darstellung` is `keine`.
- `blitz` is `nein` or a duration like `800ms`.
- `antwortfelder` and `erwartete-antwort` are sub-bullet lists. Each `antwortfelder` line is `` - `key` — Label ``; each `erwartete-antwort` line is `` - `key` = value ``. Their key sets must be equal — that is rule I5, the arity check.
- `reviewer` is `—` until Jakob signs the item at Gate 1.

---

## Task 1: Konstruktkarte derived from the matrix

**Files:**
- Create: `scripts/derive_ableitungen.py`
- Create: `scripts/tests/test_derive_ableitungen.py`
- Create: `docs/clean-room/v2/11-konstruktkarte.md`

**Interfaces:**
- Consumes: `parse_matrix(text) -> Matrix` from `scripts/check_deckung.py` (`Matrix.strands: dict[str, str]` in document order, `Matrix.cells: dict[(strang, zr, rep), status]`, `Matrix.blocks: dict[(strang, zr, rep), dict[str, str]]`).
- Produces: `Konstrukt` dataclass; `konstrukte(matrix) -> list[Konstrukt]`; `render_konstruktkarte(konstrukte) -> str`; `splice(text, body) -> str`; module constants `REPS`, `ZRS`, `AUTOGEN_START`, `AUTOGEN_ENDE`.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_derive_ableitungen.py`:

```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_deckung import parse_matrix
from derive_ableitungen import konstrukte, render_konstruktkarte, splice

MATRIX = """\
# 10 — Deckungsmatrix (v2)

## Vokabular

**Stränge:**
- `zerlegung` — Zahlen in Teilmengen zerlegen und aus Teilmengen zusammensetzen
- `anzahl-simultan` — Anzahlen bis 5 auf einen Blick erfassen, ohne Zählhandlung

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: zerlegung

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | offen | offen | offen |
| ZR100 | offen | offen | offen |

### zerlegung × ZR10 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind legt die Teilmengen nebeneinander, ohne sie als Teile eines Ganzen zu lesen
- **diagnostik:** —
- **übung:** D1.1

### zerlegung × ZR10 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A
- **fehlerbild:** Kind zählt beide Teilbilder einzeln ab
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR10 × symbolisch

- **quelle:** Padberg/Benz, Teile-Ganzes
- **fehlerbild:** Zerlegungen der 10 sind nicht abrufbar
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × enaktiv

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind entbündelt nicht, sondern zählt neu
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × ikonisch

- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe B
- **fehlerbild:** Kind liest das Zwanzigerfeld nicht als Fünferstruktur
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR20 × symbolisch

- **quelle:** Gaidoschik, Kernaufgaben
- **fehlerbild:** Kind rechnet die Zerlegung jedes Mal neu aus
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × enaktiv

- **quelle:** Moser Opitz, Stellenwert
- **fehlerbild:** Kind zerlegt stellenweise falsch
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × ikonisch

- **quelle:** Moser Opitz, Stellenwert
- **fehlerbild:** Kind liest das Hunderterfeld zeilenweise ab
- **diagnostik:** —
- **übung:** —

### zerlegung × ZR100 × symbolisch

- **quelle:** Selter/Spiegel, denkendes Rechnen
- **fehlerbild:** Kind zerlegt nur in Zehner und Einer, nicht flexibel
- **diagnostik:** —
- **übung:** —

## Strang: anzahl-simultan

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | – |
| ZR20 | – | – | – |
| ZR100 | – | – | – |

**Ausnahmen:**
- `anzahl-simultan × ZR10 × symbolisch` — Simultanerfassung wird an Mengen geprüft, nicht an Ziffern.
- `anzahl-simultan × ZR20 × enaktiv` — Simultanerfassung ist bei 5 gedeckelt, im ZR20 misst sie Zählen.
- `anzahl-simultan × ZR20 × ikonisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR20 misst sie Zählen.
- `anzahl-simultan × ZR20 × symbolisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR20 misst sie Zählen.
- `anzahl-simultan × ZR100 × enaktiv` — Simultanerfassung ist bei 5 gedeckelt, im ZR100 misst sie Zählen.
- `anzahl-simultan × ZR100 × ikonisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR100 misst sie Zählen.
- `anzahl-simultan × ZR100 × symbolisch` — Simultanerfassung ist bei 5 gedeckelt, im ZR100 misst sie Zählen.

### anzahl-simultan × ZR10 × enaktiv

- **quelle:** Krajewski, Anzahlerfassung
- **fehlerbild:** Kind tippt die Plättchen einzeln an, statt die Menge zu erfassen
- **diagnostik:** —
- **übung:** —

### anzahl-simultan × ZR10 × ikonisch

- **quelle:** Krajewski, Anzahlerfassung
- **fehlerbild:** Kind zählt die Punkte einzeln, die Latenz wächst mit der Anzahl
- **diagnostik:** —
- **übung:** —
"""


class KonstrukteTest(unittest.TestCase):
    def setUp(self):
        self.k = konstrukte(parse_matrix(MATRIX))
        self.by_id = {k.id: k for k in self.k}

    def test_one_konstrukt_per_live_strang_zahlenraum_pair(self):
        # zerlegung has three live Zahlenräume, anzahl-simultan only ZR10.
        self.assertEqual(len(self.k), 4)
        self.assertEqual(
            [k.id for k in self.k],
            [
                "zerlegung.ZR10",
                "zerlegung.ZR20",
                "zerlegung.ZR100",
                "anzahl-simultan.ZR10",
            ],
        )

    def test_fully_exempted_pairs_produce_no_konstrukt(self):
        self.assertNotIn("anzahl-simultan.ZR20", self.by_id)
        self.assertNotIn("anzahl-simultan.ZR100", self.by_id)

    def test_konstrukt_keeps_only_live_representations_in_axis_order(self):
        self.assertEqual(
            self.by_id["anzahl-simultan.ZR10"].repraesentationen,
            ["enaktiv", "ikonisch"],
        )
        self.assertEqual(
            self.by_id["zerlegung.ZR20"].repraesentationen,
            ["enaktiv", "ikonisch", "symbolisch"],
        )

    def test_leading_representation_is_the_most_symbolic_live_one(self):
        self.assertEqual(self.by_id["zerlegung.ZR20"].leitend, "symbolisch")
        self.assertEqual(self.by_id["anzahl-simultan.ZR10"].leitend, "ikonisch")

    def test_supporting_representation_is_the_most_enactive_live_one(self):
        self.assertEqual(self.by_id["zerlegung.ZR20"].stuetzend, "enaktiv")

    def test_konstrukt_carries_the_fehlerbild_of_each_live_cell(self):
        k = self.by_id["zerlegung.ZR10"]
        self.assertIn("Teile eines Ganzen", k.fehlerbilder["enaktiv"])
        self.assertIn("nicht abrufbar", k.fehlerbilder["symbolisch"])

    def test_konstrukt_collects_sources_without_duplicates_in_order(self):
        k = self.by_id["zerlegung.ZR10"]
        self.assertEqual(
            k.quellen,
            ["RLP BE/BB Teil C, L1, Niveaustufe A", "Padberg/Benz, Teile-Ganzes"],
        )

    def test_konstrukt_collects_exercise_ids_of_its_cells(self):
        self.assertEqual(self.by_id["zerlegung.ZR10"].uebungen, ["D1.1"])
        self.assertEqual(self.by_id["zerlegung.ZR20"].uebungen, [])


class RenderKonstruktkarteTest(unittest.TestCase):
    def setUp(self):
        self.body = render_konstruktkarte(konstrukte(parse_matrix(MATRIX)))

    def test_lists_every_konstrukt_with_a_heading(self):
        self.assertIn("### zerlegung.ZR20", self.body)
        self.assertIn("### anzahl-simultan.ZR10", self.body)

    def test_names_the_leading_and_supporting_representation(self):
        self.assertIn("**leitende Repräsentation:** symbolisch", self.body)
        self.assertIn("**stützende Repräsentation:** enaktiv", self.body)

    def test_states_the_total(self):
        self.assertIn("4 Konstrukte", self.body)

    def test_output_is_cp1252_safe(self):
        self.body.encode("cp1252")


class SpliceTest(unittest.TestCase):
    def test_replaces_only_the_marked_region(self):
        doc = (
            "Vorspann\n\n"
            "<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, "
            "nicht von Hand bearbeiten -->\n\nalt\n\n"
            "<!-- AUTOGEN:ENDE -->\n\nNachspann\n"
        )
        out = splice(doc, "neu")
        self.assertIn("Vorspann", out)
        self.assertIn("Nachspann", out)
        self.assertIn("neu", out)
        self.assertNotIn("alt", out)

    def test_missing_marker_raises(self):
        with self.assertRaises(ValueError):
            splice("kein Marker hier", "neu")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_derive_ableitungen -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'derive_ableitungen'`.

- [ ] **Step 3: Write the implementation**

Create `scripts/derive_ableitungen.py`:

```python
#!/usr/bin/env python3
"""Leitet Konstruktkarte und Blueprint aus der Deckungsmatrix ab (v2-Entwurf §3, §9).

Die Matrix ist die einzige handgeschriebene Quelle. Diese beiden Dokumente sind
Ableitungen: alles zwischen den AUTOGEN-Marken erzeugt dieses Skript, alles
außerhalb bleibt von Hand geschrieben.

Ohne Argument werden beide Dateien neu geschrieben. Mit --check wird nichts
geschrieben, sondern geprüft, ob sie noch dem entsprechen, was die Matrix
ergibt — der Driftschutz, an dem v1 gescheitert ist (v2-Entwurf §7).

Exit 0 wenn sauber, Exit 1 mit je einer FAIL-Zeile pro Problem.
"""

import argparse
import sys
from dataclasses import dataclass, field
from pathlib import Path

from check_deckung import MATRIX_PATH, parse_matrix

ROOT = Path(__file__).resolve().parents[1]
V2 = ROOT / "docs" / "clean-room" / "v2"
KONSTRUKTKARTE_PATH = V2 / "11-konstruktkarte.md"
BLUEPRINT_PATH = V2 / "12-blueprint.md"

ZRS = ("ZR10", "ZR20", "ZR100")
REPS = ("enaktiv", "ikonisch", "symbolisch")
LEER = "—"

AUTOGEN_START = (
    "<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, "
    "nicht von Hand bearbeiten -->"
)
AUTOGEN_ENDE = "<!-- AUTOGEN:ENDE -->"


@dataclass
class Konstrukt:
    id: str
    strang: str
    zahlenraum: str
    beschreibung: str
    repraesentationen: list = field(default_factory=list)
    quellen: list = field(default_factory=list)
    fehlerbilder: dict = field(default_factory=dict)
    uebungen: list = field(default_factory=list)

    @property
    def leitend(self):
        """Die symbolischste lebende Repraesentation - dort zeigt sich die Strategie."""
        for rep in reversed(REPS):
            if rep in self.repraesentationen:
                return rep
        return None

    @property
    def stuetzend(self):
        """Die enaktivste lebende Repraesentation - dort zeigt sich das Zaehlen."""
        for rep in REPS:
            if rep in self.repraesentationen:
                return rep
        return None


def split_list(value):
    """'RLP …; Padberg/Benz …' -> ['RLP …', 'Padberg/Benz …']; '—' -> []."""
    if not value or value == LEER:
        return []
    return [tok.strip() for tok in value.split(";") if tok.strip()]


def konstrukte(matrix):
    """Ein Konstrukt je lebendem (Strang x Zahlenraum)-Paar, in Dokumentreihenfolge."""
    result = []
    for strang, beschreibung in matrix.strands.items():
        for zr in ZRS:
            live = [
                rep for rep in REPS
                if matrix.cells.get((strang, zr, rep), "–") != "–"
            ]
            if not live:
                continue
            k = Konstrukt(
                id=f"{strang}.{zr}",
                strang=strang,
                zahlenraum=zr,
                beschreibung=beschreibung,
                repraesentationen=live,
            )
            for rep in live:
                block = matrix.blocks.get((strang, zr, rep), {})
                k.fehlerbilder[rep] = block.get("fehlerbild", "")
                for quelle in split_list(block.get("quelle", "")):
                    if quelle not in k.quellen:
                        k.quellen.append(quelle)
                for uebung in split_refs_local(block.get("übung", "")):
                    if uebung not in k.uebungen:
                        k.uebungen.append(uebung)
            result.append(k)
    return result


def split_refs_local(value):
    """Wie check_deckung.split_refs, hier importiert statt kopiert."""
    from check_deckung import split_refs
    return split_refs(value)


def render_konstruktkarte(ks):
    lines = [
        f"**{len(ks)} Konstrukte** aus {len({k.strang for k in ks})} Strängen. "
        "Ein Konstrukt ist ein Strang in einem Zahlenraum; die Repräsentationen "
        "sind die Evidenzstufen darin.",
        "",
        "| Konstrukt | Strang | Zahlenraum | lebende Repräsentationen | leitend | stützend |",
        "|---|---|---|---|---|---|",
    ]
    for k in ks:
        lines.append(
            f"| `{k.id}` | {k.strang} | {k.zahlenraum} | "
            f"{', '.join(k.repraesentationen)} | {k.leitend} | {k.stuetzend} |"
        )
    lines.append("")
    for k in ks:
        lines.append(f"### {k.id}")
        lines.append("")
        lines.append(f"- **Beschreibung:** {k.beschreibung} — im {k.zahlenraum}")
        lines.append(f"- **lebende Repräsentation:** {', '.join(k.repraesentationen)}")
        lines.append(f"- **leitende Repräsentation:** {k.leitend}")
        lines.append(
            f"- **stützende Repräsentation:** {k.stuetzend}"
            if k.stuetzend != k.leitend
            else "- **stützende Repräsentation:** — (nur eine lebende Repräsentation)"
        )
        lines.append(f"- **Quellen:** {'; '.join(k.quellen) if k.quellen else LEER}")
        lines.append(
            f"- **Übungen im Bestand:** {', '.join(k.uebungen) if k.uebungen else LEER}"
        )
        lines.append("- **Fehlerbilder je Repräsentation:**")
        for rep in k.repraesentationen:
            lines.append(f"  - *{rep}* — {k.fehlerbilder.get(rep, '')}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def splice(text, body):
    """Ersetzt den Bereich zwischen den AUTOGEN-Marken durch body."""
    start = text.find(AUTOGEN_START)
    ende = text.find(AUTOGEN_ENDE)
    if start == -1 or ende == -1 or ende < start:
        raise ValueError("AUTOGEN-Marken fehlen oder stehen in falscher Reihenfolge")
    head = text[: start + len(AUTOGEN_START)]
    tail = text[ende:]
    return f"{head}\n\n{body}\n{tail}"


def write_or_check(path, body, check):
    """Schreibt die Datei neu oder meldet Drift. Gibt eine Fehlerliste zurueck."""
    if not path.exists():
        return [f"{path.name} fehlt — erst anlegen, dann erzeugen"]
    current = path.read_text(encoding="utf-8")
    try:
        wanted = splice(current, body)
    except ValueError as exc:
        return [f"{path.name}: {exc}"]
    if check:
        if current != wanted:
            return [
                f"{path.name} weicht von der Matrix ab — "
                "`python scripts/derive_ableitungen.py` ausfuehren"
            ]
        return []
    path.write_text(wanted, encoding="utf-8")
    return []


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Konstruktkarte und Blueprint aus der Deckungsmatrix ableiten."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="nichts schreiben, nur auf Drift gegen die Matrix pruefen",
    )
    args = parser.parse_args(argv)

    matrix = parse_matrix(MATRIX_PATH.read_text(encoding="utf-8"))
    ks = konstrukte(matrix)

    errors = write_or_check(KONSTRUKTKARTE_PATH, render_konstruktkarte(ks), args.check)

    verb = "geprueft" if args.check else "erzeugt"
    print(f"derive_ableitungen: {len(ks)} Konstrukte aus {len(matrix.cells)} Zellen {verb}")
    if errors:
        for err in errors:
            print("FAIL:", err)
        return 1
    print("OK: Ableitungen stimmen mit der Matrix ueberein")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m unittest scripts.tests.test_derive_ableitungen -v`
Expected: PASS, 14 tests (8 `KonstrukteTest` + 4 `RenderKonstruktkarteTest` + 2 `SpliceTest`).

- [ ] **Step 5: Create the Konstruktkarte shell with its hand-written preamble**

Create `docs/clean-room/v2/11-konstruktkarte.md`:

```markdown
# 11 — Konstruktkarte (v2)

| | |
|---|---|
| **Status** | Entwurf — Gate 1 offen |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Quelle** | [10-deckungsmatrix.md](10-deckungsmatrix.md) — freigegeben 2026-09-07 |
| **Erzeugt von** | `python scripts/derive_ableitungen.py` |
| **Gate** | `python scripts/derive_ableitungen.py --check` |

Dieses Dokument ist **abgeleitet**. Es wird nicht von Hand gepflegt: der Rumpf unten
entsteht aus der Deckungsmatrix, und `--check` schlägt fehl, sobald beide auseinanderlaufen.
Genau dieser Drift — ein abgeleitetes Artefakt, das seiner Quelle davonläuft, ohne dass
es jemand merkt — hat in v1 22 veraltete Fragetexte in die laufende CSV gebracht
(v2-Entwurf §7). Soll sich hier etwas ändern, ändert sich die Matrix.

**Was ein Konstrukt ist.** Ein Strang in einem Zahlenraum. Die Repräsentation ist keine
eigene Fähigkeit, sondern die Stufe, auf der wir eine Fähigkeit erheben; sie bleibt als
Evidenzstufe *innerhalb* des Konstrukts sichtbar. Ein Kind, das 50 nicht halbieren kann,
kann 50 nicht halbieren — ob es am Dienes-Material oder auf dem Papier scheitert, ist der
diagnostische Befund darin, nicht ein zweiter Befund.

Warum nicht der Strang allein: das war v1s Fehler. „Verdoppeln" war ein Konstrukt, und
der ZR100 ist darin verschwunden.

**Leitende und stützende Repräsentation.** Die *leitende* ist die symbolischste lebende —
dort zeigt sich die Strategie, und sie ist für ein Kind allein am Gerät am billigsten zu
erheben. Die *stützende* ist die enaktivste lebende — dort zeigt sich das zählende Rechnen.
Der Blueprint (12-blueprint.md) verteilt die Items entlang dieser beiden.

**Vorrang:** Deckungsmatrix > Konstruktkarte > Blueprint > Items/Übungen.

<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, nicht von Hand bearbeiten -->

<!-- AUTOGEN:ENDE -->
```

- [ ] **Step 6: Generate the body and read it**

Run: `python scripts/derive_ableitungen.py`
Expected: `derive_ableitungen: 54 Konstrukte aus 180 Zellen erzeugt` and `OK: …`.

Then read the file and confirm by eye: 54 rows in the overview table, `anzahl-simultan.ZR20` and `anzahl-simultan.ZR100` absent, `stellenwerttafel.ZR10` absent, `verdoppeln-halbieren.ZR100` present with `leitend: symbolisch`.

Run: `python -c "print(open('docs/clean-room/v2/11-konstruktkarte.md',encoding='utf-8').read().count('### '))"`
Expected: `54`.

- [ ] **Step 7: Verify the drift guard actually fires**

Run:
```bash
python -c "
p='docs/clean-room/v2/11-konstruktkarte.md'
t=open(p,encoding='utf-8').read().replace('### zerlegung.ZR10','### zerlegung.ZR11',1)
open(p,'w',encoding='utf-8').write(t)"
python scripts/derive_ableitungen.py --check
```
Expected: exit 1, `FAIL: 11-konstruktkarte.md weicht von der Matrix ab — …`.

Then restore and re-verify:
```bash
python scripts/derive_ableitungen.py && python scripts/derive_ableitungen.py --check
```
Expected: exit 0 both times.

- [ ] **Step 8: Commit** *(gated — only after Jakob authorizes)*

```bash
git add scripts/derive_ableitungen.py scripts/tests/test_derive_ableitungen.py docs/clean-room/v2/11-konstruktkarte.md
git commit -m "$(cat <<'EOF'
feat(v2): Konstruktkarte aus der Deckungsmatrix ableiten (54 Konstrukte)

Ein Konstrukt ist ein Strang in einem Zahlenraum; die Repraesentation bleibt
Evidenzstufe darin. 60 Paare minus 6 vollstaendig ausgenommene ergeben 54.

Der Rumpf der Konstruktkarte wird erzeugt, nicht gepflegt: --check schlaegt
fehl, sobald Karte und Matrix auseinanderlaufen. Das ist der Driftschutz gegen
v1s 22 veraltete Fragetexte in der laufenden CSV.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Blueprint — item allocation, order, Abkürzung

**Files:**
- Modify: `scripts/derive_ableitungen.py` (add `zuteilung`, `render_blueprint`, wire into `main`)
- Modify: `scripts/tests/test_derive_ableitungen.py` (append a test class)
- Create: `docs/clean-room/v2/12-blueprint.md`

**Interfaces:**
- Consumes: `Konstrukt` and `konstrukte(matrix)` from Task 1; `Konstrukt.leitend`, `Konstrukt.stuetzend`, `Konstrukt.repraesentationen`, `Konstrukt.zahlenraum`.
- Produces: `Item` dataclass (`id: str`, `konstrukt: str`, `repraesentation: str`, `rolle: str`, `blitz: bool`, `position: int`); `zuteilung(konstrukte) -> list[Item]`; `render_blueprint(konstrukte, items) -> str`; module constant `BLITZ_STRAENGE`.

- [ ] **Step 1: Write the failing test**

Append to `scripts/tests/test_derive_ableitungen.py` (before the `if __name__` block), and add `Item`, `zuteilung`, `render_blueprint` to the import line at the top:

```python
class ZuteilungTest(unittest.TestCase):
    def setUp(self):
        self.ks = konstrukte(parse_matrix(MATRIX))
        self.items = zuteilung(self.ks)
        self.by_konstrukt = {}
        for item in self.items:
            self.by_konstrukt.setdefault(item.konstrukt, []).append(item)

    def test_every_konstrukt_gets_a_kern_item(self):
        for k in self.ks:
            self.assertGreaterEqual(len(self.by_konstrukt[k.id]), 1)
            self.assertEqual(self.by_konstrukt[k.id][0].rolle, "Kern")

    def test_kern_item_sits_at_the_leading_representation(self):
        self.assertEqual(
            self.by_konstrukt["zerlegung.ZR20"][0].repraesentation, "symbolisch"
        )
        self.assertEqual(
            self.by_konstrukt["anzahl-simultan.ZR10"][0].repraesentation, "ikonisch"
        )

    def test_second_item_only_when_all_three_reps_live_and_zr20_or_zr100(self):
        self.assertEqual(len(self.by_konstrukt["zerlegung.ZR20"]), 2)
        self.assertEqual(len(self.by_konstrukt["zerlegung.ZR100"]), 2)
        # ZR10 is excluded by the rule even with three live representations.
        self.assertEqual(len(self.by_konstrukt["zerlegung.ZR10"]), 1)
        # Two live representations is not enough.
        self.assertEqual(len(self.by_konstrukt["anzahl-simultan.ZR10"]), 1)

    def test_second_item_sits_at_the_supporting_representation(self):
        second = self.by_konstrukt["zerlegung.ZR20"][1]
        self.assertEqual(second.repraesentation, "enaktiv")
        self.assertEqual(second.rolle, "Stütze")

    def test_item_ids_are_konstrukt_plus_two_digit_index(self):
        self.assertEqual(
            [i.id for i in self.by_konstrukt["zerlegung.ZR20"]],
            ["zerlegung.ZR20-01", "zerlegung.ZR20-02"],
        )

    def test_positions_are_gapless_and_start_at_one(self):
        self.assertEqual(
            [i.position for i in self.items], list(range(1, len(self.items) + 1))
        )

    def test_administration_order_is_strand_major_then_zahlenraum_ascending(self):
        order = [i.konstrukt for i in self.items]
        self.assertLess(order.index("zerlegung.ZR10"), order.index("zerlegung.ZR20"))
        self.assertLess(order.index("zerlegung.ZR20"), order.index("zerlegung.ZR100"))
        self.assertLess(
            order.index("zerlegung.ZR100"), order.index("anzahl-simultan.ZR10")
        )

    def test_blitz_flag_follows_the_named_strand_list(self):
        blitz = {i.id: i.blitz for i in self.items}
        self.assertTrue(blitz["anzahl-simultan.ZR10-01"])
        self.assertTrue(blitz["zerlegung.ZR10-01"])
        self.assertFalse(blitz["zerlegung.ZR20-02"])  # Stütze is never a Blitz item


class RenderBlueprintTest(unittest.TestCase):
    def setUp(self):
        ks = konstrukte(parse_matrix(MATRIX))
        self.body = render_blueprint(ks, zuteilung(ks))

    def test_states_both_totals(self):
        self.assertIn("4 Konstrukte", self.body)
        self.assertIn("6 Items", self.body)

    def test_allocation_table_carries_every_item_once(self):
        for item_id in ("zerlegung.ZR10-01", "zerlegung.ZR20-02", "anzahl-simultan.ZR10-01"):
            self.assertEqual(self.body.count(f"`{item_id}`"), 1)

    def test_output_is_cp1252_safe(self):
        self.body.encode("cp1252")
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_derive_ableitungen -v`
Expected: FAIL — `ImportError: cannot import name 'zuteilung'`.

- [ ] **Step 3: Write the implementation**

In `scripts/derive_ableitungen.py`, add after the `Konstrukt` dataclass:

```python
# Straenge, deren Kern-Item als Blitz-Item gestellt wird: dort wird Abruf
# gemessen, nicht ein Verfahren, und eine kurze Darbietung macht Zaehlen
# konstruktiv unmoeglich (v2-Entwurf §5.2). Redaktionelle Festlegung.
BLITZ_STRAENGE = (
    "anzahl-simultan",
    "anzahl-strukturiert",
    "vorgaenger-nachfolger",
    "zerlegung",
    "verdoppeln-halbieren",
)


@dataclass
class Item:
    id: str
    konstrukt: str
    repraesentation: str
    rolle: str
    blitz: bool
    position: int
```

and after `konstrukte()`:

```python
def zuteilung(ks):
    """Verteilt Items auf Konstrukte (Blueprint-Regel, v2-Entwurf §5.5).

    Jedes Konstrukt bekommt ein Kern-Item an seiner leitenden Repraesentation.
    Ein zweites, stuetzendes Item bekommt ein Konstrukt genau dann, wenn alle
    drei Repraesentationen leben und es im ZR20 oder ZR100 liegt: dort
    verzweigen die Strategien, und ein einzelnes symbolisches Item kann Abruf
    nicht von einem schnellen Verfahren unterscheiden.
    """
    items = []
    position = 0
    for k in ks:
        position += 1
        items.append(Item(
            id=f"{k.id}-01",
            konstrukt=k.id,
            repraesentation=k.leitend,
            rolle="Kern",
            blitz=k.strang in BLITZ_STRAENGE,
            position=position,
        ))
        if len(k.repraesentationen) == 3 and k.zahlenraum in ("ZR20", "ZR100"):
            position += 1
            items.append(Item(
                id=f"{k.id}-02",
                konstrukt=k.id,
                repraesentation=k.stuetzend,
                rolle="Stütze",
                blitz=False,
                position=position,
            ))
    return items


def render_blueprint(ks, items):
    zweite = sum(1 for i in items if i.rolle == "Stütze")
    blitz = sum(1 for i in items if i.blitz)
    lines = [
        f"**{len(ks)} Konstrukte, {len(items)} Items** — "
        f"{len(ks)} Kern-Items und {zweite} stützende Items, davon {blitz} Blitz-Items.",
        "",
        "| # | Item | Konstrukt | Zahlenraum | Repräsentation | Rolle | Blitz |",
        "|---|---|---|---|---|---|---|",
    ]
    zr_of = {k.id: k.zahlenraum for k in ks}
    for item in items:
        lines.append(
            f"| {item.position} | `{item.id}` | `{item.konstrukt}` | "
            f"{zr_of[item.konstrukt]} | {item.repraesentation} | {item.rolle} | "
            f"{'ja' if item.blitz else 'nein'} |"
        )
    lines.append("")
    lines.append("### Abkürzungstabelle")
    lines.append("")
    lines.append("| Strang | ZR10 | ZR20 | ZR100 |")
    lines.append("|---|---|---|---|")
    for strang in dict.fromkeys(k.strang for k in ks):
        row = []
        for zr in ZRS:
            hit = [k for k in ks if k.strang == strang and k.zahlenraum == zr]
            row.append(f"`{hit[0].id}`" if hit else "—")
        lines.append(f"| {strang} | {row[0]} | {row[1]} | {row[2]} |")
    return "\n".join(lines).rstrip() + "\n"
```

and extend `main()` — replace the single `errors = …` line with:

```python
    errors = write_or_check(KONSTRUKTKARTE_PATH, render_konstruktkarte(ks), args.check)
    items = zuteilung(ks)
    errors += write_or_check(BLUEPRINT_PATH, render_blueprint(ks, items), args.check)
```

and replace the summary print with:

```python
    print(f"derive_ableitungen: {len(ks)} Konstrukte, {len(items)} Items "
          f"aus {len(matrix.cells)} Zellen {verb}")
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python -m unittest scripts.tests.test_derive_ableitungen -v`
Expected: PASS, 25 tests (the 14 from Task 1, plus 8 `ZuteilungTest` and 3 `RenderBlueprintTest`).

- [ ] **Step 5: Create the Blueprint shell with its hand-written rules**

Create `docs/clean-room/v2/12-blueprint.md`:

```markdown
# 12 — Blueprint (v2)

| | |
|---|---|
| **Status** | Entwurf — Gate 1 offen |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Quelle** | [11-konstruktkarte.md](11-konstruktkarte.md), abgeleitet aus [10-deckungsmatrix.md](10-deckungsmatrix.md) |
| **Erzeugt von** | `python scripts/derive_ableitungen.py` |
| **Gate** | `python scripts/derive_ableitungen.py --check` |

Der Rumpf dieses Dokuments ist **abgeleitet** und wird nicht von Hand gepflegt. Die Regeln
oberhalb der AUTOGEN-Marke sind redaktionelle Festlegungen; die Tabelle darunter ist ihre
mechanische Anwendung auf die Matrix.

## Itemzahl

**Ein Kern-Item je Konstrukt**, an dessen leitender Repräsentation. **Ein zweites,
stützendes Item** bekommt ein Konstrukt genau dann, wenn alle drei Repräsentationen leben
*und* es im ZR20 oder ZR100 liegt. Ergebnis: 86 Items.

Begründung des zweiten Items: im ZR10 genügt eine Sonde je Konstrukt, die Zahlen sind
klein und der Befund eindeutig. Ab dem ZR20 verzweigen die Strategien, und ein einzelnes
symbolisches Item kann Abruf nicht von einem schnell ausgeführten Verfahren unterscheiden.
Das stützende Item steht deshalb an der enaktivsten lebenden Repräsentation — dort wird
sichtbar, ob das Kind zählt.

**Keine Zielgröße.** Die 86 sind das Ergebnis der Regel, nicht deren Vorgabe (v2-Entwurf
§5.5: Vollständigkeit vor Kürze). Die Abkürzung kürzt für das einzelne Kind.

## Diagnostik je Konstrukt, Übung je Zelle

Ein Item gehört zu einem **Konstrukt**, eine Übung zu einer **Zelle**. Beim Üben ist die
Repräsentation die Sache selbst — ein Kind, das am Material nicht bündeln kann, braucht
das Material, kein Arbeitsblatt. Beim Erheben ist sie die Sonde, und 152 Sonden sind kein
Befund, den eine Lehrkraft lesen kann.

Eine Zelle ist deshalb `freigegeben`, wenn **ihr Konstrukt ein Item** und **sie selbst eine
Übung** hat. `scripts/check_deckung.py` prüft genau das.

## Reihenfolge

Strangweise in der Reihenfolge der Matrix, innerhalb eines Strangs ZR10 -> ZR20 -> ZR100,
innerhalb eines Konstrukts Kern-Item vor stützendem Item. Die Positionsnummern sind
lückenlos und stabil: sie sind ein Vertrag, keine Anzeigeentscheidung (v2-Entwurf §7), und
die Sitzung nimmt sie über Wochen hinweg unverändert wieder auf (§5.4).

Der monotone Schwierigkeitsverlauf aus §5.1 Regel 12 gilt **innerhalb eines Strangs**. Der
Sprung von `<strang>.ZR100` auf `<nächster-strang>.ZR10` ist gewollt und kein Defekt.

## Abkürzung

Strangintern (v2-Entwurf §5.3). Sind **alle** Items eines Konstrukts falsch, werden die
Konstrukte desselben Strangs in den höheren Zahlenräumen als `übersprungen (Abkürzung)`
vermerkt — nie als falsch. Der Förderplan schreibt „im ZR100 nicht erhoben".

Kein strangübergreifender Abbruch. v1 hat bei einem Zählfehler die ganze Domäne C
übersprungen und der Lehrkraft damit Information genommen, die sie brauchte.

## Blitz-Items

Kern-Items der Stränge `anzahl-simultan`, `anzahl-strukturiert`, `vorgaenger-nachfolger`,
`zerlegung` und `verdoppeln-halbieren` werden als Blitz-Items gestellt: die Darbietung ist
so kurz, dass Zählen konstruktiv unmöglich ist. Das ist die sauberste maschinenlesbare
Evidenz für das Konstrukt, nach dem das Produkt benannt ist; v1 hatte genau ein solches
Item. Stützende Items sind nie Blitz-Items — sie sollen das Zählen ja sichtbar machen.

## Keine Schwierigkeitsquote

v1 hat 30/50/20 auf leicht/mittel/schwer verteilt und die Passquoten geschätzt, ohne je ein
Kind gesehen zu haben. Solche Zahlen werden hier nicht erfunden. Die Schwierigkeit ergibt
sich aus Konstrukt und Zahlenraum; geprüft wird die Monotonie innerhalb des Strangs, und
nachgezogen wird nach den ersten echten Sitzungen.

<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, nicht von Hand bearbeiten -->

<!-- AUTOGEN:ENDE -->
```

- [ ] **Step 6: Generate both bodies and verify the totals**

Run: `python scripts/derive_ableitungen.py`
Expected: `derive_ableitungen: 54 Konstrukte, 86 Items aus 180 Zellen erzeugt` and `OK: …`.

Run: `python scripts/derive_ableitungen.py --check`
Expected: exit 0.

If the item count is not 86, **stop and report it** — the number is a load-bearing claim of this plan and of §5.5, and a mismatch means the allocation rule or the matrix has changed since 2026-09-08.

- [ ] **Step 7: Commit** *(gated)*

```bash
git add scripts/derive_ableitungen.py scripts/tests/test_derive_ableitungen.py docs/clean-room/v2/12-blueprint.md docs/clean-room/v2/11-konstruktkarte.md
git commit -m "$(cat <<'EOF'
feat(v2): Blueprint aus der Konstruktkarte ableiten - 86 Items auf 54 Konstrukte

Ein Kern-Item je Konstrukt an der leitenden Repraesentation; ein zweites,
stuetzendes Item, wo alle drei Repraesentationen leben und der Zahlenraum ZR20
oder ZR100 ist. 54 + 32 = 86, innerhalb der 70-90 aus dem v2-Entwurf §5.5 -
als Ergebnis der Regel, nicht als vorher gewaehlte Zielgroesse.

Diagnostik gehoert zum Konstrukt, Uebung zur Zelle. Reihenfolge strangweise,
Abkuerzung strangintern, keine erfundene Schwierigkeitsquote.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Itemregeln, Darstellungsregister und Item-Template

**Files:**
- Create: `docs/clean-room/v2/14-itemregeln.md`
- Create: `docs/clean-room/v2/15-darstellungen.md`
- Create: `docs/clean-room/v2/items/TEMPLATE.md`

**Interfaces:**
- Consumes: nothing in code.
- Produces: the field names, the `darstellung` keys and the rule numbers `I1`–`I12` that Tasks 4 and 5 implement. `15-darstellungen.md` carries a table whose rows are `| key | Widget-Klasse | Manipulativ | Zahlenräume |`, parsed by `check_item_quality.load_darstellungen()`.

- [ ] **Step 1: Collect the real widget class names**

Run:
```bash
grep -rn "^class .*Widget extends" math_app/lib/widgets/manipulatives/*.dart math_app/lib/widgets/diagnostic/*.dart
```
Expected: 17 classes across `dienes_place_value.dart`, `fingerbild.dart`, `rekenrek.dart`, `staebchen.dart`, `stellenwerttafel.dart`, `zahlenstrahl.dart`, `zehnerfeld.dart` and `diagnostic/dice_widget.dart`. Sixteen of them go into the register in Step 2 — `Q21AnswerWidget` does not, because it is an answer widget bound to one v1 item, not a representation. Use the exact class names; the checker greps the Flutter source for them.

- [ ] **Step 2: Write `15-darstellungen.md`**

Create `docs/clean-room/v2/15-darstellungen.md`:

```markdown
# 15 — Darstellungsregister (v2)

| | |
|---|---|
| **Status** | Entwurf — Gate 1 offen |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Gate** | `python scripts/check_item_quality.py` |

Ein Item nennt in `darstellung:` einen Schlüssel aus diesem Register. Der Schlüssel bindet
den Wortlaut an genau ein Widget. In v1 wurden Text und Widget getrennt gepflegt — die
Aufgabe fragte nach Stäbchen, der Bildschirm zeigte Würfel (00-v1-assessment.md, Anhang A).
Seitdem ist die Paarung eine geprüfte Tabelle: `check_item_quality.py` schlägt fehl, wenn ein
Item einen Schlüssel nennt, den es hier nicht gibt, oder wenn die Widget-Klasse im
Flutter-Quelltext fehlt.

Alle Manipulative hier sind gemeinfreie Fachdidaktik-Standards und tragen kein
Clean-Room-Risiko (ADR-Lage unverändert): Dienes, Rechenschiffchen, Zehnerfeld, Rekenrek,
Fingerbilder, Zahlenstrahl, Plättchen.

| key | Widget-Klasse | Manipulativ | Zahlenräume |
|---|---|---|---|
| `keine` | — | keine Darstellung, rein symbolisch | ZR10, ZR20, ZR100 |
| `zehnerfeld` | `ZehnerfeldWidget` | Zehnerfeld 5×2 | ZR10, ZR20 |
| `zehnerfeld-vergleich` | `VergleichZehnerfelderWidget` | zwei Zehnerfelder nebeneinander | ZR10, ZR20 |
| `rekenrek` | `RekenrekWidget` | Rechenrahmen, zwei Stangen | ZR10, ZR20 |
| `rekenrek-blitz` | `RekenrekFlashWidget` | Rechenrahmen, kurze Darbietung | ZR10 |
| `rekenrek-vergleich` | `VergleichRekenrekWidget` | zwei Rechenrahmen nebeneinander | ZR10, ZR20 |
| `fingerbild` | `FingerBildWidget` | Fingerbild, Fünferstruktur | ZR10, ZR20 |
| `dienes` | `DienesPlaceValueWidget` | Zehnerstangen und Einerwürfel | ZR100 |
| `dienes-oeffnen` | `DienesOeffnenWidget` | Zehnerstange antippen und entbündeln | ZR20, ZR100 |
| `staebchen` | `StaebchenWidget` | Stäbchen, lose | ZR10, ZR20 |
| `staebchen-buendel` | `StaebchenBundelWidget` | Stäbchen in Zehnerbündeln | ZR20, ZR100 |
| `staebchen-einzeln` | `StaebchenEinzelWidget` | Stäbchen einzeln | ZR10, ZR20 |
| `staebchen-oeffnen` | `StaebchenOeffnenWidget` | Zehnerbündel antippen und öffnen | ZR20, ZR100 |
| `stellenwerttafel` | `StellenwerttafelWidget` | Tafel mit Z- und E-Spalte | ZR100 |
| `zahlenstrahl-pfeil` | `ZahlenstrahlArrowWidget` | Zahlenstrahl, Pfeil zeigt auf einen Wert | ZR10, ZR20, ZR100 |
| `zahlenstrahl-markieren` | `ZahlenstrahlMarkWidget` | Zahlenstrahl, Kind setzt die Marke | ZR10, ZR20, ZR100 |
| `wuerfelbild` | `DiceWidget` | Würfelbild | ZR10 |

**Lücken, die Phase 3 füllen muss.** Für `zwanzigerfeld` und `hunderterfeld` gibt es im
Diagnostik-Bestand noch kein Widget; die Übungs-Engine hat mit `InteractiveTwentyFrameWidget`
und den `Count100Field…`-Widgets Kandidaten, die erst gesichtet werden müssen. Bis dahin
steht hier kein Schlüssel dafür — ein Item darf nichts nennen, was nicht gebaut ist.
```

- [ ] **Step 3: Write `14-itemregeln.md`**

Create `docs/clean-room/v2/14-itemregeln.md`:

```markdown
# 14 — Itemregeln (v2)

| | |
|---|---|
| **Status** | Entwurf — Gate 1 offen |
| **Stand** | 2026-09-08 |
| **Owner** | Jakob |
| **Grundlage** | [v2-Entwurf](../../superpowers/specs/2026-09-07-diagnostik-v2-design.md) §5.1; [00-v1-assessment.md](../00-v1-assessment.md) Anhang A |
| **Gate** | `python scripts/check_item_quality.py` |

Abnahmekriterien für ein Diagnostik-Item. Jede Regel trägt einen Vermerk, wer sie prüft:
**maschinell** heißt, `check_item_quality.py` entscheidet sie; **Gate 1** heißt, nur Jakobs
Urteil entscheidet sie. Der Checker ist ein Boden, kein Ersatz — v1 hatte fünf grüne Gates
bei unbrauchbarem Instrument.

Jede Regel nennt den Defekt, wegen dem es sie gibt.

## I1 — Eine Anweisung, ein Satz *(maschinell)*

Der Prompt enthält höchstens einen Satz. Gezählt wird an `.`, `?` und `!`.

*Defekt:* v1 Item 44 hatte sechs Sätze und 45 Wörter und hat dem Kind das Verfahren
diktiert.

## I2 — Höchstens zwölf Wörter *(maschinell)*

*Defekt:* dieselbe Familie, Items 44–53. Ein Klasse-2-Förderkind trägt diese Leselast nicht.

## I3 — Kein verratenes Verfahren *(maschinell)*

Verbotene Wendungen am Satzanfang oder als Teilsatz: `Zerlege`, `Rechne zuerst`,
`In der Tabelle stehen`, `Trage ein`, `Schreib sie so auf`, `Und wenn du`, `Sieh dir`,
`Denk daran`, `Nimm zuerst`, `Zähl in`. Wer die Strategie nennt, misst Gehorsam.

*Defekt:* v1 Item 15 („Schreib sie so auf: 8 = ___ + ___"), Item 44, Item 22.

## I4 — Keine Nebensätze, keine Zahlwörter *(maschinell)*

Verboten als eigenes Wort: `weil`, `wenn`, `damit`, `dass`, `nachdem`, `obwohl`, `während`.
Zahlen stehen als Ziffern, nicht als Wort (`8`, nicht `acht`).

*Grund:* Ohne Lehrkraft, die vorliest, konfundiert Lesefähigkeit die Messung. Der Prompt
wird zusätzlich gesprochen (I9), aber er muss auch gelesen tragen.

## I5 — Ein Item, eine Antwort *(maschinell)*

Die Schlüsselmenge von `antwortfelder` und `erwartete-antwort` ist identisch, und jedes
Feld trägt ein eigenes Label. Zwei Antworten heißen zwei Items oder zwei beschriftete
Zeilen — nie zwei nackte Kästchen.

*Defekt:* v1 Q7 („welche Zahl kommt vor der 37, und welche danach?" — `AnswerFormat: Single`,
zwei erwartete Zahlen), Q20, Q22.

## I6 — Prompt und Darstellung sind ein Artefakt *(maschinell)*

`darstellung` ist ein Schlüssel aus [15-darstellungen.md](15-darstellungen.md) oder `keine`;
die dort genannte Widget-Klasse existiert im Flutter-Quelltext. Ist `darstellung` gleich
`keine`, ist `darstellung-konfiguration` gleich `—`; sonst nicht leer.

*Defekt:* v1 fragte nach Stäbchen, während der Bildschirm Würfel zeigte, weil Text und
Widget getrennt gepflegt wurden.

## I7 — Simultanerfassung ist bei 5 gedeckelt *(maschinell)*

Bei einem Item des Strangs `anzahl-simultan` ist jede Zahl in `erwartete-antwort` höchstens
5. Darüber misst das Item Zählen, was immer es behauptet.

*Defekt:* v1s Subitizing-Item zeigte acht Objekte.

## I8 — Jedes Item nennt sein Fehlerbild *(maschinell, Inhalt Gate 1)*

`fehlersignatur` hat mindestens zwei Einträge, jeder in der Form `` `Antwort` — Bedeutung ``.
Der Förderplan und die Fehlermusteranalyse lesen beide dieses Feld. Ob die Bedeutung
stimmt, entscheidet Gate 1.

## I9 — Gesprochener Prompt *(maschinell)*

`audio` ist gesetzt und lautet `audio/v2/<item-id>.mp3`. Die Datei selbst entsteht in
Phase 5 (TTS zur Bauzeit); geprüft wird hier der Vertrag, nicht die Existenz.

## I10 — Verankerung in Konstrukt und Zelle *(maschinell)*

`konstrukt` steht in [11-konstruktkarte.md](11-konstruktkarte.md); `zelle` steht in der
Deckungsmatrix und lebt; Strang und Zahlenraum der Zelle stimmen mit dem Konstrukt überein;
`item-id` ist gleich dem Dateinamen und beginnt mit `<konstrukt>-`.

*Defekt:* v1s Independence-Sidecar hing an der Zeilennummer, sodass das Löschen eines Items
Zuordnungen still verschoben hat. Hier hängt alles an IDs.

## I11 — Zwei Items derselben Zelle brauchen einen benannten Unterschied *(Gate 1)*

Kann die Item-Datei nicht sagen, was dieses Item misst und das Geschwisteritem nicht, fliegt
eines. Maschinell nicht entscheidbar.

*Defekt:* v1 Q15/Q17 und Q20/Q24/Q25.

## I12 — Monotoner Schwierigkeitsverlauf im Strang *(Gate 1)*

Ein schweres Item mit trivialem Nachbarn ist für sich ein Defekt. Die Zahlenraumleiter wird
in der Reihenfolge gegangen, nie direkt in den ZR100. Die Reihenfolge selbst erzeugt der
Blueprint; ob der Verlauf sich für ein Kind richtig anfühlt, entscheidet Gate 1 — und
endgültig Gate 2 am laufenden Bildschirm.

## Was der Checker nicht kann

Ob ein Item das Konstrukt misst, ob das Fehlerbild dem entspricht, was Kinder tatsächlich
tun, ob die Aufgabe für ein Förderkind zumutbar ist: alles Gate 1 und Gate 2. Die
maschinellen Regeln oben fangen genau die Defektklassen ab, die v1 tatsächlich ausgeliefert
hat — mehr behaupten sie nicht.
```

- [ ] **Step 4: Write `items/TEMPLATE.md`**

Create `docs/clean-room/v2/items/TEMPLATE.md` with the exact format from the File Structure section above, plus a header note:

```markdown
# Item <item-id>

> Vorlage. Kopieren, jedes Feld füllen, dann `python scripts/check_item_quality.py`.
> Die Regeln stehen in [14-itemregeln.md](../14-itemregeln.md), die Darstellungsschlüssel
> in [15-darstellungen.md](../15-darstellungen.md). `TEMPLATE.md` selbst wird vom Checker
> übersprungen.

- **item-id:** verdoppeln-halbieren.ZR20-01
- **konstrukt:** verdoppeln-halbieren.ZR20
- **zelle:** verdoppeln-halbieren × ZR20 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Rechne: 8 + 8
- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3
- **antwortfelder:**
  - `ergebnis` — Ergebnis
- **erwartete-antwort:**
  - `ergebnis` = 16
- **fehlersignatur:**
  - `15` — ±1 nach unten: zählend gerechnet, ein Schritt zu wenig
  - `17` — ±1 nach oben: zählend gerechnet, ein Schritt zu viel
  - `10` — die Verdopplung wird als Ergänzung zur Zehn missdeutet
- **quelle:** RLP BE/BB Teil C, L1, Niveaustufe A/B; Gaidoschik, Automatisierung der Kernaufgaben
- **eigenstaendigkeit:** Zahlenpaar, Wortlaut und Antwortlayout eigenständig gewählt; kein bestehendes Instrument als Vorlage.
- **reviewer:** —
```

- [ ] **Step 5: Verify every widget class named in the register actually exists**

Run:
```bash
python - <<'PY'
import re, subprocess
from pathlib import Path
reg = Path("docs/clean-room/v2/15-darstellungen.md").read_text(encoding="utf-8")
klassen = set(re.findall(r"\| `[a-z-]+` \| `(\w+)` \|", reg))
quelle = "\n".join(
    p.read_text(encoding="utf-8")
    for p in Path("math_app/lib").rglob("*.dart")
)
fehlen = sorted(k for k in klassen if f"class {k} extends" not in quelle)
print(f"{len(klassen)} Klassen im Register, {len(fehlen)} fehlen im Quelltext")
for k in fehlen:
    print("FEHLT:", k)
PY
```
Expected: `16 Klassen im Register, 0 fehlen im Quelltext`. If any are missing, remove that row from the register rather than inventing a widget — the register may only name what exists.

- [ ] **Step 6: Commit** *(gated)*

```bash
git add docs/clean-room/v2/14-itemregeln.md docs/clean-room/v2/15-darstellungen.md docs/clean-room/v2/items/TEMPLATE.md
git commit -m "$(cat <<'EOF'
docs(v2): Itemregeln I1-I12, Darstellungsregister und Item-Template

Die zwoelf Regeln aus dem v2-Entwurf §5.1 als nummerierte Abnahmekriterien,
jede mit dem v1-Defekt, wegen dem es sie gibt, und mit dem Vermerk, ob eine
Maschine oder nur Jakob sie entscheiden kann.

Das Darstellungsregister bindet jeden Wortlaut an genau ein Widget. Getrennt
gepflegter Text und Bildschirm sind der Grund, warum v1 nach Staebchen fragte
und Wuerfel zeigte.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `check_item_quality.py` — parser and structural rules I5, I6, I10

**Files:**
- Create: `scripts/check_item_quality.py`
- Create: `scripts/tests/test_check_item_quality.py`
- Create: `scripts/tests/fixtures/items/verdoppeln-halbieren.ZR20-01.md`

**Interfaces:**
- Consumes: `parse_matrix` and `MATRIX_PATH` from `check_deckung.py`; `konstrukte` from `derive_ableitungen.py`.
- Produces: `Item` dataclass (`path: Path`, `fields: dict[str, str]`, `listen: dict[str, list[str]]`); `parse_item(text, path) -> Item`; `load_darstellungen() -> dict[str, str]`; `load_widget_klassen() -> set[str]`; `validate_item(item, konstrukt_ids, live_cells, darstellungen, widget_klassen) -> list[str]`; `item_files(items_dir) -> list[Path]`.

- [ ] **Step 1: Create the clean fixture**

Create `scripts/tests/fixtures/items/verdoppeln-halbieren.ZR20-01.md` with exactly the template content from Task 3 Step 4, minus the `>` blockquote note. This is the item every "should pass" test runs against.

- [ ] **Step 2: Write the failing test**

Create `scripts/tests/test_check_item_quality.py`:

```python
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_item_quality import parse_item, validate_item

FIXTURES = Path(__file__).resolve().parent / "fixtures" / "items"

KONSTRUKT_IDS = {"verdoppeln-halbieren.ZR20", "anzahl-simultan.ZR10"}
LIVE_CELLS = {
    ("verdoppeln-halbieren", "ZR20", "symbolisch"),
    ("verdoppeln-halbieren", "ZR20", "enaktiv"),
    ("anzahl-simultan", "ZR10", "ikonisch"),
}
DARSTELLUNGEN = {
    "keine": "—",
    "rekenrek-blitz": "RekenrekFlashWidget",
    "zehnerfeld": "ZehnerfeldWidget",
}
WIDGETS = {"RekenrekFlashWidget", "ZehnerfeldWidget"}


def load(name):
    path = FIXTURES / name
    return parse_item(path.read_text(encoding="utf-8"), path)


def check(item):
    return validate_item(item, KONSTRUKT_IDS, LIVE_CELLS, DARSTELLUNGEN, WIDGETS)


class ParseItemTest(unittest.TestCase):
    def setUp(self):
        self.item = load("verdoppeln-halbieren.ZR20-01.md")

    def test_reads_scalar_fields(self):
        self.assertEqual(self.item.fields["item-id"], "verdoppeln-halbieren.ZR20-01")
        self.assertEqual(self.item.fields["prompt"], "Rechne: 8 + 8")
        self.assertEqual(self.item.fields["blitz"], "nein")

    def test_reads_sub_bullet_lists(self):
        self.assertEqual(self.item.listen["antwortfelder"], ["`ergebnis` — Ergebnis"])
        self.assertEqual(self.item.listen["erwartete-antwort"], ["`ergebnis` = 16"])
        self.assertEqual(len(self.item.listen["fehlersignatur"]), 3)

    def test_a_list_field_is_not_also_a_scalar(self):
        self.assertNotIn("antwortfelder", self.item.fields)


class CleanItemTest(unittest.TestCase):
    def test_the_reference_item_passes_every_rule(self):
        self.assertEqual(check(load("verdoppeln-halbieren.ZR20-01.md")), [])


class StructuralRulesTest(unittest.TestCase):
    def mutate(self, **changes):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        for old, new in changes.items():
            text = text.replace(old.replace("_", " "), new)
        return check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))

    def test_i5_answer_field_count_must_match_expected_answer_count(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "  - `ergebnis` — Ergebnis",
            "  - `ergebnis` — Ergebnis\n  - `zweites` — Zweites",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I5" in e for e in errors), errors)

    def test_i5_every_answer_field_needs_a_label(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("  - `ergebnis` — Ergebnis", "  - `ergebnis`")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I5" in e and "Label" in e for e in errors), errors)

    def test_i6_unknown_darstellung_key_fails(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("**darstellung:** keine", "**darstellung:** wolkenbild")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I6" in e for e in errors), errors)

    def test_i6_darstellung_keine_requires_an_empty_configuration(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**darstellung-konfiguration:** —", "**darstellung-konfiguration:** oben 8"
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I6" in e for e in errors), errors)

    def test_i6_a_real_darstellung_requires_a_configuration(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("**darstellung:** keine", "**darstellung:** zehnerfeld")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I6" in e and "konfiguration" in e for e in errors), errors)

    def test_i10_unknown_konstrukt_fails(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**konstrukt:** verdoppeln-halbieren.ZR20",
            "**konstrukt:** verdoppeln-halbieren.ZR50",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e for e in errors), errors)

    def test_i10_cell_must_be_live_in_the_matrix(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**zelle:** verdoppeln-halbieren × ZR20 × symbolisch",
            "**zelle:** verdoppeln-halbieren × ZR20 × ikonisch",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e for e in errors), errors)

    def test_i10_cell_must_belong_to_the_konstrukt(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**zelle:** verdoppeln-halbieren × ZR20 × symbolisch",
            "**zelle:** anzahl-simultan × ZR10 × ikonisch",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e for e in errors), errors)

    def test_i10_item_id_must_match_the_filename(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**item-id:** verdoppeln-halbieren.ZR20-01",
            "**item-id:** verdoppeln-halbieren.ZR20-09",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I10" in e and "Dateiname" in e for e in errors), errors)

    def test_a_missing_field_is_reported_by_name(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3\n", "")
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("audio" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_check_item_quality -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'check_item_quality'`.

- [ ] **Step 4: Write the implementation**

Create `scripts/check_item_quality.py`:

```python
#!/usr/bin/env python3
"""Prüft die Diagnostik-Items gegen die Itemregeln I1-I12 (v2-Entwurf §5.1, §8).

Der mechanische Boden unter Jakobs Urteil, nicht sein Ersatz: geprueft wird, was
eine Maschine entscheiden kann - Satz- und Wortzahl, verratene Verfahren,
Antwortarität, Feldbeschriftung, Darstellungsschluessel gegen das Register,
Verankerung in Konstrukt und Zelle, der Deckel bei 5 fuer die Simultanerfassung.

Jede Regel faengt eine Defektklasse ab, die v1 tatsaechlich ausgeliefert hat.
Die Regeltexte stehen in docs/clean-room/v2/14-itemregeln.md.

Exit 0 wenn sauber, Exit 1 mit je einer FAIL-Zeile pro Problem.
"""

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from check_deckung import MATRIX_PATH, parse_matrix
from derive_ableitungen import konstrukte

ROOT = Path(__file__).resolve().parents[1]
V2 = ROOT / "docs" / "clean-room" / "v2"
ITEMS_DIR = V2 / "items"
DARSTELLUNGEN_PATH = V2 / "15-darstellungen.md"
DART_ROOT = ROOT / "math_app" / "lib"

LEER = "—"

SCALAR_FIELDS = (
    "item-id",
    "konstrukt",
    "zelle",
    "darstellung",
    "darstellung-konfiguration",
    "blitz",
    "prompt",
    "audio",
    "quelle",
    "eigenstaendigkeit",
    "reviewer",
)
LIST_FIELDS = ("antwortfelder", "erwartete-antwort", "fehlersignatur")

FIELD_RE = re.compile(r"^- \*\*([a-zä-ü-]+):\*\*\s*(.*)$", re.MULTILINE)
SUBBULLET_RE = re.compile(r"^  - (.+)$")
ZELLE_RE = re.compile(r"^([a-z0-9-]+) × (\w+) × (\w+)$")
FELD_LABEL_RE = re.compile(r"^`([a-z0-9_-]+)`\s+—\s+(.+)$")
FELD_WERT_RE = re.compile(r"^`([a-z0-9_-]+)`\s*=\s*(.+)$")
SIGNATUR_RE = re.compile(r"^`[^`]+`\s+—\s+(.+)$")
REGISTER_ROW_RE = re.compile(r"^\|\s*`([a-z-]+)`\s*\|\s*`?([\w—-]+)`?\s*\|", re.MULTILINE)


@dataclass
class Item:
    path: Path
    fields: dict = field(default_factory=dict)
    listen: dict = field(default_factory=dict)


def parse_item(text, path):
    """Zerlegt eine Item-Datei in Skalarfelder und Unterlisten."""
    item = Item(path=path)
    lines = text.splitlines()
    current_list = None
    for line in lines:
        sub = SUBBULLET_RE.match(line)
        if sub and current_list is not None:
            item.listen[current_list].append(sub.group(1).strip())
            continue
        match = FIELD_RE.match(line)
        if not match:
            if line.strip() and not line.startswith("  "):
                current_list = None
            continue
        name, value = match.group(1).strip(), match.group(2).strip()
        if name in LIST_FIELDS:
            item.listen[name] = []
            current_list = name
        else:
            item.fields[name] = value
            current_list = None
    return item


def load_darstellungen():
    """key -> Widget-Klasse, aus 15-darstellungen.md."""
    if not DARSTELLUNGEN_PATH.exists():
        return {}
    text = DARSTELLUNGEN_PATH.read_text(encoding="utf-8")
    return {m.group(1): m.group(2) for m in REGISTER_ROW_RE.finditer(text)}


def load_widget_klassen():
    """Alle im Flutter-Quelltext definierten Widget-Klassen."""
    klassen = set()
    if not DART_ROOT.is_dir():
        return klassen
    pattern = re.compile(r"^class (\w+) extends", re.MULTILINE)
    for path in DART_ROOT.rglob("*.dart"):
        klassen.update(pattern.findall(path.read_text(encoding="utf-8", errors="ignore")))
    return klassen


def item_files(items_dir):
    """Item-Dateien, ohne TEMPLATE.md, README.md und Namen mit fuehrendem '_'."""
    if not items_dir.is_dir():
        return []
    return sorted(
        p for p in items_dir.glob("*.md")
        if p.name not in ("TEMPLATE.md", "README.md") and not p.name.startswith("_")
    )


def validate_item(item, konstrukt_ids, live_cells, darstellungen, widget_klassen):
    """Gibt eine Liste deutscher Fehlermeldungen zurueck; leer heisst sauber."""
    errors = []
    name = item.path.name

    for feld in SCALAR_FIELDS:
        if not item.fields.get(feld):
            errors.append(f"{name}: Feld '{feld}' fehlt oder ist leer")
    for feld in LIST_FIELDS:
        if feld not in item.listen:
            errors.append(f"{name}: Liste '{feld}' fehlt")
        elif not item.listen[feld]:
            errors.append(f"{name}: Liste '{feld}' ist leer")

    # I5 — Aritaet und Beschriftung
    felder, werte = {}, {}
    for zeile in item.listen.get("antwortfelder", []):
        m = FELD_LABEL_RE.match(zeile)
        if not m:
            errors.append(f"{name}: I5 — Antwortfeld ohne Label: '{zeile}'")
            continue
        felder[m.group(1)] = m.group(2)
    for zeile in item.listen.get("erwartete-antwort", []):
        m = FELD_WERT_RE.match(zeile)
        if not m:
            errors.append(f"{name}: I5 — erwartete Antwort ohne Feldbezug: '{zeile}'")
            continue
        werte[m.group(1)] = m.group(2)
    if felder and werte and set(felder) != set(werte):
        fehlend = sorted(set(felder) ^ set(werte))
        errors.append(
            f"{name}: I5 — Antwortfelder und erwartete Antworten stimmen nicht ueberein "
            f"({', '.join(fehlend)})"
        )

    # I6 — Darstellung
    darstellung = item.fields.get("darstellung", "")
    konfiguration = item.fields.get("darstellung-konfiguration", "")
    if darstellung and darstellung not in darstellungen:
        errors.append(
            f"{name}: I6 — Darstellung '{darstellung}' steht nicht im Register "
            f"(15-darstellungen.md)"
        )
    elif darstellung == "keine":
        if konfiguration != LEER:
            errors.append(
                f"{name}: I6 — Darstellung 'keine' verlangt eine leere "
                f"darstellung-konfiguration ('{LEER}')"
            )
    elif darstellung:
        if not konfiguration or konfiguration == LEER:
            errors.append(
                f"{name}: I6 — Darstellung '{darstellung}' ohne "
                f"darstellung-konfiguration"
            )
        klasse = darstellungen[darstellung]
        if klasse != LEER and klasse not in widget_klassen:
            errors.append(
                f"{name}: I6 — Widget-Klasse '{klasse}' aus dem Register existiert "
                f"nicht im Flutter-Quelltext"
            )

    # I10 — Verankerung
    item_id = item.fields.get("item-id", "")
    konstrukt = item.fields.get("konstrukt", "")
    if item_id and item_id != item.path.stem:
        errors.append(
            f"{name}: I10 — item-id '{item_id}' und Dateiname stimmen nicht ueberein"
        )
    if konstrukt and konstrukt not in konstrukt_ids:
        errors.append(
            f"{name}: I10 — Konstrukt '{konstrukt}' steht nicht in der Konstruktkarte"
        )
    if item_id and konstrukt and not item_id.startswith(f"{konstrukt}-"):
        errors.append(
            f"{name}: I10 — item-id '{item_id}' beginnt nicht mit '{konstrukt}-'"
        )
    zelle = item.fields.get("zelle", "")
    m = ZELLE_RE.match(zelle)
    if zelle and not m:
        errors.append(f"{name}: I10 — Zelle '{zelle}' hat nicht die Form 'strang × ZR × rep'")
    elif m:
        key = (m.group(1), m.group(2), m.group(3))
        if key not in live_cells:
            errors.append(
                f"{name}: I10 — Zelle '{zelle}' gibt es in der Matrix nicht oder sie ist "
                f"als nicht abgedeckt markiert"
            )
        if konstrukt and konstrukt != f"{m.group(1)}.{m.group(2)}":
            errors.append(
                f"{name}: I10 — Zelle '{zelle}' gehoert nicht zum Konstrukt '{konstrukt}'"
            )

    return errors


def main():
    matrix = parse_matrix(MATRIX_PATH.read_text(encoding="utf-8"))
    konstrukt_ids = {k.id for k in konstrukte(matrix)}
    live_cells = {key for key, status in matrix.cells.items() if status != "–"}
    darstellungen = load_darstellungen()
    widget_klassen = load_widget_klassen()

    paths = item_files(ITEMS_DIR)
    errors = []
    for path in paths:
        item = parse_item(path.read_text(encoding="utf-8"), path)
        errors += validate_item(
            item, konstrukt_ids, live_cells, darstellungen, widget_klassen
        )

    print(
        f"check_item_quality: {len(paths)} Items gegen {len(konstrukt_ids)} Konstrukte "
        f"und {len(darstellungen)} Darstellungen geprueft"
    )
    if errors:
        for err in errors:
            print("FAIL:", err)
        return 1
    print("OK: jedes Item verankert, beschriftet und regelkonform")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `python -m unittest scripts.tests.test_check_item_quality -v`
Expected: PASS, 14 tests.

- [ ] **Step 6: Run the gate against the real (still empty) tree**

Run: `python scripts/check_item_quality.py`
Expected: `check_item_quality: 0 Items gegen 54 Konstrukte und 17 Darstellungen geprueft` / `OK: …`, exit 0.

Zero items is correct and expected — items are Phase 3. Say so in the commit message rather than letting a green gate imply coverage.

- [ ] **Step 7: Commit** *(gated)*

```bash
git add scripts/check_item_quality.py scripts/tests/test_check_item_quality.py scripts/tests/fixtures/
git commit -m "$(cat <<'EOF'
feat(v2): check_item_quality - Parser und Strukturregeln I5, I6, I10

Antwortarität und Feldbeschriftung (v1 Q7/Q20/Q22 hatten zwei Antworten in
einem unbeschrifteten Feld), Darstellungsschluessel gegen das Register samt
Existenz der Widget-Klasse im Flutter-Quelltext, und die Verankerung in
Konstrukt und Zelle ueber IDs statt ueber Zeilennummern.

Der Gate laeuft gegen einen noch leeren Itembaum: Items sind Phase 3 und
brauchen je Zelle Jakobs Gate 1. Gruen heisst hier "keine Regelverletzung",
nicht "abgedeckt".

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Language rules I1–I4, I7–I9 and the v1 regression corpus

**Files:**
- Modify: `scripts/check_item_quality.py` (add the language rules to `validate_item`)
- Modify: `scripts/tests/test_check_item_quality.py` (append two test classes)
- Create: `scripts/tests/fixtures/items/_v1-q44-stellenwert.md`
- Create: `scripts/tests/fixtures/items/_v1-q07-vorgaenger-nachfolger.md`
- Create: `scripts/tests/fixtures/items/_v1-q15-zerlegung.md`
- Create: `scripts/tests/fixtures/items/_v1-q-subitizing-acht.md`

**Interfaces:**
- Consumes: `validate_item(item, konstrukt_ids, live_cells, darstellungen, widget_klassen)` from Task 4 — same signature, more rules inside.
- Produces: module constants `VERBOTENE_WENDUNGEN`, `NEBENSATZ_MARKER`, `ZAHLWOERTER`, `LANGE_FACHWOERTER`, `MAX_WOERTER`.

The four fixtures are transcriptions of items v1 actually shipped, taken from `math_app/Research/diagnostic_core_v1.csv` (a frozen v1 artifact — read only, never written). They exist so each rule is proven against a real defect rather than an invented one. Their filenames start with `_` so `item_files()` would skip them even if they were ever copied into `docs/`.

- [ ] **Step 1: Write the failing test**

Append to `scripts/tests/test_check_item_quality.py`:

```python
class LanguageRulesTest(unittest.TestCase):
    def with_prompt(self, prompt):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace("**prompt:** Rechne: 8 + 8", f"**prompt:** {prompt}")
        return check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))

    def test_i1_more_than_one_sentence_fails(self):
        errors = self.with_prompt("Sieh die Zahl an. Wie viel ist 8 + 8?")
        self.assertTrue(any("I1" in e for e in errors), errors)

    def test_i1_a_single_question_mark_is_fine(self):
        errors = self.with_prompt("Wie viel ist 8 + 8?")
        self.assertEqual(errors, [])

    def test_i2_more_than_twelve_words_fails(self):
        errors = self.with_prompt(
            "Rechne die Aufgabe 8 + 8 aus und schreibe dein Ergebnis in das Kaestchen dort"
        )
        self.assertTrue(any("I2" in e for e in errors), errors)

    def test_i3_banned_procedure_phrase_fails(self):
        errors = self.with_prompt("Zerlege die 8 in zwei Teile")
        self.assertTrue(any("I3" in e for e in errors), errors)

    def test_i3_reports_which_phrase_it_found(self):
        errors = self.with_prompt("Trage ein: 8 + 8")
        self.assertTrue(any("Trage ein" in e for e in errors), errors)

    def test_i4_subordinate_clause_marker_fails(self):
        errors = self.with_prompt("Rechne 8 + 8, wenn du bereit bist")
        self.assertTrue(any("I4" in e for e in errors), errors)

    def test_i4_number_word_fails(self):
        errors = self.with_prompt("Verdopple acht")
        self.assertTrue(any("I4" in e for e in errors), errors)

    def test_i4_allows_a_long_subject_term(self):
        errors = self.with_prompt("Wie viele Zehner hat die Stellenwerttafel?")
        self.assertEqual(errors, [])

    def test_i8_fewer_than_two_error_signatures_fails(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "  - `17` — ±1 nach oben: zählend gerechnet, ein Schritt zu viel\n", ""
        ).replace(
            "  - `10` — die Verdopplung wird als Ergänzung zur Zehn missdeutet\n", ""
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I8" in e for e in errors), errors)

    def test_i9_audio_path_must_follow_the_naming_contract(self):
        text = (FIXTURES / "verdoppeln-halbieren.ZR20-01.md").read_text(encoding="utf-8")
        text = text.replace(
            "**audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3",
            "**audio:** audio/v2/irgendwas.mp3",
        )
        errors = check(parse_item(text, FIXTURES / "verdoppeln-halbieren.ZR20-01.md"))
        self.assertTrue(any("I9" in e for e in errors), errors)


class V1RegressionCorpusTest(unittest.TestCase):
    """Jede Regel gegen einen Defekt, den v1 tatsaechlich ausgeliefert hat."""

    def test_q44_stellenwert_script_is_rejected_for_length_and_procedure(self):
        errors = check(load("_v1-q44-stellenwert.md"))
        self.assertTrue(any("I1" in e for e in errors), errors)
        self.assertTrue(any("I2" in e for e in errors), errors)
        self.assertTrue(any("I3" in e for e in errors), errors)

    def test_q07_vorgaenger_nachfolger_is_rejected_for_arity(self):
        errors = check(load("_v1-q07-vorgaenger-nachfolger.md"))
        self.assertTrue(any("I5" in e for e in errors), errors)

    def test_q15_zerlegung_is_rejected_for_giving_away_the_form(self):
        errors = check(load("_v1-q15-zerlegung.md"))
        self.assertTrue(any("I3" in e for e in errors), errors)

    def test_subitizing_at_eight_is_rejected_by_the_cap(self):
        errors = check(load("_v1-q-subitizing-acht.md"))
        self.assertTrue(any("I7" in e for e in errors), errors)
```

- [ ] **Step 2: Create the four regression fixtures**

Create `scripts/tests/fixtures/items/_v1-q44-stellenwert.md` — the prompt is verbatim from v1's shipped CSV row 44:

```markdown
# Item verdoppeln-halbieren.ZR20-01

- **item-id:** verdoppeln-halbieren.ZR20-01
- **konstrukt:** verdoppeln-halbieren.ZR20
- **zelle:** verdoppeln-halbieren × ZR20 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Rechne 34 + 28. In der Tabelle stehen Zehner und Einer. Die Zahl 34 hat 3 Zehner und 4 Einer. Trage ein: Wie viele Zehner haben beide Zahlen zusammen?
- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3
- **antwortfelder:**
  - `ergebnis` — Ergebnis
- **erwartete-antwort:**
  - `ergebnis` = 62
- **fehlersignatur:**
  - `52` — der Übertrag geht verloren
  - `512` — Zehner und Einer werden unverbunden notiert
- **quelle:** v1-Bestand, nur als Regressionsfall
- **eigenstaendigkeit:** Transkript eines v1-Items, ausschliesslich als Testfixture.
- **reviewer:** —
```

Create `_v1-q07-vorgaenger-nachfolger.md` — two answers, one unlabelled field:

```markdown
# Item verdoppeln-halbieren.ZR20-01

- **item-id:** verdoppeln-halbieren.ZR20-01
- **konstrukt:** verdoppeln-halbieren.ZR20
- **zelle:** verdoppeln-halbieren × ZR20 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Welche Zahl kommt vor 37?
- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3
- **antwortfelder:**
  - `antwort` — Antwort
- **erwartete-antwort:**
  - `vorgaenger` = 36
  - `nachfolger` = 38
- **fehlersignatur:**
  - `36` — nur der Vorgänger wird genannt
  - `38` — nur der Nachfolger wird genannt
- **quelle:** v1-Bestand, nur als Regressionsfall
- **eigenstaendigkeit:** Transkript eines v1-Items, ausschliesslich als Testfixture.
- **reviewer:** —
```

Create `_v1-q15-zerlegung.md` — the prompt hands over the notation:

```markdown
# Item verdoppeln-halbieren.ZR20-01

- **item-id:** verdoppeln-halbieren.ZR20-01
- **konstrukt:** verdoppeln-halbieren.ZR20
- **zelle:** verdoppeln-halbieren × ZR20 × symbolisch
- **darstellung:** keine
- **darstellung-konfiguration:** —
- **blitz:** nein
- **prompt:** Schreib sie so auf: 8 = ___ + ___
- **audio:** audio/v2/verdoppeln-halbieren.ZR20-01.mp3
- **antwortfelder:**
  - `zerlegung` — Zerlegung
- **erwartete-antwort:**
  - `zerlegung` = 4 + 4
- **fehlersignatur:**
  - `8 + 0` — die triviale Zerlegung wird gewählt
  - `4` — nur ein Teil wird genannt
- **quelle:** v1-Bestand, nur als Regressionsfall
- **eigenstaendigkeit:** Transkript eines v1-Items, ausschliesslich als Testfixture.
- **reviewer:** —
```

Create `_v1-q-subitizing-acht.md` — subitizing asked at 8:

```markdown
# Item anzahl-simultan.ZR10-01

- **item-id:** anzahl-simultan.ZR10-01
- **konstrukt:** anzahl-simultan.ZR10
- **zelle:** anzahl-simultan × ZR10 × ikonisch
- **darstellung:** rekenrek-blitz
- **darstellung-konfiguration:** obere Stange 8 Perlen, Darbietung 500ms
- **blitz:** 500ms
- **prompt:** Wie viele Perlen sind das?
- **audio:** audio/v2/anzahl-simultan.ZR10-01.mp3
- **antwortfelder:**
  - `anzahl` — Anzahl
- **erwartete-antwort:**
  - `anzahl` = 8
- **fehlersignatur:**
  - `7` — ±1 beim Abzählen
  - `9` — ±1 beim Abzählen
- **quelle:** v1-Bestand, nur als Regressionsfall
- **eigenstaendigkeit:** Transkript eines v1-Items, ausschliesslich als Testfixture.
- **reviewer:** —
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_check_item_quality -v`
Expected: `Ran 28 tests`, `FAILED (failures=11)`. The 14 Task-4 tests pass. Of the 14 new
ones, exactly 11 fail because no language rule fires yet. Three pass already, and must:
`test_i1_a_single_question_mark_is_fine` and `test_i4_allows_a_long_subject_term` assert the
*absence* of an error, so an empty rule set satisfies them — they only turn red if Step 4
makes a rule fire too eagerly. `test_q07_vorgaenger_nachfolger_is_rejected_for_arity` asserts
`I5`, which Task 4 already implements; the fixture is still a real v1 regression case, it just
proves an existing rule rather than a new one.

- [ ] **Step 4: Write the implementation**

In `scripts/check_item_quality.py`, add after the regex block:

```python
MAX_WOERTER = 12

# I3 — Wendungen, die dem Kind das Verfahren verraten. Alle aus v1 belegt.
VERBOTENE_WENDUNGEN = (
    "Zerlege",
    "Rechne zuerst",
    "In der Tabelle stehen",
    "Trage ein",
    "Schreib sie so auf",
    "Und wenn du",
    "Sieh dir",
    "Denk daran",
    "Nimm zuerst",
    "Zähl in",
)

# I4 — Nebensatzmarker und Zahlwoerter.
NEBENSATZ_MARKER = (
    "weil", "wenn", "damit", "dass", "nachdem", "obwohl", "während",
)
ZAHLWOERTER = (
    "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun",
    "zehn", "elf", "zwölf", "zwanzig", "dreißig", "vierzig", "fünfzig",
    "hundert",
)
# Fachwoerter, die laenger als die Lesbarkeitsgrenze sind und trotzdem
# unvermeidlich - sie benennen das Material, nach dem gefragt wird.
LANGE_FACHWOERTER = (
    "stellenwerttafel", "rechenschiffchen", "zwanzigerfeld", "hunderterfeld",
    "zehnerstange", "zehnerstangen", "zahlenstrahl", "einerwürfel",
)
```

and add to `validate_item`, before the closing `return errors`:

```python
    # I1-I4 — Sprache des Prompts
    prompt = item.fields.get("prompt", "")
    if prompt:
        saetze = [s for s in re.split(r"[.?!]+", prompt) if s.strip()]
        if len(saetze) > 1:
            errors.append(
                f"{name}: I1 — Prompt hat {len(saetze)} Saetze, erlaubt ist einer"
            )
        woerter = prompt.split()
        if len(woerter) > MAX_WOERTER:
            errors.append(
                f"{name}: I2 — Prompt hat {len(woerter)} Woerter, erlaubt sind "
                f"{MAX_WOERTER}"
            )
        for wendung in VERBOTENE_WENDUNGEN:
            if wendung.lower() in prompt.lower():
                errors.append(
                    f"{name}: I3 — Prompt verraet das Verfahren: '{wendung}'"
                )
        blank = [w.strip(".,;:?!„“\"'()").lower() for w in woerter]
        for marker in NEBENSATZ_MARKER:
            if marker in blank:
                errors.append(f"{name}: I4 — Nebensatzmarker '{marker}' im Prompt")
        for zahlwort in ZAHLWOERTER:
            if zahlwort in blank:
                errors.append(
                    f"{name}: I4 — Zahlwort '{zahlwort}' im Prompt, Ziffern verwenden"
                )
        for wort in blank:
            if len(wort) > 14 and wort not in LANGE_FACHWOERTER:
                errors.append(f"{name}: I4 — zu langes Wort im Prompt: '{wort}'")

    # I7 — Simultanerfassung ist bei 5 gedeckelt
    if item.fields.get("konstrukt", "").startswith("anzahl-simultan"):
        for zeile in item.listen.get("erwartete-antwort", []):
            for zahl in re.findall(r"\d+", zeile):
                if int(zahl) > 5:
                    errors.append(
                        f"{name}: I7 — Simultanerfassung mit erwarteter Antwort {zahl}; "
                        f"ueber 5 misst das Item Zaehlen"
                    )

    # I8 — mindestens zwei benannte Fehlersignaturen
    signaturen = item.listen.get("fehlersignatur", [])
    if len(signaturen) < 2:
        errors.append(
            f"{name}: I8 — nur {len(signaturen)} Fehlersignatur(en), mindestens zwei "
            f"noetig"
        )
    for zeile in signaturen:
        if not SIGNATUR_RE.match(zeile):
            errors.append(
                f"{name}: I8 — Fehlersignatur ohne Bedeutung: '{zeile}'"
            )

    # I9 — Audio-Vertrag
    audio = item.fields.get("audio", "")
    erwartet = f"audio/v2/{item.path.stem}.mp3"
    if audio and audio != erwartet:
        errors.append(f"{name}: I9 — audio muss '{erwartet}' lauten, steht aber '{audio}'")
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `python -m unittest scripts.tests.test_check_item_quality -v`
Expected: PASS, 28 tests.

If `test_i4_allows_a_long_subject_term` fails, the word `stellenwerttafel` is missing from `LANGE_FACHWOERTER` — add it rather than raising the length limit.

- [ ] **Step 6: Run the full suite and both gates**

```bash
python -m unittest discover -s scripts/tests -p "test_*.py" -v
python scripts/check_deckung.py
python scripts/derive_ableitungen.py --check
python scripts/check_item_quality.py
```
Expected: all tests green; all three gates exit 0.

- [ ] **Step 7: Commit** *(gated)*

```bash
git add scripts/check_item_quality.py scripts/tests/test_check_item_quality.py scripts/tests/fixtures/
git commit -m "$(cat <<'EOF'
feat(v2): check_item_quality - Sprachregeln I1-I4, I7-I9 und v1-Regressionskorpus

Ein Satz, hoechstens zwoelf Woerter, keine verratenen Verfahren, keine
Nebensaetze und keine Zahlwoerter; Deckel bei 5 fuer die Simultanerfassung;
mindestens zwei benannte Fehlersignaturen; Audio-Namensvertrag.

Vier Fixtures sind Transkripte von Items, die v1 tatsaechlich ausgeliefert hat -
das Stellenwert-Skript aus Zeile 44, die Vorgaenger/Nachfolger-Frage mit zwei
Antworten in einem Feld, die Zerlegung mit vorgegebener Schreibweise und das
Subitizing-Item mit acht Objekten. Jede Regel wird gegen einen echten Defekt
geprueft, nicht gegen einen erfundenen.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `check_deckung.py` — Freigabe per Konstrukt (Decision B)

**Files:**
- Modify: `scripts/check_deckung.py` (R6's `freigegeben` clause; new rule R9)
- Modify: `scripts/tests/test_check_deckung.py` (append a test class)
- Modify: `docs/clean-room/v2/10-deckungsmatrix.md` (one preamble sentence only)

**Interfaces:**
- Consumes: `validate(matrix, known_uebungen=None, known_items=None)` — signature gains one keyword argument.
- Produces: `validate(matrix, known_uebungen=None, known_items=None, konstrukt_items=None)`, where `konstrukt_items: dict[str, list[str]]` maps a Konstrukt-ID to the item IDs found in its cells. New helper `konstrukt_items_of(matrix) -> dict[str, list[str]]`.

Today `validate` demands a `diagnostik:` entry on the *cell* before `freigegeben`. After this task it demands one somewhere in the cell's *Konstrukt*, and it demands the `übung:` entry on the cell itself, unchanged.

- [ ] **Step 1: Write the failing test**

Append to `scripts/tests/test_check_deckung.py`, adding `konstrukt_items_of` to the import at the top:

```python
FREIGEGEBEN_MATRIX = """\
# 10 — Deckungsmatrix (v2)

## Vokabular

**Stränge:**
- `verdoppeln-halbieren` — Verdoppeln und Halbieren als abrufbare Beziehung

**Zahlenräume:** ZR10 · ZR20 · ZR100
**Repräsentationen:** enaktiv · ikonisch · symbolisch
**Status:** offen · entworfen · freigegeben · – (bewusst nicht abgedeckt)

## Strang: verdoppeln-halbieren

| Zahlenraum | enaktiv | ikonisch | symbolisch |
|---|---|---|---|
| ZR10 | offen | offen | offen |
| ZR20 | freigegeben | offen | freigegeben |
| ZR100 | offen | offen | offen |

### verdoppeln-halbieren × ZR10 × enaktiv

- **quelle:** RLP
- **fehlerbild:** zaehlt statt zu verdoppeln
- **diagnostik:** —
- **übung:** S3.3

### verdoppeln-halbieren × ZR10 × ikonisch

- **quelle:** RLP
- **fehlerbild:** zaehlt die Punkte einzeln
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR10 × symbolisch

- **quelle:** RLP
- **fehlerbild:** Kernaufgabe nicht abrufbar
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR20 × enaktiv

- **quelle:** RLP
- **fehlerbild:** nutzt die Fuenferstruktur nicht
- **diagnostik:** —
- **übung:** S3.4

### verdoppeln-halbieren × ZR20 × ikonisch

- **quelle:** RLP
- **fehlerbild:** zaehlt am Zwanzigerfeld weiter
- **diagnostik:** —
- **übung:** S3.2

### verdoppeln-halbieren × ZR20 × symbolisch

- **quelle:** RLP
- **fehlerbild:** Verdopplungen nicht automatisiert
- **diagnostik:** verdoppeln-halbieren.ZR20-01
- **übung:** S3.5

### verdoppeln-halbieren × ZR100 × enaktiv

- **quelle:** RLP
- **fehlerbild:** verdoppelt Zehnerstangen zaehlend
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × ikonisch

- **quelle:** RLP
- **fehlerbild:** liest das Hunderterfeld zeilenweise
- **diagnostik:** —
- **übung:** —

### verdoppeln-halbieren × ZR100 × symbolisch

- **quelle:** RLP
- **fehlerbild:** rechnet stellenweise neu
- **diagnostik:** —
- **übung:** —
"""


class KonstruktFreigabeTest(unittest.TestCase):
    def setUp(self):
        self.matrix = parse_matrix(FREIGEGEBEN_MATRIX)
        self.k_items = konstrukt_items_of(self.matrix)

    def test_collects_item_ids_per_konstrukt(self):
        self.assertEqual(
            self.k_items["verdoppeln-halbieren.ZR20"],
            ["verdoppeln-halbieren.ZR20-01"],
        )
        self.assertEqual(self.k_items["verdoppeln-halbieren.ZR10"], [])

    def test_a_freigegeben_cell_may_borrow_its_item_from_a_sibling_cell(self):
        # ZR20 x enaktiv has no diagnostik of its own but its Konstrukt does,
        # and the cell has an exercise -> it may be freigegeben.
        errors = validate(self.matrix, konstrukt_items=self.k_items)
        self.assertEqual(
            [e for e in errors if "ZR20 × enaktiv" in e], []
        )

    def test_a_freigegeben_cell_without_an_exercise_still_fails(self):
        text = FREIGEGEBEN_MATRIX.replace(
            "| ZR100 | offen | offen | offen |",
            "| ZR100 | freigegeben | offen | offen |",
        )
        matrix = parse_matrix(text)
        errors = validate(matrix, konstrukt_items=konstrukt_items_of(matrix))
        self.assertTrue(
            any("ZR100 × enaktiv" in e and "übung" in e for e in errors), errors
        )

    def test_a_freigegeben_cell_whose_konstrukt_has_no_item_fails(self):
        text = FREIGEGEBEN_MATRIX.replace(
            "- **diagnostik:** verdoppeln-halbieren.ZR20-01", "- **diagnostik:** —"
        )
        matrix = parse_matrix(text)
        errors = validate(matrix, konstrukt_items=konstrukt_items_of(matrix))
        self.assertTrue(
            any("ZR20 × enaktiv" in e and "Konstrukt" in e for e in errors), errors
        )

    def test_r9_an_item_must_sit_in_a_cell_of_its_own_konstrukt(self):
        text = FREIGEGEBEN_MATRIX.replace(
            "- **diagnostik:** verdoppeln-halbieren.ZR20-01",
            "- **diagnostik:** verdoppeln-halbieren.ZR100-01",
        )
        matrix = parse_matrix(text)
        errors = validate(matrix, konstrukt_items=konstrukt_items_of(matrix))
        self.assertTrue(any("R9" in e for e in errors), errors)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: FAIL — `ImportError: cannot import name 'konstrukt_items_of'`.

- [ ] **Step 3: Write the implementation**

In `scripts/check_deckung.py`, add after `load_known_items()`:

```python
def konstrukt_items_of(matrix):
    """Konstrukt-ID -> Item-IDs, die in irgendeiner Zelle dieses Konstrukts stehen.

    Ein Konstrukt ist ein (Strang x Zahlenraum)-Paar. Diagnostik gehoert zum
    Konstrukt, Uebung zur Zelle (12-blueprint.md).
    """
    result = {}
    for (strang, zr, rep), status in matrix.cells.items():
        if status == "–":
            continue
        key = f"{strang}.{zr}"
        result.setdefault(key, [])
        block = matrix.blocks.get((strang, zr, rep), {})
        for ref in split_refs(block.get("diagnostik", "")):
            if ref not in result[key]:
                result[key].append(ref)
    return result
```

Change the `validate` signature to:

```python
def validate(matrix, known_uebungen=None, known_items=None, konstrukt_items=None):
```

Replace the `freigegeben` block inside the per-cell loop:

```python
        if status == "freigegeben":
            if block.get("übung", LEER) == LEER:
                errors.append(f"{label}: Status 'freigegeben' verlangt einen Eintrag in 'übung'")
            if konstrukt_items is not None:
                key = f"{strand}.{zr}"
                if not konstrukt_items.get(key):
                    errors.append(
                        f"{label}: Status 'freigegeben', aber das Konstrukt '{key}' "
                        f"hat kein Diagnostik-Item"
                    )
```

Add R9 after the duplicate-block loop:

```python
    # R9 — ein Item steht nur in einer Zelle seines eigenen Konstrukts
    for key in sorted(matrix.blocks):
        strand, zr, rep = key
        block = matrix.blocks[key]
        for ref in split_refs(block.get("diagnostik", "")):
            if not ref.startswith(f"{strand}.{zr}-"):
                errors.append(
                    f"{strand} × {zr} × {rep}: R9 — Item '{ref}' gehoert nicht zum "
                    f"Konstrukt '{strand}.{zr}'"
                )
```

In `main()`, pass the new argument:

```python
    errors = validate(
        matrix,
        known_uebungen=load_known_uebungen(),
        known_items=load_known_items(),
        konstrukt_items=konstrukt_items_of(matrix),
    )
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python -m unittest scripts.tests.test_check_deckung -v`
Expected: `Ran 21 tests`, `OK` — the five new tests plus the 16 pre-existing ones.

One pre-existing test must be updated, and this is the only test in the phase that may be:
`ValidateTest.test_freigegeben_without_item_or_exercise_fails` asserts the *cell-level*
`diagnostik` requirement, which Decision B deliberately replaces. Rewrite it to assert both
halves of the new rule rather than dropping either:

```python
    def test_freigegeben_without_item_or_exercise_fails(self):
        # Decision B (12-blueprint.md): die Uebung gehoert zur Zelle, das Diagnostik-Item
        # zum Konstrukt. Vor Phase 2 verlangte diese Regel beides auf der Zelle.
        rows = ALL_OFFEN.replace("| ZR10 | offen", "| ZR10 | freigegeben")
        text = matrix_with(rows, blocks_for(ALL_KEYS))
        errors = validate(parse_matrix(text), konstrukt_items={})
        self.assertTrue(any("freigegeben" in e and "übung" in e for e in errors), errors)
        self.assertTrue(
            any("freigegeben" in e and "teststrang.ZR10" in e for e in errors), errors)
```

Note in the commit message that the rule changed deliberately.

- [ ] **Step 5: Run the real gate**

Run: `python scripts/check_deckung.py`
Expected: `check_deckung: 20 Stränge, 180 Zellen (152 aktiv, 0 freigegeben)` / `OK: …`, exit 0. No cell is `freigegeben` yet, so R9 and the new clause have nothing to reject in the real tree — they are proven by the unit tests.

- [ ] **Step 6: Add the one permitted sentence to the matrix preamble**

In `docs/clean-room/v2/10-deckungsmatrix.md`, immediately after the paragraph that ends *„…braucht eine Begründung unter `Ausnahmen:`."*, insert:

```markdown
**Nachtrag 2026-09-08 (Phase 2).** Aus dieser Matrix sind
[11-konstruktkarte.md](11-konstruktkarte.md) und [12-blueprint.md](12-blueprint.md)
abgeleitet. Dabei ist die Freigaberegel präzisiert worden: die **Übung** gehört zur Zelle,
das **Diagnostik-Item** zum Konstrukt (Strang × Zahlenraum). Eine Zelle ist `freigegeben`,
wenn ihr Konstrukt ein Item hat und sie selbst eine Übung. Begründung und Zahlen stehen in
12-blueprint.md. An den Zellen, Ausnahmen und Status dieser Matrix ändert das nichts.
```

Change nothing else in the file. Re-run `python scripts/check_deckung.py` and confirm the counts are still `20 Stränge, 180 Zellen (152 aktiv, 0 freigegeben)`.

- [ ] **Step 7: Commit** *(gated)*

```bash
git add scripts/check_deckung.py scripts/tests/test_check_deckung.py docs/clean-room/v2/10-deckungsmatrix.md
git commit -m "$(cat <<'EOF'
feat(v2): Freigabe je Konstrukt statt je Zelle, neue Regel R9

Die Uebung gehoert zur Zelle, das Diagnostik-Item zum Konstrukt. Sonst
verlangte die Matrix mindestens 152 Items gegen die 70-90 aus dem v2-Entwurf
§5.5; mit dieser Regel sind es 86.

R9 haelt Items an ihr Konstrukt gebunden: ein Item darf nur in einer Zelle des
Konstrukts stehen, dessen ID es traegt.

Die Matrix selbst bleibt unveraendert - ein Nachtrag im Vorspann haelt die
praezisierte Regel fest, Zellen, Ausnahmen und Status sind unberuehrt.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Documentation, provenance, and Gate 1

**Files:**
- Modify: `docs/clean-room/v2/README.md`
- Modify: `DOCS_INDEX.md`
- Modify: `STATUS.md`
- Modify: `docs/clean-room/provenance.csv`

**Interfaces:**
- Consumes: everything above.
- Produces: nothing in code. Ends with the four questions Jakob answers at Gate 1.

- [ ] **Step 1: Update `docs/clean-room/v2/README.md`**

Add the five new files to the file table with one line each, and replace the gate command list with:

```bash
python scripts/extract_exercise_inventory.py   # Inventar aus exercise_service.dart neu erzeugen
python scripts/check_deckung.py            # Matrix: Deckung, Ausnahmen, Detailblöcke, R1-R9
python scripts/derive_ableitungen.py --check   # Konstruktkarte + Blueprint gegen die Matrix
python scripts/check_item_quality.py       # Items gegen die Itemregeln I1-I12
python -m unittest discover -s scripts/tests -p "test_*.py"
```

Add a short section stating the derivation chain and what is generated:

```markdown
## Was abgeleitet ist und was von Hand kommt

`10-deckungsmatrix.md` ist von Hand geschrieben und von Jakob unterschrieben. Alles
darunter fällt daraus:

Matrix -> Konstruktkarte -> Blueprint -> Items/Übungen

Der Rumpf von `11-konstruktkarte.md` und `12-blueprint.md` steht zwischen AUTOGEN-Marken
und wird erzeugt; `--check` schlägt fehl, sobald er von der Matrix abweicht. Die Regeln
oberhalb der Marken und die Dokumente 14/15 sind von Hand geschrieben.

Stand: 20 Stränge, 180 Zellen, 152 lebend, 28 begründete Ausnahmen, **54 Konstrukte,
86 geplante Items, 0 geschriebene Items** (Items sind Phase 3).
```

- [ ] **Step 2: Update `DOCS_INDEX.md`**

Under "⭐ Start here", after the Deckungsmatrix line, add:

```markdown
- [docs/clean-room/v2/11-konstruktkarte.md](docs/clean-room/v2/11-konstruktkarte.md) — 🟢 54 Konstrukte (Strang × Zahlenraum), aus der Matrix erzeugt. Ersetzt `01-construct-map.md`.
- [docs/clean-room/v2/12-blueprint.md](docs/clean-room/v2/12-blueprint.md) — 🟢 86 Items, Reihenfolge, Abkürzung, Blitz-Items. Aus der Konstruktkarte erzeugt. Ersetzt `02-blueprint.md`.
- [docs/clean-room/v2/14-itemregeln.md](docs/clean-room/v2/14-itemregeln.md) — 🟢 Abnahmekriterien I1–I12 für ein Item, je Regel der v1-Defekt dahinter.
- [docs/clean-room/v2/15-darstellungen.md](docs/clean-room/v2/15-darstellungen.md) — 🟢 Darstellungsschlüssel → Widget-Klasse → Manipulativ.
```

Extend the Vorrangregel line to:

```markdown
**Deckungsmatrix** > **Konstruktkarte** > **Blueprint** > **v2-Entwurf** > `docs/clean-room/00-v1-assessment.md` > `STATUS.md` > `rewrite.md` (rechtlich) > `phase1_school_platform.md` (Infrastruktur) > `TERMINOLOGY.md` > Rest.
```

and append one sentence to the paragraph below it:

```markdown
Konstruktkarte und Blueprint stehen über dem v2-Entwurf, weil sie aus der Matrix erzeugt
werden und der Entwurf nur noch beschreibt, wie das zustande kam.
```

- [ ] **Step 3: Update `STATUS.md`**

Update the `Last updated:` / `Previously:` line to `2026-09-08` / `2026-09-07`, and add to Active item #1:

```markdown
**Phase 2 abgeschlossen (2026-09-08).** Konstruktkarte (54 Konstrukte) und Blueprint
(86 Items) werden aus der Matrix erzeugt; `derive_ableitungen.py --check` verhindert
Drift. Itemregeln I1–I12 und das Darstellungsregister stehen; `check_item_quality.py`
prüft die mechanische Hälfte davon gegen ein Regressionskorpus aus vier Items, die v1
tatsächlich ausgeliefert hat. Die Freigaberegel der Matrix ist präzisiert: Übung je Zelle,
Diagnostik je Konstrukt. Noch kein einziges Item geschrieben — das ist Phase 3.

**Als Nächstes Phase 3:** der erste vertikale Slice, Verdoppeln/Halbieren × ZR10 · ZR20 ·
ZR100, von den Items über die handgebauten Übungsstufen bis in die Lehrerkonsole.
```

- [ ] **Step 4: Add provenance rows**

Append to `docs/clean-room/provenance.csv` one row per new artifact, matching the existing column order (`artifact_id,type,author,created,sources_cited,reviewed_by,reviewed_on,independent_of`), with `sources_cited` naming the Deckungsmatrix and the v2-Entwurf sections, and an independence statement recording that `_sources_private/` was not opened:

```
11-konstruktkarte,matrix-ableitung,Claude (erzeugt),2026-09-08,"10-deckungsmatrix.md; v2-Entwurf §3, §9",Jakob,,"Vollstaendig aus der freigegebenen Deckungsmatrix erzeugt; keine externe Quelle herangezogen, _sources_private/ nicht geoeffnet."
12-blueprint,matrix-ableitung,Claude (erzeugt),2026-09-08,"11-konstruktkarte.md; v2-Entwurf §5.3, §5.5",Jakob,,"Zuteilungs- und Reihenfolgeregel eigenstaendig festgelegt und begruendet; keine Itemzahl, Gruppierung oder Abbruchschwelle eines bestehenden Instruments uebernommen; _sources_private/ nicht geoeffnet."
14-itemregeln,regelwerk,Claude (Entwurf),2026-09-08,"v2-Entwurf §5.1; 00-v1-assessment.md Anhang A",Jakob,,"Jede Regel aus einem im eigenen v1-Bestand belegten Defekt abgeleitet; _sources_private/ nicht geoeffnet."
15-darstellungen,regelwerk,Claude (Entwurf),2026-09-08,"math_app/lib/widgets/manipulatives/; v2-Entwurf §5.1 Regel 4, Regel 8",Jakob,,"Register der bereits gebauten, gemeinfreien Manipulativ-Widgets; keine fremde Kartei herangezogen, _sources_private/ nicht geoeffnet."
```

Leave `reviewed_on` empty until Jakob signs at Step 6.

- [ ] **Step 5: Run every gate**

```bash
python -m unittest discover -s scripts/tests -p "test_*.py"
python scripts/check_deckung.py
python scripts/derive_ableitungen.py --check
python scripts/check_item_quality.py
python scripts/check_provenance.py
python scripts/check_mapping.py
```
Expected: tests green; `check_deckung`, `derive_ableitungen --check`, `check_item_quality`,
`check_provenance` and `check_mapping` all exit 0.

**Do not run `check_item_independence.py` in this phase.** It requires `--new` (a new item
bank CSV), and Phase 2 authors no items — there is nothing for it to compare. Worse, its
`--legacy` default is `_sources_private/MathApp_Diagnostic_with_skills.csv`, so running it
would open `_sources_private/`, which the standing rule forbids while drafting. It belongs to
Phase 3, once real items exist.

`python scripts/check_provenance.py --all` will fail on the four new rows because `reviewed_on` is empty — that is correct and expected until Step 6. Do not fill it in yourself.

`python scripts/check_legal_pages.py` fails on the Impressum/Datenschutz `[Name]` placeholders. Pre-existing, tracked in `tasks.md`, not part of this change — name it in the commit message rather than fixing it here.

- [ ] **Step 6: Put Gate 1 to Jakob**

Do not commit the review fields yourself. Ask these four questions and write his answers into `11-konstruktkarte.md` and `12-blueprint.md` under a `## Gate 1 — Freigabe` heading, exactly as Phase 1 did for the matrix:

1. **Ist ein Konstrukt ein Strang in einem Zahlenraum?** 54 Konstrukte statt 152 Zellen oder 20 Strängen. Die Repräsentation wird zur Evidenzstufe darin. Trägt das als Einheit, über die du einem Kollegen einen Befund berichtest?
2. **86 Items — zu viele, zu wenige, oder richtig?** Ein Kern-Item je Konstrukt, ein zweites nur bei drei lebenden Repräsentationen im ZR20/ZR100. Wo würdest du das zweite Item streichen, wo eines dazu wollen?
3. **Die Blitz-Stränge:** `anzahl-simultan`, `anzahl-strukturiert`, `vorgaenger-nachfolger`, `zerlegung`, `verdoppeln-halbieren`. Fehlt einer, steht einer zu viel darin?
4. **Die Itemregeln I1–I12:** Regel I2 deckelt den Prompt bei zwölf Wörtern und I1 bei einem Satz. Ist das für ein Klasse-2-Förderkind die richtige Grenze — oder wird eine sinnvolle Aufgabe damit unsagbar?

- [ ] **Step 7: Commit** *(gated — after Jakob's answers are written in)*

```bash
git add docs/clean-room/v2/README.md DOCS_INDEX.md STATUS.md docs/clean-room/provenance.csv docs/clean-room/v2/11-konstruktkarte.md docs/clean-room/v2/12-blueprint.md
git commit -m "$(cat <<'EOF'
docs(v2): Ableitungen in die Dokumentation einhaengen, Gate 1 freigegeben

Konstruktkarte und Blueprint stehen in der Vorrangregel zwischen Matrix und
v2-Entwurf. Provenance-Zeilen fuer die vier neuen Artefakte. STATUS auf
Phase 2 abgeschlossen, Phase 3 als naechstes.

check_legal_pages schlaegt weiterhin an den Impressum/Datenschutz-Platzhaltern
fehl - vorbestehend, in tasks.md gefuehrt, nicht Teil dieser Aenderung.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage (§9 Phase 2: "Konstruktkarte and Blueprint fall out of the matrix. Item acceptance criteria written down; `check_item_quality.py`."):**

| Spec requirement | Task |
|---|---|
| Konstruktkarte derived from the matrix (§3) | Task 1 |
| Blueprint: allocation, sequencing, Abkürzungsregeln (§3, §5.3, §5.5) | Task 2 |
| Item acceptance criteria written down (§5.1 rules 1–12) | Task 3 (`14-itemregeln.md`) |
| `check_item_quality.py`: sentence/word count, banned procedure phrases, reading proxy, audio present (§8) | Task 5 (I1–I4, I9) |
| `check_item_quality.py`: answer-field arity == expected-answer count, every field labelled (§8) | Task 4 (I5) |
| `check_item_quality.py`: manipulative named == widget registered (§8) | Tasks 3 + 4 (I6, `15-darstellungen.md`) |
| `check_item_quality.py`: Simultanerfassung capped at 5 (§8) | Task 5 (I7) |
| One generator, one source; drift gate (§7) | Tasks 1, 2 (`--check`) |
| Precedence Matrix > Konstruktkarte > Blueprint > Items (§3) | Task 7 |
| Provenance slimmed to four fields (§8) | Task 7 — the four new rows carry source, rationale-in-source, reviewer and independence statement; the CSV keeps its existing columns because v1 rows still use them. |

Two spec points are deliberately **not** in this plan, with reasons:

- **`check_item_independence.py` stays unchanged** (§8 says so). It is run in Task 7 Step 5 only to prove nothing broke.
- **Audio files are not generated.** §7 puts TTS at build time in Phase 5. I9 checks the naming contract, not file existence.

**Open point this plan resolves and Jakob must confirm:** §5.5's "~70–90 items" was written before the matrix existed, when §4 also estimated "roughly 60–70 live cells" and the signed matrix has 152. Decision B and the allocation rule reconcile them at 86. If Jakob rejects Decision B at Gate 1, Tasks 2 and 6 change and Tasks 1, 3, 4, 5 stand.

**Placeholder scan:** no TBD, no "handle edge cases", no "similar to Task N". Every code step carries the code; every verification step names the command and the expected output.

**Type consistency:** `Konstrukt` (Task 1) is consumed by `zuteilung` (Task 2) and `konstrukte()` by `check_item_quality.main` (Task 4). `Item` is defined twice under the same name in two modules — `derive_ableitungen.Item` (a planned item slot) and `check_item_quality.Item` (a parsed file). They never meet in one import; the names are correct in each module's own vocabulary. `validate_item`'s five-argument signature is identical in Tasks 4 and 5. `validate`'s new `konstrukt_items` keyword (Task 6) defaults to `None`, so the 19 existing `check_deckung` tests that omit it keep passing.
