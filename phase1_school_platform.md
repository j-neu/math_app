# School Platform Foundation

**Status:** Phases A ✅ + B ✅ + C ✅ + D.5 ✅ done. Phase D in progress (AVV + teacher onboarding doc remaining). Phase E (real pilot) ready to schedule.
**Created:** 2026-05-15
**Last updated:** 2026-05-23
**Owner:** Jakob (solo)
**Horizon:** 3–6 months elapsed, part-time. First pilot school using it by ~2026 Q4 if started in earnest after current diagnostic work ships.

---

## Context

The Flutter app today is a **single-device, offline-first** tool. Today's `UserProfile` (see `math_app/lib/services/user_service.dart`) is a single JSON blob in `shared_preferences`; there is **no networking code, no auth, no concept of teacher / class / school**. The app has 160 Dart files / ~47k LOC, dominated by exercise widgets. Flutter web is target-enabled but unverified.

A teacher who wants to use this in a real classroom has no path. They cannot:
- Hand out a link or QR to kids without installing anything.
- See results across kids in their class on their own screen.
- Re-print a Förderplan a week later without visiting that student's tablet.
- Add or remove students without touching every device.

Until a teacher can do those four things, the product is a demo — not a tool. Pilot schools are willing; the gap between "willing" and "actually deployable" is closed by the work below.

**The decision is to pivot from "local Flutter app" to a "browser-based diagnostic for kids + web dashboard for teachers, backed by a multi-tenant EU-hosted backend."** Pricing is deferred to after the pilot validates value (free for pilot schools).

This plan is the work that follows the diagnostic report MVP (`Archive/phase0_tasks.md`, shipped) and supersedes the practice-engine roadmap (`Archive/tasks_2026-05.md`, paused). It does **not** include practice exercises in v1 of the platform — diagnostic only. Practice migration is a future phase.

---

## Strategic decisions (locked)

| Decision | Choice | Reasoning |
|---|---|---|
| Student client | Flutter Web — kids open URL or scan QR | Zero install, fastest to a working pilot. Performance hit acceptable for 20-min diagnostic. |
| Teacher dashboard | Separate web app (Next.js + React, hosted EU) | Flutter Web is bad at forms/tables/exports/SEO. Teacher UX deserves real web. |
| Backend | **Supabase EU (Frankfurt)** | Postgres + auth + storage + RLS in one. DSGVO/AVV available. Open-source escape hatch. Solo-dev tractable. |
| Hosting region | EU only (Supabase Frankfurt; dashboard + Flutter web on Vercel Frankfurt `fra1`) | DSGVO + Schulträger procurement won't accept US data flow. Vercel CLI authenticated + MCP plugin installed 2026-05-17. |
| Authentication | Teachers: email + password (Supabase Auth). Students: anonymous JWT bound to single-use **session ticket** URL/QR. | Kids in Grundschule (6–10) can't manage accounts. Teacher-mediated identity. |
| Monetization | Free for pilot schools. Pricing model decided after Pilot data. | B2B EdTech in DE — no school signs a contract for unproven software. |
| Multi-diagnostic | Schema supports N diagnostics from day 1 (not just "the diagnostic"). | User wants other tests later; retrofit is expensive, prep is cheap. |
| Förderplan generation | **Server-side** (TypeScript port of `DiagnosticReportGenerator`). | Single source of truth. Dashboard can re-render PDF anytime, no Flutter dependency on client. |
| PDF generation | Server-side (Puppeteer or `pdf-lib`). | Drop client-side `pdf` + `printing` packages from the web build — they bloat the Flutter Web bundle. |

---

## Target architecture

```
┌─────────────────────────────────────────────────────────────┐
│ STUDENT CLIENT — Flutter Web                                │
│ URL: diagnostic.example.de/s/<session-ticket>               │
│ - Loads diagnostic by ID from API                           │
│ - Submits each answer (or batch) to API                     │
│ - Stateless; no local user storage                          │
└────────────────┬────────────────────────────────────────────┘
                 │ HTTPS (Bearer = session ticket JWT)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ BACKEND — Supabase EU (Frankfurt)                           │
│ - Postgres + Row-Level Security                             │
│ - Auth (teachers)                                           │
│ - Edge Functions: foerderplan generation, PDF render        │
│ - Storage: PDF cache, audio assets                          │
└────────────────▲────────────────┬───────────────────────────┘
                 │                │
                 │ HTTPS (Teacher │ HTTPS
                 │  JWT)          │
┌────────────────┴──────────────┐ │
│ TEACHER DASHBOARD             │ │
│ Next.js + React, hosted EU    │ │
│ - Login                       │ │
│ - Create class                │ │
│ - Generate student session    │ │
│   tickets + QR codes          │ │
│ - View per-student Förderplan │ │
│ - Class-level overview        │ │
│ - Export PDFs                 │ │
└───────────────────────────────┘ │
                                  ▼
                       (later: parent app, kid practice app)
```

---

## Data model (Postgres / Supabase)

Drafted; bend before implementation. Multi-tenant via RLS on `school_id`.

```
schools                     -- one row per Schule (pilot: hand-created)
  id (uuid)
  name (text)
  region (text)            -- "Berlin", "Brandenburg"…
  created_at

teachers                    -- auth.users mirror (Supabase auth)
  id (uuid, fk auth.users)
  school_id (fk schools)
  display_name
  role                     -- 'teacher' | 'school_admin'

classes                     -- "Klasse 2a"
  id (uuid)
  school_id (fk)
  name
  grade (int)
  teacher_id (fk teachers, nullable — class can have multiple teachers via join later)

students                    -- pseudonymized; what teacher types is what's stored
  id (uuid)
  class_id (fk)
  display_name             -- "Lara M." or "S03" — teacher decides
  age (int, nullable)
  external_ref (text, nullable)  -- teacher's own code, optional

session_tickets             -- single-use URL/QR for a student to start a diagnostic
  id (uuid)
  student_id (fk)
  diagnostic_id (fk diagnostics)
  expires_at
  consumed_at (nullable)
  jwt_jti (text)           -- for revocation

diagnostics                 -- the test definitions; today's CSV becomes row #1
  id (uuid)
  slug                     -- 'imint-grundschule-zr20'
  name_de
  version (int)
  question_count

diagnostic_questions        -- ports MathApp_Diagnostic_with_skills.csv
  id (uuid)
  diagnostic_id (fk)
  question_number (int)
  prompt_de
  answer_format            -- 'single' | 'multiple' | 'sort' | …
  correct_answer (jsonb)
  if_wrong_practice_skills (text[])
  audio_asset (text, nullable)

diagnostic_sessions         -- one row per attempt by a student
  id (uuid)
  student_id (fk)
  diagnostic_id (fk)
  started_at, completed_at
  status                   -- 'in_progress' | 'completed' | 'abandoned'

diagnostic_results          -- per-question result inside a session
  id (uuid)
  session_id (fk)
  question_id (fk)
  was_correct (bool)
  response_time_seconds (float)
  status                   -- 'attempted' | 'skipped' | 'timeout'
  user_answer (text)
  answered_at

foerderplaene               -- materialized; regeneratable from results
  id (uuid)
  session_id (fk, unique)
  generated_at
  brief_skill_ids (text[])
  recommended_skill_ids (text[])
  category_stats (jsonb)
  slow_response_flag (bool)
  pdf_storage_path (text, nullable)  -- Supabase Storage

skills                      -- ports skills_taxonomy.csv
  id (text, PK)            -- e.g. 'counting_1'
  category, color, card_number
  title_de, description_de
  title_en, description_en
```

RLS policies: teachers see only their school's rows. Students (anon JWT with session-ticket claim) can only read their own session + diagnostic + write results.

---

## Migration: what stays vs. what changes in the Flutter codebase

### Stays (no rewrite)
- **All exercise widgets and diagnostic question UIs** (`math_app/lib/widgets/diagnostic/`, the various `*_widget.dart` files). These are the bulk of the LOC and are the actual product. Verify Flutter Web rendering, no rewrite.
- **Diagnostic flow orchestration** in `math_app/lib/screens/diagnostic_screen.dart` (lines 1–965). Logic stays; persistence calls swap from `UserService` to an `ApiService`.
- **`DiagnosticResult`, `DiagnosticSession` models** (`math_app/lib/models/`). Wire format to API stays compatible.
- **`SkillCatalog`** (`math_app/lib/services/skill_catalog.dart`). Continue loading from bundled CSV in the Flutter client; server has its own copy.

### Changes (touch lightly)
- **`UserProfile`**: collapse to a thin session-scoped object (`{studentId, displayName, sessionTicket}`). Strip `diagnosticHistory`, `exerciseProgress`, etc. — those live server-side now.
- **`UserService`**: replaced by `ApiService` (Supabase Dart client + REST). Local `shared_preferences` write paths become no-ops for the web build. Keep a `LocalUserService` for desktop dev mode.
- **Entry point**: web build skips `UserSelectionScreen`. URL contains the session ticket → app starts the diagnostic directly.
- **`PdfReportService`**: deleted in the web build (PDF generated server-side). Kept only if a local desktop/native mode is preserved for dev.

### Deletes (web build only)
- `pdf:`, `printing:`, `path_provider:`, `share_plus:` from `pubspec.yaml` for web builds — server owns these now. Use platform-conditional imports if keeping desktop mode alive.

### New code (Flutter side)
- `math_app/lib/services/api_service.dart` — thin Supabase wrapper.
- `math_app/lib/services/auth_service.dart` — session ticket → JWT exchange + storage.
- URL routing: `go_router` or `flutter_web_plugins` URL strategy so `/s/<ticket>` works.

---

## Implementation phases

Each phase ends with something a pilot teacher can actually use. No phase is "infrastructure only — no user value."

### Phases A–C — Backend, dashboard, Flutter Web ✅ DONE (2026-05-17)

Shipped together: Supabase EU project `zzxqeqwffexythqzjkxr` (Frankfurt) with 9-table schema, RLS, 87-skill seed, edge functions (`diagnostic-sessions`, `diagnostic-results`, `foerderplan-generate`, `foerderplan-pdf`), `pdf-cache` Storage bucket; Next.js 14 dashboard at `dashboard/` (login, Klassen-Übersicht, Klasse-Detail with QR tickets, Förderplan-Ansicht, aggregate table); Flutter Web client at `math_app/` with `go_router`, `ApiService`, `/s/:ticket` route, `DiagnosticCompleteScreen`, deployed as static site to Vercel `fra1` (`prozedia-app`). Local dirs: `backend/`, `dashboard/`, `math_app/`. Credentials and deploy commands in memory (`project-school-platform-status`, `reference-vercel`); per-file diffs in `git log`.

Cross-browser test (iPad Safari / Android Chrome / Firefox) deferred to pilot day-1.

### Phase D — Pilot polish ⏳ IN PROGRESS

**Done:**
- DSGVO public routes `/datenschutz` and `/impressum` (German content, but with `[NAME/ADRESSE/EMAIL]` placeholders).
- `CookieBanner` (essential-only, localStorage consent) + footer in dashboard root layout.
- `delete-school-data` edge function — DSGVO right-to-erasure, cascades classes → students → sessions → results → Förderpläne, deletes auth.users for teachers.
- `zahlen_diktat.mp3` moved to Supabase Storage public bucket `audio`; `DiagnosticQuestion.audioAsset` URL field; CSV column `AudioAsset`; `DiagnosticScreen` uses `UrlSource` on web.

**Remaining:**
- [ ] Fill `[NAME/ADRESSE/EMAIL]` placeholders in `dashboard/app/impressum/page.tsx` and `dashboard/app/datenschutz/page.tsx`.
- [ ] Sign AVV/DPA — Supabase template at supabase.com/legal/dpa; must also be signed with each pilot school before data processing.
- [ ] One-page German teacher onboarding doc.

**Bundle size reference (uncompressed Flutter web build):** ~36 MB total (WASM lazy-loaded). `main.dart.js` 4.3 MB (gzip ~1.1 MB). `skwasm.wasm` 3.3 MB on Chromium, 6.8 MB elsewhere. Diagnostic pictures ~1.5 MB. Material icons font 1.6 MB (unavoidable).

### Phase D.5 — Pilot blockers ✅ DONE (2026-05-20 → 2026-05-22)

First end-to-end test on the deployed flow surfaced seven blockers; all shipped:

- **Diagnostic resume across browser close** — `diagnostic-sessions` returns prior results joined with question metadata; `_hydrateFromServer()` in `DiagnosticScreen` restores `_answers`, `_diagnosticResults`, and break-off state, trusting server's `was_correct`.
- **Q47 audio silent** — audio moved to Supabase Storage; `DiagnosticQuestion.audioAsset` URL field added; trigger condition changed from `listNumber == 38` magic to `question.audioAsset != null`.
- **Förderplan not generated on completion** — dashboard lazy-generates on view; edge function accepts in-progress sessions and upserts; "Diagnostik noch nicht abgeschlossen" banner on partial plans; layout aligned with Flutter `DiagnosticReportScreen`.
- **Web build missing new questions** + **wrong order** — bundled CSV + Supabase + Flutter web build now all carry full 98 questions in correct pedagogical order (Zählen 1–23, Zahlzerlegung 24–38, Stellenwerte 39–47, Grundstrategien 48–87, Kombinierte Strategien 88–98). Reorder via `scripts/reorder_diagnostic.py`.
- **Bulk QR PDF for a class** — `dashboard/app/api/bulk-qr-pdf` creates tickets for all students; A4 PDF 2-per-page with QR + name via `pdf-lib` + `qrcode`.
- **Short-URL school login** — `schools.slug` + `session_tickets.short_code` (4-char, globally unique, confusables excluded). Router detects UUID vs slug in `/s/:param`. `SchoolCodeEntryScreen` for code entry. `diagnostic-sessions` accepts `{school_slug, short_code}`. Dashboard shows Kurzlink banner. Bulk QR PDF shows QR + short code side-by-side. **Tickets no longer expire.**

**Deploy/infra also shipped:** Vercel `prozedia-portal` (git-connected, Root Directory `dashboard`, Next.js, fra1) and `prozedia-app` (git-disconnected, CLI-only deploys since Vercel has no Flutter SDK), `NEXT_PUBLIC_STUDENT_APP_URL` env var set on portal.

### Phase E — Pilot (3 months, in parallel with E+)

Real classroom use at one or two schools. Watch what breaks. Do not add features in this period unless a pilot teacher asks twice.

### Future phases (not planned here)

- **Phase F: Practice migration** — port exercise widgets, server-side ExerciseProgress, kid login (since now they come back over weeks not minutes, identity must persist somehow).
- **Phase G: Billing** — Schulträger procurement or direct-school invoicing.
- **Phase H: Parent / home practice** — separate kid identity model (parent-mediated, not teacher-mediated).
- **Phase I: Additional diagnostics** — schema already supports.

---

## Critical risks (with confidence levels)

- **(High confidence) Solo-dev burnout.** This is a 4–6 month part-time pivot. The plan front-loads the boring infra so the fun part (real pilot feedback) arrives sooner — but it is still a lot of work for one person.
- **(High confidence) DSGVO is the showstopper, not the tech.** A Schulleiter who says yes can be vetoed by the Datenschutzbeauftragte. Get the school's data-protection officer to review the AVV before deep building. If they say "no US-flow, no third-party JS," that already constrains tools — Vercel may need to swap to Hetzner.
- **(Moderate confidence) Flutter Web bundle size + first-paint.** A Flutter Web app on a school's old Windows tablet over school WiFi can take 5–10 s to first interactive. Test early on the actual hardware a pilot school has, not on your dev laptop.
- **(Moderate confidence) Schulträger procurement will eat 6+ months when you try to charge.** Doesn't matter for pilot, matters for revenue. Start that conversation while pilot is running, not after.
- **(Low confidence but high-impact) Pedagogical validity claims under DE school law.** A "Förderplan" is a term with regulatory weight in some Bundesländer. Marketing language should be careful: "Vorschlag zur individuellen Förderung" or similar. Ask a pilot teacher how they'd phrase it.
- **(Moderate confidence) Kids' identification is a privacy minefield.** Default to pseudonyms ("S03"). Teachers know who S03 is on their list; the system stores no full name unless teacher chooses. This is also good for the AVV review.

---

## Open questions to answer before starting Phase A

1. **Hosting choice for dashboard**: Vercel EU vs. Hetzner-hosted Next.js. Vercel is faster to set up; Hetzner is unimpeachably EU and cheaper at scale. Default: **Vercel EU** for pilot speed; revisit before billing customers.
2. **PDF rendering**: server-side Puppeteer (heavy, accurate) vs. `pdf-lib` / `@react-pdf/renderer` (lightweight, layout pain). Default: `@react-pdf/renderer` — same JSX mental model as the dashboard.
3. **What does "school admin" do that "teacher" doesn't?** For pilot, probably just "can invite other teachers." Lock down later.
4. **Audio assets** (`zahlen_diktat.mp3` etc.) — bundled in Flutter Web build or served from Supabase Storage? Default: Storage (avoids cache-busting headaches on deploy).
5. **Session ticket lifetime**: 60 min from creation? 24 h? Pinned to class period? Default: 24 h, single-use after first answer.
6. **What happens if a kid closes the browser mid-diagnostic?** Resume by re-scanning QR? Or session is lost? Default: resume on same ticket within its lifetime — server stores the in-progress session.
7. **Locale and copy**: anything beyond German for pilot? Default: German only, hard-coded. No i18n infra until expansion.

---

## Verification (end-to-end smoke test for Phase D completion)

1. Teacher logs into dashboard at `dashboard.example.de`.
2. Creates a class "Klasse 2a" and adds students "S01", "S02", "S03".
3. Clicks "Diagnostik starten" on S01 → sees printable QR code.
4. Scans QR with an iPad in Safari → kid sees the diagnostic intro screen in German, no install prompt.
5. Kid completes ~10 questions, deliberately fails 3, times out 2. Closes browser.
6. Teacher sees S01 as "in Bearbeitung" in dashboard.
7. Kid re-scans QR; resumes from where they left off.
8. Kid finishes; sees "Fertig" screen.
9. Teacher refreshes dashboard; S01 now shows "abgeschlossen" with Förderplan link.
10. Opens Förderplan — same layout as `DiagnosticReportScreen` today: brief plan (3 skills), Kategorie-Übersicht, full plan, detail table.
11. Clicks "Als PDF exportieren" — PDF downloads, identical content, German throughout.
12. Logs out, logs in as a teacher at a different school — does **not** see Klasse 2a (RLS check).
13. Lighthouse on student client: first-interactive under 5 s on a 4 Mbps connection.
14. `psql` check: deleting a school cascades to classes/students/sessions/results (DSGVO right-to-erasure).

---

## What this plan deliberately does **not** include

- Practice exercises migrated to the web. (Phase F.)
- Parent / home accounts. (Phase H.)
- Billing, Stripe, invoicing. (Phase G.)
- Mobile native apps. (Decided against; pilot is browser.)
- Adaptive diagnostic logic changes. (Out of scope; the diagnostic content stays as-is.)
- Multilingual support. (German-only.)
- A second diagnostic. (Schema supports; content not in v1.)
- Analytics beyond the Förderplan view. (No Mixpanel/PostHog/GA in pilot — DSGVO friction not worth it.)

---

## Dependencies on current work

This plan **assumes complete**:
- `Archive/phase0_tasks.md` — `DiagnosticReportGenerator`, `Foerderplan` model, German `DiagnosticReportScreen`, CSV fixes. Shipped.
- Practice-engine Set 1 QA was paused, not finished — see `Archive/tasks_2026-05.md`. If practice resumes, residual "Z1 hangs after 10 problems" bugs must be cleared before going live in a multi-tenant deployment.

This plan **does not require**:
- Any practice exercise work past Set 1.
- Reward system implementation.
- Analytics service.
