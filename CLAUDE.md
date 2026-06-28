# CLAUDE.md — read me first

You are picking up development of **Anchor**, a native-iOS strength tracker. This
file is your orientation: what the project is, where to find everything, what
state it's in, and the rules you must work under. **Read it fully, then read
[`docs/STATUS.md`](docs/STATUS.md) for the live "where we are right now" state.**

---

## 1. What Anchor is (30-second version)

A clinically-aware workout tracker for one owner who trains ~3×/week and whose
ADHD/OCD training style breaks normal apps (loses rep counts, swaps exercise
variations, does scattered ad-hoc sets). Three jobs, in priority order:

1. **Frictionless, chaos-tolerant logging** — log in plain language ("did some
   calf raises and a couple hard sets of rows"), any time. Reps are *nullable*;
   "didn't count" is a first-class state. Track **set count + effort
   (light/medium/hard)**, never reps, never heart rate. If a feature adds logging
   friction, it's wrong.
2. **An over/under-training ledger** — roll logs into a per-muscle view (weekly
   set volume vs. an MEV/MAV/MRV band + a recovery/readiness score).
3. **A Claude coach agent** that generates/modifies the 3×/week full-body plan,
   swaps variations via "equivalence classes," tracks progression, reacts to
   "I'm wiped / knee's cranky," and schedules deloads — **all within the owner's
   documented injury constraints** (the key differentiator).

---

## 2. Read these, in this order

| # | File | Why |
|---|------|-----|
| 1 | **`docs/STATUS.md`** | **Live state**: current phase, what's done, what's next, open TODOs. The single source of "now." Update it as you work. |
| 2 | `DESIGN.md` | Master design doc: data model (§3), recovery/volume algorithm (§5), NL pipeline (§4), Coach Agent (§7b), clinical constraints (§7), architecture (§8), roadmap (§10), decisions (§11). |
| 3 | `exercise-library.md` | Human-readable exercise library (source of truth for `Anchor/Seed/seed.json`) + the tag legend + the 3×/week split. |
| 4 | `docs/phase-1-spec.md` | The exact, testable Phase 1 build contract. |
| 5 | `docs/muscle-taxonomy.md` | The 21-group provisional taxonomy + the OWNER TODOs that gate Phase 2. |
| 6 | `docs/RUNNING.md` | How to open/build/run in the Simulator + the smoke test. |

If anything you do changes a decision, **write it back into `DESIGN.md`** (and
note it in `docs/STATUS.md`). This is how cross-session continuity is preserved.

---

## 3. Codemap (the `Anchor/` app)

```
Anchor/
  AnchorApp.swift            App entry; builds the SwiftData ModelContainer, seeds on first launch.
  Models/
    Enums.swift              Effort, SetSource, MovementPattern (stored as raw strings).
    MuscleGroup.swift        Canonical muscle unit; tuning constants are OWNER-TODO placeholders.
    Exercise.swift           Library movement; primary/secondary muscles, equivalenceClass, clinicalTags.
    SetLog.swift             THE atomic capture unit. reps/load nullable. rawText kept verbatim.
    Workout.swift            Session container (exists for forward-compat; not built out in P1).
    MuscleState.swift        Derived, NOT stored — Phase 2 sketch only.
  Seed/
    seed.json                Generated from exercise-library.md (21 groups, 34 movements).
    SeedLoader.swift         Idempotent first-launch loader.
  Parsing/
    SetLogParser.swift       protocol + ParsedSetLog struct + ParserError.
    MockSetLogParser.swift   On-device regex/keyword parser (DEFAULT, no network).
    ClaudeSetLogParser.swift Anthropic Messages API, tool-use structured output.
    AnchorConfig.swift       SINGLE source for model ids / endpoint. Don't hardcode model ids elsewhere.
  Security/
    KeychainStore.swift      API key in iOS Keychain only.
  Views/
    RootView.swift           TabView: Log · Balance · Today · Coach · Settings.
    LogView.swift            Home tab: capture field, today's sets, undoable confirmation.
    LogStore.swift           @Observable logic: parse → resolve → insert → undo.
    SetLogEditView.swift     Quick edit for a logged set.
    SettingsView.swift       Store/clear the API key.
    PlaceholderViews.swift   Balance/Today/Coach stubs (Phase 2/3/4).
```

`Anchor.xcodeproj` uses the Xcode-16 **file-system-synchronized group** format —
files under `Anchor/` are picked up automatically; you do **not** hand-edit the
target's file list when adding sources.

---

## 4. Hard rules (non-negotiable)

1. **Clinical deferral.** Anchor is a *training* assistant within already-documented
   limits. It does **not** diagnose, reassure, or give medical advice. If the
   owner asks a symptom/injury/pain question, do not answer it clinically —
   acknowledge, optionally note it, conservatively adjust *that day's* training if
   useful, and route him to his clinicians + his separate private health KB. The
   coach gets **training tools only**, never clinical tools. (DESIGN.md §7b.5.)
   When encoding constraints, use only the *derived flags* (e.g.
   `no_loaded_lumbar_flexion`), never raw medical text.
2. **Effort, not reps, not heart rate.** Reps nullable; intensity = RPE/effort.
   (The owner takes a beta-blocker, so HR zones are unreliable — don't build
   HR-based logic.)
3. **Stay in phase.** Don't exceed the current phase's scope without asking the
   owner. Roadmap + current phase live in `DESIGN.md §10` / `docs/STATUS.md`.
4. **Secrets never touch git.** API key is Keychain-only. Respect `.gitignore`.
5. **Settled product decisions** (don't re-litigate without the owner): native
   iOS, SwiftUI + SwiftData, local-first, iOS 17+, no third-party deps;
   full-body 3×/week; coach autonomy "auto small, confirm big" with a change-undo
   log; app must run with no API key.
6. **Branch.** Active development branch is `claude/app-planning-build-b7s0tt`.
   Commit with clear messages; push there. Don't push elsewhere without
   permission.

---

## 5. Build verification reality

This repo is often edited in a **Linux container with no Xcode/Swift toolchain**,
so code here may be written but **not compiled**. The acceptance gate for any
iOS work is a **Mac `xcodebuild` + Simulator run** (see `docs/RUNNING.md`). When
you finish app code you can't compile, say so plainly and leave the owner exact
run steps — don't claim it builds.

---

## 6. When you finish a chunk of work

- Update **`docs/STATUS.md`** (move items from "Next" to "Done", add new TODOs,
  bump the date + "last session" line). This is the handoff to the next agent.
- If a decision changed, update **`DESIGN.md`**.
- Commit + push to the active branch with a descriptive message.
