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
    items = zuteilung(ks)
    errors += write_or_check(BLUEPRINT_PATH, render_blueprint(ks, items), args.check)

    verb = "geprueft" if args.check else "erzeugt"
    print(f"derive_ableitungen: {len(ks)} Konstrukte, {len(items)} Items "
          f"aus {len(matrix.cells)} Zellen {verb}")
    if errors:
        for err in errors:
            print("FAIL:", err)
        return 1
    print("OK: Ableitungen stimmen mit der Matrix ueberein")
    return 0


if __name__ == "__main__":
    sys.exit(main())
