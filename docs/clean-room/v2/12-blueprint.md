# 12 — Blueprint (v2)

| | |
|---|---|
| **Status** | ✅ FREIGEGEBEN — Jakob, 2026-09-08 (Gate 1) |
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

## Gate 1 — Freigabe

Jakob hat Itemzahl und Blitz-Stränge am **2026-09-08** als Förderlehrer geprüft und
freigegeben.

| Prüffrage | Antwort |
|---|---|
| 86 Items — zu viele, zu wenige, oder richtig? Ein Kern-Item je Konstrukt, ein zweites nur bei drei lebenden Repräsentationen im ZR20/ZR100. | 86 ist ok |
| Die Blitz-Stränge `anzahl-simultan`, `anzahl-strukturiert`, `vorgaenger-nachfolger`, `zerlegung`, `verdoppeln-halbieren` — fehlt einer, steht einer zu viel darin? | ist gut |

Damit sind die Zuteilungsregel und die Blitz-Liste verbindlich. Die Regel, nicht die Zahl,
ist das Freigegebene: 86 ist ihr Ergebnis an der heutigen Matrix. Ändert sich die Matrix,
ändert sich die Zahl mit — das braucht keine neue Freigabe, eine Änderung an der *Regel*
schon.

**Damit ausdrücklich mitentschieden:** §5.5 des v2-Entwurfs nannte ~70–90 Items und schätzte
60–70 lebende Zellen; die unterschriebene Matrix hat 152. Unter der alten Regel „ein Item je
Zelle" wären das ≥152 Items gewesen. Aufgelöst zugunsten der Matrix — die Schätzung ist
älter als sie — durch die Trennung **Übung je Zelle, Diagnostik je Konstrukt**. Die 86
liegen als Ergebnis dieser Regel in §5.5s Band, nicht weil das Band ein Ziel gewesen wäre.

<!-- AUTOGEN:START — erzeugt von scripts/derive_ableitungen.py, nicht von Hand bearbeiten -->

**54 Konstrukte, 86 Items** — 54 Kern-Items und 32 stützende Items, davon 13 Blitz-Items.

| # | Item | Konstrukt | Zahlenraum | Repräsentation | Rolle | Blitz |
|---|---|---|---|---|---|---|
| 1 | `zaehlen-vorwaerts.ZR10-01` | `zaehlen-vorwaerts.ZR10` | ZR10 | symbolisch | Kern | nein |
| 2 | `zaehlen-vorwaerts.ZR20-01` | `zaehlen-vorwaerts.ZR20` | ZR20 | symbolisch | Kern | nein |
| 3 | `zaehlen-vorwaerts.ZR20-02` | `zaehlen-vorwaerts.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 4 | `zaehlen-vorwaerts.ZR100-01` | `zaehlen-vorwaerts.ZR100` | ZR100 | symbolisch | Kern | nein |
| 5 | `zaehlen-vorwaerts.ZR100-02` | `zaehlen-vorwaerts.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 6 | `zaehlen-rueckwaerts.ZR10-01` | `zaehlen-rueckwaerts.ZR10` | ZR10 | symbolisch | Kern | nein |
| 7 | `zaehlen-rueckwaerts.ZR20-01` | `zaehlen-rueckwaerts.ZR20` | ZR20 | symbolisch | Kern | nein |
| 8 | `zaehlen-rueckwaerts.ZR20-02` | `zaehlen-rueckwaerts.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 9 | `zaehlen-rueckwaerts.ZR100-01` | `zaehlen-rueckwaerts.ZR100` | ZR100 | symbolisch | Kern | nein |
| 10 | `zaehlen-rueckwaerts.ZR100-02` | `zaehlen-rueckwaerts.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 11 | `zaehlen-schritte.ZR10-01` | `zaehlen-schritte.ZR10` | ZR10 | symbolisch | Kern | nein |
| 12 | `zaehlen-schritte.ZR20-01` | `zaehlen-schritte.ZR20` | ZR20 | symbolisch | Kern | nein |
| 13 | `zaehlen-schritte.ZR20-02` | `zaehlen-schritte.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 14 | `zaehlen-schritte.ZR100-01` | `zaehlen-schritte.ZR100` | ZR100 | symbolisch | Kern | nein |
| 15 | `zaehlen-schritte.ZR100-02` | `zaehlen-schritte.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 16 | `vorgaenger-nachfolger.ZR10-01` | `vorgaenger-nachfolger.ZR10` | ZR10 | symbolisch | Kern | ja |
| 17 | `vorgaenger-nachfolger.ZR20-01` | `vorgaenger-nachfolger.ZR20` | ZR20 | symbolisch | Kern | ja |
| 18 | `vorgaenger-nachfolger.ZR20-02` | `vorgaenger-nachfolger.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 19 | `vorgaenger-nachfolger.ZR100-01` | `vorgaenger-nachfolger.ZR100` | ZR100 | symbolisch | Kern | ja |
| 20 | `vorgaenger-nachfolger.ZR100-02` | `vorgaenger-nachfolger.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 21 | `anzahl-simultan.ZR10-01` | `anzahl-simultan.ZR10` | ZR10 | ikonisch | Kern | ja |
| 22 | `anzahl-strukturiert.ZR10-01` | `anzahl-strukturiert.ZR10` | ZR10 | ikonisch | Kern | ja |
| 23 | `anzahl-strukturiert.ZR20-01` | `anzahl-strukturiert.ZR20` | ZR20 | ikonisch | Kern | ja |
| 24 | `anzahl-strukturiert.ZR100-01` | `anzahl-strukturiert.ZR100` | ZR100 | ikonisch | Kern | ja |
| 25 | `anzahl-vergleich.ZR10-01` | `anzahl-vergleich.ZR10` | ZR10 | symbolisch | Kern | nein |
| 26 | `anzahl-vergleich.ZR20-01` | `anzahl-vergleich.ZR20` | ZR20 | symbolisch | Kern | nein |
| 27 | `anzahl-vergleich.ZR20-02` | `anzahl-vergleich.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 28 | `anzahl-vergleich.ZR100-01` | `anzahl-vergleich.ZR100` | ZR100 | symbolisch | Kern | nein |
| 29 | `anzahl-vergleich.ZR100-02` | `anzahl-vergleich.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 30 | `zahlvergleich-ordnen.ZR10-01` | `zahlvergleich-ordnen.ZR10` | ZR10 | symbolisch | Kern | nein |
| 31 | `zahlvergleich-ordnen.ZR20-01` | `zahlvergleich-ordnen.ZR20` | ZR20 | symbolisch | Kern | nein |
| 32 | `zahlvergleich-ordnen.ZR20-02` | `zahlvergleich-ordnen.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 33 | `zahlvergleich-ordnen.ZR100-01` | `zahlvergleich-ordnen.ZR100` | ZR100 | symbolisch | Kern | nein |
| 34 | `zahlvergleich-ordnen.ZR100-02` | `zahlvergleich-ordnen.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 35 | `zerlegung.ZR10-01` | `zerlegung.ZR10` | ZR10 | symbolisch | Kern | ja |
| 36 | `zerlegung.ZR20-01` | `zerlegung.ZR20` | ZR20 | symbolisch | Kern | ja |
| 37 | `zerlegung.ZR20-02` | `zerlegung.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 38 | `zerlegung.ZR100-01` | `zerlegung.ZR100` | ZR100 | symbolisch | Kern | ja |
| 39 | `zerlegung.ZR100-02` | `zerlegung.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 40 | `verdoppeln-halbieren.ZR10-01` | `verdoppeln-halbieren.ZR10` | ZR10 | symbolisch | Kern | ja |
| 41 | `verdoppeln-halbieren.ZR20-01` | `verdoppeln-halbieren.ZR20` | ZR20 | symbolisch | Kern | ja |
| 42 | `verdoppeln-halbieren.ZR20-02` | `verdoppeln-halbieren.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 43 | `verdoppeln-halbieren.ZR100-01` | `verdoppeln-halbieren.ZR100` | ZR100 | symbolisch | Kern | ja |
| 44 | `verdoppeln-halbieren.ZR100-02` | `verdoppeln-halbieren.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 45 | `buendeln-entbuendeln.ZR10-01` | `buendeln-entbuendeln.ZR10` | ZR10 | ikonisch | Kern | nein |
| 46 | `buendeln-entbuendeln.ZR20-01` | `buendeln-entbuendeln.ZR20` | ZR20 | symbolisch | Kern | nein |
| 47 | `buendeln-entbuendeln.ZR20-02` | `buendeln-entbuendeln.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 48 | `buendeln-entbuendeln.ZR100-01` | `buendeln-entbuendeln.ZR100` | ZR100 | symbolisch | Kern | nein |
| 49 | `buendeln-entbuendeln.ZR100-02` | `buendeln-entbuendeln.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 50 | `stellenwerttafel.ZR20-01` | `stellenwerttafel.ZR20` | ZR20 | symbolisch | Kern | nein |
| 51 | `stellenwerttafel.ZR20-02` | `stellenwerttafel.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 52 | `stellenwerttafel.ZR100-01` | `stellenwerttafel.ZR100` | ZR100 | symbolisch | Kern | nein |
| 53 | `stellenwerttafel.ZR100-02` | `stellenwerttafel.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 54 | `zahlenstrahl.ZR10-01` | `zahlenstrahl.ZR10` | ZR10 | symbolisch | Kern | nein |
| 55 | `zahlenstrahl.ZR20-01` | `zahlenstrahl.ZR20` | ZR20 | symbolisch | Kern | nein |
| 56 | `zahlenstrahl.ZR20-02` | `zahlenstrahl.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 57 | `zahlenstrahl.ZR100-01` | `zahlenstrahl.ZR100` | ZR100 | symbolisch | Kern | nein |
| 58 | `zahlenstrahl.ZR100-02` | `zahlenstrahl.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 59 | `addition-ohne-uebergang.ZR10-01` | `addition-ohne-uebergang.ZR10` | ZR10 | symbolisch | Kern | nein |
| 60 | `addition-ohne-uebergang.ZR20-01` | `addition-ohne-uebergang.ZR20` | ZR20 | symbolisch | Kern | nein |
| 61 | `addition-ohne-uebergang.ZR20-02` | `addition-ohne-uebergang.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 62 | `addition-ohne-uebergang.ZR100-01` | `addition-ohne-uebergang.ZR100` | ZR100 | symbolisch | Kern | nein |
| 63 | `addition-ohne-uebergang.ZR100-02` | `addition-ohne-uebergang.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 64 | `addition-mit-uebergang.ZR20-01` | `addition-mit-uebergang.ZR20` | ZR20 | symbolisch | Kern | nein |
| 65 | `addition-mit-uebergang.ZR20-02` | `addition-mit-uebergang.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 66 | `addition-mit-uebergang.ZR100-01` | `addition-mit-uebergang.ZR100` | ZR100 | symbolisch | Kern | nein |
| 67 | `addition-mit-uebergang.ZR100-02` | `addition-mit-uebergang.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 68 | `subtraktion-ohne-uebergang.ZR10-01` | `subtraktion-ohne-uebergang.ZR10` | ZR10 | symbolisch | Kern | nein |
| 69 | `subtraktion-ohne-uebergang.ZR20-01` | `subtraktion-ohne-uebergang.ZR20` | ZR20 | symbolisch | Kern | nein |
| 70 | `subtraktion-ohne-uebergang.ZR20-02` | `subtraktion-ohne-uebergang.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 71 | `subtraktion-ohne-uebergang.ZR100-01` | `subtraktion-ohne-uebergang.ZR100` | ZR100 | symbolisch | Kern | nein |
| 72 | `subtraktion-ohne-uebergang.ZR100-02` | `subtraktion-ohne-uebergang.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 73 | `subtraktion-mit-uebergang.ZR20-01` | `subtraktion-mit-uebergang.ZR20` | ZR20 | symbolisch | Kern | nein |
| 74 | `subtraktion-mit-uebergang.ZR20-02` | `subtraktion-mit-uebergang.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 75 | `subtraktion-mit-uebergang.ZR100-01` | `subtraktion-mit-uebergang.ZR100` | ZR100 | symbolisch | Kern | nein |
| 76 | `subtraktion-mit-uebergang.ZR100-02` | `subtraktion-mit-uebergang.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 77 | `ergaenzen.ZR10-01` | `ergaenzen.ZR10` | ZR10 | symbolisch | Kern | nein |
| 78 | `ergaenzen.ZR20-01` | `ergaenzen.ZR20` | ZR20 | symbolisch | Kern | nein |
| 79 | `ergaenzen.ZR20-02` | `ergaenzen.ZR20` | ZR20 | enaktiv | Stütze | nein |
| 80 | `ergaenzen.ZR100-01` | `ergaenzen.ZR100` | ZR100 | symbolisch | Kern | nein |
| 81 | `ergaenzen.ZR100-02` | `ergaenzen.ZR100` | ZR100 | enaktiv | Stütze | nein |
| 82 | `flexibles-rechnen.ZR20-01` | `flexibles-rechnen.ZR20` | ZR20 | symbolisch | Kern | nein |
| 83 | `flexibles-rechnen.ZR100-01` | `flexibles-rechnen.ZR100` | ZR100 | symbolisch | Kern | nein |
| 84 | `sachsituationen.ZR10-01` | `sachsituationen.ZR10` | ZR10 | symbolisch | Kern | nein |
| 85 | `sachsituationen.ZR20-01` | `sachsituationen.ZR20` | ZR20 | symbolisch | Kern | nein |
| 86 | `sachsituationen.ZR100-01` | `sachsituationen.ZR100` | ZR100 | symbolisch | Kern | nein |

### Abkürzungstabelle

| Strang | ZR10 | ZR20 | ZR100 |
|---|---|---|---|
| zaehlen-vorwaerts | `zaehlen-vorwaerts.ZR10` | `zaehlen-vorwaerts.ZR20` | `zaehlen-vorwaerts.ZR100` |
| zaehlen-rueckwaerts | `zaehlen-rueckwaerts.ZR10` | `zaehlen-rueckwaerts.ZR20` | `zaehlen-rueckwaerts.ZR100` |
| zaehlen-schritte | `zaehlen-schritte.ZR10` | `zaehlen-schritte.ZR20` | `zaehlen-schritte.ZR100` |
| vorgaenger-nachfolger | `vorgaenger-nachfolger.ZR10` | `vorgaenger-nachfolger.ZR20` | `vorgaenger-nachfolger.ZR100` |
| anzahl-simultan | `anzahl-simultan.ZR10` | — | — |
| anzahl-strukturiert | `anzahl-strukturiert.ZR10` | `anzahl-strukturiert.ZR20` | `anzahl-strukturiert.ZR100` |
| anzahl-vergleich | `anzahl-vergleich.ZR10` | `anzahl-vergleich.ZR20` | `anzahl-vergleich.ZR100` |
| zahlvergleich-ordnen | `zahlvergleich-ordnen.ZR10` | `zahlvergleich-ordnen.ZR20` | `zahlvergleich-ordnen.ZR100` |
| zerlegung | `zerlegung.ZR10` | `zerlegung.ZR20` | `zerlegung.ZR100` |
| verdoppeln-halbieren | `verdoppeln-halbieren.ZR10` | `verdoppeln-halbieren.ZR20` | `verdoppeln-halbieren.ZR100` |
| buendeln-entbuendeln | `buendeln-entbuendeln.ZR10` | `buendeln-entbuendeln.ZR20` | `buendeln-entbuendeln.ZR100` |
| stellenwerttafel | — | `stellenwerttafel.ZR20` | `stellenwerttafel.ZR100` |
| zahlenstrahl | `zahlenstrahl.ZR10` | `zahlenstrahl.ZR20` | `zahlenstrahl.ZR100` |
| addition-ohne-uebergang | `addition-ohne-uebergang.ZR10` | `addition-ohne-uebergang.ZR20` | `addition-ohne-uebergang.ZR100` |
| addition-mit-uebergang | — | `addition-mit-uebergang.ZR20` | `addition-mit-uebergang.ZR100` |
| subtraktion-ohne-uebergang | `subtraktion-ohne-uebergang.ZR10` | `subtraktion-ohne-uebergang.ZR20` | `subtraktion-ohne-uebergang.ZR100` |
| subtraktion-mit-uebergang | — | `subtraktion-mit-uebergang.ZR20` | `subtraktion-mit-uebergang.ZR100` |
| ergaenzen | `ergaenzen.ZR10` | `ergaenzen.ZR20` | `ergaenzen.ZR100` |
| flexibles-rechnen | — | `flexibles-rechnen.ZR20` | `flexibles-rechnen.ZR100` |
| sachsituationen | `sachsituationen.ZR10` | `sachsituationen.ZR20` | `sachsituationen.ZR100` |

<!-- AUTOGEN:ENDE -->
