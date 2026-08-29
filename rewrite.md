Clean-Room Rewrite Plan — Math Diagnostic App
Purpose: Convert the current iMINT-derived diagnostic into an independently-developed product that can be sold without copyright, database-right, or CC-license violations, while preserving and explicitly attributing the scientific foundations of the work.

Scope: Replaces the iMINT-derived diagnostic items, the question selection and sequencing, the skill catalog, the Förderplan recommendation mappings, and any PIKAS-derived practice content. Preserves the app architecture, the diagnostic flow logic (the code), the UI patterns, the technical infrastructure, and the underlying pedagogical principles.

Reality check: This is real work — roughly 3–6 months of pedagogical effort for a solo developer, possibly accelerated with a co-author. It is not a search-and-replace exercise. The result is something you own, can sell, and can defend.

1. What "clean-room" actually means here
Clean-room rewriting comes from software reverse engineering: one team studies the protected work and writes a specification of what it does; a separate team builds a new implementation from that specification without ever seeing the protected work. The firewall guarantees the new implementation isn't a derivative.

A solo developer cannot literally do this two-team separation. The practical equivalent is the provenance firewall: for every artifact you ship (item, skill description, recommendation rule, category structure), you must be able to point to:

A scientific construct the artifact measures or addresses (from published, independent literature — not from the iMINT Kartei).
An independent rationale for the specific form your artifact takes (the numbers, the wording, the count, the ordering, the cutoff).
No specific feature traceable to a protected source beyond the scientific construct itself.
The firewall is documentation-based: you keep an audit trail showing that each artifact was developed from cited public-domain or properly-licensed sources, not lifted from iMINT/PIKAS/Schulz.

The legal standard you're meeting: substantial dissimilarity in protected expression (selection, arrangement, specific wording, specific exercise design) combined with legitimate use of unprotected ideas (constructs, methods, theories).

2. What stays, what changes, what comes out
Stays (no rewrite — these are yours or are unprotected)
Asset	Reason
All Flutter UI code (math_app/lib/widgets/diagnostic/*, the various input widgets, dice/audio displays)	Your code. Not derived from any protected source.
Diagnostic flow logic in diagnostic_screen.dart (965 lines) — answer handling, breakoff logic, hydration, navigation	Your code. The mechanism of running a diagnostic is not protected.
All Next.js dashboard code (dashboard/)	Your code.
All Supabase schema, edge functions, RLS policies (backend/)	Your code.
DiagnosticResult, DiagnosticSession, Foerderplan model classes	Your code.
DiagnosticReportGenerator / Förderplan engine architecture	Your code. The mapping data inside it changes — see below.
The pedagogical constructs being measured (counting, number decomposition, place value, addition/subtraction strategies, etc.)	Scientific constructs are not protected.
The general didactic sequence concept (number sense before operations, ZR10 before ZR20 before ZR100)	Standard German Grundschulmathematik didactics, not iMINT's invention.
The German UI translations of generic terms (Zählen, Zahlzerlegung, Stellenwert, etc.)	Standard didactic vocabulary.
The break-off / abbreviated diagnostic mechanism	Your code. The trigger rules (which failures abbreviate which subsequent groups) need review — see §6.
Changes (rewrite required)
Asset	What changes
MathApp_Diagnostic_with_skills.csv (92 items)	Every item rewritten. New numbers, new framings, new ordering. New total count chosen from your own blueprint, not iMINT's 98 (now 92).
IfWrong_practice_skills mappings	Rebuilt from your own competency model, not from iMINT's "wenn → übe" relations.
Question grouping (Zählen 1–23, Zahlzerlegung 24–38, etc.)	Replaced with your own structure derived from your blueprint. May coincidentally have similar category names because the constructs themselves are standard. Item counts per category and cutoff points will differ.
skills_taxonomy.csv — the 87 skills, their IDs, categories, colors, card numbers, German/English titles, descriptions	All descriptions rewritten. ID system replaced (the current Z1, C1.1, etc. mirrors PIKAS card numbering). Categories restructured to your model.
Category structure (Zählen / Zahlzerlegung / Stellenwerte / Grundstrategien / Kombinierte Strategien)	Defensible to keep — these are standard didactic categories used across the German literature, not iMINT-original. But the specific boundaries between categories (which skill goes where, which item tests which) must be derived from your blueprint, not iMINT's.
Q47 audio item (Zahlendiktat)	Rewritten with different numbers; or replaced with a different item testing the same construct (auditory number recognition / Hörverstehen).
Q21 / Q38 / Q46 / Q48 dice items	Rewritten with different configurations testing subitizing / part-whole.
Skill description text (German and English) for all 87 skills	All rewritten. Current descriptions likely echo PIKAS / iMINT phrasing.
Comes out completely (cannot remain in a commercial product)
Asset	Reason
Any practice exercise content directly modeled on PIKAS cards — review all 8 shipped skills (Z1, C1.1, C1.2, C2.1, C3.1, C4.1, S1.1, S3.4) for PIKAS-derived structure.	CC BY-NC-SA. NC blocks commercial use; SA contaminates the whole app.
The 12 PIKAS-sourced skills (per SKILLS_README.md: 76 iMINT + 12 PIKAS) — at minimum their descriptions and any specific exercise designs derived from PIKAS cards.	Same.
The Schulz 151-question diagnostic in any modified/integrated form.	CC BY-ND. If you reorder, recategorize, or feed individual items into adaptive Förderplan logic, you have made a derivative work and ND forbids distributing it.
The framework documents that explicitly describe how to translate PIKAS cards into app levels (IMINT_TO_APP_FRAMEWORK.md)	Should be archived or rewritten to reference your own pedagogical sources rather than iMINT/PIKAS specifically.
The Werktitel "Auf dem Weg zum denkenden Rechnen" / "Erfolgreich rechnen lernen" anywhere except a scientific-citations page.	Werktitelschutz; UWG §5.
Conditional — keep with restrictions
Asset	Condition
Schulz diagnostic, verbatim and unmodified, as an OPTIONAL second instrument behind a "ich präsentiere Ihnen den Test wie publiziert" framing	Allowed under CC BY-ND if (a) every item is verbatim, (b) order is exactly as Schulz published, (c) full attribution is shown, (d) no adaptive logic alters which items get shown, (e) the Förderplan does not internalize Schulz items as atomic units in your own logic. Verify the CC license is in fact BY-ND before relying on this.
References to Wartha/Schulz, Padberg/Benz, Selter, etc. as scientific basis in a "Wissenschaftliche Grundlagen" page	Standard academic citation, §51 UrhG. Fine in any context including commercial.
3. Scientific foundation you will stand on
The clean-room rewrite needs a defensible bibliography that you actually read and use as the basis for your independent decisions. These are the works you cite as your sources — not iMINT, not PIKAS as instruments, but the underlying scientific literature that those instruments themselves draw from.

Core references (read these, work from these):

Wartha, S. & Schulz, A. Rechenproblemen vorbeugen. (Most editions are Klett/Cornelsen — verify your edition.) Foundational German-language synthesis on prevention of math difficulties. Frames the four-pillar model: counting, number decomposition, place value, strategies.
Padberg, F. & Benz, C. Didaktik der Arithmetik für Lehrerausbildung und Lehrerfortbildung. Spektrum. The standard German university textbook on arithmetic didactics. Defines what each construct means and how it is taught.
Selter, C. & Spiegel, H. Wie Kinder rechnen. Klett. Classic German work on children's calculation strategies.
Schipper, W. Handbuch für den Mathematikunterricht an Grundschulen. Schroedel. Comprehensive reference on primary math teaching.
Krajewski, K. Vorhersage von Rechenschwäche in der Grundschule. Theoretical model of early numerical competence development.
Fritz-Stratmann, A., Ehlert, A., Klüsener, G. Mit Mathe richtig anfangen. Developmental model from MARKO-D.
Moser Opitz, E. Rechenschwäche/Dyskalkulie. Empirical research on what struggling learners specifically fail at.
Lorenz, J. H. Lernschwache Rechner fördern. Cornelsen.
KMK Bildungsstandards Mathematik Primarstufe. The official competency framework — explicitly public.
Where these underlie the iMINT/PIKAS work: all of the above are cited in the iMINT Kartei's own Literaturliste and in PIKAS's theoretical writings. That's the point: iMINT and PIKAS are themselves derived from this literature. You go to the same source, derive your own product, and you are not derivative of iMINT/PIKAS — you are a sibling work.

Documentation rule: every diagnostic item, every skill description, every Förderplan rule needs to be traceable in your audit trail to at least one of these published sources (or to your own original pedagogical reasoning, documented as such).

4. Construct map — what your diagnostic measures
This is the most important section. The constructs themselves are unprotected scientific concepts. Decide which constructs you will measure, based on the literature above, and write them down independently. This becomes your blueprint.

A defensible construct map for a Grundschule arithmetic diagnostic, derived from Wartha/Schulz, Padberg/Benz, and Krajewski:

Domain A: Zahlbegriff (Number Sense)
A1. Zählkompetenz (counting competence)

A1.1 Vorwärtszählen in ZR20 / ZR100 vom beliebigen Startpunkt
A1.2 Rückwärtszählen in ZR20 / ZR100 vom beliebigen Startpunkt
A1.3 Zählen in Schritten (2er, 5er, 10er) — vor- und rückwärts
A1.4 Vorgänger/Nachfolger bestimmen
A1.5 Zählen über Zehnerübergang hinweg
A2. Anzahlerfassung (quantity recognition)

A2.1 Simultanerfassung (subitizing) bis 4–5
A2.2 Strukturierte Anzahlerfassung (Würfelbild, Fünferstrukturen) bis 10
A2.3 Anzahlvergleich / mehr/weniger
A3. Zahlzerlegung (number decomposition)

A3.1 Teil-Teil-Ganzes (part-part-whole) in ZR10
A3.2 Zerlegungen einer Zahl flexibel finden
A3.3 Zahlbeziehungen (Verdopplungen, Nachbarzahlen)
Domain B: Stellenwertverständnis (Place Value)
B1. Bündelung und Entbündelung

B1.1 Zehner und Einer in zweistelliger Zahl erkennen
B1.2 Bündelung von Einzelobjekten zu Zehnern
B1.3 Entbündelung eines Zehners
B2. Zahldarstellung

B2.1 Standardform und Stellenwerttafel
B2.2 Zahlen am Zahlenstrahl verorten
B2.3 Zahlen in nicht-standardisierter Form (z. B. 1 Z + 14 E = ?)
Domain C: Rechenstrategien Addition / Subtraktion
C1. Grundaufgaben (number facts) ZR10

C1.1 Aufgaben ohne Zehnerübergang automatisiert abrufbar
C1.2 Verdopplungsaufgaben automatisiert
C1.3 Halbierungsaufgaben automatisiert
C2. Strategien mit Zehnerübergang ZR20

C2.1 Zerlegungsstrategien (Teilschritt-Verfahren)
C2.2 Verdopplung/Halbierung als Stützpunkt
C2.3 Ergänzen statt Abziehen bei Subtraktion
C3. Strategien im erweiterten Zahlraum (ZR100)

C3.1 Stellenweises Rechnen (Z + Z, E + E)
C3.2 Schrittweises Rechnen
C3.3 Hilfsaufgaben (Nachbaraufgaben, Ergänzen)
C3.4 Zerlegungsstrategien
C4. Flexibles Rechnen

C4.1 Strategieauswahl abhängig von Zahlen
C4.2 Inverse Beziehung Addition/Subtraktion nutzen
Domain D: Sachsituationen (optional in v1)
D1. Einfache Rechengeschichten

D1.1 Mathematisierung von Alltagskontexten
D1.2 Erkennen der Rechenoperation
This is your construct map. It is recognizable as standard Grundschulmathematik because the constructs themselves are standard — but the specific way you've grouped, named, and partitioned them is your editorial choice, defensible from your reading of the literature.

Compare to iMINT's structure (Zählen / Zahlzerlegung / Stellenwerte / Grundstrategien / Kombinierte Strategien): there is unavoidable overlap because both are competent didactic structures and both descend from the same literature. The defense is that you can show your construct map came from Wartha/Schulz/Padberg directly, not from iMINT's specific partitioning.

5. Independent test blueprint
The blueprint specifies, before any items are written, what the test will measure and how. This is the document that makes your selection and arrangement independent of iMINT's selection and arrangement.

Blueprint specification
Total item count: Choose your own. 92 (current) is suspiciously close to iMINT's 98. Pick a different target. A defensible range based on a 20–30 minute administration time for ages 6–10 is 50–80 items. Recommendation: 60 items.

Coverage targets per construct:

Construct	Items	Rationale
A1 Zählkompetenz	8	Multiple counting tasks needed: forward, backward, in steps, both ZR. Wartha/Schulz argue counting is the single highest-leverage diagnostic, so generous coverage.
A2 Anzahlerfassung	4	Krajewski's research on subitizing as predictor; need enough items to distinguish reliance on counting vs. structure.
A3 Zahlzerlegung	8	Padberg/Benz: foundational for non-counting strategies. Test both directions (decompose, compose).
B1 Bündelung	4	Empirically the most diagnostic of place-value problems per Moser Opitz.
B2 Zahldarstellung	4	Number line and Stellenwerttafel tasks.
C1 Grundaufgaben ZR10	8	Need spread across +/−, doubles, near-doubles, zero, complements-to-10.
C2 Strategien ZR20 mit ÜZ	8	The "Zehnerübergang" cliff; needs both + and −, both directions.
C3 Strategien ZR100	10	Largest range, multiple strategies, both operations.
C4 Flexibles Rechnen	4	Items designed to reveal strategy use vs. counting.
D1 Sachsituationen	2 (optional)	Light coverage; many existing instruments cover this.
Total	60	
These numbers are your editorial choices, defensible from the literature. They differ from iMINT's. Document the rationale for each in your blueprint document.

Sequencing rules:

Easiest constructs first (A1 → A2 → A3 → B1 → B2 → C1 → C2 → C3 → C4 → D1). This is standard didactic sequencing, not iMINT-original.
Within each construct, items ordered by difficulty (smaller numbers / smaller ranges first).
Items that allow break-off (where failure predicts failure at higher levels) are placed early in each construct.
Mixed-operation items (where both + and − are tested) alternate to prevent set effects.
Break-off / abbreviated rules:

The current code has skip-group rules ("wenn ZR20 Aufgabe X falsch, überspringe ZR100 Gruppe Y"). These rules are part of the diagnostic logic and need their own independent justification.

Defensible source: Wartha/Schulz argue that failure at ZR20 + with Zehnerübergang predicts failure at ZR100 +; thus if a child cannot do 8+7, asking them 38+27 has low information value. This is published reasoning. Encode your own version of this argument as your skip rules. Document the source.

Difficulty distribution targets:

30% items designed so >80% of typically-developing 2nd-graders pass
50% items designed so 40–80% pass
20% items designed so <40% pass
These targets allow the diagnostic to spread children meaningfully. Source for the spread: Item Response Theory norms for diagnostic instruments (any IRT textbook); not iMINT-derived.

6. Item development process and standards
For each of the 60 items in your blueprint, follow this process:

Item development template (one per item)

Item ID: A1-04
Construct: A1.3 Zählen in 2er-Schritten vorwärts ZR20
Difficulty target: medium (40–80% pass)
Number range: ZR20
Stimulus type: spoken instruction + child answers verbally / via input
Source of construct definition: Padberg/Benz 2021, Kap. 3.2 (Zählen)
Source of difficulty rationale: own choice, ZR20 with 2er-Schritten is post-introduction
Distinct from any known iMINT item: confirmed — iMINT item Z-something asks
  "[different specific task]"; this item uses [different specific task]
Wording (German): "Zähle in Zweierschritten von 6 bis 18."
Expected correct answer: "6, 8, 10, 12, 14, 16, 18"
Acceptable variants: stopping at 18 vs. continuing to 20 both accepted
Wrong-answer diagnostics:
  - Counts in 1s: indicates step-counting not yet developed
  - Skips a step: typical processing slip, not diagnostic alone
  - Stops at 16 or 17: indicates ZR boundary confusion
Maps to skills (for Förderplan): A1.3, A1.5 if Zehnerübergang involved
This template is the audit trail unit. Every shipped item has one. Stored together (e.g., docs/items/A1-04.md or in a database) so that if you ever face a challenge, you can produce the file showing how that item was developed.

Item writing standards
1. Different numbers. If iMINT's counting items use 7→13, yours do not. Choose number ranges deliberately to avoid the specific numbers iMINT chose. This is the cheapest part of the rewrite and the most legally visible.

2. Different framings. Where iMINT uses verbal instruction, you might use visual presentation, or vice versa. Where iMINT uses a story problem, you use a bare calculation. Where iMINT uses a single answer field, you use multiple choice or vice versa.

3. Different counts per construct. As long as your blueprint shows 8 items for A1 and iMINT's shows 11 for "Zählen", you are demonstrably making independent editorial choices.

4. No characteristic copying. Specifically:

Do NOT use Q47's "Zahlendiktat" mechanism if that audio approach is a distinctive iMINT feature. Use a different auditory format (e.g., teacher reads aloud once and child writes — no recorded audio at all in v1).
Do NOT use the specific dice configurations from Q21/Q38/Q46/Q48 if those are characteristic iMINT items. Use different visual structures (10-frame instead of dice, finger patterns, beads on a rekenrek).
Do NOT replicate any unusual or memorable item that is identifiably "the iMINT one".
5. Item review by a second person if possible. If you know a Grundschullehrer who would review for didactic soundness, ask. This both improves quality and creates an independent witness.

Worked example — A1.1 (Vorwärtszählen)
Property	iMINT (representative — adjust based on actual)	Your rewrite
Construct	Forward counting from arbitrary start	Same
Number range	ZR20	ZR20
Start point	(e.g., 7)	6
End point	(e.g., 13)	14
Format	"Zähle weiter: 7, 8, ..."	"Beginne bei 6 und zähle laut bis 14."
Input method	Voice (teacher records)	Voice or written sequence
Acceptance	exact sequence	exact sequence; allow self-correction
Same construct. Different specifics. Both items competently measure A1.1. Yours is yours.

Worked example — C2.1 (Zehnerübergang +)
Property	iMINT (representative)	Your rewrite
Construct	Addition with Zehnerübergang ZR20	Same
Specific item	(e.g., 8 + 7 = ?)	7 + 6 = ?
Difficulty	both addends > 5; sum > 10	same difficulty class, different addends
Format	bare arithmetic	bare arithmetic, allow scratch
Wrong-answer codes	wrong by 1, off by 10	wrong by 1, off by 10, counted on (timing > X seconds)
The timing diagnostic (using response time to infer strategy) is a published technique (Selter; Schulz). Whether iMINT does or doesn't use it isn't relevant — you cite Selter as your source.

7. Skill catalog rewrite
The current skills_taxonomy.csv has 87 skills with an ID system (Z1, C1.1, S3.4, etc.) that mirrors the PIKAS card numbering convention. SKILLS_README.md explicitly says: "76 iMINT + 12 PIKAS". Both halves need to be reworked.

Rewrite scope
Element	Action
ID scheme	Replace. Use your construct map's IDs (A1.3, B2.1, C3.2) instead of the current Z/C/S scheme. This visibly disconnects you from PIKAS card numbering.
Number of skills	Reconsider. 87 is a lot. Many of them are PIKAS-imported and may be redundant. Your blueprint's construct map yields maybe 30–40 distinct fördernswerte skills. Trim to your real model.
Category structure	Use your Domain A/B/C/D structure.
Color coding	Free choice; can stay if not PIKAS-specific.
German title (title_de)	Rewrite every one. Current titles likely echo iMINT/PIKAS phrasing.
English title (title_en)	Rewrite.
German one-line description (description_de)	Rewrite every one. This is the highest-risk text in the catalog because it's where iMINT/PIKAS phrasing tends to leak through verbatim.
English description	Rewrite.
card_number field	Delete. The concept of "card number" is borrowed from PIKAS card decks. You're not shipping cards.
Skill description writing standard
Each skill description should:

Be 1–2 sentences (German), 1–2 sentences (English).
State what the child can do, not what activity teaches it.
Use standard didactic vocabulary that appears across the literature (so it's not traceable to any one source).
Avoid specific phrasings from Wartha/Schulz or Padberg/Benz that would be quotation.
Example — current vs. clean:

Current (representative, may echo PIKAS): "Das Kind kann Zahlen bis 10 in verschiedene Teile zerlegen und die Teil-Ganzes-Beziehung erkennen."

Clean rewrite: "Zerlegt Zahlen im Zahlraum bis 10 flexibel in zwei Summanden und erfasst dabei den Zusammenhang von Teilen und Ganzem."

Same meaning. Different specific wording. The construct is unprotected; only the specific phrasing matters.

Do this for every skill. Time estimate: ~5 minutes per skill × 35 skills (after trimming) = 3 hours of focused work.

8. Förderplan generation logic
The IfWrong_practice_skills mapping
Current: each diagnostic item has a column IfWrong_practice_skills listing skill IDs to recommend if the child gets that item wrong. This mapping is derived from iMINT's Kartei structure. It is protected — the specific "wenn dieses Item falsch, übe diese Skills" relations are part of the iMINT diagnostic system.

You need your own version. Build it from your own pedagogy:

For each of your 60 items, decide independently:

What does failure on this item suggest the child is missing?
Which of your (now ~35) skills directly address that gap?
Which 1–3 skills are highest priority?
Document the reasoning. Source: your construct map. The mapping is yours.

Example reasoning chain:


Item C2.1-03 (7 + 6 with Zehnerübergang)
If wrong:
  → Most likely cause: child cannot decompose to reach 10
  → Underlying skill gap: A3.1 (Teil-Teil-Ganzes) and/or A3.2 (Zerlegungen einer Zahl)
  → Secondary: C1.1 (Grundaufgaben ZR10) if even these aren't automatized
  → Recommended skills (in priority): A3.1, C1.1, C2.1
  Source: Wartha/Schulz auf Verfestigung des zählenden Rechnens; Padberg/Benz Kap. 4
Förderplan report structure
The current DiagnosticReportGenerator produces a brief plan, category overview, full plan, and detail table. The structure is your code. The content — which skills get recommended, in what priority — depends on the mappings you build.

Decision on the report structure itself: the four-section structure (brief / categories / full / table) is a sensible diagnostic report layout, not iMINT-specific. Many published förderdiagnostic instruments follow similar structures. Keep it. Verify the section labels you use are generic German didactic terms, not iMINT-specific labels.

Kurzförderplan SenBJF format
This is named after the Berlin Senate for Education ("Senatsverwaltung für Bildung, Jugend und Familie"). If the Kurzförderplan template you're using is the SenBJF official template, you have a different copyright question on that specific document layout.

Action: check the source of the Kurzförderplan template you ported. If it's from a SenBJF publication, you have the same protection issue as the Kartei. Either:

Use SenBJF's published Kurzförderplan form only with their permission (it may be permitted for school use, but not for distribution by you to other schools as part of your product),
Or design your own Kurzförderplan layout based on the standard headings that German schools use (Ist-Stand, Soll-Stand, Lernweg, Förderziele, Methoden, Zeitraum).
These section names are standard pedagogical vocabulary, not SenBJF inventions. The specific layout of the SenBJF form, however, may be a protected work. Design your own form. Call it a "Kurzer Förderplan" or "Einseitiger Förderplan" — not "Förderplan nach SenBJF."

9. The Schulz diagnostic (151 questions) specifically
The conditional path:

If the LISUM publication is genuinely CC BY-ND 4.0 DE (verify on the actual publication, not just the website), and you ship it verbatim and unmodified, then you can include it in a commercial product.

Verbatim and unmodified means:

Every item exactly as Schulz wrote it.
Order exactly as Schulz published.
The 8 blocks Schulz defined, not your re-blocking.
The PairId structure Schulz designed, not your reinterpretation.
Any answer scoring exactly as Schulz specified.
Full attribution displayed on the diagnostic itself, not buried in a credits page.
You cannot:

Feed individual Schulz items into your own Förderplan generation as if they were atomic units in your taxonomy.
Show only some items based on adaptive logic of your own design (selection is part of the work; selecting differently is a derivative).
Mix Schulz items with iMINT-derived items in a single report (which your project_two_diagnostics rule already prevents — good).
Restate Schulz's items in your own words "for clarity" — that is a modification.
Recommendation: in v1 of the commercial product, drop Schulz. The integration constraints are too restrictive to be useful as anything more than a digital photocopy. If you want to revisit it later, contact LISUM and Schulz directly for a license that overrides ND for your specific integration. Schulz may be amenable; LISUM is a Bundesländer-funded institute and may have rules either way.

10. Documentation and audit-trail requirements
If this is ever challenged, the difference between "we developed this independently" and "we copied this" is documentation. Build the trail as you go; don't reconstruct it later.

Required artifacts (one repo, version controlled)

docs/
  clean-room/
    00-charter.md            — what this rewrite is, what it's not
    01-construct-map.md      — your Domain A/B/C/D map (§4)
    02-blueprint.md          — your item-count plan, sequencing rules (§5)
    03-bibliography.md       — full scientific bibliography (§3)
    04-item-development-log.md  — chronological log of decisions
    items/
      A1-01.md  ...  D1-02.md  — one file per item per template in §6
    skills/
      A1.1.md  ...  C4.2.md   — one file per skill, descriptions + rationale
    foerderplan/
      mapping-rationale.md    — per-item "if-wrong → recommend" reasoning
    decisions/
      0001-why-60-items.md
      0002-why-domain-structure-not-iMINT-categories.md
      0003-dropping-PIKAS-derived-skills.md
      ...
Decision records (ADR-style) for any non-obvious editorial choice. These are the documents you produce in court if you ever need to.

Provenance log
For each shipped artifact (item, skill, mapping rule), one line in a master log:


artifact_id | type | author | created | sources_cited | independent_of (positive statement)
A1-01 | item | Jakob | 2026-06-03 | Padberg/Benz 2021 Kap. 3.2 | not modeled on any iMINT, PIKAS, Schulz, or commercial test item
Keep this log as a CSV in the repo. Update as you go.

Do not keep around
Old iMINT-derived CSV files in the repo (move to Archive/ and clearly mark "do not ship, do not use as basis for new items").
Internal documents that reference iMINT items by ID as if they're authoritative.
Old skill descriptions that may have been lifted from PIKAS.
Better: archive these in a separate, non-distributed branch or external private location.

11. Validation plan (so you can defend pedagogical quality)
The legal rewrite gives you a defensible product on copyright. It does not give you a clinically validated instrument. That's a separate problem.

For the commercial pitch ("our diagnostic identifies the same Förderbedarf as established instruments") to be credible without violating UWG §5, you need some validation evidence. Options ranked by cost:

Low-effort (acceptable as marketing for v1 with careful wording):

Construct validity from theory: "Items operationalize constructs from Wartha/Schulz, Padberg/Benz, Krajewski." Cite. This is honest, doesn't claim empirical equivalence.
Expert review: invite 3–5 Grundschullehrer or sonderpädagogen to review the item bank for didactic soundness. Document their feedback.
Medium-effort (real evidence):

Pilot with 30–50 children in one or two schools (you have access). Compare your diagnostic's category-level results against teacher-assessed Förderbedarf. Even a small correlation (r > 0.6 at category level) is reportable.
Item analysis: classical test theory parameters (item difficulty, item discrimination). With 30 children per item, you can flag bad items and revise.
High-effort (defensible scientific publication):

Parallel administration with an established (commercial, licensed) diagnostic like HRT or ZAREKI on 100+ children, report correlations. Requires ethics approval, license fees, real time. This is the only way you can defensibly use the word "vergleichbar" in marketing.
For a v1 commercial launch, low-effort is acceptable if your marketing language is calibrated to it ("orientiert an", "auf Grundlage der Forschung von", not "validiert gleichwertig zu"). Build medium-effort during the pilot you're already planning — your pilot data IS your validation evidence if you collect it deliberately.

12. Naming, marketing, and attribution language
What you can write on the product page, the dashboard, the report PDFs:

Acceptable, defensible:

"Numeris/Prozedia ist eine digitale Förderdiagnostik für die Grundschule, entwickelt auf Grundlage der aktuellen mathematikdidaktischen Forschung zur Prävention von Rechenproblemen (Wartha & Schulz, Padberg & Benz, Selter, Krajewski u. a.)."

"Die Diagnostik erfasst zentrale Kompetenzbereiche der Grundschulmathematik: Zählkompetenz, Zahlbegriff, Stellenwertverständnis, Rechenstrategien."

"Konzeptionell orientiert an etablierten Verfahren der präventiven Rechenförderung."

"Wissenschaftliche Grundlage: [Bibliography page]."

Not acceptable, do not write:

"Die digitale Version der iMINT-Kartei."
"Gleichwertig zur Berliner Kartei 'Auf dem Weg zum denkenden Rechnen'."
"Empfohlen von SenBJF / PIKAS / LISUM" (unless they actually do).
"Ersetzt das Schulz-Verfahren."

Product name: Keep your existing "Numeris" / "Prozedia" — already independent of any protected title. Do not add a tagline echoing the iMINT title.

Citations page: include a dedicated page (in dashboard and in PDF reports) that lists your scientific bibliography. This is good academic practice and protects you under §51 UrhG should a court ask whether you're acknowledging your influences.

13. Reviewing the 8 shipped practice exercises
The IMINT_TO_APP_FRAMEWORK.md file states the framework was built around translating PIKAS/iMINT cards into app levels. The 8 shipped skills (Z1, C1.1, C1.2, C2.1, C3.1, C4.1, S1.1, S3.4) need to be audited:

For each shipped exercise:

Identify source: does this exercise correspond to a specific PIKAS card or iMINT card?
Examine derivative depth: are the levels, problem types, sequencing, and visuals modeled on the card's structure? Or are they generic exercises that happen to teach the same skill?
Triage:
Generic exercise teaching standard skill (e.g., "child decomposes 7 into two parts" with own visual design): keep, document independent source.
Identifiable PIKAS card adaptation (matches a specific card's structure, problem types, level progression): rewrite or drop.
iMINT-specific exercise design: rewrite or drop.
This audit is its own multi-day effort. If you cannot afford to rewrite all 8 practice exercises before launch, the alternative is to launch the commercial v1 as diagnostic-only, with practice exercises explicitly out of scope. Phase F (Practice migration in phase1_school_platform.md) is already deferred. That's actually the right legal choice.

14. Timeline and resource estimate
Realistic for a solo developer working part-time, who is also a practicing Grundschullehrer:

Phase	Work	Estimate
1. Foundation	Read or re-read core bibliography. Write construct map (§4). Write blueprint (§5).	3–4 weeks
2. Item development	Write 60 items per §6, including item template files.	6–8 weeks (about 1 item per evening, with thinking time)
3. Item review	Send to 2–3 fellow teachers for review. Revise.	2 weeks (mostly waiting)
4. Skill catalog rewrite	Rewrite 35 skills' descriptions and rationale files.	1 week
5. Förderplan mapping	Build new IfWrong mappings with rationale.	1–2 weeks
6. Migration & testing	Replace CSVs in code, regenerate DB seeds, re-test full diagnostic flow.	1 week
7. Documentation finalization	ADRs, provenance log, bibliography page in dashboard.	1 week
8. Legal review	Fachanwalt für Urheberrecht reviews the artifacts and gives written opinion.	2 weeks elapsed
9. Pilot validation	Run new diagnostic with own school's children. Item analysis. Revise weak items.	4–6 weeks
Total elapsed		5–6 months part-time
If you can recruit a co-author (a Grundschullehrer or Mathematikdidaktiker willing to contribute on revenue share or a flat fee), Phase 2 (item development) parallelizes — they can write half the items while you build the rest. That collapses to ~3 months.

Critical-path items (don't start commercial sales until these are done)
 Item bank fully rewritten and audit-trail complete
 Skill catalog rewritten, PIKAS references removed
 Förderplan mappings derived independently
 Practice exercises either rewritten or removed from commercial scope
 Werktitel "Auf dem Weg zum denkenden Rechnen" / "Erfolgreich rechnen lernen" / "Förderplan nach SenBJF" removed from product surface
 Marketing copy reviewed for UWG §5 risk
 Fachanwalt für Urheberrecht has written opinion in hand
 AVV/DSGVO in place (separate workstream, you already track it)
Until all are checked, the legitimate posture is: free, school-internal, non-commercial use only.

15. What this does NOT change (so you don't over-rewrite)
The app's architecture: stays.
The deployment infrastructure (Supabase, Vercel, Next.js dashboard, Flutter web client): stays.
The diagnostic-administration UX (how questions appear, how answers are entered, dice/audio components, break-off mechanism, resume-across-browser-close): stays.
The teacher dashboard layout: stays.
The QR-ticket and short-code login flow: stays.
The DSGVO/AVV/right-to-erasure infrastructure: stays.
You are rewriting content, not software. The product as engineered is sound and is yours. The pedagogical payload it ships is what needs to change.

16. Single most important rule
For every artifact you ship, you must be able to answer the question: "Why does this exist, and where did it come from?" — without citing iMINT, PIKAS, or Schulz as the answer.

The valid answers are:

"It tests construct X from Padberg/Benz / Wartha-Schulz / Krajewski."
"It was developed by [you] based on the published literature on [topic]."
"It came from expert review feedback from [teacher name] with [credentials]."
"It is the standard didactic vocabulary used across German Grundschulmathematik literature."
The invalid answer is:

"We took this from iMINT/PIKAS/Schulz and changed [some details]."
If you can answer all 60 items, 35 skills, and all mapping rules with valid answers, you have a clean-room product. If even one artifact requires the invalid answer, that one is a liability — fix it before shipping.

17. Recommended next steps, this week
Verify the licenses of the sources you're using. Specifically: confirm in writing what the LISUM/Schulz publication's actual CC license is. Check whether the SenBJF Kartei has any commercial-licensing program. Look up the title in DPMA for trademark registration.
Buy or borrow the core bibliography (§3) if you don't already have them. Padberg/Benz and Wartha/Schulz are the two you'll lean on hardest.
Start §4 construct map as a single document. This is the foundation of everything else and takes maybe 4–6 hours of focused work.
Defer all commercial discussions with potential pilot schools that imply pricing until the rewrite is complete. Frame current pilots as research/development partnerships.
Talk to a Fachanwalt für Urheberrecht early — not for a final opinion, but for a 30-minute consult on whether the plan is on the right track. Roughly €200–€400 for initial consultation. Cheap insurance.
The rewrite is large but bounded. You will know when you are done. After it is done, you have a sellable product whose IP you actually own