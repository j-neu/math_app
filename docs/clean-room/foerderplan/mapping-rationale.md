# Item→Skill-Zuordnung (If-wrong → Förderskills)

| Feld | Wert |
|---|---|
| **Titel** | Item→Skill-Zuordnung (If-wrong → Förderskills) |
| **Status** | DRAFT — awaiting Jakob's sign-off |
| **Datum** | 2026-08-29 |
| **Owner** | Jakob |
| **Bezug** | tasks.md, R4.1 |

## Einführung

Diese Datei ist die Item→Skill-Zuordnung (tasks.md, R4.1): Für jedes der 92 Items des Item-Banks (60 Kern-Items + 32 Deep-Dive-Items) wird begründet, welche Förderskills ein Fehler auf dem Item nahelegt. Die Fehlerdiagnostik stammt aus den Item-Dateien (R2.*), die Ursachenzuschreibung aus der Konstruktkarte (`01-construct-map.md`) und der Bibliographie (`03-bibliography.md`).

**Begründungsform (Reasoning Chain):** *wahrscheinliche Ursache → Skill-Lücke → empfohlene Skills in Prioritätsreihenfolge.* Jeder Eintrag nennt erst die wahrscheinlichste Fehlerursache, dann die dadurch sichtbare Skill-Lücke (aus `skills_taxonomy.csv`, R3.3), dann die empfohlenen Skills in Prioritätsreihenfolge (1. = höchste Priorität).

**Vollständige Skill-IDs:** Die Taxonomie kennt 36 Skill-IDs; gesplittete Konstrukte verwenden Suffix-IDs (A1.1a/b, A1.2a/b, C1.1a/b, C3.1a/b, C3.4a/b). Wo die Item-Datei nur den unsuffigierten Konstruktnamen nennt (z. B. „A1.1" oder „C1.1"), wählt diese Zuordnung die passende Teil-Skill-ID — entscheidend sind der Zahlraum (ZR20 → a, ZR100 → b) bzw. die Operationsrichtung (Addition → a, Subtraktion → b). Solche Auflösungen sind im jeweiligen Eintrag markiert.

**Reihenfolge im Förderplan:** Die Prioritätsreihenfolge innerhalb eines Eintrags ist die Item→Skill-Priorität (1. = höchste). Die endgültige Sortierung aller Empfehlungen eines Förderplans übernimmt die Reihenfolgeregel (`ordering-rule.md`, R4.2): Primärschlüssel ist die kanonische Konstruktposition, Sekundärschlüssel das ID-Suffix; die hier vergebene Priorität übersteuert nur innerhalb desselben Konstrukts.

---

## Kern-Items Domäne A — Zahlbegriff

### A1.1-01 — Vorwärtszählen ZR20
**If wrong → most likely cause:** Die Zahlwortreihe ist nicht stabil oder der Zehnerwechsel an der 20 ist nicht sicher (Springen von 19 auf 21, Abbruch vor der Zielzahl).
**Skill gap:** Vorwärtszählen bis 20 (A1.1a) ist nicht automatisiert.
**Recommended (priority order):** A1.1a
**Reasoning:** Das Item liegt im ZR20 (Start 12, Ziel 20); Fehler wie Reihenfolgefehler oder „19 → 21" zeigen genau die Kompetenz von A1.1a. Auflösung: die Item-Datei nennt „A1.1", gewählt wird A1.1a wegen des Zahlraums ZR20. Höchste Priorität, weil die Zählkompetenz das Fundament aller späteren Operationsvorstellungen trägt (Wartha 2019; Padberg/Benz 2021). Kein Break-off-Item.

### A1.1-02 — Vorwärtszählen ZR100
**If wrong → most likely cause:** Die Dekadenübergänge im Hunderterraum (49 → 50, 59 → 60) sind nicht automatisiert.
**Skill gap:** Vorwärtszählen bis 100 (A1.1b) fehlt; zusätzlich ist das Zählen über die Zehnergrenze (A1.5) unsicher.
**Recommended (priority order):** A1.1b, A1.5
**Reasoning:** ZR100-Start 48 über zwei Dekadenwechsel → A1.1b. Auflösung: „A1.1" → A1.1b. Der dokumentierte Fehler „Dreht bei 59 auf 40/50 zurück" zeigt zugleich die Zehnergrenzen-Hürde (A1.5); deshalb wird erst die flüssige Zahlwortreihe (A1.1b), dann der Übergang (A1.5) gefördert. Break-off-relevant: scheitert dieses Item zusammen mit A1.3-01/02 und A1.5-01, wird Domäne C übersprungen (§Break-off).

### A1.2-01 — Rückwärtszählen ZR20
**If wrong → most likely cause:** Die rückwärtige Zahlwortreihe ist nicht stabil oder der Richtungswechsel (21 → 20) misslingt.
**Skill gap:** Rückwärtszählen bis 20 (A1.2a) ist nicht gesichert.
**Recommended (priority order):** A1.2a
**Reasoning:** Item im Zwanzigerraum (21 → 16); Fehler wie „zählt vorwärts" oder „lässt Zahlen aus" zeigen die Lücke der rückwärtigen Zahlwortreihe (Wartha 2019). Auflösung: „A1.2" → A1.2a (ZR20). Kein Break-off-Item; Rückwärtszählen ist aber Voraussetzung des Ablösens vom zählenden Rechnen (Selter/Spiegel 1997).

### A1.2-02 — Rückwärtszählen ZR100
**If wrong → most likely cause:** Die rückwärtige Zahlwortreihe im Hunderterraum ist lückenhaft; der Dekadenwechsel rückwärts (59 → 50) ist unsicher.
**Skill gap:** Rückwärtszählen bis 100 (A1.2b) ist nicht automatisiert.
**Recommended (priority order):** A1.2b
**Reasoning:** ZR100-Folge 58–51 → A1.2b. Auflösung: „A1.2" → A1.2b. Fehlerdiagnostik nennt Hängenbleiben an der 50 und Einerstrangfehler — exakt die Kompetenz von A1.2b. Kein Break-off-Item.

### A1.3-01 — Zählen in Zweierschritten
**If wrong → most likely cause:** Schrittweises Zählen ist nicht entwickelt (zählt in Einserschritten) oder die Schrittweite wird nicht konstant gehalten.
**Skill gap:** Zählen in Schritten (A1.3) fehlt.
**Recommended (priority order):** A1.3
**Reasoning:** Das Item misst genau A1.3 (2er-Schritte, Start 26 im ZR100; Padberg/Benz 2021). Fehler „27, 28, …" bzw. „28, 31, 34" zeigen die fehlende rhythmisierte Zahlenreihe. Break-off-relevant: A1.3-01/02 falsch plus A1.5-01 falsch überspringen Domäne C (§Break-off) — der Fehler hier hat Vorhersagekraft, daher hohe Förderpriorität.

### A1.3-02 — Zählen in Fünferschritten rückwärts
**If wrong → most likely cause:** Die Kombination aus Schrittweite und Rückwärtsrichtung ist nicht verfügbar; die Zehnerstruktur der Fünferreihe wird nicht genutzt.
**Skill gap:** Zählen in Schritten (A1.3), insbesondere die rückwärtige Schrittfolge.
**Recommended (priority order):** A1.3
**Reasoning:** A1.3 umfasst vor- und rückwärts in 2er/5er/10er-Schritten. Fehler wie „45 → 44, 43, …" oder Schrittweiten-Verlust zeigen die A1.3-Lücke. Break-off-relevant wie A1.3-01 (§Break-off): Ein Fehler hier prädiziert Frustration in Domäne C.

### A1.4-01 — Vorgänger/Nachfolger
**If wrong → most likely cause:** Die Ordnungsrelation ist nicht auf der Zahlwortreihe verankert; Vorgänger und Nachfolger werden vertauscht oder zu weit entfernt benannt.
**Skill gap:** Vorgänger/Nachfolger (A1.4); bei fehlender Ordnungsvorstellung zusätzlich die Zahlwortreihe im ZR100 (A1.1b).
**Recommended (priority order):** A1.4, A1.1b
**Reasoning:** Item zur Zahl 37 prüft A1.4 (Wartha 2019). Auflösung: sekundär genannter Skill „A1.1" → A1.1b (ZR100-Zahl). Die Fehlerdiagnostik „Keine Antwort: Zahlreihe als Ordnung nicht verfügbar" begründet den Anschluss-Skill. Priorität: erst das Nachbarzahlen-Konzept (A1.4), dann die zugrunde liegende Zahlwortreihe (A1.1b).

### A1.5-01 — Zählen über den Zehnerübergang
**If wrong → most likely cause:** Der Zehnerübergang beim Zählen ist nicht flüssig — das Kind reißt an der Stelle 19 → 20 ab oder springt auf 30.
**Skill gap:** Zählen über den Zehnerübergang (A1.5); sekundär die Zahlwortreihe im ZR20 (A1.1a).
**Recommended (priority order):** A1.5, A1.1a
**Reasoning:** Kernindikator des Break-off: A1.3 (beide Items) und A1.5-01 falsch überspringen Domäne C (§Break-off; Wartha 2019). Auflösung: „A1.1" → A1.1a (ZR20). Priorität A1.5 vor A1.1a, weil der Übergang die eigentliche Hürde ist; die stabile Folge innerhalb der 20er ist die Basis.

### A2.1-01 — Simultanerfassung (Subitizing)
**If wrong → most likely cause:** Die Anzahl wird geschätzt statt erfasst (Unterschätzung/Überschätzung), oder das Abzählen ist noch die tragende Strategie.
**Skill gap:** Mengen auf einen Blick erfassen (A2.1); sekundär Vorwärtszählen (A1.1a), falls zum Abzählen gegriffen wird.
**Recommended (priority order):** A2.1, A1.1a
**Reasoning:** 800-ms-Flash auf dem Rekenrek erzwingt Simultanerfassung → A2.1 (Krajewski 2003/2008). Auflösung: „A1.1" → A1.1a (Zählen kleiner Zahlen als Anschluss beim Abzählen). Priorität: erst die Simultanerfassung (A2.1), die das Abzählen ersetzen soll.

### A2.2-01 — Strukturierte Erfassung 5+1
**If wrong → most likely cause:** Die Restzelle wird übersehen (Antwort 5) — die Fünferstruktur dominiert, die Ergänzung wird nicht integriert.
**Skill gap:** Mengen über Strukturen erkennen (A2.2); Anschluss Simultanerfassung (A2.1) bei einzelner Zählung.
**Recommended (priority order):** A2.2, A2.1
**Reasoning:** Zehnerfeld-Belegung 5+1 prüft A2.2 (Padberg/Benz 2021; Rahmenlehrplan BE/BB 2023). Fehler „5" = reine Fünferanker-Erfassung ohne Rest; Fehler „zählt einzeln" = A2.1-Lücke. Priorität A2.2, dann A2.1.

### A2.2-02 — Fingerbild 5+3
**If wrong → most likely cause:** Die Teilmengen der beiden Hände werden nicht zusammengeführt (Antwort 5 oder 3) oder ungenau addiert.
**Skill gap:** Mengen über Strukturen erkennen (A2.2); Anschluss A2.1.
**Recommended (priority order):** A2.2, A2.1
**Reasoning:** Struktur 5+3 über zwei Hände verlangt das getrennte Erfassen und Zusammenführen zweier Teilbilder (Padberg/Benz 2021). Fehler „5"/„3" = Teilmengen nicht verbunden. Priorität A2.2, dann A2.1.

### A2.3-01 — Mengenvergleich 6 vs 8
**If wrong → most likely cause:** Der Vergleich läuft ohne Struktur ab; der Unterschied von zwei Feldern wird nicht erkannt („gleich") oder die Seiten verwechselt.
**Skill gap:** Mengen vergleichen (A2.3); Anschluss strukturierte Erfassung (A2.2).
**Recommended (priority order):** A2.3, A2.2
**Reasoning:** Item prüft die mehr/weniger-Beziehung bei strukturierten Mengen (Krajewski 2003/2008; KMK 2022). Fehler „gleich" = untere Zeilen nicht verglichen; Abzählen beider Mengen = A2.2-Anschluss. Priorität A2.3, dann A2.2.

### A3.1-01 — Teil-Teil-Ganzes: Ergänzen
**If wrong → most likely cause:** Die Teil-Ganzes-Beziehung ist instabil — das Kind addiert Teil und Ganzes (10) oder nennt das Ganze statt des fehlenden Teils.
**Skill gap:** Zahlen aus Teilen zusammensetzen (A3.1); bei abzählender Lösung Anschluss strukturierte Erfassung (A2.2).
**Recommended (priority order):** A3.1, A2.2
**Reasoning:** Ergänzungsrichtung der Teil-Teil-Ganzes-Aufgabe (6 = 4 + ?) prüft A3.1 (Lenz & Wittmann 2023; Padberg/Benz 2021). Fehler „10" = Teil und Ganzes addiert; „zählt einzeln ab" = A2.2-Anschluss. Priorität A3.1.

### A3.1-02 — Teil-Teil-Ganzes: 10 = 3 + __
**If wrong → most likely cause:** Ganzes und Teile werden verwechselt (13 = 3 + 10) oder die Zehnerzerlegung ist nicht aktivierbar.
**Skill gap:** A3.1; die Zehnerzerlegung als Zahlbeziehung (A3.3) als Stütze.
**Recommended (priority order):** A3.1, A3.3
**Reasoning:** Symbolische Lückenform prüft A3.1 (Padberg/Benz 2021). Fehler „13" = Teil + Ganzes; die Ergänzung 3 + 7 = 10 ist zugleich eine A3.3-Zahlbeziehung. Priorität A3.1, dann A3.3.

### A3.1-03 — Teil-Teil-Ganzes: Zusammensetzen
**If wrong → most likely cause:** Die Komposition gelingt nicht vollständig — das Kind bildet die Differenz (2) oder nennt nur einen der beiden Teile.
**Skill gap:** A3.1; Zahlbeziehungen (A3.3) als Stütze für „6 und 4 sind 10".
**Recommended (priority order):** A3.1, A3.3
**Reasoning:** Kompositionsrichtung von A3.1 (Lenz & Wittmann 2023). Fehler „2" = Differenz statt Summe; A3.3 stützt das Zusammensetzen zum vollen Zehner. Priorität A3.1, dann A3.3.

### A3.2-01 — Zerlegungen von 8
**If wrong → most likely cause:** Nur eine Standardzerlegung ist verfügbar; die Flexibilität über mehrere Zerlegungen fehlt.
**Skill gap:** Zerlegungen einer Zahl finden (A3.2); A3.1 als Teil-Ganzes-Basis.
**Recommended (priority order):** A3.2, A3.1
**Reasoning:** Offene Produktionsform prüft flexible Zerlegung (Karner, Zahlzerlegungen im ZR10). Fehler „nur eine Zerlegung" bzw. „Tauschaufgabe als verschieden" = A3.2-Lücke. Priorität A3.2, dann A3.1.

### A3.2-02 — Tauschaufgabe
**If wrong → most likely cause:** Die Tauschbeziehung wird nicht als Stütze genutzt (3 statt 5) oder Ganzes/Teile verwechselt.
**Skill gap:** A3.2; A3.1 als Fundament.
**Recommended (priority order):** A3.2, A3.1
**Reasoning:** Stützsatz „8 = 5 + 3" prüft die flexible Nutzung der Tauschbeziehung (Karner). Fehler „3" = sichtbarer Teil wiederholt. Priorität A3.2, dann A3.1.

### A3.2-03 — Alle Zerlegungen von 10
**If wrong → most likely cause:** Die Enumeration ist nicht systematisch — Zerlegungen werden zufällig gesammelt, Vollständigkeit fehlt.
**Skill gap:** A3.2 (systematische Zerlegung); A3.1 als Ganzes-Konzept.
**Recommended (priority order):** A3.2, A3.1
**Reasoning:** Vollständigkeitsanforderung ist die höchste Stufe von A3.2 (Karner). Fehler „lässt 4+6/5+5 aus" = fehlende Systematik. Priorität A3.2, dann A3.1.

### A3.3-01 — Verdopplung der 4
**If wrong → most likely cause:** Die Verdopplungs-/Halbierungsbeziehung ist verwechselt (2) oder die Zahlbeziehung wird nicht erfasst (4).
**Skill gap:** Zahlbeziehungen nutzen (A3.3); A3.1 als Teil-Ganzes-Basis.
**Recommended (priority order):** A3.3, A3.1
**Reasoning:** Verdopplung als Zahlbeziehung (Gaidoschik 2010). Fehler „2" = halbiert statt verdoppelt. A3.1 stützt die Teil-Ganzes-Sicht. Priorität A3.3, dann A3.1.

### A3.3-02 — Nachbaraufgabe 4+5
**If wrong → most likely cause:** Die Nachbaraufgaben-Beziehung wird nicht genutzt — das Doppel 8 wird übernommen oder es wird abgezählt.
**Skill gap:** A3.3; A3.1.
**Recommended (priority order):** A3.3, A3.1
**Reasoning:** Ableitung einer Nachbaraufgabe aus einem Doppel ist der Kern von A3.3 (Gaidoschik 2010). Fehler „8" = Beziehung nicht übertragen. Priorität A3.3, dann A3.1.

## Kern-Items Domäne B — Stellenwertverständnis

### B1.1-01 — Zehner/Einer in 58
**If wrong → most likely cause:** Die Ziffern sind nicht an ihre Stellenwert-Bedeutung gebunden (Rollenumkehr „8 Zehner, 5 Einer" oder reine Ziffernlektüre).
**Skill gap:** Zehner und Einer erkennen (B1.1); bei unsicherer Bündelungsvorstellung B1.2, bei Stellenzuordnung B2.1.
**Recommended (priority order):** B1.1, B1.2, B2.1
**Reasoning:** Item prüft B1.1 (Moser Opitz 2013). Die Fehlerdiagnostik der Item-Datei nennt B1.2 (Bündelungsvorstellung) und B2.1 (Stellenzuordnung) als Anschlüsse — übernommen in dieser Reihenfolge. Priorität B1.1.

### B1.2-01 — Bündelung 34
**If wrong → most likely cause:** Der Zehnerwert der Bündel wird nicht berücksichtigt („7" = alle Teile als Einer) oder die Stellenwert-Reihenfolge ist instabil („43").
**Skill gap:** Einzelstücke zu Zehnern bündeln (B1.2); B1.1 (Übertrag Anordnung → Zahl); A2.2 als Vorläufer.
**Recommended (priority order):** B1.2, B1.1, A2.2
**Reasoning:** Item prüft B1.2 (Schipper 2009). Fehler „7" = Bündel als Einzelobjekte gezählt. B1.1 als Übergang zur Zahlschreibweise, A2.2 als strukturierte Mengenerfassung. Priorität B1.2.

### B1.2-02 — Überbündelung 41
**If wrong → most likely cause:** Die Überbündelung fehlt — 11 Einer werden nicht als 1 Zehner + 1 Einer gedeutet („311" oder „31").
**Skill gap:** B1.2 (Überbündelung); B1.3 (Entbündelung als Umkehrung); B2.3 (nicht-standardisierte Form).
**Recommended (priority order):** B1.2, B1.3, B2.3
**Reasoning:** Die >9-Einermenge ist der dokumentierte Fehlerort des Stellenwertverständnisses (Moser Opitz 2013). Fehler „311"/„31" = Überbündelung fehlt. B1.3/B2.3 als Umkehr- und Darstellungsbezug. Priorität B1.2.

### B1.3-01 — Entbündelung 13
**If wrong → most likely cause:** Die Mengenerhaltung beim Öffnen des Bündels ist nicht gesichert („10" statt 13).
**Skill gap:** Einen Zehner in Einer tauschen (B1.3); B1.1; B2.3.
**Recommended (priority order):** B1.3, B1.1, B2.3
**Reasoning:** Tausch 1 Z → 10 E bei Erhalt der Gesamtmenge = B1.3 (Schipper 2009). Fehler „10" = Bestand nicht gewahrt. B1.1 als Zehner/Einer-Konzept; B2.3 als nicht-standardisierte Vorstellung. Priorität B1.3.

### B2.1-01 — Stellenwerttafel 47
**If wrong → most likely cause:** Die Spaltenbedeutung wird ignoriert — die Ziffern werden in Leserichtung eingetragen (7/4) oder die ganze Zahl in die E-Spalte gesetzt.
**Skill gap:** Zahlen in der Stellenwerttafel darstellen (B2.1); B1.1; B2.3.
**Recommended (priority order):** B2.1, B1.1, B2.3
**Reasoning:** Eintragen in die Stellenwerttafel prüft B2.1 (Padberg/Benz 2021). Fehler „7/4" = Stellenwert-Schreibweise nicht verstanden → B1.1 (Stellenzuordnung) und B2.3 (Abgrenzung Standard-/nicht-standardisiert). Priorität B2.1.

### B2.1-02 — Nullstelle 60 aus Tafel
**If wrong → most likely cause:** Die Null als Platzhalter wird nicht verstanden („6", „600").
**Skill gap:** B2.1; B1.1; A1.4 bei unsicherem Zehnerwort.
**Recommended (priority order):** B2.1, B1.1, A1.4
**Reasoning:** Die Nullstelle ist ein dokumentierter Fehlerort (Wartha 2019). Fehler „6"/„600" = Platzhalterwert der Null fehlt. B1.1 als Zehner/Einer-Konzept; A1.4 als Zehnerwort-Zahlbeziehung. Priorität B2.1.

### B2.2-01 — Zahlenstrahl 80
**If wrong → most likely cause:** Die Skalierung wird nicht genutzt — Zehner-Schritte vom Anker 50 aus werden falsch gezählt (70/90) oder die Marke ohne Faktor 10 gelesen (8).
**Skill gap:** Zahlen am Zahlenstrahl verorten (B2.2); B1.1 (Stellenwert als Skalierungsfaktor); A1.5 (Zählen über Zehnergrenzen).
**Recommended (priority order):** B2.2, B1.1, A1.5
**Reasoning:** Item prüft B2.2 (Schipper 2009). Fehler „8" = Faktor 10 verloren → B1.1; Fehler ±1 Marke = Zehnerzählen über die Grenzen → A1.5. Priorität B2.2.

### B2.3-01 — 1 Z + 14 E
**If wrong → most likely cause:** Die Überbündelung wird gedanklich nicht geleistet („114", „15") — die Einheiten werden nicht gedeutet.
**Skill gap:** Zahlen in ungewohnter Schreibweise lesen (B2.3); B1.2 (Überbündelung); B1.3 (Entbündelung).
**Recommended (priority order):** B2.3, B1.2, B1.3
**Reasoning:** Nicht-standardisierte Schreibweise mit >9 Einern (Moser Opitz 2013). Fehler „114"/„15" = Stellenwerte nicht gedeutet. B1.2/B1.3 als Bündelungs-Konzept. Priorität B2.3.

## Kern-Items Domäne C — Rechenstrategien

### C1.1-01 — 3 + 4
**If wrong → most likely cause:** Der automatisierte Abruf fehlt — Zählfehler (+1) oder das Doppel 3+3 wird als Ergebnis genommen; langes Nachzählen.
**Skill gap:** Additionsaufgaben bis 10 (C1.1a); A3.1/A3.3 als Zerlegungs- und Zahlbeziehungs-Stütze.
**Recommended (priority order):** C1.1a, A3.1, A3.3
**Reasoning:** Auflösung: „C1.1" → C1.1a (Additionsrichtung, Gaidoschik 2010). Fehlerdiagnostik verweist auf Automatisation; A3.1 (Teil-Teil-Ganzes) und A3.3 (Nachbarfakten zum Doppel) sind die Stütz-Skills. Priorität C1.1a.

### C1.1-02 — 6 − 6
**If wrong → most likely cause:** Die Beziehung „Zahl minus sich selbst" ist nicht gesichert (6) oder die Operation wird verwechselt (12).
**Skill gap:** Subtraktionsaufgaben bis 10 (C1.1b); A3.1; A1.2a.
**Recommended (priority order):** C1.1b, A3.1, A1.2a
**Reasoning:** Auflösung: „C1.1" → C1.1b (Subtraktionsrichtung); „A1.2" → A1.2a (Rückwärtszählen kleiner Zahlen, Fehler „1" = Reihenfolgesicherheit bis null). Priorität C1.1b.

### C1.1-03 — 2 + 8
**If wrong → most likely cause:** Die Zerlegung der 10 ist nicht gesichert; das Kind zählt über die Zehn hinaus (11).
**Skill gap:** C1.1a; A3.2 (Zerlegungen der 10); A3.1.
**Recommended (priority order):** C1.1a, A3.2, A3.1
**Reasoning:** Auflösung: „C1.1" → C1.1a (Addition). Ergänzung zur Zehn ist Additionsrichtung; Fehler „9"/„11" = Zählfehler an der Zehngrenze, die Zerlegungssicherheit der 10 (A3.2, A3.1) ist die Stütze (Gaidoschik 2010). Priorität C1.1a.

### C1.1-04 — 10 − 4
**If wrong → most likely cause:** Die Subtraktion aus der 10 ist nicht automatisiert; das Kind nennt den Subtrahenden (4) statt der Differenz.
**Skill gap:** C1.1b; A3.2; A3.1.
**Recommended (priority order):** C1.1b, A3.2, A3.1
**Reasoning:** Auflösung: „C1.1" → C1.1b (Subtraktion). Die Ergänzungskompetenz zur Zehn (A3.2/A3.1) ist die Basis der Subtraktion aus der 10. Priorität C1.1b.

### C1.2-01 — Doppel 4 + 4
**If wrong → most likely cause:** Die Verdopplung ist noch nicht als Fakt gesichert (Zählfehler ±1 oder Nennung des Summanden).
**Skill gap:** Verdopplungsaufgaben (C1.2); C1.1a; A3.3.
**Recommended (priority order):** C1.2, C1.1a, A3.3
**Reasoning:** Doppel 4+4 = C1.2 (Padberg/Benz 2021). Auflösung: „C1.1" → C1.1a (Addition, Doppel wird über Summanden gelöst). A3.3 als Verdopplungsbeziehung. Priorität C1.2.

### C1.2-02 — Doppel 5 + 5
**If wrong → most likely cause:** Das Grenz-Doppel 5+5 ist nicht automatisiert; die Zehnervorstellung wird nicht für den Abruf genutzt.
**Skill gap:** C1.2; A3.2 (10 als 5+5); C1.1a.
**Recommended (priority order):** C1.2, A3.2, C1.1a
**Reasoning:** Doppel mit Ergebnis an der Zehnergrenze (Padberg/Benz 2021). Auflösung: „C1.1" → C1.1a. A3.2 als Zehnerzerlegung. Priorität C1.2.

### C1.3-01 — Hälfte von 6
**If wrong → most likely cause:** Die Verdopplungs-/Halbierungsbeziehung ist verwechselt (12) oder die Relation wird nicht erfasst (6).
**Skill gap:** Halbierungsaufgaben (C1.3); C1.2 als Umkehrung; A3.3.
**Recommended (priority order):** C1.3, C1.2, A3.3
**Reasoning:** Halbierung als Umkehrung der Verdopplung (Gaidoschik 2010). Fehler „12" = verdoppelt statt halbiert → C1.2-Lücke. A3.3 als Zahlbeziehungs-Stütze. Priorität C1.3.

### C1.3-02 — Hälfte von 10
**If wrong → most likely cause:** Die Vorstellung von 10 als 5 und 5 ist nicht gesichert; die Halbierung des Zehners ist nicht automatisiert.
**Skill gap:** C1.3; C1.2; A3.2 (Zerlegungen der 10).
**Recommended (priority order):** C1.3, C1.2, A3.2
**Reasoning:** Halbierung des Zehners (KMK 2022). A3.2 als Zerlegungs-Stütze. Priorität C1.3.

### C2.1-01 — 7 + 6
**If wrong → most likely cause:** Die Zerlegung des zweiten Summanden für den Teilschritt über die Zehn ist nicht verfügbar; das Kind zählt weiter.
**Skill gap:** Addieren mit Zehnerübergang über Zerlegen (C2.1); A3.1 (Zerlegungsbasis); C1.1a (Fakten für den Rest).
**Recommended (priority order):** C2.1, A3.1, C1.1a
**Reasoning:** Auflösung: „C1.1" → C1.1a. Fehlerdiagnostik: „12 = Zählfehler", „14 = Doppel statt Nachbarfakt". C2.1 ist der Kern (Wartha 2019); A3.1 liefert die Zerlegung, C1.1a die Zahlfakten. Priorität C2.1.

### C2.1-02 — 8 + 5
**If wrong → most likely cause:** Die Restzerlegung 5 in 2 und 3 ist unsicher („12") oder das Zählen geht über das Ziel hinaus.
**Skill gap:** C2.1; A3.1; A3.2.
**Recommended (priority order):** C2.1, A3.1, A3.2
**Reasoning:** Zerlegungsfehler (5 in 2+2) zeigt die A3.1/A3.2-Lücke unter dem Teilschrittverfahren. Priorität C2.1.

### C2.1-03 — 9 + 7
**If wrong → most likely cause:** Der maximale Zehnerübergang wird nicht bewältigt — das Kind stoppt nach der Zehnergänzung (10) oder verliert den Rest.
**Skill gap:** C2.1; A3.1; A3.2.
**Recommended (priority order):** C2.1, A3.1, A3.2
**Reasoning:** Fehler „10" = Teilschritt begonnen, aber nicht zu Ende geführt (Gaidoschik 2010). Zerlegungssicherheit (A3.1/A3.2) als Fundament. Priorität C2.1.

### C2.2-01 — 8 + 7 über Doppel
**If wrong → most likely cause:** Die Stützaufgabe 7+7 wird gelöst, der Nachbarfakt aber nicht abgeleitet (14).
**Skill gap:** Verdopplungen als Stützaufgaben nutzen (C2.2); C1.2 (Doppel); A3.3 (Nachbarzahlen).
**Recommended (priority order):** C2.2, C1.2, A3.3
**Reasoning:** Fehler „14" = Doppel-Anker ohne Nachbar. C1.2 und A3.3 sind die Stütz-Skills (Padberg/Benz 2021). Priorität C2.2.

### C2.2-02 — 9 + 8 über Doppel
**If wrong → most likely cause:** Das Stützdoppel 8+8 ist unsicher oder wird mit 9+9 verwechselt (16, 18).
**Skill gap:** C2.2; C1.2; C2.1 (Zerlegung als Alternativweg).
**Recommended (priority order):** C2.2, C1.2, C2.1
**Reasoning:** Fehler „16" = Anker ohne Nachbar, „18" = falsches Doppel. C1.2 als Doppelbasis, C2.1 als Zerlegungs-Alternative. Priorität C2.2.

### C2.3-01 — 13 − 8
**If wrong → most likely cause:** Das Ergänzen fehlt — das Kind zählt rückwärts (Fehler ±1) oder verwechselt die Operation (21).
**Skill gap:** Subtrahieren durch Ergänzen (C2.3); C2.1 (Ergänzungsweg); C1.1b (Fakten).
**Recommended (priority order):** C2.3, C2.1, C1.1b
**Reasoning:** Ergänzen statt Abziehen (Selter/Spiegel 1997). Auflösung: „C1.1" → C1.1b. Fehler ±1 = rückwärts zählendes Rechnen. C2.1 als Ergänzungsweg, C1.1b als Faktenbasis. Priorität C2.3.

### C2.3-02 — 12 − 9
**If wrong → most likely cause:** Das Ergänzen fehlt — das Kind zählt rückwärts oder verwechselt die Operation (21).
**Skill gap:** C2.3; C2.1; C1.1b.
**Recommended (priority order):** C2.3, C2.1, C1.1b
**Reasoning:** Analog C2.3-01 (Selter/Spiegel 1997). Auflösung: „C1.1" → C1.1b. Priorität C2.3.

### C2.3-03 — 15 − 6
**If wrong → most likely cause:** Das Ergänzen über zwei Schritte wird nicht zu Ende geführt (11: stoppt an der Zehn); rückwärts zählendes Rechnen.
**Skill gap:** C2.3; C2.1; A3.2 (Zerlegung 6 in 4+2).
**Recommended (priority order):** C2.3, C2.1, A3.2
**Reasoning:** Fehler „11" = Ergänzen bis 10 ohne Rest (Selter/Spiegel 1997). A3.2 als Zerlegungs-Stütze. Priorität C2.3.

### C3.1-01 — Stellenweises Addieren 34 + 28
**If wrong → most likely cause:** Der Übertrag der Einersumme wird nicht überbündelt („54", „612") oder die Einersumme fehlt („50").
**Skill gap:** Im Hunderterraum stellenweise addieren (C3.1a); C2.1 (Teilschritt/Übertrag); B1.1 (Stellenwerttrennung).
**Recommended (priority order):** C3.1a, C2.1, B1.1
**Reasoning:** Auflösung: „C3.1" → C3.1a (Addition). Fehler „612" = Übertrag nicht überbündelt (B1.1-Stellenwert); „Teilschritt unsicher" → C2.1 (Wartha 2019). Priorität C3.1a.

### C3.1-02 — Stellenweises Subtrahieren 57 − 19
**If wrong → most likely cause:** Das Borgen wird nicht erkannt — 7 − 9 falsch herum („48") oder der Subtrahend falsch zerlegt („42").
**Skill gap:** Im Hunderterraum stellenweise subtrahieren (C3.1b); C2.1; B1.3 (Entbündelung eines Zehners).
**Recommended (priority order):** C3.1b, C2.1, B1.3
**Reasoning:** Auflösung: „C3.1" → C3.1b (Subtraktion). Borgen = Auflösen eines Zehners → B1.3 (Wartha 2019). Priorität C3.1b.

### C3.1-03 — Stellenweises Subtrahieren 84 − 26
**If wrong → most likely cause:** Die Borge-Entscheidung bei ungeradem Einer wird nicht getroffen („68", „62").
**Skill gap:** C3.1b; B1.3; C3.4b (Borgen als Zerlegung).
**Recommended (priority order):** C3.1b, B1.3, C3.4b
**Reasoning:** Auflösungen: „C3.1" → C3.1b, „C3.4" → C3.4b (Zerlegen bei Subtraktion). Fehler „62" = 4 − 6 falsch herum. Priorität C3.1b.

### C3.2-01 — Schrittweises Rechnen 26 + 35
**If wrong → most likely cause:** Das Auffüllen zum Zehner gelingt nicht; die Teilschritte werden nicht zusammengesetzt („56", „30").
**Skill gap:** Im Hunderterraum in Schritten rechnen (C3.2); C3.1a (Zusammensetzen); C2.3 (Ergänzen).
**Recommended (priority order):** C3.2, C3.1a, C2.3
**Reasoning:** Auflösung: „C3.1" → C3.1a. Auffüllen (26 + 4 = 30) ist der Kern von C3.2 (Selter/Spiegel 1997). Fehler „56" = Zehner addiert, Einer übersprungen. Priorität C3.2.

### C3.2-02 — Schrittweises Rechnen 63 − 28
**If wrong → most likely cause:** Die Zehnersubtraktion oder der Einerübergang im Zweitschritt ist unsicher; der Subtrahend wird verlesen.
**Skill gap:** C3.2; C2.3; C3.1b (Borgen im Zweitschritt).
**Recommended (priority order):** C3.2, C2.3, C3.1b
**Reasoning:** Auflösung: „C3.1" → C3.1b. Schrittweises Subtrahieren (Schipper 2009). Priorität C3.2.

### C3.2-03 — Schrittweises Rechnen 67 + 28
**If wrong → most likely cause:** Das Auffüllen über die Zehnergrenze mit großer Restaddition wird nicht geführt („97", „93").
**Skill gap:** C3.2; C3.1a (Zusammensetzen); C2.1 (Übertrag beim Teilschritt).
**Recommended (priority order):** C3.2, C3.1a, C2.1
**Reasoning:** Auflösung: „C3.1" → C3.1a. Fehler „97" = 67 + 30 ohne Korrektur. Priorität C3.2.

### C3.3-01 — Hilfsaufgabe 21 + 50
**If wrong → most likely cause:** Die Nachbaraufgaben-Beziehung wird nicht genutzt — die Hilfsaufgabe wird ohne +1 übernommen (70).
**Skill gap:** Mit Hilfsaufgaben rechnen (C3.3); C3.1a (Zehneraddition); A3.3 (Nachbarzahlen).
**Recommended (priority order):** C3.3, C3.1a, A3.3
**Reasoning:** Auflösung: „C3.1" → C3.1a. Nutzen einer gegebenen Stützaufgabe = C3.3 (Padberg/Benz 2021). Priorität C3.3.

### C3.3-02 — Hilfsaufgaben 45 + 38
**If wrong → most likely cause:** Die Korrektur aus der Stützaufgabe wird nicht gebildet (85, 75) oder falsch (77).
**Skill gap:** C3.3; C3.1a; A3.3.
**Recommended (priority order):** C3.3, C3.1a, A3.3
**Reasoning:** Auflösung: „C3.1" → C3.1a. Zwei Stützaufgaben + Korrektur = Kern von C3.3 (Padberg/Benz 2021). Priorität C3.3.

### C3.4-01 — Zerlegen über Doppel 37 + 38
**If wrong → most likely cause:** Die Korrektur um 1 wird vergessen (76, 74) oder die Korrekturrichtung verwechselt (77).
**Skill gap:** Im Hunderterraum zerlegen und addieren (C3.4a); C3.3 (Nachbaraufgaben); C1.2 (Verdopplungen als Stützpunkt).
**Recommended (priority order):** C3.4a, C3.3, C1.2
**Reasoning:** Auflösung: „C3.4" → C3.4a (Addition). Zerlegung über die Nachbar-Verdopplung (Wartha 2019). Priorität C3.4a.

### C3.4-02 — Zerlegen 73 − 38
**If wrong → most likely cause:** Die günstige Zerlegung 38 = 40 − 2 wird nicht erkannt; die Korrektur +2 wird vergessen (33).
**Skill gap:** Im Hunderterraum zerlegen und subtrahieren (C3.4b); C3.2 (schrittweises Rechnen); C2.3 (Ergänzen).
**Recommended (priority order):** C3.4b, C3.2, C2.3
**Reasoning:** Auflösung: „C3.4" → C3.4b (Subtraktion). Fehler „33" = 73 − 40 ohne +2. Priorität C3.4b.

### C4.1-01 — Strategiewahl 34 + 29
**If wrong → most likely cause:** Es fehlt die zahlangepasste Strategiewahl — über den Zehner gerechnet ohne Korrektur (64) oder zählendes Rechnen (Option d).
**Skill gap:** Rechenstrategien bewusst auswählen (C4.1); C3.1a (stellenweise); C2.1 (Teilschritt).
**Recommended (priority order):** C4.1, C3.1a, C2.1
**Reasoning:** Auflösung: „C3.1" → C3.1a. Strategieabfrage + Reaktionszeit prüfen C4.1 (Selter/Spiegel 1997). Fehler „64" = 34 + 30 ohne −1. Priorität C4.1.

### C4.1-02 — Strategiewahl 52 − 19
**If wrong → most likely cause:** Der effiziente Weg 52 − 20 + 1 wird nicht erkannt (32); zählendes Rechnen.
**Skill gap:** C4.1; C3.2 (schrittweises Rechnen); C2.3 (Ergänzen).
**Recommended (priority order):** C4.1, C3.2, C2.3
**Reasoning:** Fehler „32" = 52 − 20 ohne +1 (Selter/Spiegel 1997). Priorität C4.1.

### C4.2-01 — Umkehraufgaben 72 − 29 / 72 − 43
**If wrong → most likely cause:** Die Umkehrbeziehung wird nur einseitig genutzt oder Minuend und Subtrahend werden addiert (93).
**Skill gap:** Umkehraufgaben zur Kontrolle nutzen (C4.2); C3.1b (Subtraktion); C1.3 (Umkehrung der Addition).
**Recommended (priority order):** C4.2, C3.1b, C1.3
**Reasoning:** Auflösung: „C3.1" → C3.1b (Subtraktion). Ableiten zweier Minusaufgaben aus einer Summe (Padberg/Benz 2021). Priorität C4.2.

### C4.2-02 — Umkehraufgabe 83 − 47
**If wrong → most likely cause:** Die Umkehraufgabe wird nicht selbst gebildet (136) oder die Ergänzung verfehlt (46).
**Skill gap:** C4.2; C3.4b (Ergänzen als Zerlegung); C2.3 (Ergänzen statt Abziehen).
**Recommended (priority order):** C4.2, C3.4b, C2.3
**Reasoning:** Auflösung: „C3.4" → C3.4b. Selbstständiges Bilden der Umkehraufgabe ist die höchste Stufe von C4.2 (Padberg/Benz 2021). Priorität C4.2.

## Kern-Items Domäne D — Sachsituationen

### D1.1-01 — Mathematisierung (Schwimmbad)
**If wrong → most likely cause:** Die Operationswahl scheitert (8 − 5) oder die Übersetzung in eine Rechnung fehlt (nur „13").
**Skill gap:** Sachsituationen mathematisch erfassen (D1.1); C2.1 (Rechnung 8 + 5 über den Zehnerübergang); C1.1a (Grundfakten).
**Recommended (priority order):** D1.1, C2.1, C1.1a
**Reasoning:** Auflösung: „C1.1" → C1.1a. Mathematisierung = D1.1 (KMK 2022). Fehler „8 − 5" = Operationswahl; „8 + 5 = 12" = C2.1-Zeiger. Priorität D1.1.

### D1.2-01 — Operationserkennung (Schulgarten)
**If wrong → most likely cause:** „Mehr" wird nicht als Zunahme gedeutet (9 − 4); die Operation wird nicht aus der Situation abgeleitet.
**Skill gap:** Die passende Rechenoperation erkennen (D1.2); C2.1 (Rechnung 9 + 4); C1.1a (Grundfakten).
**Recommended (priority order):** D1.2, C2.1, C1.1a
**Reasoning:** Auflösung: „C1.1" → C1.1a. Operationserkennung bei sprachlich versteckter Vergrößerung = D1.2 (Padberg/Benz 2021). Priorität D1.2.

---

## Deep-Dive-Blöcke — Deep-Dive A (Zahlbegriff)

### DDA-01 — Zehnerschritte vorwärts
**If wrong → most likely cause:** Die Zehnerstruktur der Zahlenreihe wird nicht genutzt; die Schrittweite geht beim Wechsel der Einerstelle verloren.
**Skill gap:** Zählen in Schritten (A1.3); A1.1b (Vorwärtszählen im ZR100 als Basis).
**Recommended (priority order):** A1.3, A1.1b
**Reasoning:** Auflösung: „A1.1" → A1.1b (ZR100). Deep-Dive-A-Item; Einstiegskriterium: A1 im Kerntest auffällig (Blueprint, Deep-Dive-Blöcke). Priorität A1.3.

### DDA-02 — Zählen über 90
**If wrong → most likely cause:** Das Kind bricht am Zehnerübergang ab (bei 89 stehen bleiben) oder die Folge gerät nach dem Übergang aus dem Tritt.
**Skill gap:** Zählen über den Zehnerübergang (A1.5); A1.1b (Zahlwortreihe ZR100).
**Recommended (priority order):** A1.5, A1.1b
**Reasoning:** Auflösung: „A1.1" → A1.1b. Übergang über 90 im ZR100 = A1.5 (Gaidoschik 2010; Wartha 2019). Priorität A1.5.

### DDA-03 — Fünferschritte rückwärts
**If wrong → most likely cause:** Schrittweite und Rückwärtsrichtung sind kombiniert nicht verfügbar; die Fünferreihe wird beim Einerübergang verlassen.
**Skill gap:** A1.3; A1.2b (Rückwärtszählen im ZR100 als Basis).
**Recommended (priority order):** A1.3, A1.2b
**Reasoning:** Auflösung: „A1.2" → A1.2b (ZR100). Schwerste Zählkombination des Blocks (Padberg/Benz 2021). Priorität A1.3.

### DDA-04 — Zehnerfeld 5+2
**If wrong → most likely cause:** Der Fünferanker dominiert (5) — die Restzellen der zweiten Zeile werden nicht integriert.
**Skill gap:** Mengen über Strukturen erkennen (A2.2); A2.1.
**Recommended (priority order):** A2.2, A2.1
**Reasoning:** Deep-Dive-A-Item zu A2.2; Einstiegskriterium: A2 auffällig (Blueprint). Belegung 5+2 übersteigt die reine Fünferanker-Erfassung. Priorität A2.2.

### DDA-05 — Rekenrek 5+4
**If wrong → most likely cause:** Die Teilgruppen der zwei Stäbe werden nicht zusammengeführt (5, 4) oder links/rechts verwechselt (10).
**Skill gap:** A2.2; A2.1.
**Recommended (priority order):** A2.2, A2.1
**Reasoning:** Menge 9 über zwei Stäbe erfordert das Zusammenführen zweier Teilgruppen (Padberg/Benz 2021). Priorität A2.2.

### DDA-06 — Mengenvergleich mit Differenz
**If wrong → most likely cause:** Die Vergleichsentscheidung oder die Differenzbestimmung ist nicht gesichert.
**Skill gap:** Mengen vergleichen (A2.3); A2.2 (strukturierte Erfassung der Einzelmengen).
**Recommended (priority order):** A2.3, A2.2
**Reasoning:** Differenzbestimmung übersteigt die reine mehr/weniger-Entscheidung (Krajewski 2003/2008). Priorität A2.3.

### DDA-07 — Zerlegungen der 9
**If wrong → most likely cause:** Es ist nur eine Standardzerlegung verfügbar; die Flexibilität fehlt.
**Skill gap:** A3.2; A3.1.
**Recommended (priority order):** A3.2, A3.1
**Reasoning:** Ungerade Zahl 9 ohne Verdopplungs-Anker (Karner). Einstiegskriterium: A3 auffällig (Blueprint). Priorität A3.2.

### DDA-08 — Ergänzen zum Ganzen 7
**If wrong → most likely cause:** Der ergänzende Teil wird nicht erschlossen (3) oder der Zehnerbezug dominiert über das Ganze (10).
**Skill gap:** A3.1; A3.2.
**Recommended (priority order):** A3.1, A3.2
**Reasoning:** Synthetische Ergänzungsrichtung der Teil-Ganzes-Beziehung (Lenz & Wittmann 2023). Fehler „10" = Zehnerergänzen dominiert. Priorität A3.1.

### DDA-09 — Nachbaraufgabe 5+6
**If wrong → most likely cause:** Die Zahlbeziehung wird nicht übertragen — die Stützaufgabe wird statt der Nachbaraufgabe genannt (10).
**Skill gap:** A3.3; C1.2 (Doppel als Stützpunkt).
**Recommended (priority order):** A3.3, C1.2
**Reasoning:** Deep-Dive-A-Vertiefung von A3.3; Begründungsanforderung erzwingt die bewusste Zahlbeziehung (Gaidoschik 2010). Priorität A3.3.

### DDA-10 — Doppeltes und Hälfte
**If wrong → most likely cause:** Die Verdopplungs-/Halbierungsbeziehung im ZR20 ist nicht verfügbar (18, 4).
**Skill gap:** A3.3; C1.2; C1.3.
**Recommended (priority order):** A3.3, C1.2, C1.3
**Reasoning:** Doppel 6 → 12 liegt im ZR20, jenseits der ZR10-Verdopplungen des Kerntests (Gaidoschik 2010). Priorität A3.3.

## Deep-Dive-Block B (Stellenwert)

### DDB-01 — Bündelung 56
**If wrong → most likely cause:** Der Zehnerwert der Bündel wird nicht berücksichtigt (11) oder die Teilgruppen werden nicht zusammengeführt.
**Skill gap:** B1.2; B1.1; A2.2 (Vorläufer).
**Recommended (priority order):** B1.2, B1.1, A2.2
**Reasoning:** Deep-Dive-B-Item; Einstiegskriterium: B1 nicht bestanden (Blueprint). Höhere Bündel-/Einerzahl als im Kerntest. Priorität B1.2.

### DDB-02 — Entbündelung 25
**If wrong → most likely cause:** Der Tausch wird nicht als Wechsel verstanden (2 Z + 15 E) oder die neue Einerzahl wird verwechselt.
**Skill gap:** B1.3; B2.3 (nicht-standardisierte Bündelung).
**Recommended (priority order):** B1.3, B2.3
**Reasoning:** Umformung 25 → 1 Z + 15 E verbindet B1.3 mit der B2.3-Darstellung (Schipper 2009). Priorität B1.3.

### DDB-03 — Nullstelle 60
**If wrong → most likely cause:** Die Null wird nicht als Platzhalter gedeutet (6 Z + 6 E) oder die Zahl als reine Einerzahl gelesen.
**Skill gap:** B1.1; B2.1.
**Recommended (priority order):** B1.1, B2.1
**Reasoning:** Grenzfall des Stellenwertverständnisses (Wartha 2019; Moser Opitz 2013). Priorität B1.1.

### DDB-04 — Stellenwerttafel lesen 58
**If wrong → most likely cause:** Die Spalten werden in falscher Reihenfolge gelesen (85) oder die Werte addiert (13).
**Skill gap:** B2.1; B1.1.
**Recommended (priority order):** B2.1, B1.1
**Reasoning:** Umkehraufgabe zum Eintragen (Tafel → Zahl) prüft B2.1 (Padberg/Benz 2021). Priorität B2.1.

### DDB-05 — Zahlenstrahl 75
**If wrong → most likely cause:** Die Struktur des Strahls wird nicht genutzt (25, 50, 100); die Orientierung im ZR100 fehlt.
**Skill gap:** B2.2; B2.1 (Skalierung/Stellenwert).
**Recommended (priority order):** B2.2, B2.1
**Reasoning:** Viertel-/Dreiviertelstrahl-Verortung (Schipper 2009). Priorität B2.2.

### DDB-06 — Zahlendiktat 70
**If wrong → most likely cause:** Die Nullstelle wird nicht geschrieben (7) oder das Zahlwort nicht in eine Ziffernfolge übertragen (700).
**Skill gap:** B2.1; B1.1.
**Recommended (priority order):** B2.1, B1.1
**Reasoning:** Einzige auditive Zahldarstellung des gesamten Tests (Blueprint, Deep-Dive-Blöcke). Fehler „7" = Stellenwert-Halter fehlt. Priorität B2.1.

## Deep-Dive-Block C (Rechenstrategien)

### DDC-01 — 9 + 5
**If wrong → most likely cause:** Die Zerlegung 9 + 1 + 4 wird nicht geführt (10: nur bis zur Zehn) oder ein Nachbarfehler tritt auf.
**Skill gap:** C2.1; A3.1; A3.2.
**Recommended (priority order):** C2.1, A3.1, A3.2
**Reasoning:** Deep-Dive-C; Einstiegskriterium: C2 grenzwertig oder zählendes Rechnen vermutet (Blueprint). Priorität C2.1.

### DDC-02 — 14 − 8
**If wrong → most likely cause:** Das Ergänzen fehlt — rückwärts zählendes Rechnen oder Operationsverwechslung (20).
**Skill gap:** C2.3; C1.1b (Subtraktionsfakten).
**Recommended (priority order):** C2.3, C1.1b
**Reasoning:** Auflösung: „C1.1" → C1.1b. Ergänzen 8 + 6 = C2.3 (Selter/Spiegel 1997). Priorität C2.3.

### DDC-03 — 7 + 8 über Doppel
**If wrong → most likely cause:** Der Stützpunkt 7+7 wird nicht vollständig genutzt (14) oder der Nachbar doppelt verrechnet (16).
**Skill gap:** C2.2; A3.3; C1.2.
**Recommended (priority order):** C2.2, A3.3, C1.2
**Reasoning:** Deep-Dive-C-Verzahnung von C2.2 mit A3.3/C1.2 (Selter/Spiegel 1997). Priorität C2.2.

### DDC-04 — 16 − 9
**If wrong → most likely cause:** Das Ergänzen 9 + 1 + 6 wird nicht geführt (6, 8) oder die Operation verwechselt (17).
**Skill gap:** C2.3; C1.1b.
**Recommended (priority order):** C2.3, C1.1b
**Reasoning:** Auflösung: „C1.1" → C1.1b. Hoher Subtrahend belohnt das Ergänzen (Selter/Spiegel 1997). Priorität C2.3.

### DDC-05 — Stellenweise 48 − 26
**If wrong → most likely cause:** Das getrennte Bearbeiten von Zehnern und Einern ist nicht verfügbar (30, 12).
**Skill gap:** C3.1b; B1.1.
**Recommended (priority order):** C3.1b, B1.1
**Reasoning:** Auflösung: „C3.1" → C3.1b (Subtraktion). Fehler „12" = Einerdifferenz falsch herum. Priorität C3.1b.

### DDC-06 — Schrittweise 37 + 8
**If wrong → most likely cause:** Das Auffüllen über die Zehnergrenze wird nicht geführt (44, 46).
**Skill gap:** C3.2; A1.5 (Zählen über die Zehnergrenze als Vorstufe).
**Recommended (priority order):** C3.2, A1.5
**Reasoning:** Auffüllen 37 + 3 = 40 = C3.2 (Selter/Spiegel 1997); A1.5 als Zahlreihen-Basis. Priorität C3.2.

### DDC-07 — Stellenweise 38 + 27
**If wrong → most likely cause:** Der Übertrag wird nicht geführt (55: 8 + 7 ohne Übertrag auf die Zehner).
**Skill gap:** C3.1a; C2.1.
**Recommended (priority order):** C3.1a, C2.1
**Reasoning:** Auflösung: „C3.1" → C3.1a (Addition). Fehler „55" = Zehnerübertrag vergessen (Wartha 2019). Priorität C3.1a.

### DDC-08 — Schrittweise 62 − 7
**If wrong → most likely cause:** Das schrittweise Subtrahieren über die Zehnergrenze wird nicht geführt (57: stoppt an der 60).
**Skill gap:** C3.2; A1.5.
**Recommended (priority order):** C3.2, A1.5
**Reasoning:** 62 − 2 = 60, dann − 5 = C3.2 (Selter/Spiegel 1997). Priorität C3.2.

### DDC-09 — Hilfsaufgabe 36 + 39
**If wrong → most likely cause:** Die Hilfsaufgabe 36 + 40 wird gelöst, die Korrektur −1 aber vergessen (76).
**Skill gap:** C3.3; C3.1a; C2.2.
**Recommended (priority order):** C3.3, C3.1a, C2.2
**Reasoning:** Auflösung: „C3.1" → C3.1a. Stützen auf eine Nachbaraufgabe = C3.3 (Padberg/Benz 2021). Priorität C3.3.

### DDC-10 — Zerlegen 54 − 28
**If wrong → most likely cause:** Die Entbündelung wird nicht ins Rechnen übertragen (36: Zehnerstand nicht reduziert).
**Skill gap:** C3.4b; B1.3 (Entbündelung); C2.1 (Teilschritt).
**Recommended (priority order):** C3.4b, B1.3, C2.1
**Reasoning:** Auflösung: „C3.4" → C3.4b (Subtraktion). Kombination von Stellenwertwissen und Rechnen (Wartha 2019). Priorität C3.4b.

## Deep-Dive-Block D (Sachsituationen)

### DDD-01 — Mathematisierung (Schulfest)
**If wrong → most likely cause:** Die Verminderungssituation wird nicht als Subtraktion gelesen (14 + 6).
**Skill gap:** D1.1; D1.2 (Operationswahl).
**Recommended (priority order):** D1.1, D1.2
**Reasoning:** Item trennt Mathematisierung von Rechnung (Blueprint, Deep-Dive-D). Fehler „14 + 6" = Operationswahl aus der Situation fehlt → D1.2 als Anschluss. Priorität D1.1.

### DDD-02 — Mathematisierung (Garderobe)
**If wrong → most likely cause:** Die Verminderungssituation („abgeholt") wird nicht als Subtraktion gelesen (8 + 3).
**Skill gap:** D1.1; D1.2.
**Recommended (priority order):** D1.1, D1.2
**Reasoning:** Analog DDD-01 (KMK 2022). Priorität D1.1.

### DDD-03 — Mathematisierung (Fahrradständer)
**If wrong → most likely cause:** Die Hinzufügung wird nicht als Addition gelesen (9 − 4) oder der Zehnerübergang beim Rechnen scheitert.
**Skill gap:** D1.1; C2.1 (Rechnung 9 + 4 über den Zehnerübergang).
**Recommended (priority order):** D1.1, C2.1
**Reasoning:** Rechnung 9 + 4 überschreitet die Zehnergrenze (Blueprint, Deep-Dive-D). Priorität D1.1.

### DDD-04 — Operationserkennung (Pausenhof)
**If wrong → most likely cause:** Die Zusammenführung zweier Teilgruppen wird nicht erkannt (1: subtrahiert) oder nur eine Teilgruppe genannt.
**Skill gap:** D1.2; D1.1.
**Recommended (priority order):** D1.2, D1.1
**Reasoning:** Operationserkennung auf der zweiten Stufe der D1-Trennung (Padberg/Benz 2021). Priorität D1.2.

### DDD-05 — Operationserkennung (Bücherei)
**If wrong → most likely cause:** Die Wegnahme wird als Hinzufügung gelesen (16) oder die Frageperspektive nicht beachtet (4).
**Skill gap:** D1.2; C1.1b (Subtraktionsfakt 12 − 4).
**Recommended (priority order):** D1.2, C1.1b
**Reasoning:** Auflösung: „C1.1" → C1.1b. Fehler „4" = Frageperspektive. Priorität D1.2.

### DDD-06 — Operationserkennung (Springseile)
**If wrong → most likely cause:** Operationserkennung und Zehnerübergang koppeln sich (15, 17).
**Skill gap:** D1.2; C2.1 (Rechnung 9 + 7).
**Recommended (priority order):** D1.2, C2.1
**Reasoning:** Kopplung von Sachkontext und Zehnerübergang (Blueprint, Deep-Dive-D schwer). Priorität D1.2.
