# ADR 0005 — Why Domains A–D replace the legacy five categories

**Status:** ✅ DECIDED (provisional — Jakob to confirm)
**Date:** 2026-08-29
**Owner:** Jakob
**Task:** `tasks.md` R1.8

## Context

The legacy structure groups items and skills into five categories — Zählen, Zahlzerlegung, Stellenwerte, Grundstrategien, Kombinierte Strategien — inherited from the protected instrument's own partitioning. `rewrite.md` §4 warns that the category names themselves are standard didactic vocabulary (defensible to keep), but the **specific boundaries** — which skill sits in which category, which item tests what — must be derived from our own construct map, not from the legacy arrangement.

## Decision

The construct map and every downstream artifact (blueprint, item bank, skill catalog, Förderplan mappings) are structured around four domains:

- **Domain A — Zahlbegriff** (Zählkompetenz, Anzahlerfassung, Zahlzerlegung)
- **Domain B — Stellenwertverständnis** (Bündelung/Entbündelung, Zahldarstellung)
- **Domain C — Rechenstrategien** (Grundaufgaben ZR10, Strategien mit Zehnerübergang ZR20, Strategien ZR100, flexibles Rechnen)
- **Domain D — Sachsituationen**

## Reasoning

1. The four-pillar model of counting, number decomposition, place value and strategies (Wartha/Schulz 2019) maps directly onto A–D; the KMK competence areas anchor them in the official framework (KMK Bildungsstandards Mathematik Primarstufe 2022; Rahmenlehrplan BE/BB).
2. The boundaries between and within domains — which construct is grouped where, which item operationalises which construct — are our editorial choice, argued from the literature in the construct map (`01-construct-map.md`, `tasks.md` R1.3).
3. The legacy five categories were the protected source's arrangement. Keeping that partitioning wholesale would inherit its selection and arrangement; rebuilding from the construct map demonstrates independent structure even where category *names* coincide by necessity of the standard vocabulary.

## Consequences

- `tasks.md` R5.4: all code and dashboard surfaces that assume the five legacy categories move to Domains A–D.
- Individual legacy category names may coincidentally appear in UI strings — they are standard German didactic terms — but the grouping, boundaries and allocations come from the construct map, and that is where any overlap is documented.
- The Förderplan recommendation ordering (R4.2) is defined over domains and skills, not over legacy category order.
