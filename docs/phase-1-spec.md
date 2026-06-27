# Phase 1 Build Spec — Anchor

> Granular build contract for **Phase 1** of the roadmap in [`../DESIGN.md`](../DESIGN.md) §10.
> The master doc holds the vision; this file holds the exact, testable scope for the
> first build. A new agent should be able to build Phase 1 from this file alone.
>
> **Status:** Not started (no app code yet). Written 2026-06-27.
> **Build verification note:** this work was scoped on a Windows machine, which cannot run
> `xcodebuild` or the iOS Simulator. Whoever builds Phase 1 must do the compile + Simulator
> run on a Mac before calling the phase done.

---

## 1. Scope

**In scope (Phase 1 only):**
- Xcode project that opens and runs in the iOS Simulator.
- SwiftData data model (DESIGN.md §3).
- A seed loader that fills the Exercise + MuscleGroup tables from a bundled JSON resource.
- The **Log** screen as the home tab: natural-language set logging, end to end.
- Natural-language parsing behind a `SetLogParser` protocol with a mock and a Claude version.
- A minimal **Settings** screen to store/clear the Anthropic API key in the Keychain.

**Out of scope (leave clean stubs/TODOs, do not build):**
- Balance screen (Phase 2).
- Today / workout generation screen (Phase 3).
- Coach Agent chat + tool layer (Phase 4).
- Progression, deload, history-edit, iCloud sync (Phase 5).

---

## 2. Tech constraints (locked)

| Constraint | Value |
|------------|-------|
| Platform | Native iOS, SwiftUI |
| Min target | iOS 17+ |
| Local store | SwiftData |
| Third-party deps | None |
| Networking | Plain `URLSession` only |
| Project name | **Anchor** |
| Bundle id | `com.mrihm.anchor` (placeholder; owner will change) |
| Runs with no API key | **Required.** App must fully work offline via the mock parser. |
| Secrets | Anthropic API key in iOS Keychain only. Never committed. Respect `.gitignore`. |

---

## 3. Data model (from DESIGN.md §3)

SwiftData `@Model` types. Field names follow §3.

### MuscleGroup
- `name` (canonical id, e.g. `calves`). See [`muscle-taxonomy.md`](muscle-taxonomy.md) for the
  provisional set Phase 1 seeds from.
- Tuning constants (`tau`, `mev`, `mav`, `mrv`) are **placeholders / OWNER TODO** (DESIGN.md §5,
  §11). Phase 1 may store them as optional/zero; the Log screen does not use them.

### Exercise
- `name`
- `primaryMuscles: [MuscleGroup]` (full credit ×1.0)
- `secondaryMuscles: [MuscleGroup]` (partial credit ×0.5)
- `equivalenceClass` (swap pool, e.g. `hip_abductor_iso`)
- `pattern` (`isolation` / `hinge` / `squat` / `press` / `pull` / `carry` / `core` / `mobility` / `cardio`)
- `clinicalTags: [String]` (e.g. `spine_neutral_req`, `left_knee_priority`; see exercise-library.md legend)
- `defaultEffort` (`light` / `medium` / `hard`, default `medium`)
- `comfortRating` (1–5, default 3)

### SetLog — the atomic unit of capture
Tolerant of missing data by design.

| Field | Required | Notes |
|-------|----------|-------|
| `exercise` | yes | resolved/created from the parsed text |
| `timestamp` | yes | auto |
| `sets` | yes | defaults to 1 if unstated |
| `reps` | **no — nullable** | "didn't count" is a first-class valid state. Never force a value. |
| `load` | no — nullable | bodyweight / band / unknown all fine |
| `effort` | yes | enum `light` / `medium` / `hard` |
| `source` | yes | enum `planned` / `adhoc` |
| `rawText` | yes | the original sentence, kept verbatim |

### Workout
- A session: ordered planned exercises + the SetLogs attached to it.
- Phase 1 only needs the type to exist; ad-hoc logging does not require a Workout.

### MuscleState — **derived, not stored**
- Computed type (struct/computed property), never a `@Model`. Not built out in Phase 1.

---

## 4. Seed loader

1. Generate a JSON resource (e.g. `seed.json`) from [`../exercise-library.md`](../exercise-library.md):
   every movement with its primary/secondary muscles, equivalence class, pattern, and clinical tags.
   Encode the equivalence classes and clinical tags faithfully.
2. Bundle the JSON in the app target.
3. On first launch (empty store), the loader inserts the MuscleGroup rows, then the Exercise rows.
   Idempotent: do not duplicate on later launches.
4. The JSON is the generated artifact; `exercise-library.md` stays the human-readable source.

---

## 5. Log screen (home tab)

Capture is the whole point, so this is the first tab.

- A big text field with an **"What did you do?"** prompt.
- **iOS dictation** into that same field (no separate voice pipeline).
- After logging: a **glanceable, undoable** confirmation (toast/banner), e.g.
  "Logged: 3× calf raise (calves), 3× row (upper back). Tap to edit." With an **Undo**.
- Below the field: a simple list of **today's logged sets**. Tapping a row opens a quick edit.
- **Never block on missing reps.** "a few sets" → `sets: 3, reps: nil`. No nagging.

---

## 6. Natural-language parsing — `SetLogParser`

A protocol with two implementations. The app picks one at runtime.

```
protocol SetLogParser {
    func parse(_ text: String) async throws -> [ParsedSetLog]
}
```

### MockSetLogParser (default, no network)
- On-device keyword/regex parsing. No API call.
- Must be good enough to demo logging **"3 sets of calf raises and a few hard rows"**:
  - "3 sets of calf raises" → calf raise, `sets: 3`, `reps: nil`, effort default.
  - "a few hard rows" → row, `sets: 3` (a few → 3), `effort: hard`.
- Effort words map to the enum: easy/light → `light`; hard/went hard/burned out → `hard`; else `medium`.
- Resolve the exercise name against the seeded library (fuzzy/contains match). Unknown name:
  keep it as `rawText` and surface a lightweight "add to library?" path or a plain unresolved row.

### ClaudeSetLogParser (optional, network)
- Calls the **Anthropic Messages API** with `URLSession`, using **tool use / structured output**
  to return typed SetLogs (not prose to parse).
- Reads the API key from the **Keychain**. If the key is **absent, silently fall back to the
  mock parser** (no error shown).
- Endpoint `POST https://api.anthropic.com/v1/messages`; headers `x-api-key`, `anthropic-version`
  (confirm the current value at build time), `content-type: application/json`.

### Model id — single source
- One config constant only. Do not hardcode the model id in more than one place.
- Phase 1 parse model = **`claude-haiku-4-5`** (DESIGN.md §8: fast/cheap for the extraction task).
  Confirm the exact id at build time.
- The stronger generation model (`claude-sonnet-4-6`) is for later phases; keep a slot for it but
  do not use it in Phase 1.

---

## 7. Settings screen (minimal)

- A `SecureField` to enter the Anthropic API key, which is written to the **Keychain**.
- A way to **clear** the stored key.
- Nothing else in Phase 1. No key value is ever written to disk in plaintext or committed.

---

## 8. Stubs for later phases

Leave clean, obvious stubs so the tab bar/structure is visible but nothing half-built:
- **Balance** tab → placeholder view with a `// TODO: Phase 2` note.
- **Today** tab → placeholder view with a `// TODO: Phase 3` note.
- **Coach** tab → placeholder view with a `// TODO: Phase 4` note.

---

## 9. Deliverables (acceptance criteria)

1. A buildable Xcode project committed to the repo.
2. Compiles via `xcodebuild` (run on a Mac) and runs in the iOS Simulator **with no API key set**.
3. Logging "3 sets of calf raises and a few hard rows" with no key produces the right SetLogs
   via the mock parser, with a glanceable undoable confirmation and a today's-sets list.
4. Settings can store and clear the key in the Keychain.
5. A short **"Phase 1"** section appended to `../README.md`: what works, what is stubbed.
6. Exact open + run steps documented for the Simulator.
7. Commit message: **"Phase 1: Xcode scaffold + Log screen + NL parse"**, pushed to `main`.

---

## 10. Open items that touch Phase 1 (flagged, not blocking)

- **Muscle taxonomy** is not finalized (OWNER TODO). Phase 1 seeds from the provisional set in
  [`muscle-taxonomy.md`](muscle-taxonomy.md), which is enough for logging. Final taxonomy +
  volume constants are a Phase 2 prerequisite.
- **Exercise-science constants** (MEV/MAV/MRV, recovery `tau`) are placeholders (DESIGN.md §5, §11).
  Not used by the Log screen, so they do not block Phase 1.
