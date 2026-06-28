# STATUS — live handoff state

> **The single source of "where we are right now."** A new agent reads `CLAUDE.md`
> then this file and is immediately current. **Keep this updated as you work** —
> it's the handoff to the next session.

- **Last updated:** 2026-06-28
- **Last session did:** Built Phase 1 (Xcode scaffold + data model + seed + Log
  screen + NL parse + Settings/Keychain) and the session-continuity system
  (`CLAUDE.md`, this file, SessionStart hook).
- **Active branch:** `claude/app-planning-build-b7s0tt`
- **Current phase:** **Phase 1 — code complete, pending Mac verification.**

---

## Where the project stands

| Phase | What | State |
|-------|------|-------|
| 0 | Design doc, exercise library, split, coach spec | ✅ done |
| 1 | Xcode project + data model + Log screen + NL parse | ✅ **written; NOT yet compiled on a Mac** |
| 2 | Balance dashboard (volume + readiness) | ⛔ not started (blocked on OWNER TODOs below) |
| 3 | Today / workout generation (Claude + constraints) | ⛔ not started |
| 4 | Coach Agent (chat + buttons, tool layer) | ⛔ not started |
| 5 | Progression + deload + history-edit + iCloud sync | ⛔ not started |
| 6 | App reads health repo to auto-refresh constraints | ⛔ later |

---

## Immediate next action (do this first)

**Verify Phase 1 on a Mac.** This repo was written in a Linux container with no
Xcode toolchain, so Phase 1 has not been compiled. Run the steps in
[`RUNNING.md`](RUNNING.md):
1. `open Anchor.xcodeproj`, build for an iPhone simulator, run.
2. Do the smoke test: log `3 sets of calf raises and a few hard rows` with **no
   API key** → expect two correct sets + an undoable confirmation.
3. Fix any compile errors (the hand-authored `project.pbxproj` and SwiftData
   relationship graph are the most likely suspects — see "Risks" below).
4. When it builds + the smoke test passes, mark Phase 1 ✅ verified here and in
   `DESIGN.md §10`.

---

## Phase 1 — what's done (detail)

- **Data model** (`Anchor/Models/`): `MuscleGroup`, `Exercise`, `SetLog`,
  `Workout`; enums `Effort`/`SetSource`/`MovementPattern`; `MuscleState` sketch.
- **Seed**: `Anchor/Seed/seed.json` (21 muscle groups, 34 movements, generated
  from `exercise-library.md`) + idempotent `SeedLoader`.
- **Log screen**: capture field + dictation, today's-sets list, tap-to-edit,
  glanceable undoable confirmation. Reps never required.
- **Parsing**: `SetLogParser` protocol; `MockSetLogParser` (default, on-device);
  `ClaudeSetLogParser` (Anthropic Messages API, tool-use); model id centralized
  in `AnchorConfig` (`claude-haiku-4-5` for parse). Silent fallback to mock when
  no key.
- **Settings + Keychain**: store/clear the API key; app runs fully without one.
- **Stubs**: Balance/Today/Coach tabs are clean placeholders.

## Phase 1 — what's intentionally NOT done

- No Balance/Today/Coach functionality (later phases).
- No tuning constants in `seed.json` (zeros — placeholders; not used by logging).
- No unit-test target (would not run on Linux; add when verifying on a Mac if wanted).
- Not compiled/run — see "Immediate next action."

---

## Open decisions blocking later phases (OWNER TODO)

These are owner calls, flagged in `DESIGN.md §11` and `docs/muscle-taxonomy.md`.
**Phase 2 (Balance) cannot give a trustworthy signal until they're settled:**
1. **Lock the final muscle taxonomy** (confirm/adjust the provisional 21).
2. **Per-group tuning constants** — recovery `tau` + volume landmarks
   MEV/MAV/MRV, evidence-grounded.
3. **Biceps/forearms** — add direct movements or leave secondary-only?
4. **Left/right tracking** — per-group split, or cue-only note?

---

## Risks / things to watch when verifying

- **Hand-authored `project.pbxproj`** (`objectVersion = 77`, synchronized group).
  Requires Xcode 16+. If it won't open, re-create the project in Xcode and drag
  `Anchor/` in — all source is plain Swift and portable.
- **SwiftData relationships**: `Exercise` ↔ `MuscleGroup` is two relationships
  (primary/secondary) with inverses declared on `MuscleGroup`; `SetLog.workout`
  ↔ `Workout.setLogs`. If the schema fails to build, check inverse declarations.
- **Mock parser** is heuristic; it's meant to pass the smoke-test sentence, not
  be perfect. Real parsing quality comes from the Claude path.

---

## How to update this file

When you finish work: move items between sections, refresh the date + "last
session did" line, add any new TODOs/risks. Keep it short and current — it is the
first thing the next agent trusts.
