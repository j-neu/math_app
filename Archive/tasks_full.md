# Math App Development Tasks

**Last Updated:** 2025-11-01

**For completed work history:** [COMPLETED_TASKS.md](COMPLETED_TASKS.md)
**For implementation details:** [ARCHIVE_IMPLEMENTATIONS.md](ARCHIVE_IMPLEMENTATIONS.md)

---

## 🎯 CURRENT FOCUS: Phase 2.5 - Completion Tracking & Rewards

**Status:** Ready to implement (Planning complete)
**Timeline:** 6 weeks (Nov 2 - Dec 13, 2025)
**Priority:** HIGH - Blocks all future exercise work

### What This Phase Adds

- ✨ **Exercise completion tracking** (finished vs completed status)
- ✨ **Persistent progress** (saves level unlocks, accuracy, times across sessions)
- ✨ **Finale levels** (ADHD-friendly Easy→Hard→Easy flow)
- ✨ **Parent reward system** (configurable rewards for practice milestones)
- ✨ **Learning path redesign** (vertical scrolling, milestone grouping, visual states)

**📖 Full Specification:** [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) | [REWARDS_SYSTEM.md](REWARDS_SYSTEM.md)

---

## Phase 2.5 Checklist

### Week 1: Data Models & Foundation ✅ COMPLETE
- [x] Create `lib/models/exercise_progress.dart` (ExerciseProgress + enum)
- [x] Create `lib/models/level_progress.dart` (LevelProgress + ProblemResult)
- [x] Create `lib/models/reward_config.dart` (RewardConfig model)
- [x] Create `lib/models/milestone.dart` (Milestone definitions)
- [x] Extend `lib/models/user_profile.dart` with new fields:
  - [x] Add `Map<String, ExerciseProgress>? exerciseProgress`
  - [x] Add `RewardConfig? rewardConfig`
  - [x] Add `DateTime? lastSessionDate`
  - [x] Add `int totalExercisesCompleted`
  - [x] Add `int exercisesCompletedToday`
  - [x] Update JSON serialization
  - [x] Update copyWith method
- [x] Update `lib/models/scaffold_level.dart`:
  - [x] Add `finale` to ScaffoldLevel enum
- [x] Test save/load with UserService (JSON serialization confirmed working)

**Note:** Non-exhaustive switch warnings for `ScaffoldLevel.finale` will be resolved as exercises are updated in Weeks 2-5.

### Week 2: Exercise Framework
- [x] Create `lib/mixins/exercise_progress_mixin.dart` (reusable progress logic)
- [x] Update **C1.1** (Count Dots V2) as proof-of-concept:
  - [x] Add Level 5: Finale (8-12 dots, structured only, easier)
  - [x] Integrate ExerciseProgressMixin
  - [x] Implement load progress on init
  - [x] Implement save progress on level unlock
  - [x] Implement save progress every 5 problems
  - [x] Implement save progress on exit (WillPopScope)
  - [x] Implement track time per problem (Stopwatch via mixin)
  - [x] Define completion criteria (10 problems, <20s each, zero errors)
  - [x] Test complete flow: start → progress → exit → reload → continue
- [x] **BLOCKER:** Fix non-exhaustive switch warnings in other exercises
  - Automated script corrupted files - need  fixes
  - Files need cleanup and proper finale case addition
- [x] Document C1.1 finale level pattern for reference

### Week 3: Services & UI ✅ COMPLETE
- [x] Create `lib/services/reward_service.dart`:
  - [x] `shouldShowDailyReward()`
  - [x] `shouldShowCompletedReward()`
  - [x] `shouldShowMilestoneReward()`
  - [x] `getNextRewardText()`
  - [x] `markRewardEarned()`
- [x] Extend `lib/services/exercise_service.dart`:
  - [x] `getLearningPathGroupedByMilestone()`
  - [x] `getExercisesByStatus()`
  - [x] `getNextRecommendedExercise()`
  - [x] `isMilestoneComplete()`
  - [x] `getMilestoneProgress()`
- [x] Redesign `lib/screens/learning_path_screen.dart`:
  - [x] Vertical scrolling layout
  - [x] Progress overview card (with daily reward trophy if applicable)
  - [x] Milestone section widgets (with progress bars)
  - [x] Exercise cards (left-right alternating)
  - [x] Visual states: completed (green ✅), finished (blue ✓), in-progress (cyan →), not started (gray)
  - [x] Trophy icons at reward points
  - [x] Reward celebration modals (daily, completed, milestone)
- [x] Add Rewards submenu to `lib/screens/settings_screen.dart`:
  - [x] ListTile navigation to rewards settings
- [x] Create `lib/screens/rewards_settings_screen.dart`:
  - [x] Daily exercise reward checkbox
  - [x] Completed exercise reward checkbox
  - [x] Milestone reward checkbox
  - [x] Add reward text field + button
  - [x] Reward list (delete button)
  - [x] Save to UserProfile
- [ ] Test: Configure rewards → Complete exercise → See celebration

### Week 4: Update Existing Exercises (Part 1) - IN PROGRESS
- [x] Update **C2.1** (Order Cards) - ✅ COMPLETE:
  - [x] Level 1: Show 2-row structure, complete once (was: 3 times)
  - [x] Level 2: Show ALL 20 numbers with 2 missing (was: vertical pairs only)
  - [x] Level 3: Show ALL 20 numbers with 4-6 missing (adaptive)
  - [x] Add Level 4: Finale (2-3 missing, easier than Level 3, completable)
  - [x] Integrate ExerciseProgressMixin (load/save state, track time)
  - [x] Define completion criteria for finale level (10 problems, 100% accuracy, <30s)
  - [ ] Test complete flow with state persistence (ready for manual testing)
- [ ] Update **C1.2** (Count the Objects):
  - [ ] Add Level 5: Finale (easier mixed review, MUST be completable)
  - [ ] Integrate ExerciseProgressMixin (load/save state)
  - [ ] Define completion criteria
  - [ ] Test state persistence
- [ ] Update **C3.1** (Count Forward):
  - [ ] Add Level 4: Finale (forward by 1s/2s, 0-15 range, MUST be completable)
  - [ ] Integrate ExerciseProgressMixin (load/save state)
  - [ ] Define completion criteria
  - [ ] Test state persistence
- [ ] Update **C4.1** (What Comes Next):
  - [ ] Add Level 4: Finale (predecessor/successor 0-15 range, MUST be completable)
  - [ ] Integrate ExerciseProgressMixin (load/save state)
  - [ ] Define completion criteria
  - [ ] Test state persistence

### Week 5: Update Existing Exercises (Part 2) - Z1 Completion
**CRITICAL:** Z1 (Decompose 10) is currently NOT completable - Level 3 is the hardest level.

- [ ] Update **Z1** (Decompose 10):
  - [ ] Add Level 4: Finale (decompose 5-8, easier than 10, MUST be completable)
  - [ ] Integrate ExerciseProgressMixin (load/save state)
  - [ ] Define completion criteria
  - [ ] Test state persistence

### Week 6: Testing & Documentation
- [ ] End-to-end testing of all 6 exercises:
  - [ ] C1.1: Verify state saves/loads, finale completable
  - [ ] C1.2: Verify state saves/loads, finale completable
  - [ ] C2.1: Verify state saves/loads, finale completable
  - [ ] C3.1: Verify state saves/loads, finale completable
  - [ ] C4.1: Verify state saves/loads, finale completable
  - [ ] Z1: Verify state saves/loads, finale completable
- [ ] Test reward system integration:
  - [ ] Daily practice rewards trigger correctly
  - [ ] Completed exercise rewards trigger correctly
  - [ ] Milestone rewards trigger correctly
- [ ] Update documentation:
  - [ ] Update CLAUDE.md with state persistence requirements
  - [ ] Update IMINT_TO_APP_FRAMEWORK.md with completable finale mandate
  - [ ] Document completion criteria patterns for future exercises

---

## 🔑 CRITICAL DESIGN REQUIREMENTS (Added 2025-11-09)

### 1. **ALL Exercises MUST Be Completable**
Every exercise's **finale level** (the last level) MUST be designed to be completable:
- Define clear completion criteria (accuracy, time limits, minimum problems)
- Ensure criteria are achievable by the target age group
- Test that completion status can be reached within reasonable practice time
- **BLOCKER:** No exercise can be considered "done" if finale isn't completable

### 2. **State Persistence is Mandatory**
ALL exercises MUST save and load state:
- **Progress tracking:** ExerciseProgressMixin integration (saves every 5 problems, on exit)
- **Level unlocks:** Once unlocked, stays unlocked (persisted via UserProfile)
- **Problem results:** Track time, accuracy per problem (stored in LevelProgress)
- **Resume capability:** Child can exit and continue from where they left off
- **Status transitions:** notStarted → inProgress → finished → completed

### 3. **Exercise Integration Checklist**
Before marking ANY exercise as complete, verify:
- [ ] ExerciseProgressMixin integrated (load on init, save on exit/every 5 problems)
- [ ] Finale level exists and is easier than hardest card-prescribed level
- [ ] Completion criteria defined and tested (can reach "completed" status)
- [ ] State persistence tested (exit → relaunch → progress restored)
- [ ] Level unlocks persist across app restarts
- [ ] Reward celebrations trigger on completion (if rewards enabled)

**See:** [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) for full specification

---
- [ ] Test all 7 exercises:
  - [ ] Progress saves correctly
  - [ ] Progress loads on return
  - [ ] Completion criteria work
  - [ ] Finale levels unlock properly

### Week 6: Testing & Documentation
- [ ] End-to-end testing:
  - [ ] New user → diagnostic → learning path shows correctly
  - [ ] Complete exercise → progress saves → status updates
  - [ ] Learning path filters by status
  - [ ] Rewards trigger correctly (daily, completed, milestone)
  - [ ] App restart preserves all progress
- [ ] Edge case testing:
  - [ ] Incomplete exercises handled correctly
  - [ ] Reset progress works
  - [ ] Multiple users don't interfere
- [ ] Update documentation:
  - [ ] CLAUDE.md (update exercise count, status)
  - [ ] COMPLETION_CRITERIA.md (add any learnings)
  - [ ] REWARDS_SYSTEM.md (add any adjustments)
  - [ ] README.md (update feature list)
- [ ] Code cleanup:
  - [ ] Run `flutter analyze` (fix warnings)
  - [ ] Remove debug prints
  - [ ] Add code comments to complex logic
- [ ] Create summary document:
  - [ ] Phase 2.5 completion summary
  - [ ] Move to COMPLETED_TASKS.md

---

## 📚 Exercise Creation Framework

**Every new exercise MUST include:**

1. **Read the card** - Extract scaffolding from "Wie kommt die Handlung in den Kopf?"
2. **Card-prescribed levels** - Implement exact levels from card (typically 2-4)
3. **Finale level** - Add easier mixed review (Easy→Hard→Easy)
4. **Progress tracking** - Integrate ExerciseProgressMixin, save/load from UserProfile
5. **Completion criteria** - Define time limits per problem, accuracy requirements
6. **Skill tags** - Tag with appropriate skills from taxonomy
7. **No-fail feedback** - Hints, visual safety net, never say "wrong"

**📖 Full Framework:** [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md)

---

## 🚀 Future Work: Phase 2 Exercise Sets

**Status:** ON HOLD until Phase 2.5 complete

All future exercises will use the new completion tracking system and finale level pattern.

### SET 1: Foundation Counting (Current - 7/7 done)
- [x] C1.1: Count the Dots V2 (counting_1) - 4 card levels + finale
- [ ] C1.2: Count the Objects (counting_1) - 3 card levels + finale --REMOVE
- [ ] C2.1: Order Cards to 20 (counting_2) - 3 card levels + finale
- [ ] C3.1: Count Forward to 20 (counting_3) - 3 card levels + finale
- [ ] C4.1: What Comes Next? (counting_4, counting_5) - 3 card levels + finale
- [ ] C10.1: Place Numbers on Line (counting_10, counting_11) - 3 card levels + finale
- [ ] Z1: Decompose 10 (decomposition_1, decomposition_3) - 3 card levels + finale

### SET 2: Number Decomposition Basics
**Skills:** decomposition_1-5, decomposition_15
**Widgets Needed:** WendeplättchenWidget, RechenschiffchenWidget

- [ ] Z1.1: Decompose Numbers 2-9
- [ ] Z1.2: Decompose on Boat
- [ ] Z1.4: All Ways to Make 10
- [ ] Z1.5: Decompose 20
- [ ] Z1.6: Flip Card Game
- [ ] Z2.2: Complete to 10

### SET 3: Quick Recognition & Subitizing
**Skills:** decomposition_6-8, decomposition_11
**Widgets Needed:** FlashCardWidget, PatternDisplayWidget

- [ ] Z3.1: Flash Recognition to 10
- [ ] Z3.2: Flash Recognition to 20
- [ ] Z3.3: Dice Patterns
- [ ] Z3.4: Five-Frame Patterns
- [ ] Z3.5: Quick See on Boat
- [ ] Z3.6: How Many Without Counting?

### SET 4: Place Value Foundations
**Skills:** place_value_1-6
**Widgets Needed:** DienesBlocksWidget (ESSENTIAL), StellentafelWidget, HundredChartWidget

- [ ] P1.1: Bundle 10 Ones
- [ ] P1.2: Make Bundles to 100
- [ ] P2.1: Show Number with Blocks
- [ ] P2.2: Read the Blocks
- [ ] P3.1: Stellentafel Practice
- [ ] P4.1: Hear and Write Numbers
- [ ] P4.2: Inversion Challenge
- [ ] P5.1: Tens-Ones Quiz
- [ ] P6.1: 100-Chart Patterns
- [ ] P6.2: Jump on 100-Chart

### SET 5: Skip Counting & Patterns
**Skills:** counting_6-9

- [ ] C2.2: Skip by 2s on 100-Chart
- [ ] C2.3: Skip Count by 5s
- [ ] C2.4: Skip Count by 10s
- [ ] C2.5: Find the Pattern
- [ ] C2.6: Skip Count on Boat

### Sets 6-18 (Future)
**Total:** 110+ additional exercises covering:
- Finger & dice strategies (6 ex)
- Doubling & halving (10 ex)
- Commutativity (5 ex)
- Decade operations (8 ex)
- Power of 5/10 strategies (8 ex)
- Near-doubles (6 ex)
- Partial steps (10 ex)
- Number structures (6 ex)
- Advanced 2-digit (10 ex)
- Ordinal numbers (4 ex)
- Representation networking (8 ex)
- Operational sense (10 ex)
- Number line strategies (8 ex)

**📖 Future exercise details:** See ARCHIVE version of tasks.md if needed

---

## 🧩 Widget Library Status

### Existing (3)
- ✅ NumberLineWidget
- ✅ TwentyFrameWidget
- ✅ Custom Painters (Star, Heart, Triangle, Diamond)

### Critical Priority (Build for SET 2-4)
- [ ] DienesBlocksWidget (Place value - SET 4)
- [ ] RechenschiffchenWidget (Boat 5+5 - SET 2)
- [ ] HundredChartWidget (10×10 grid - SET 4-5)
- [ ] FlashCardWidget (Subitizing - SET 3)
- [ ] WendeplättchenWidget (Two-color counters - SET 2)

### High Priority (Build Soon)
- [ ] FingerWidget
- [ ] Make10VisualizerWidget
- [ ] StepVisualizerWidget
- [ ] EmptyNumberLineWidget
- [ ] MarkedNumberLineWidget

---

## 📖 Key Documentation

### Essential Reading
- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Scaffolding + finale level design
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) - Completion tracking system
- [REWARDS_SYSTEM.md](REWARDS_SYSTEM.md) - Parent reward configuration
- [CLAUDE.md](CLAUDE.md) - Project guide for AI
- [adhd guidelines.md](adhd%20guidelines.md) - ADHD design principles

### Research Materials
- `Research/SKILLS_README.md` - 88 skills documentation
- `Research/skills_taxonomy.csv` - Complete skill catalog
- `Research/MathApp_Diagnostic_with_skills.csv` - 59 diagnostic questions
- `Research/iMINT-Kartei_190529.pdf` - iMINT cards (German)
- `Research/PIKAS_Analysis.md` - 36/58 PIKAS cards analyzed

### Historical Context
- [COMPLETED_TASKS.md](COMPLETED_TASKS.md) - Phases 1, 1.5 summary
- [ARCHIVE_IMPLEMENTATIONS.md](ARCHIVE_IMPLEMENTATIONS.md) - First 4 exercises detailed notes

---

## 🎓 Development Philosophy

**Research-Informed, App-Adapted:**
- **iMINT Kartei:** Diagnostic-first approach, strategy-focused practice
- **PIKAS:** Connecting representations (Action/Image/Symbol)
- **ADHD:** Short lessons, immediate feedback, concrete visuals, no-fail approach

**Skill System:** 88 semantic IDs (`counting_1`, `decomposition_3`, etc.)
- 76 iMINT skills: counting, decomposition, place value, strategies
- 12 PIKAS skills: ordinal, representation, operational sense, number line

**Completion Tracking:**
- `notStarted` → `inProgress` → `finished` (all levels unlocked) → `completed` (mastered with zero errors + time limits)

---

## 📊 Project Status Summary

| Phase | Status | Progress | Notes |
|---|---|---|---|
| **Phase 1** | ✅ Complete | 100% | Core architecture, diagnostic, navigation |
| **Phase 1.5** | ✅ Complete | 100% | PIKAS integration, 88 skills |
| **Phase 2** | 🔄 In Progress | 6% | 7/120+ exercises (SET 1 complete) |
| **Phase 2.5** | ⏳ Ready | 0% | Completion tracking & rewards (6 weeks) |
| **Phase 3** | ⏳ Planned | 0% | UI polish, ADHD features, localization |
| **Phase 4** | ⏳ Planned | 0% | Content expansion, beta testing |

**Next Milestone:** Phase 2.5 complete (Dec 13, 2025)

---

**Current Priority:** Complete Phase 2.5 checklist before building new exercises
