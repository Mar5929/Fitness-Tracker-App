# Anchor — Clinically-Aware Workout Tracker

A stripped-down, native-iOS strength tracker built for how an ADHD/OCD brain actually trains:
**frictionless natural-language logging**, a **per-muscle over/under-training ledger**, and a
**Claude-powered coach agent** that generates, modifies, and manages workouts — all *within a
user's documented injury constraints*.

> **Working name:** *Anchor* (placeholder — rename freely).
> **Status:** Phase 1 built (Xcode scaffold + Log screen + NL parse). Needs a Mac
> compile/Simulator run to verify — see [`docs/RUNNING.md`](docs/RUNNING.md) and
> [`docs/STATUS.md`](docs/STATUS.md) for the live state.

---

## Why this exists

Existing trackers (Fitbod et al.) demand clean structured input — exact reps, exact weight, a
planned session followed in order. That breaks down for a scattered training style: lost rep
counts, week-to-week variation swaps, random ad-hoc sets. The result is **no trustworthy
record** and a nagging fear of **over- or under-training** a body part.

Anchor's job, in priority order:

1. **Absorb chaos** — log whatever you actually did, in plain language, without requiring rep
   precision (`"did some calf raises and a couple hard sets of rows"`).
2. **Show the balance sheet** — roll it up into a per-muscle ledger (volume vs. an
   evidence-based band + a recovery/readiness score) so "am I over/under-training X?" has a
   data answer.
3. **Manage the training** — a Claude **coach agent** that writes the next session, swaps
   variations for freshness, tracks progression, handles deloads, and edits the exercise
   library — all respecting the user's documented clinical constraints.

## The differentiator

The coach is **clinically aware by construction.** It loads a derived constraint set (e.g.
"no loaded lumbar flexion," "prioritize left-leg unilateral / VMO work," "keep arm-bracing
load moderate") so its programming respects real injury limits a generic app can't know. It
does **not** give medical advice — anything symptom/injury-shaped is routed back to the user's
clinicians.

---

## Repo contents

| File | What it is |
|------|------------|
| [`DESIGN.md`](DESIGN.md) | **Master design doc** (v0.1): problem, data model, recovery/volume algorithm, NL logging pipeline, Coach Agent spec (§7b), iOS architecture, roadmap, decisions + open questions. References the granular `docs/` files. |
| [`exercise-library.md`](exercise-library.md) | Seed exercise library — movements mapped to muscle groups, equivalence classes (swap pools), and clinical constraint tags; proposed 3×/week full-body split |
| [`docs/phase-1-spec.md`](docs/phase-1-spec.md) | Granular Phase 1 build contract: exact scope, data model, seed loader, Log screen, `SetLogParser` (mock + Claude), Settings/Keychain, acceptance criteria |
| [`docs/muscle-taxonomy.md`](docs/muscle-taxonomy.md) | Reconciles the two muscle-group lists into one provisional set; flags the taxonomy + tuning-constant TODOs |
| [`docs/RUNNING.md`](docs/RUNNING.md) | How to open, build, and run the app in the iOS Simulator + the Phase 1 smoke test |
| [`docs/STATUS.md`](docs/STATUS.md) | **Living handoff state** — what's done, what's next, open TODOs. Read this first each session. |
| [`Anchor/`](Anchor) · `Anchor.xcodeproj` | The iOS app (Phase 1): SwiftData model, seed loader, Log screen, NL parsers, Settings |
| `CLAUDE.md` | Orientation auto-loaded by Claude Code — reading order, codemap, working rules |
| `README.md` | This file |

## Tech stack (planned)

- **iOS / SwiftUI**, local-first store (**SwiftData**), optional iCloud sync
- **Anthropic Messages API** (user's own key, stored in iOS **Keychain**) — tool use for both
  NL parsing and the agentic coach loop
- Swift Charts for the Balance dashboard

## Roadmap

- **Phase 0** ✅ — design doc, exercise library, split, coach-agent spec
- **Phase 1** ✅ *(written; pending Mac verify)* — Xcode project + Log screen + natural-language parse (the core capture loop)
- **Phase 2** — Balance screen (volume + readiness from real data)
- **Phase 3** — Today screen (Claude generation + constraint-aware swaps)
- **Phase 4** — Coach Agent (chat + buttons, auto/confirm tiers, undo log, clinical deferral)
- **Phase 5** — Progression + deload logic, history/edit, polish, sync

## Phase 1 — what works / what's stubbed

**Works (in code; verify on a Mac per [`docs/RUNNING.md`](docs/RUNNING.md)):**
- Xcode project (`Anchor.xcodeproj`), iOS 17+, SwiftUI + SwiftData, no third-party deps.
- SwiftData model: `MuscleGroup`, `Exercise`, `SetLog`, `Workout` (+ derived `MuscleState` sketch).
- Seed loader fills 21 muscle groups + 34 movements from bundled `seed.json` on first launch (idempotent).
- **Log** tab (home): natural-language capture, iOS dictation, glanceable **undoable** confirmation, today's-sets list, tap-to-edit. Never blocks on missing reps.
- NL parsing behind a `SetLogParser` protocol: `MockSetLogParser` (on-device, no network, the default) and `ClaudeSetLogParser` (Anthropic Messages API, tool-use). Silent fallback to mock when no key.
- **Settings** tab: store/clear the Anthropic API key in the **Keychain** only.
- App runs fully **with no API key**.

**Stubbed (clean placeholders, not half-built):**
- **Balance** (Phase 2), **Today** (Phase 3), **Coach** (Phase 4) tabs — each a labeled stub.
- Volume/readiness tuning constants are placeholders (OWNER TODO; see `docs/muscle-taxonomy.md`).

---

*Design docs originated in a private health knowledge base and were split out into this
standalone repo so the app project lives separately from any medical records.*
