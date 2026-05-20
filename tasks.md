# Math App Master Task List

**Last Updated:** 2026-05-20
**Goal:** Complete feature parity with research frameworks (iMINT/PIKAS) and prepare for beta release.

> Pilot platform issues (deployed `prozedia-portal` + `prozedia-app`) live in [phase1_school_platform.md](phase1_school_platform.md), not here.

---
## 🛠 Widget Library Needs
**Critical for Sets 2-4:**
- [x] `DienesBlocksWidget` (Place Value)
- [x] `RechenschiffchenWidget` (Boat 5+5)
- [x] `HundredChartWidget` (10x10 Grid)
- [x] `FlashCardWidget` (Subitizing)
- [x] `WendeplättchenWidget` (Two-color counters)

## Phase 2.5: QA & Bug Fixes (Set 1)

**Priority:** High
**Goal:** Ensure the first 6 exercises (Set 1) are flawless, persistent, and track completion correctly.

### 1. Z1: Decompose 10 (Completion)
- [ ] **Integrate `ExerciseProgressMixin`:** Update `exercises/decompose_10_exercise.dart`.
- [ ] **Verify Persistence:** Ensure state saves/loads correctly.
- [ ] **UI Polish:** Update UI to match new visual aesthetic (MinimalistExerciseScaffold pattern).

### 2. Critical Bug Fixes
- [ ] **Level Completion Logic:** Fix issues where levels hang after 10 problems (no transition/dialog).
  - Verify `_onProblemComplete` checks `currentProblemIndex >= totalProblems`.
  - Verify `_onLevelComplete` triggers correctly.
- [ ] **Android Rendering:** Fix black background issues (e.g., C1.1, C1.2, Z1).
  - Ensure all Scaffolds/Containers have explicit `backgroundColor: Colors.white` (or theme equivalent).

### 3. Set 1 Quality Assurance
**Scope:** C1.1, C1.2, C2.1, C3.1, C4.1, Z1
- [ ] **Audit Level Switching:** Verify auto-advance works for all levels.
- [ ] **Audit Completion Marking:** Ensure "Completed" status (green check) only triggers when criteria are met (accuracy + time) on the final level.
- [ ] **Retroactive Difficulty Check:** Review all levels against [DIFFICULTY_CURVE.md](DIFFICULTY_CURVE.md).

---

## Phase 3: Basic Strategies (Set 5)

**Priority:** MEDIUM (Next Focus)
**Goal:** Implement strategy-based skills (Finger patterns, Dice patterns, Doubling).

**Widgets:** `FingerDisplayWidget`, `DiceWidget`, `MirrorWidget`
- [x] **S1.1: Fingerblitz** (`basic_strategy_1`) - Recognize finger patterns (0-10) instantly.
- [x] **S1.2: Finger Folding** (`basic_strategy_2`) - Simple addition/subtraction by folding fingers.
- [x] **S2.3: Opposite Change** (`strategy_opposite_change_1`) - One marker flips color, total remains same.
- [ ] **S1.3: Plus/Minus 1 or 2** (`basic_strategy_3`) - Modify finger patterns by ±1/2.
- [ ] **S2.1: Dice Patterns** (`basic_strategy_5`) - Recognize and modify dice patterns (±1/2).
- [x] **S3.1: Doubling with Mirror** (`basic_strategy_7`) - Visual doubling using a mirror metaphor (ZR10).
- [x] **S3.2: Doubling with Mirror** (`basic_strategy_7`) - Visual doubling using a mirror metaphor (ZR20).
- [x] **S3.3: Doubling with Fingers** (`basic_strategy_8`) - 5+5=10, 3+3=6 using hands.
- [x] **S3.4: Doubling Boat** (`basic_strategy_9`, `basic_strategy_10`) - Doubling with Rechenschiffchen (5+5 structure).

---

## 📊 Phase 4: Diagnostic & Reporting

**Status:** ✅ Complete (shipped 2026-05-15). Manually verified end-to-end. Possible future polish: PDF wording/structure tweaks.
**Priority:** Low
**Goal:** Turn diagnostic results into an actionable learning plan.

### 1. Diagnostic Logic Review
- [x] **Review Skippability:** Reduce the number of skippable questions to ensure valid results (Default: Complete Test).
- [x] **Time Tracking:** Response time is captured per question; feeds slow-response flag in Förderplan generator.

### 2. Report Generation System
- [x] **Create `SkillCatalog`** — shared singleton that loads `skills_taxonomy.csv` once; replaces per-service CSV loaders.
- [x] **Create `SkillRecommendation` + `Foerderplan` models** — typed output of the report generator.
- [x] **Create `DiagnosticReportGenerator`** — `generate(UserProfile, DiagnosticSession) → Foerderplan`. Collects failed/timeout question skill IDs, dedupes, sorts pedagogically (Zählen → Zahlzerlegung → Stellenwerte → Grundstrategien → Kombinierte Strategien), computes category stats and slow-response flag.
- [x] **Create `DiagnosticReportScreen`** — native Flutter screen (German). Kurzer Förderplan (3 skills), Kategorie-Übersicht, collapsible Vollständiger Förderplan, collapsible Detail-Tabelle, PDF export, "Weiter zum Üben" → LearningPathScreen.
- [x] **Rewrite `PdfReportService`** — new signature `generatePdf(Foerderplan, DiagnosticSession)`; German throughout; mirrors screen layout.
- [x] **Wire navigation** — diagnostic completion now builds `Foerderplan` and pushes `DiagnosticReportScreen` instead of going directly to LearningPathScreen.
- [x] **Fix diagnostic CSV** — corrected typos, green/red colour mismatches, truncated English text, over-broad skill mappings (Q15–18, Q36–37, Q47), documented all valid Q21 dice decompositions.
- [x] **Diagnostic UX polish** — Q21 generated dice + structured input, Q33/Q34 correct answers swapped, Q38 audio dictation (web/Android/Windows), Q46 generated dice with red/blue comparison, image zoom-on-tap (1.5× popup), full German UI, autofocus + Enter-to-next-field + digit-only input, drag-anywhere reorder cards, detail-table wrapping.

---

## ⚙️ Phase 5: Core Systems

**Priority:** Low

### 1. Reward System (Implementation)
- [ ] **Settings UI:** Complete `RewardsSettingsScreen` (parent configuration).
- [ ] **Logic:** Finalize `RewardService` to trigger:
  - Daily Streak Reward.
  - Exercise Completion Reward.
  - Milestone Completion Reward.
- [ ] **Visuals:** Add animations/modals for reward triggers.

### 2. Analytics & Usage Tracking
- [ ] **Local Analytics Service:**
  - Track session duration.
  - Track frequency of use (daily/weekly).
  - Track "Struggle Points" (levels where user quits or fails repeatedly).
- [ ] **Parent Dashboard (Optional):** Simple view of "Time Spent this Week".

---

## 📚 Phase 6: Content Expansion (The Big Build)

**Priority:** MEDIUM (Parallelizable)
**Goal:** Implement remaining 110+ exercises.

### Set 2: Number Decomposition Basics (Z1.x)
**Widgets:** `WendeplättchenWidget` (Two-color counters), `RechenschiffchenWidget` (Boat)
- [ ] **Z1.1:** Decompose Numbers 2-9
- [ ] **Z1.2:** Decompose on Boat
- [ ] **Z1.4:** All Ways to Make 10
- [ ] **Z1.5:** Decompose 20
- [ ] **Z1.6:** Flip Card Game
- [ ] **Z2.2:** Complete to 10

### Set 3: Subitizing & Quick Recognition (Z3.x)
**Widgets:** `FlashCardWidget`, `PatternDisplayWidget`
- [ ] **Z3.1:** Flash Recognition to 10
- [ ] **Z3.2:** Flash Recognition to 20
- [ ] **Z3.3:** Dice Patterns
- [ ] **Z3.4:** Five-Frame Patterns
- [ ] **Z3.5:** Quick See on Boat
- [ ] **Z3.6:** How Many Without Counting?

### Set 4: Place Value Foundations (P1.x - P6.x)
**Widgets:** `DienesBlocksWidget` (Base-10 Blocks), `StellentafelWidget` (Place Value Chart), `HundredChartWidget`
- [ ] **P1.1:** Bundle 10 Ones
- [ ] **P1.2:** Make Bundles to 100
- [ ] **P2.1:** Show Number with Blocks
- [ ] **P2.2:** Read the Blocks
- [ ] **P3.1:** Stellentafel Practice
- [ ] **P4.1:** Hear and Write Numbers
- [ ] **P4.2:** Inversion Challenge
- [ ] **P5.1:** Tens-Ones Quiz
- [ ] **P6.1:** 100-Chart Patterns
- [ ] **P6.2:** Jump on 100-Chart

### Set 5: Strategies (Basic & Advanced)

#### Advanced Strategies (Future)
- [ ] **Commutativity** (Tauschaufgaben).
- [ ] **Decade Operations** (Rechnen mit Zehnerzahlen).
- [ ] **Near-Doubles** (Nachbaraufgaben - e.g., 6+7 is 6+6+1).
- [ ] **Partial Steps** (Schrittweise Rechnen).

---


