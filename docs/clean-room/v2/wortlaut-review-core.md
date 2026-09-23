# Wortlaut-Review: Kern-Diagnostik (Stand 2026-09-11)

Ein File, zwei Spalten: **welcher Skill wird geprüft** und **welcher Wortlaut**.
Reihenfolge = exakt die Reihenfolge, in der ein Kind die Items heute im Client bekommt
(`diagnostic_service.dart`: `coreQuestions` minus die drei bereits ersetzten Items,
dann `v2Questions`, dann `v2FixesQuestions`).

**So benutzen:** Wo ich nichts zu beanstanden habe, steht der aktuelle Wortlaut einfach da.
Wo ich ein Problem sehe, steht mein Vorschlag da, mit einer kurzen Begründung in Klammern.
**Überschreib die Vorschlagsspalte direkt mit deiner eigenen Fassung** — das ist die finale
Fassung, nicht meine.

Nicht enthalten: die 32 Deep-Dive-Items (optionaler Lehrer-Zusatzblock) — eigener Durchgang,
falls gewünscht.

---

## Genereller Befund vorab

Drei Dinge ziehen sich durch mehrere Items, hier einmal benannt statt 15× wiederholt:

1. **Papier-Relikte.** Phrasen wie „Schreib sie auf", „trage das Ergebnis ein", „Kreuze an" stammen
   aus der Kartei-Logik (Papier, Stift). Im digitalen Client gibt es ein Eingabefeld — das Feld sagt
   dem Kind bereits, dass es eine Antwort eintippt. Wo das die einzige Auffälligkeit ist, hab ich die
   Phrase kommentarlos gestrichen; ist unten nicht extra vermerkt.
2. **Items 41–54 (im alten `ListNumber`-Schema: 44–58) waren durchgehend defekt — auch die, die
   ich zuerst als „Referenzformat" bezeichnet hatte.** Zwei getrennte Probleme, korrigiert
   2026-09-11 nach direkter Rückfrage:
   - **Verfahrensdiktat** (41–50): schreibt das Rechenverfahren Satz für Satz vor. Behoben durch
     nackte Rechnung, ein Satz, keine Schritte.
   - **Erfundene Selbstauskunft** (51–54): „Wie hast du gerechnet? (a)/(b)/(c)/(d)" — dafür gibt es
     **kein Eingabefeld**. `AnswerFormat` kennt nur `single`/`multiple`/`sort`; die App erfasst
     ausschließlich eine Zahlenantwort plus `responseTimeSeconds`. ADR 0009 (von dir 2026-09-04
     freigegeben) legt genau das fest: Zeit ist das einzige Strategiesignal, lehrkraftseitig, nie
     eine Kindfrage. Diese Items hatten also nicht nur zu viel Text — der Text versprach eine
     Interaktion, die es nicht gibt. Behoben durch dieselbe nackte Rechnung wie 41–50, ohne
     Auswahlfrage.
   - **Zusätzlich, erst jetzt aufgefallen:** Item 41 (34 + 28, mit Zehnerübertrag) folgte direkt auf
     Item 40 (eine bloße ZR20-Grundaufgabe) — ein Sprung von der leichtesten zur schwersten Form
     desselben Strangs ohne Rampe, genau das, was **I12** in `14-itemregeln.md` (von dir am
     2026-09-08 freigegeben) verbietet: „Ein schweres Item mit trivialem Nachbarn ist für sich ein
     Defekt." Die Vorschläge unten ordnen jeden Strang jetzt leicht → schwer, wo eine Rampe
     überhaupt möglich ist.
3. **Drei Items stehen an der falschen Stelle, inhaltlich aber richtig.** #65 (symbolischer
   Mengenvergleich) gehört direkt neben #11 (der ikonische Vergleich), nicht 54 Items später.
   #66/#67 (Zahlenstrahl-Rampen ZR10/ZR20) gehören **vor** #23 (Zahlenstrahl ZR100), das sonst ohne
   Vorstufe direkt auf 0–100 springt. Reihenfolge-Fix in der CSV, kein Wortlaut-Fix — trotzdem hier
   vermerkt, damit er nicht untergeht.

---

## Tabelle

| # | Skill (Konstrukt, ZR) | Wortlaut (Claude-Vorschlag) |
|---|---|---|
| 1 | A1.1a, Vorwärtszählen (ZR20) | Zähle von der Zahl 12 weiter, bis zur Zahl 20. |
| 2 | A1.1b, Vorwärtszählen (ZR100) | Zähle von der Zahl 58 weiter, bis zur Zahl 63. |
| 3 | A1.2a, Rückwärtszählen (ZR20/100) | Zähle von der Zahl 21 rückwärts, bis zur Zahl 16. |
| 4 | A1.2b, Rückwärtszählen (ZR100) | Zähle von der Zahl 52 rückwärts, bis zur Zahl 47. |
| 5 | A1.3, Schrittzählen 2er (ZR100) | Zähle in Zweierschritten von der Zahl 26 weiter. Nenne die nächsten vier Zahlen. |
| 6 | A1.3, Schrittzählen 5er rückwärts (ZR100) | Zähle in Fünferschritten rückwärts von der Zahl 45. Nenne die nächsten fünf Zahlen. |
| 7 | A1.4 + A1.1b, Vorgänger/Nachfolger (ZR100) | Welche Zahl kommt direkt vor der 37? Welche Zahl kommt direkt nach der 37? *(inhaltlich ok, sofern die UI wirklich zwei beschriftete Felder zeigt — bitte am Gerät bestätigen)* | Bestätigt
| 8 | A2.1 Subitizing (ZR5, Bild) | Schau genau hin! Wie viele Perlen waren es? *(inhaltlich jetzt korrekt: Antwort 4, innerhalb der Simultanerfassungsgrenze — bitte am Gerät bestätigen, dass die Reihen nicht mehr versetzt sind)* |
| 9 | A2.2 Zehnerfeld (ZR10, Bild) | Wie viele Felder sind gefüllt? |
| 10 | A2.2 Fingerbild (ZR10, Bild) | Wie viele Finger sind es insgesamt? |
| 11 | A2.3 Mengenvergleich ikonisch (ZR10, Bild) | Wo sind mehr Felder gefüllt — links oder rechts? *(Paar mit #65 — siehe Struktur-Flag oben)* |
| 12 | A3.1 Teil-Teil-Ganzes (ZR10) | In der Dose sind 6 Murmeln. 4 sind rot, die anderen blau. Wie viele sind blau? |
| 13 | A3.1/A3.3 Ergänzen zu 10 (ZR10) | Welche Zahl fehlt? 10 = 3 + ___ |
| 14 | A3.1/A3.3 Teil-Teil-Ganzes (ZR10) | Lena hat 6 rote und 4 blaue Perlen. Wie viele Perlen hat Lena zusammen? |
| 15 | A3.2 Zerlegung flexibel, 3 Wege (ZR10) | Finde drei verschiedene Wege, die 8 zu zerlegen: 8 = ___ + ___ |
| 16 | A3.2 Nachbarzerlegung (ZR10) | Paul weiß: 8 = 5 + 3. Damit weiß er auch: 8 = 3 + ___. Welche Zahl fehlt? |
| 17 | A3.2 Zerlegung vollständig (ZR10) | **Problem: Redundanz zu #15, kein ausgewiesener diagnostischer Unterschied.** Entweder streichen, oder klar abgrenzen — Vorschlag: „Finde **alle** Zerlegungen von 10 in zwei Zahlen. Wie viele hast du gefunden?" (prüft Vollständigkeit/Systematik statt nur „drei Wege finden" wie #15 — das wäre der Unterschied, den es bräuchte) | Streichen
| — | *(A3.3 #18 „Kim kennt die Zahl 4…" — bereits durch #62 ersetzt, nicht mehr live)* | |
| 18 | A3.3 Nachbaraufgabe zu Doppelt (ZR10) | Tim weiß: 4 + 4 = 8. Wie viel ist dann 4 + 5? |
| 19 | B1.1 Zehner/Einer (ZR100) | **Problem: unnötige Vorrede „Sieh dir die Zahl an. Die Zahl ist 58."** Vorschlag: „Die Zahl 58: Wie viele Zehner, wie viele Einer?" |
| 20 | B1.2 Bündelung (ZR100, Bild) | Wie heißt die Zahl, die hier dargestellt ist? |
| 21 | B2.1 Stellenwerttafel eintragen (ZR100, Bild) | Trage die Zahl 47 in die Tafel ein. |
| 22 | B2.1 Stellenwerttafel lesen (ZR100, Bild) | Welche Zahl steht in der Tafel? |
| 23 | B2.2 Zahlenstrahl ZR100 (Bild) | Auf welche Zahl zeigt der Pfeil? *(Struktur-Flag: #66/#67 gehören davor)* |
| 24 | B2.3 nicht-standardisierte Form (ZR100) | **Problem: die Aufgabe erklärt sich selbst weg.** „Das heißt: 1 Zehner und 14 Einer" nimmt dem Kind genau das ab, was gemessen werden soll (kann es „1 Z + 14 E" selbst lesen?). Vorschlag: „Lies genau: 1 Z + 14 E. Wie heißt die Zahl?" (Z/E-Bedeutung ist ab #21 etabliert) |
| 25 | C1.1a Grundaufgabe ohne Übergang (ZR10) | Wie viel ist 3 plus 4? |
| 26 | C1.1b Grundaufgabe ohne Übergang (ZR10) | Wie viel ist 6 minus 6? |
| 27 | C1.1a Grundaufgabe ohne Übergang (ZR10) | Was ergibt 2 plus 8? |
| 28 | C1.1b Grundaufgabe ohne Übergang (ZR10) | Wie viel sind 10 minus 4? |
| 29 | C1.2 Verdopplung automatisiert (ZR10) | Wie viel ist 4 plus 4? |
| 30 | C1.2 Verdopplung automatisiert (ZR10) | Wie viel ist 5 plus 5? |
| 31 | C1.3 Halbierung automatisiert (ZR10) | Welche Zahl ist halb so groß wie 6? |
| 32 | C1.3 Halbierung automatisiert (ZR10) | Welche Zahl ist halb so groß wie 10? |
| 33 | C2.1 Zehnerübergang (ZR20) | Wie viel ist 7 plus 6? |
| 34 | C2.1 Zehnerübergang (ZR20) | Wie viel ist 8 plus 5? |
| 35 | C2.1 Zehnerübergang (ZR20) | Wie viel ist 9 plus 7? |
| 36 | C2.2 Verdopplung als Stützpunkt (ZR20) | Wie viel ist 8 plus 7? |
| 37 | C2.2 Verdopplung als Stützpunkt (ZR20) | Wie viel ist 9 plus 8? |
| 38 | C2.3 Ergänzen statt Abziehen (ZR20) | Wie viel ist 13 minus 8? |
| 39 | C2.3 Ergänzen statt Abziehen (ZR20) | Wie viel ist 12 minus 9? |
| 40 | C2.3 Ergänzen statt Abziehen (ZR20) | Wie viel ist 15 minus 6? |
| 41 | C3.1a Stellenweises Rechnen + (ZR100) | „Rechne 34 + 22." *(Operand geändert 34+28→34+22: kein Zehnerübertrag — erste ZR100-Strategieaufgabe im ganzen Block, muss die leichteste Form sein, nicht die schwerste. **Wenn übernommen: CorrectAnswer in der CSV auf 56 ändern.**)* |
| 42 | C3.1b Stellenweises Rechnen − (ZR100) | „Rechne 56 − 23." *(Operand geändert 57−19→56−23: kein Entbündeln nötig, Rampe vor #43. **CorrectAnswer → 33.**)* |
| 43 | C3.1b Stellenweises Rechnen − (ZR100) | „Rechne 84 − 26." *(unverändert — jetzt bewusst die schwerste C3.1-Aufgabe, am Ende des Strangs statt am Anfang)* |
| 44 | C3.2 Schrittweises Rechnen + (ZR100) | „Rechne 26 + 35." *(nackte Rechnung; die alte Version rechnet „bis zum nächsten Zehner auffüllen" komplett vor — das ist die zu messende Strategie, nicht die Anleitung dazu)* |
| 45 | C3.2 Schrittweises Rechnen − (ZR100) | „Rechne 63 − 28." *(gleiches Muster)* |
| 46 | C3.2 Schrittweises Rechnen + (ZR100) | „Rechne 67 + 28." *(gleiches Muster)* |
| 47 | C3.3 Hilfsaufgabe (ZR100) | „20 + 50 = 70 — wie viel ist 21 + 50?" *(ein Satz per Gedankenstrich statt zwei Sätze, damit I1 hält; die gegebene Nachbaraufgabe ist hier legitim, weil sie der Konstrukt selbst ist — nicht das Verfahren für dieselbe Rechnung)* |
| 48 | C3.3 Hilfsaufgabe/Nachbaraufgabe (ZR100) | „45 + 40 = 85 — wie viel ist 45 + 38?" *(auf eine Nachbaraufgabe gekürzt statt zwei; gleiches Ein-Satz-Muster wie #47)* |
| 49 | C3.4a Zerlegungsstrategie „fast gleich" (ZR100) | „Rechne 37 + 38." *(der Tipp „37 und 38 sind fast gleich, rechne 38+38 und zieh 1 ab" ist hier das Verfahren für dieselbe Rechnung, nicht wie bei #47/#48 ein separater Fakt — komplett entfernt statt umformuliert)* |
| 50 | C3.4b Zerlegungsstrategie günstig runden (ZR100) | „Rechne 73 − 38." *(gleiches Muster wie #49)* |
| 51 | C4.1 Strategieauswahl + (ZR100) | „Rechne 34 + 29." *(die „Wie hast du gerechnet?"-Auswahl a–d entfernt — es gibt kein Feld dafür, siehe Befund oben; übrig bleibt Antwort + Reaktionszeit, wie überall sonst)* |
| 52 | C4.1 Strategieauswahl − (ZR100) | „Rechne 52 − 19." *(gleiches Muster)* |
| 53 | C4.2 Umkehrbeziehung (ZR100) | „43 + 29 = 72 — wie viel ist 72 − 29?" *(auf **eine** Frage gekürzt statt zwei — zwei Antworten in einem Feld war ein I5-Verstoß; die zweite Richtung testet jetzt #54 mit einem anderen Zahlenpaar, damit nichts an Abdeckung verloren geht)* |
| 54 | C4.2 Umkehrbeziehung (ZR100) | „47 + 36 = 83 — wie viel ist 83 − 47?" *(ersetzt das alte „welche Plusaufgabe passt dazu, finde sie selbst"-Zweischritt-Item; testet dieselbe Umkehrbeziehung mit dem ursprünglichen 83/47-Zahlenpaar, aber als eine Frage. **CorrectAnswer → 36.**)* |
| 55 | D1.1 Sachsituation + (ZR20) | Luna schwimmt 8 Bahnen, nach der Pause noch 5. Wie viele Bahnen insgesamt? |
| 56 | D1.2 Rechenoperation erkennen (ZR20) | **Problem: die Antwortoptionen „9 + 4 · 9 − 4 · 4 − 9" sind mit einem Multiplikationspunkt getrennt — sieht aus wie eine vierte Rechnung.** Vorschlag: Leo zählt heute 9 Bohnenpflanzen. Am Nachmittag sind es 4 mehr. Wie viele stehen jetzt in seinem Beet? *(Antwortoptionen als klar getrennte Buttons/Zeilen in der UI, nicht als ein Fließtext mit „·")* |
| 57 | verdoppeln-halbieren.ZR10 | Was ist das Doppelte von 4? *(Referenzqualität — so sollen alle anderen auch klingen)* |
| 58 | verdoppeln-halbieren.ZR20 | Was ist das Doppelte von 7? |
| 59 | verdoppeln-halbieren.ZR100 | Was ist das Doppelte von 20? |
| 60 | verdoppeln-halbieren.ZR100 | Was ist das Doppelte von 43? |
| 61 | verdoppeln-halbieren.ZR100 | Was ist das Doppelte von 27? |
| 62 | A3.3, Verdopplung (ZR10, Ersatz für altes #18) | Welche Zahl ist doppelt so groß wie die 4? |
| 63 | B1.2, Bündelung, ein Feld (ZR100, Bild, Ersatz für altes #22) | Wie viel ist das insgesamt? *(Hilfetext: „Hier liegen 3 Zehnerstangen und 11 einzelne Würfel.")* |
| 64 | B1.3, Entbündelung (ZR100, Bild, Ersatz für altes #23) | Öffne die Zehnerstange. Wie viele einzelne Würfel hast du dann? |
| 65 | A2.3, Mengenvergleich symbolisch (ZR10) | Welche Zahl ist größer: 6 oder 8? *(sollte neben #11 stehen — siehe Struktur-Flag oben)* |
| 66 | B2.2, Zahlenstrahl-Rampe (ZR10) | Auf welche Zahl zeigt der Pfeil? *(sollte vor #23 stehen — siehe Struktur-Flag oben)* |
| 67 | B2.2, Zahlenstrahl-Rampe (ZR20) | Auf welche Zahl zeigt der Pfeil? *(direkt nach der ZR10-Rampe, vor #23)* |

---

## Was noch fehlt, unabhängig vom Wortlaut

Aus dem 2026-09-07-Befund, nicht durch Wortlaut lösbar — nur zur Erinnerung, damit es hier nicht
verschwindet:

- **Verdoppeln/Halbieren ZR20:** #58 prüft nur Verdoppeln. Halbieren im ZR20 (Hälfte von 14/16/18)
  fehlt im Kerntest weiterhin komplett.
- **Zählendes Rechnen als Leitkonstrukt** wird noch nirgends direkt erhoben, nur indirekt über
  Reaktionszeit bei #51–54.
- **C4.1/C4.2 messen jetzt nur noch Antwort + Reaktionszeit, nicht mehr „welche Strategie genau".**
  Das war schon vorher so (die Selbstauskunft war nie erfasst), aber jetzt ist es auch so
  *benannt*. Falls du die feinere Strategieunterscheidung willst, bräuchte es ein echtes
  Eingabefeld dafür (neuer `AnswerFormat`-Wert + Widget) — das ist eine Engineering-Entscheidung,
  keine Wortlaut-Frage, und gehört nicht in dieses File.
- **Der Sprung von ZR20 (#40) auf ZR100 (#41) bleibt ein Zahlenraumleiter-Übergang**, auch nachdem
  #41 jetzt die leichteste C3.1-Aufgabe ist. Ob davor noch eine eigene Übergangsaufgabe hingehört,
  ist eine Blueprint-Frage (Itemanzahl je Zelle), keine Wortlaut-Frage — hier nur vermerkt, damit
  sie nicht untergeht.
