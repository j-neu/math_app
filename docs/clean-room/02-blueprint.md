# 02 — Zweistufiger Test-Blueprint

| Feld | Wert |
|---|---|
| **Titel** | Blueprint: Kerntest (60 Items) + optionale Deep-Dive-Blöcke |
| **Status** | DRAFT — awaiting Jakob's sign-off |
| **Datum** | 2026-08-29 |
| **Owner** | Jakob |
| **Ersetzt** | die Item- und Sequenzplanung des bisherigen Diagnostikums (tasks.md, R1.4). |

## Zweistufiges Design

Die Diagnostik besteht aus zwei Stufen, die die Lehrkraft wählen kann:

1. **Kerntest — 60 Items** über alle vier Domänen (A–D). Er liefert in einer Sitzung ein belastbares Profil über alle Konstrukte der Konstruktkarte (01-construct-map.md). Administrationszeit: **20–30 Minuten**.
2. **Optionale Deep-Dive-Blöcke** je Domäne. Sie werden nur dann vorgelegt, wenn der Kerntest in einer Domäne Auffälligkeiten oder Uneindeutigkeiten zeigt, und vertiefen gezielt die betroffenen Konstrukte (siehe Abschnitt Deep-Dive-Blöcke). Sie verlängern die Sitzung um 5–10 Minuten pro Block.

Die Gesamtzahl von 60 Kern-Items ist eine eigene redaktionelle Entscheidung — bewusst gewählt, nicht von einem bestehenden Instrument übernommen (Begründung siehe `decisions/0003-why-60-core-items.md`). Jede Zuweisung unten ist mit der Literatur begründet.

Die Entscheidung, ob ein Deep-Dive-Block vorgelegt wird, trifft die Lehrkraft pro Kind nach Sichtung des Kernprofils; die App schlägt passende Blöcke vor, legt sie aber nicht automatisch vor. Beide Stufen verwenden dasselbe Item-Template (rewrite.md §6) und dieselben Provenance-Anforderungen.

## Kern-Allokation (60 Items)

| Konstrukt | Items | Verteilung auf Teilkonstrukte | Begründung |
|---|---|---|---|
| A1 Zählkompetenz | 7 | A1.1×2, A1.2×2, A1.3×2, A1.4×1 | Zählkompetenz ist der diagnostisch wirkungsvollste Einzelbereich und trägt alle späteren Zahl- und Operationsvorstellungen (Wartha 2019; Padberg/Benz 2021). Sieben Items decken alle fünf Teilkonstrukte ab; A1.5 (Zehnerübergang) wird nicht durch ein eigenes Item geprüft, sondern durch A1.1-02 (ZR100-Zählfolge über zwei Dekadenwechsel), das den Übergang bereits misst — ein separates A1.5-Item (ehem. A1.5-01) erwies sich bei der R2.9-Durchsicht (2026-08-30) als redundant dazu und wurde entfernt. |
| A2 Anzahlerfassung | 4 | A2.1×1, A2.2×2, A2.3×1 | Die frühe Mengenerfassung ist ein Prädiktor für die weitere Zahlentwicklung (Krajewski 2003/2008). Vier Items genügen, um zu unterscheiden, ob ein Kind Mengen strukturell erfasst oder noch abzählt. |
| A3 Zahlzerlegung | 8 | A3.1×3, A3.2×3, A3.3×2 | Die Zerlegung ist die Grundlage jeder nicht-zählenden Strategie (Padberg/Benz 2021; Karner, Open Access). Acht Items decken beide Richtungen ab — Zerlegen und Zusammensetzen — und die Zahlbeziehungen als Stütze. |
| B1 Bündelung/Entbündelung | 4 | B1.1×1, B1.2×2, B1.3×1 | Stellenwertprobleme zeigen sich empirisch am deutlichsten beim Bündeln und Entbündeln (Moser Opitz 2013). Vier Items decken die drei Teilkonstrukte mit einem Schwerpunkt auf der Bündelung selbst ab. |
| B2 Zahldarstellung | 4 | B2.1×2, B2.2×1, B2.3×1 | Die Zahldarstellung verbindet Zahlverständnis mit Repräsentationen wie Stellenwerttafel und Zahlenstrahl (Schipper 2009; KMK 2022). Vier Items prüfen Standardform, Zahlenstrahl und eine nicht-standardisierte Darstellung. |
| C1 Grundaufgaben ZR10 | 8 | C1.1×4, C1.2×2, C1.3×2 | Grundaufgaben im ZR10 sind die automatisierte Basis des Rechnens (Gaidoschik 2010). Acht Items spreizen sich über Plus- und Minusaufgaben, Verdopplungen, Halbierungen und Ergänzungen zur Zehn. |
| C2 Strategien ZR20 mit Zehnerübergang | 8 | C2.1×3, C2.2×2, C2.3×3 | Der Zehnerübergang ist die zentrale Hürde im ZR20 (Gaidoschik 2010; Wartha 2019). Acht Items decken Zerlegen, Stützaufgaben und Ergänzen in beiden Operationen ab; dieser Bereich trägt zugleich die Abkürzungsregel. |
| C3 Strategien ZR100 | 10 | C3.1×3, C3.2×3, C3.3×2, C3.4×2 | Der Hunderterraum ist der größte Zahlraum und bietet mehrere Strategien in beiden Operationen (Selter/Spiegel 1997). Zehn Items sind nötig, um stellenweises und schrittweises Rechnen, Hilfsaufgaben und Zerlegung getrennt beurteilen zu können. |
| C4 Flexibles Rechnen | 4 | C4.1×2, C4.2×2 | Flexibles Rechnen zeigt sich in der Strategiewahl. Vier Items sind so gestaltet, dass die gewählte Strategie sichtbar wird (u. a. über Reaktionszeiterfassung), statt nur die Richtigkeit zu prüfen (Selter/Spiegel 1997). |
| D1 Sachsituationen | 2 | D1.1×1, D1.2×1 | Sachsituationen sind in vielen bestehenden Instrumenten bereits abgedeckt (KMK 2022). Im Kerntest genügen zwei Items als Indikator; vertieft wird der Bereich im Deep-Dive-D-Block. |
| **Gesamt** | **59** | | Die Summe der Teilkonstrukte je Zeile ergibt die Items-Zahl. Ursprünglich 60 (siehe `decisions/0003-why-60-core-items.md`); seit der A1.5-01-Streichung (R2.9, 2026-08-30) 59 — die Zielgröße war eine Ausgangsschätzung, keine harte Vorgabe, und eine Domäne durch ein redundantes Item künstlich auf 60 aufzufüllen wäre der falsche Trade-off. |

## Item-Ebene

Für jedes der 60 Kern-Items und für jedes Deep-Dive-Item wird eine Item-Datei gemäß dem Template aus rewrite.md §6 angelegt (`docs/clean-room/items/<ID>.md`) mit Konstrukt-ID, Schwierigkeitsklasse, Zahlraum, Stimulusform, erwarteter Antwort, Fehlerdiagnostik und Skill-Zuordnung. Die Fehlerschwellen der Skip-Tabelle werden in den Item-Dateien derjenigen Items hinterlegt, die den jeweiligen Break-off auslösen, damit die Implementierung alle Regeln aus einer einzigen Quelle bezieht.

## Sequenzregeln

1. **Konstruktreihenfolge vom Leichten zum Schweren:** A1 → A2 → A3 → B1 → B2 → C1 → C2 → C3 → C4 → D1. Dies folgt der üblichen didaktischen Abfolge der Grundschulmathematik (Zahlbegriff vor Operationen, ZR10 vor ZR20 vor ZR100) und steht im Einklang mit der Sequenz von Rahmenlehrplan BE/BB 2023 und Padberg/Benz 2021.
2. **Innerhalb eines Konstrukts** werden die Items nach Schwierigkeit geordnet: kleinere Zahlen beziehungsweise kleinere Zahlräume zuerst, größere danach.
3. **Break-off-fähige Items** (jene, deren Scheitern eine Abkürzung auslöst, siehe §Break-off) stehen jeweils am Anfang ihres Konstrukts, damit früh entschieden werden kann, ob weitere Items desselben Bereichs noch sinnvoll sind.
4. **Gemischte Operationen:** Wo ein Konstrukt Addition und Subtraktion testet, werden die Operationen abwechselnd gereiht, um Reihenfolge-Effekte (Set-Effekte) zu vermeiden.
5. **Reaktionszeiterfassung** ist bei jenen C2–C4-Items Teil der Spezifikation, bei denen die Strategie aus der Bearbeitungszeit erschlossen werden soll (Selter/Spiegel 1997).

## Schwierigkeitsverteilung

Die 60 Kern-Items sind über folgende Schwierigkeitsklassen verteilt:

| Klasse | Anteil | Erwartete Passquote (2. Klasse) |
|---|---|---|
| Leicht | 30 % (≈18 Items) | > 80 % |
| Mittel | 50 % (≈30 Items) | 40–80 % |
| Schwer | 20 % (≈12 Items) | < 40 % |

Begründung: Diagnostische Instrumente sollen die Kinder spreizen, damit Förderbedarf sichtbar wird. Die Verteilung mit einem Schwerpunkt im mittleren Bereich folgt der gängigen Testkonstruktionsnorm der Item-Response-Theorie, wonach Items mittlerer Schwierigkeit die meiste Information liefern; die Zielvorgaben gelten testweit, nicht je Konstrukt.

## Eigenständigkeit der Planung

Item-Anzahl, Konstruktreihenfolge, Schwierigkeitsverteilung und Abkürzungsregeln sind eigene redaktionelle Entscheidungen auf Grundlage der zitierten Literatur. Sie übernehmen weder die Itemanzahl noch die Gruppierung, die Reihenfolge oder die Abbruchschwellen irgendeines bestehenden Instruments; Überschneidungen in Konstruktnamen sind unvermeidlich, weil die Konstrukte selbst Standard der Grundschulmathematik sind (vergleiche hierzu `01-construct-map.md`, „Geltung und Abgrenzung"). Jede Abweichung von dieser Planung wird im Item-Entwicklungslog (04-item-development-log.md) mit Begründung festgehalten.

## §Break-off — Abkürzungsregel

Der Kerntest bricht ab, sobald ein Scheitern auf einem Konstrukt das Scheitern auf späteren Konstrukten vorhersagbar macht; die übersprungenen Items würden dann kaum zusätzliche diagnostische Information tragen. Die zentrale publizierte Argumentation dafür: Wer Aufgaben mit Zehnerübergang im ZR20 nicht bewältigt, wird Aufgaben im ZR100 nicht bewältigen — eine ZR100-Aufgabe wie „38 + 27" bringt für ein Kind, das „8 + 7" nicht löst, keinen neuen Erkenntniswert (Wartha 2019, Rechenproblemen vorbeugen, Kap. n.n. — folgt nach Ankunft).

Die konkrete Schwelle (z. B. „zwei von drei Items eines Konstrukts falsch") wird pro Konstrukt in den Item-Dateien festgelegt. Die folgende Tabelle ist so geschrieben, dass ein Implementierer sie direkt in eine Dart-Skip-Tabelle überführen kann (Zeilen → `Map<Konstrukt, SkipGroup>`); keine Zeile verweist auf Fragennummern eines früheren Instruments.

| Wenn Konstrukt X im Kerntest scheitert … | … dann überspringe Gruppe Y | Grundlage |
|---|---|---|
| A1.3 (Zählen in Schritten) **und** A1.5 (Zählen über den Zehnerübergang) | gesamte Domäne C (C1–C4) | Zählkompetenz ist das Fundament der Operationsvorstellungen; ohne gesichertes Zählen über die Zehn sind additive Strategien nicht erreichbar — deren Items wären reine Frustrationsitems. |
| A3 (Zahlzerlegung) | C2.1 und C2.2 (Zerlege- und Stützstrategien ZR20) | Zerlegungssicherheit ist Voraussetzung der Teilschritt-Verfahren; ohne sie tragen diese Items keine Information. |
| C2 (Strategien ZR20 mit Zehnerübergang) | C3 (Strategien ZR100) und C4 (flexibles Rechnen) | Kernregel: Scheitern im ZR20 mit Zehnerübergang sagt Scheitern im ZR100 voraus (Wartha 2019). |
| C3 (Strategien ZR100) | C4 (flexibles Rechnen) | Flexibles Rechnen setzt operative Sicherheit im Hunderterraum voraus; ohne sie ist Strategiewahl nicht aussagekräftig beobachtbar. |
| D1.1 (Mathematisierung) | D1.2 (Operationserkennung) | Ohne Übersetzung der Sachsituation in eine Darstellung ist die Operationserkennung nicht sinnvoll testbar. |

Hinweis für die Implementierung: Ein Skip wird erst ausgelöst, wenn die in den Item-Dateien festgelegte Fehlerschwelle erreicht ist; der Kerntest endet bei einem Skip, sobald die übersprungene Gruppe begonnen hätte — die bereits erreichten Konstrukte bleiben vollständig ausgewertet.

Mechanik: Der Ablauf des abkürzenden Diagnostikums (Anzeige, Antwortannahme, Fortsetzen nach Unterbrechung) bleibt bestehende Software; neu abgeleitet sind ausschließlich die Regeln selbst (tasks.md, R1.5). Ein Unit-Test prüft, dass die Dart-Skip-Tabelle für jedes Konstrukt genau den oben dokumentierten Zeilen entspricht und keine Regel eine frühere Fragennummer nennt.

## Deep-Dive-Blöcke

Jeder Block ist optional, wird nur auf Anforderung der Lehrkraft vorgelegt und folgt demselben Item-Template und denselben Provenance-Anforderungen wie der Kerntest (tasks.md, R1.4, R2.8).

| Block | Umfang | Einstiegskriterium („diesen Block hinzufügen, wenn der Kerntest … zeigt") |
|---|---|---|
| Deep-Dive A — Zahlbegriff | 10 Items | A1/A2/A3 im Kerntest auffällig oder grenzwertig sind, insbesondere beim schrittweisen Zählen, bei der strukturierten Mengenerfassung oder bei der flexiblen Zerlegung. |
| Deep-Dive B — Stellenwert | 6 Items | B1 oder B2 im Kerntest nicht bestanden wurden; der Block enthält auch die auditive Zahldarstellung (Zahlendiktat in eigener Form), die im Kerntest nicht vorkommt. |
| Deep-Dive C — Rechenstrategien | 10 Items | C2 im Kerntest nur grenzwertig bestanden wurde oder die Lehrkraft zählendes Rechnen vermutet; Items mit Reaktionszeiterfassung machen die Strategiewahl sichtbar. |
| Deep-Dive D — Sachsituationen | 6 Items | D1 im Kerntest nicht bestanden oder grenzwertig ausgefallen ist; der Block trennt Mathematisierung von reiner Operationserkennung. |

## Administrationszeit

- **Kerntest:** 20–30 Minuten (60 Items; mit Break-off verkürzt sich die Zeit entsprechend).
- **Je Deep-Dive-Block:** +5–10 Minuten.
- Für Kinder der 2. Klasse wird eine Pause nach ca. 15 Minuten eingeplant; der Kerntest ist so aufgebaut, dass er an einer festgelegten Stelle unterbrochen und in derselben Sitzung fortgesetzt werden kann.

## Abdeckung der Konstruktkarte

Jedes Konstrukt der Konstruktkarte (01-construct-map.md) ist im Kerntest oder in einem Deep-Dive-Block gemessen: A1.1–A1.5, A2.1–A2.3, A3.1–A3.3, B1.1–B1.3, B2.1–B2.3, C1.1–C1.3, C2.1–C2.3, C3.1–C3.4, C4.1–C4.2 und D1.1–D1.2 tragen alle Kern-Items (siehe Tabelle oben); die Deep-Dive-Blöcke ergänzen pro Domäne zusätzliche Items für die genannten Vertiefungsbereiche. Kein Konstrukt der Karte bleibt in beiden Stufen ungemessen.
