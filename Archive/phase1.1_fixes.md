# Phase 1.1 — Diagnostic & Dashboard Fixes

**Created:** 2026-05-23
**Owner:** Jakob (solo)
**Status:** ✅ Deployed 2026-05-23

Eleven issues found during first end-to-end testing, organized and tracked here.
Branches from Phase D.5 completion. Does not touch the practice engine.

---

## Progress

| # | Issue | Status | Notes |
|---|---|---|---|
| 1 | Delete Q39 + Q40 | ✅ Done | CSV updated; migration `20260523000000_fix_diagnostic_questions.sql` written; **push needed** |
| 2 | Doubling numbers | ✅ Done | Q54–Q61 updated in CSV + migration |
| 3 | Halving numbers | ✅ Done | Q62–Q71 updated in CSV + migration |
| 4 | Q48 dice missing | ✅ Done | Condition changed `listNumber == 46 → 48`, method renamed `_buildQ48Display()` in `diagnostic_screen.dart` |
| 5 | Förderplan fail first click | ✅ Done | Dashboard Förderplan page now uses function return value directly instead of re-fetching DB |
| 6 | In Bearbeitung 91/98 | ✅ Done | Added `completeSession()` to `ApiService`; Flutter web now force-completes session at end; `diagnostic-sessions` edge fn handles `action: 'complete'` |
| 7 | Retry via dashboard | ✅ Done | Schema migration + `diagnostic-sessions` returns wrong Q#s + `StudentRow` "Falsche wiederholen" button + `DiagnosticScreen.retryQuestionNumbers` |
| 8 | Verkürzte Diagnose toggle | ✅ Done | Schema migration + `abbreviated_mode` flag from server; `web_diagnostic_entry_screen` uses server value instead of hardcoded `true` |
| 9 | Historical diagnoses | ✅ Done | New page `dashboard/app/dashboard/students/[studentId]/page.tsx`; student name in `StudentRow` is now a link |
| 10 | Q46 extra dice | ✅ Done | Same fix as #4 |
| 11 | Förderplan nach SenBJF | ✅ Done | New edge fn `foerderplan-kurz-pdf`; API routes `foerderplan-kurz-pdf` + `foerderplan-kurz-docx`; two buttons in Förderplan page; `docx` npm added |

---

## Deploy checklist (all 11 issues)

All steps completed 2026-05-23.

```bash
# 1. DB migrations — already applied (supabase db push --dry-run confirmed up to date)
# 2. Edge functions — deployed: diagnostic-sessions, diagnostic-results, foerderplan-kurz-pdf
# 3. Flutter web — rebuilt (also fixed school_code_entry_screen.dart compile error)
# 4. Flutter web — deployed to prozedia-app.vercel.app via vercel --prod --yes
# 5. Dashboard — pushed to main; prozedia-portal auto-deployed
```

---

## Planned features (Issues 7, 8, 9, 11)

### Issue 7 — Retry wrong questions via dashboard

**Goal:** Teacher generates a "retry ticket" after a child finishes; child sees only their wrong questions.

**Schema change (new migration):**
```sql
ALTER TABLE session_tickets
  ADD COLUMN retry_mode BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN retry_session_id UUID REFERENCES diagnostic_sessions(id);
```

**Backend — `diagnostic-sessions` edge fn:**
When ticket has `retry_mode = true`, fetch `diagnostic_results` for `retry_session_id` where `was_correct = false`. Return wrong question numbers alongside session metadata. Flutter filters question list to those numbers.

**Dashboard — `dashboard/components/StudentRow.tsx`:**
After a session is `completed`, show "Falsche Antworten wiederholen" button. Creates ticket with `retry_mode: true, retry_session_id: latestSession.id`.

**Flutter web client — `math_app/lib/screens/diagnostic_screen.dart`:**
If server returns `retry_mode: true` + `retry_question_numbers`, filter the loaded question list to those numbers. Wires directly into existing `retryMode` parameter.

---

### Issue 8 — Verkürzte Diagnose toggle in dashboard

**Goal:** Teacher can toggle break-off logic for a child's next session.

**Schema change (same migration as issue 7):**
```sql
ALTER TABLE session_tickets
  ADD COLUMN abbreviated_mode BOOLEAN NOT NULL DEFAULT false;
```

**Backend:** `diagnostic-sessions` returns `abbreviated_mode` flag in response. Flutter web client sets `useBreakOffLogic` on the `UserProfile` based on this flag. Currently `web_diagnostic_entry_screen.dart` hardcodes `useBreakOffLogic: true`; that will be replaced by the server value.

**Dashboard:** Toggle added to ticket-generation modal in `StudentRow.tsx`. Default: off.

**Note:** The actual skip group rules (which ZR20 failures skip which ZR100 groups) are already implemented in `diagnostic_screen.dart`. Jakob will review and adjust as needed separately.

---

### Issue 9 — Historical diagnoses per child

**Goal:** Teacher sees all past sessions for a student.

**New page:** `dashboard/app/dashboard/students/[studentId]/page.tsx`

Query:
```typescript
supabase
  .from("diagnostic_sessions")
  .select("id, status, started_at, completed_at, diagnostic_results(count), foerderplaene(brief_skill_ids, category_stats)")
  .eq("student_id", studentId)
  .order("started_at", { ascending: false })
```

Display as timeline list: date, status badge, X/92 question count, per-category dot summary, link to Förderplan.

Link from `StudentRow.tsx`: student name becomes a link to `/dashboard/students/[studentId]`.

No schema changes needed.

---

### Issue 11 — Förderplan nach SenBJF in teacher dashboard

**Goal:** PDF + editable Word download of the abbreviated Kurzförderplan (SenBJF format), identical content to the Flutter Windows app version.

**Reference Flutter files to port:**
- `math_app/lib/services/kurz_foerderplan_service.dart` — core Ist/Soll/Lernweg generation
- `math_app/lib/services/pdf_kurz_foerderplan_service.dart` — 2-page A4 landscape PDF
- `math_app/lib/services/docx_kurz_foerderplan_service.dart` — editable DOCX

**Backend:**
1. New edge function `foerderplan-kurz-pdf` — TypeScript port of the PDF generator using `pdf-lib`. Caches to `pdf-cache/kurz/{session_id}.pdf`.
2. New API route `dashboard/app/api/foerderplan-kurz-pdf/route.ts` — proxies to edge function.
3. New API route `dashboard/app/api/foerderplan-kurz-docx/route.ts` — generates DOCX using `docx` npm package (editable, fillable cells with grey background).

**Dashboard buttons** added to `dashboard/app/dashboard/foerderplan/[sessionId]/page.tsx` header:
- "Förderplan nach SenBJF (PDF)"
- "Förderplan nach SenBJF (Word)"

---

## Files changed

| File | Change |
|---|---|
| `math_app/Research/MathApp_Diagnostic_with_skills.csv` | Deleted Q39, Q40, Q57, Q62, Q66, Q67; updated doubling/halving questions |
| `backend/supabase/migrations/20260523000000_fix_diagnostic_questions.sql` | New migration matching CSV changes |
| `backend/supabase/migrations/20260523000001_session_tickets_retry_abbreviated.sql` | New migration: `retry_mode`, `retry_session_id`, `abbreviated_mode` on `session_tickets` |
| `math_app/lib/screens/diagnostic_screen.dart` | Q46→Q48 dice fix; `completeSession()` call; `retryQuestionNumbers` param + server-driven retry filter |
| `math_app/lib/services/api_service.dart` | Added `completeSession()`; extended return type with `retryMode`, `retryQuestionNumbers`, `abbreviatedMode` |
| `math_app/lib/screens/web_diagnostic_entry_screen.dart` | Use `abbreviatedMode` from server; pass `retryMode` + `retryQuestionNumbers` to `DiagnosticScreen` |
| `backend/supabase/functions/diagnostic-sessions/index.ts` | Added `action: 'complete'` handler; returns retry/abbreviated flags and wrong question numbers |
| `backend/supabase/functions/foerderplan-kurz-pdf/index.ts` | New edge function: 2-page A4 landscape SenBJF Förderplan PDF |
| `dashboard/app/dashboard/foerderplan/[sessionId]/page.tsx` | Fix race condition; add "Förderplan nach SenBJF" PDF + Word buttons |
| `dashboard/app/api/foerderplan-kurz-pdf/route.ts` | New API route: proxy to `foerderplan-kurz-pdf` edge function |
| `dashboard/app/api/foerderplan-kurz-docx/route.ts` | New API route: generate DOCX with `docx` npm |
| `dashboard/components/StudentRow.tsx` | Student name links to history; "Falsche wiederholen" button; "Verkürzt" toggle |
| `dashboard/app/dashboard/students/[studentId]/page.tsx` | New page: timeline of all sessions per student |
| `dashboard/package.json` | Added `docx` dependency |
