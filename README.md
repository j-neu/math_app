# Math App - Research-Based Learning for Young Children

A Flutter-based math learning application for pre-1st to 4th grade students, with special focus on supporting children with ADHD. Built on iMINT and PIKAS pedagogical research frameworks.

---

## Project Status

**Phase:** 2 - Exercise Engine
**Progress:** 4/120+ exercises complete (3%)
**Last Updated:** 2025-10-30

### Completed
- ✅ Phase 1: Core Architecture (Diagnostic, Navigation, User Profiles)
- ✅ Phase 1.5: PIKAS Integration (88 skills, sufficient for Phase 2)
- ✅ Card-Based Scaffolding Framework (follows iMINT/PIKAS card prescriptions)
- ✅ 4 functional exercises: Z1, C1.1 (4-level), C1.2, C2.1

---

## Documentation Structure

### Essential Files (Read These First)
1. **[CLAUDE.md](CLAUDE.md)** - Main project guide (11KB)
   - Quick start commands
   - 3-level scaffolding framework summary
   - Architecture overview
   - Exercise creation checklist

2. **[IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md)** - Core pedagogical framework (13KB)
   - Complete 3-level scaffolding methodology
   - Translation rules (physical → digital)
   - "Wie kommt die Handlung in den Kopf?" implementation guide

3. **[tasks.md](tasks.md)** - Current/future work roadmap (11KB)
   - Phase 2 exercise sets (18 sets, 120-150 exercises)
   - Widget library status
   - Current focus: SET 1 completion

4. **[adhd guidelines.md](adhd%20guidelines.md)** - ADHD design principles (3KB)
   - 7 core principles from research
   - Concrete & visual learning
   - No-fail approach

### Historical Context
5. **[COMPLETED_TASKS.md](COMPLETED_TASKS.md)** - Brief history (7KB)
   - Phase 1 & 1.5 summary
   - 4 completed exercises overview
   - Key architectural decisions

6. **[ARCHIVE_IMPLEMENTATIONS.md](ARCHIVE_IMPLEMENTATIONS.md)** - Detailed implementation notes (11KB)
   - Z1, C1.1, C1.2, C2.1 complete documentation
   - Reusable patterns
   - Common issues & solutions

---

## Quick Start

```bash
cd math_app
flutter pub get
flutter run
```

**For AI assistance:** Start by reading [CLAUDE.md](CLAUDE.md)

**For new developers:** Read in order:
1. CLAUDE.md (overview)
2. IMINT_TO_APP_FRAMEWORK.md (framework)
3. adhd guidelines.md (design principles)
4. tasks.md (current work)

---

## Key Concepts

### 3-Level Scaffolding Framework
Every exercise implements progressive scaffolding:
- **Level 1:** Guided exploration (manipulate, observe)
- **Level 2:** Supported practice (visual shown, child writes)
- **Level 3:** Independent mastery (visual hidden, memory work)

**Purpose:** Answer "Wie kommt die Handlung in den Kopf?" (How does action become mental?)

### 88 Skills System
- 76 iMINT skills: `counting_1` through `combined_strategy_20`
- 12 PIKAS skills: `ordinal_`, `representation_`, `operation_sense_`, `number_line_`
- Format: `category_number` (self-documenting)

### ADHD-Informed Design
- Short sessions (15 min max)
- Immediate feedback
- No-fail approach (never say "wrong")
- Concrete & visual
- Low cognitive load

---

## Project Structure

```
Math_App/
├── math_app/                          # Flutter app
│   ├── lib/
│   │   ├── models/                    # Data models
│   │   ├── screens/                   # Full-screen UI
│   │   ├── widgets/                   # Level-specific widgets
│   │   ├── exercises/                 # Exercise coordinators
│   │   └── services/                  # Business logic
│   └── test/
├── Research/                          # Pedagogical materials
│   ├── SKILLS_README.md              # 88 skills documentation
│   ├── skills_taxonomy.csv           # Complete skill catalog
│   ├── MathApp_Diagnostic_with_skills.csv
│   ├── PIKAS_Analysis.md             # 36/58 cards analyzed
│   └── iMINT-Kartei_190529.pdf
├── CLAUDE.md                          # Main project guide
├── IMINT_TO_APP_FRAMEWORK.md         # Core framework
├── tasks.md                           # Current roadmap
├── adhd guidelines.md                 # Design principles
├── COMPLETED_TASKS.md                 # History
└── ARCHIVE_IMPLEMENTATIONS.md         # Detailed notes
```

---

## Development Phases

### Phase 1: Core Architecture ✅ COMPLETE
- Flutter project setup
- Diagnostic test (59 questions)
- Navigation & user profiles
- Semantic skill IDs system

### Phase 2: Exercise Engine (IN PROGRESS - 3%)
- **Target:** 120-150 exercises covering 88 skills
- **Current:** 4 exercises complete
- **Focus:** SET 1 - Foundation Counting (3/6 done)

### Phase 3: UI Polish & ADHD Features (PLANNED)
- Gamification
- Helper character
- Parent dashboard
- Localization (DE/EN)

### Phase 4: Content Expansion & Beta Testing (PLANNED)
- Remaining 22 PIKAS cards
- Beta testing
- Algorithm refinement

---

## Technologies

- **Framework:** Flutter
- **State Management:** Riverpod
- **Language:** Dart
- **Platforms:** Web, Android (iOS future)

---

## Research Foundation

### iMINT Kartei
- Diagnostic-first approach
- 76 skills across 5 categories
- Strategy development focus
- "Ablösung vom zählenden Rechnen"

### PIKAS FÖDIMA
- Conceptual understanding
- Connecting representations
- 58 diagnostic cards
- Rich activity repertoire

**See [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) for synthesis**

---

## Contributing

When adding exercises:
1. Follow 3-Level Scaffolding Framework
2. Document source (iMINT/PIKAS card)
3. Answer "Wie kommt die Handlung in den Kopf?"
4. Tag with appropriate skill IDs
5. Implement no-fail feedback

**See [CLAUDE.md](CLAUDE.md) Exercise Creation Checklist**

---

## License

[To be determined]

---

**For questions or guidance, see [CLAUDE.md](CLAUDE.md)**
