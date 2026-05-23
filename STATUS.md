# Project Status

**Last updated:** 2026-05-23

One-screen view of what's shipped, what's active, and what's paused. For the doc map, see [DOCS_INDEX.md](DOCS_INDEX.md). For the active plan, see [phase1_school_platform.md](phase1_school_platform.md).

---

## Shipped

- **Diagnostic + Förderplan flow** (Phase 0, 2026-05-15). `SkillCatalog`, `SkillRecommendation`/`Foerderplan` models, `DiagnosticReportGenerator`, native German `DiagnosticReportScreen`, German `PdfReportService`, diagnostic CSV fixes, full UI polish (Q21 dice / Q38 audio / Q46 dice / image zoom / autofocus / Enter-nav / digit-only / drag-anywhere reorder).
- **Full German UI** (Phase 0.5). Locale infra in `main.dart`, ~90 widget files translated, platform names switched to `Numeris`, `flutter analyze` clean.
- **Two diagnostic instruments.** iMINT CSV (98 questions, ordered Zählen → Zahlzerlegung → Stellenwerte → Grundstrategien → Kombinierte Strategien) and Schulz CSV (151 questions, 8 blocks, with `Block`/`TaskCode`/`Zahlenraum`/`PairId`). Must never be mixed in reports — see [memory: project-two-diagnostics](../../.claude/projects/c--Users-jakob-StudioProjects-Math-App/memory/project_two_diagnostics.md).
- **Supabase EU backend** (Phase A, 2026-05-17). Project ref `zzxqeqwffexythqzjkxr` (Frankfurt). 9-table schema with RLS, seeded with 87 skills + diagnostic questions. Edge functions: `diagnostic-sessions`, `diagnostic-results`, `foerderplan-generate`, `foerderplan-pdf`, `delete-school-data`. Storage bucket `pdf-cache`. Smoke-tested end-to-end.
- **Teacher dashboard** (Phase B, 2026-05-17). Next.js 14 + Supabase SSR + Tailwind at `dashboard/`. Login, Klassen-Übersicht, Klasse-Detail with QR ticket generation, Förderplan-Ansicht (brief + category + full + detail-table + PDF export), Aggregate class table.
- **Flutter Web student client** (Phase C, 2026-05-17). `go_router`, `ApiService`, `/s/:ticket` route, `WebDiagnosticEntryScreen`, `DiagnosticCompleteScreen` (no Förderplan on kid screen). Deployed to Vercel `fra1` as `prozedia-app`.
- **Pilot polish** (Phase D, ~80%). DSGVO pages (`/datenschutz`, `/impressum`), CookieBanner, footer in dashboard layout, `delete-school-data` edge function (right-to-erasure with cascade), audio moved to Supabase Storage.
- **Phase D.5 blockers fixed** (2026-05-20 → 2026-05-22). Diagnostic resume across browser close, Q47 audio, Förderplan lazy-generation on view, full 98-question web build, bulk QR PDF for a class, short-URL school login (slug + 4-char short code, no ticket expiry).
- **Vercel deployments.** `prozedia-portal` (git-connected to `main`) and `prozedia-app` (CLI-only deploys). See [memory: reference-vercel](../../.claude/projects/c--Users-jakob-StudioProjects-Math-App/memory/reference_vercel.md).

## Active

Work in flight or queued in priority order:

1. **Phase 1.1 fixes** (2026-05-23). See [phase1.1_fixes.md](phase1.1_fixes.md). All 11 issues implemented, awaiting deploy. Deploy checklist in `phase1.1_fixes.md`.
2. **Fill legal placeholders** in `dashboard/app/impressum/page.tsx` and `dashboard/app/datenschutz/page.tsx` (`[NAME/ADRESSE/EMAIL]`).
2. **AVV/DPA signature** with Supabase (`supabase.com/legal/dpa`) and with each pilot school before data processing.
3. **One-page German teacher onboarding document.**
4. **Cross-browser smoke** of the Flutter web client (iPad Safari, Android Chrome, Firefox) — deferred to pilot day-1 unless something specific surfaces sooner.
5. **Phase E pilot scheduling** — real classroom at one or two schools once items 1–3 land.
6. **Schulz diagnostic integration** into the platform (optional, scope TBD) — Schulz CSV exists but isn't wired into the dashboard/edge functions yet.

## Paused

The practice-exercise engine. Eight skills live in code (Z1, C1.1, C1.2, C2.1, C3.1, C4.1, S1.1, S3.4) and stay shipped. No new skills planned until pilot ships.

Framework docs that govern future practice work stay at the project root but are flagged as paused in [DOCS_INDEX.md](DOCS_INDEX.md):

- `IMINT_TO_APP_FRAMEWORK.md`
- `DIFFICULTY_CURVE.md`
- `COMPLETION_CRITERIA.md`
- `EXERCISE_DESIGN_SYSTEM.md`
- `COMMON_PITFALLS.md`
- `REWARDS_SYSTEM_QUICK_REF.md`
- `practice_skill_plan.md`

Old `tasks.md` (now `Archive/tasks_2026-05.md`) captured the original Phase 2/2.5/3/5/6 plan for this work.

## Quick start

```bash
# Flutter app (single-device dev mode)
cd math_app && flutter pub get && flutter run

# Flutter web build (then deploy from build/web/)
cd math_app && flutter build web --no-tree-shake-icons

# Teacher dashboard
cd dashboard && npm install && npm run dev   # http://localhost:3000

# Supabase backend
cd backend && supabase db push
cd backend && supabase functions deploy <name>
```

For credentials and deployment commands, see the memory references linked above.
