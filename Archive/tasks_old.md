# Math App Development Tasks

**Last Updated:** 2025-11-19

**For completed work:** [COMPLETED_TASKS.md](COMPLETED_TASKS.md)
**For full task history:** [Archive/tasks_full.md](Archive/tasks_full.md)

---

## 🎯 CURRENT FOCUS: Phase 2.5 - Completion Tracking & Rewards

**Timeline:** Week 4-6 (In Progress)
**Priority:** HIGH - Foundation for all future skills

### Terminology Note
- **Skill** = Complete learning module (e.g., C1.1, Z1) with multiple levels
- **Level** = Scaffolding stage within a skill (e.g., Level 1, Level 2)
- **Problem** = Individual question within a level
- See [CLAUDE.md](CLAUDE.md) Terminology section for details

### What's Left

**Week 4: Update Remaining Skills (COMPLETE)** ✅
- [x] C2.1 (Order Cards) - ✅ COMPLETE with finale level
- [x] C1.2 (Count the Objects) - ✅ COMPLETE with finale + ExerciseProgressMixin
- [x] C3.1 (Count Forward) - ✅ COMPLETE with finale + ExerciseProgressMixin
- [x] C4.1 (What Comes Next) - ✅ COMPLETE with Level 4 + Level 5 finale + ExerciseProgressMixin
  - Extended to 5 levels (3 card levels + L4 challenge + L5 finale)
  - L4: Two-number sequences (17, ___, ___ or ___, ___, 20)
  - L5: Easier mixed review (range 6-14, 10 problems, 0 errors, <20s)
  - Full state persistence with ExerciseProgressMixin
  - ~3,700 lines total (coordinator + 5 level widgets)

**Week 5: Z1 Completion (CRITICAL)**
- [ ] Z1 (Decompose 10) - Add finale level (easier than L3) + ExerciseProgressMixin
  - **BLOCKER:** Currently NOT completable - L3 is hardest level
  - Proposed finale: Decompose 5-8 (easier than 10)

**Week 6: Testing & Wrap-Up**
- [ ] Test all 6 exercises end-to-end (state persistence, completion tracking)
- [ ] Test reward system (daily, completed, milestone triggers)
- [ ] Update documentation (CLAUDE.md, IMINT_TO_APP_FRAMEWORK.md)
- [ ] Code cleanup (flutter analyze, remove debug prints)

---

## 🔑 CRITICAL REQUIREMENTS

Every skill MUST have:
1. **ExerciseProgressMixin** - Load on init, save every 5 problems + on exit
2. **Finale level** - Easier than hardest card level, MUST be completable
3. **Completion criteria** - Clear time limits, accuracy requirements
4. **State persistence** - Exit/resume works, level unlocks persist

**See:** [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) | [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md)

---

## 📋 Integration Checklist (Per Skill)

Before marking skill complete:
- [ ] ExerciseProgressMixin integrated
- [ ] Finale level exists and tested
- [ ] Completion criteria defined (in code comments)
- [ ] State persistence tested (exit → relaunch → resume)
- [ ] Can reach "completed" status (zero errors + time limits)
- [ ] Reward celebration triggers (if enabled)

---

## 🚀 Next: Phase 2 Skill Sets (ON HOLD)

**Will resume after Phase 2.5 complete**

### SET 1: Foundation Counting ✅ (5/6 skills done)
- [x] C1.1: Count the Dots V2 - ✅ COMPLETE (4 levels + finale)
- [x] C1.2: Count the Objects - ✅ COMPLETE (5 levels + finale)
- [x] C2.1: Order Cards - ✅ COMPLETE (3 levels + finale)
- [x] C3.1: Count Forward - ✅ COMPLETE (3 levels + finale)
- [x] C4.1: What Comes Next - ✅ COMPLETE (3 card levels + L4 challenge + L5 finale)
- [ ] Z1: Decompose 10 - ⚠️ NEEDS FINALE + ExerciseProgressMixin (CRITICAL)

### SET 2: Number Decomposition (Future - 0/6)
Z1.1, Z1.2, Z1.4, Z1.5, Z1.6, Z2.2

### SET 3: Subitizing (Future - 0/6)
Z3.1-Z3.6

### SET 4: Place Value (Future - 0/10)
P1.1-P6.2

**Full roadmap:** [Archive/tasks_full.md](Archive/tasks_full.md) - 120+ skills total

---

## 📖 Key Documentation

**Essential:**
- [IMINT_TO_APP_FRAMEWORK.md](IMINT_TO_APP_FRAMEWORK.md) - Card-based scaffolding framework
- [COMPLETION_CRITERIA.md](COMPLETION_CRITERIA.md) - Completion tracking system
- [REWARDS_SYSTEM_QUICK_REF.md](REWARDS_SYSTEM_QUICK_REF.md) - Reward system overview
- [CLAUDE.md](CLAUDE.md) - Project guide

**Research:**
- `Research/SKILLS_README.md` - 88 skills documentation
- `Research/REWARDS_SYSTEM.md` - Detailed reward spec

**Historical:**
- [COMPLETED_TASKS.md](COMPLETED_TASKS.md) - Phases 1, 1.5, 2 summary
- [Archive/ARCHIVE_IMPLEMENTATIONS.md](Archive/ARCHIVE_IMPLEMENTATIONS.md) - Z1 reference implementation

---

## 📊 Project Status

| Phase | Status | Progress |
|---|---|---|
| Phase 1 (Core) | ✅ Complete | 100% |
| Phase 1.5 (PIKAS) | ✅ Complete | 100% |
| Phase 2 (Skills) | 🔄 In Progress | 5% (6/120+) |
| **Phase 2.5 (Tracking)** | **🔄 In Progress** | **95%** |
| Phase 3 (Polish) | ⏳ Planned | 0% |

**Current Milestone:** Complete Z1 finale → Phase 2.5 DONE → Resume SET 2 skills

---

**Priority:** Finish Z1 finale + ExerciseProgressMixin (last remaining SET 1 skill)
