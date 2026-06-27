# Workout Tracker — Design Doc (v0.1)

> **Status:** Draft for Mike's review. No code yet. This is the "get it out of my head and
> concrete" document we agreed to write first.
> **Working name:** *Anchor* (placeholder — rename freely; see Open Questions).
> **Form factor:** Native iOS app (SwiftUI).
> **Logging:** Natural language ("did some calf raises and a couple sets of rows").
> **AI:** Calls the Claude API with Mike's own key to read history + write/modify workouts.

> **Locked decisions & granular specs (added 2026-06-27):** the open questions in §11 are now
> resolved or flagged. Deep build detail lives in `docs/`, referenced from the relevant section:
> - `docs/phase-1-spec.md` — the exact, testable Phase 1 build contract (referenced from §10).
> - `docs/muscle-taxonomy.md` — reconciles the two muscle-group lists; provisional set + TODOs (§3.1).
>
> This doc stays the master; the `docs/` files hold the granular detail.

---

## 1. The problem this actually solves

Mike has OCD + ADHD. The *failure mode of every existing app* (Fitbod included) is that they
demand clean, structured input — exact reps, exact weight, a planned session you follow in
order. Mike doesn't work that way:

- He loses count of reps, so rep-perfect logs never happen.
- He flip-flops exercise *variations* for the same body part week to week.
- He hyperfixates and does random ad-hoc sets (e.g. calf raises) scattered through the week.
- The result: **no trustworthy record**, and a nagging fear of **over- or under-training** a
  given body part with no data to settle it.

So the app's job is **not** "be a better workout planner." It's three things, in priority order:

1. **Absorb chaos.** Capture whatever he actually did, in plain language, including ad-hoc
   sets logged any time — without requiring rep precision.
2. **Show the balance sheet.** Roll that mess up into a per–muscle-group ledger: what got
   trained, how hard, how recently → answer "am I over/under-training X?" with data.
3. **Write the next session.** A Claude layer reads the ledger + Mike's documented clinical
   constraints and proposes today's workout, swapping variations for freshness.

**Design tenet:** if a feature adds logging friction, it's wrong. Frictionless capture beats
data precision every time. We track *frequency and effort per muscle*, not perfect reps.

---

## 2. The one thing that makes this better than Fitbod

Fitbod doesn't know Mike has a **regressing-but-real L5–S1 disc**, a **left knee with
confirmed VMO arthrogenic muscle inhibition (AMI) + TT-TG 24 mm lateral maltracking**, and
**bilateral ulnar nerve transpositions**. This repo documents all of it. The generator is
**clinically aware by construction** — it will never casually program loaded lumbar flexion,
it biases the left leg toward the unilateral/VMO work his rehab calls for, and it respects the
elbow nerve history. That's a safety-and-trust upgrade, not a gimmick. See §7.

---

## 3. Core data model

Six entities. Kept deliberately small.

### 3.1 `MuscleGroup`
The unit the whole app reasons in. A fixed taxonomy (~14–16 groups), e.g.:

`chest · upper_back · lats · traps · front_delts · side_delts · rear_delts · biceps ·
triceps · forearms · quads · hamstrings · glutes · hip_abductors · hip_adductors · calves ·
core`

Each carries tuning constants (see §5): recovery time-constant `τ`, and weekly volume
landmarks `MEV / MAV / MRV`.

> The exact group list is **not yet final** (the §3.1 list and the `exercise-library.md`
> coverage check differ). `docs/muscle-taxonomy.md` reconciles them and gives a provisional set
> Phase 1 seeds from. Finalizing the list + the tuning constants is an OWNER TODO and a Phase 2
> prerequisite (see §11).

### 3.2 `Exercise`
A movement in the library. Fields:

| Field | Example | Why |
|-------|---------|-----|
| `name` | "Resistance-band lateral walk" | display |
| `primaryMuscles` | `[hip_abductors]` | full stimulus credit (×1.0) |
| `secondaryMuscles` | `[glutes]` | partial credit (×0.5) |
| `equivalenceClass` | `hip_abductor_iso` | the swap pool for variety (§6) |
| `pattern` | `isolation` / `hinge` / `squat` / `press` / `pull` / `carry` | for constraint rules |
| `clinicalTags` | `[knee_safe, spine_neutral]` / `[loaded_lumbar_flexion]` | constraint filter (§7) |
| `defaultEffort` | `medium` | fallback when NL omits it |
| `comfortRating` | 1–5 (Mike-set) | bias toward "exercises I feel comfortable doing" |

Seeded from **`exercise-library.md`** (Phase 0 complete: Mike's starter list, 27 movements,
each pre-tagged for his constraints). Phase 1 exports it to the app's JSON seed.

### 3.3 `SetLog` — the atomic unit of capture
One logged set (or a cluster of sets). Intentionally tolerant of missing data:

| Field | Required? | Notes |
|-------|-----------|-------|
| `exercise` | yes | resolved/created from NL |
| `timestamp` | yes | auto |
| `sets` | yes | defaults to 1 if unstated |
| `reps` | **no** | nullable — "didn't count" is a first-class value |
| `load` | no | nullable — bodyweight/band/unknown all fine |
| `effort` | yes | `light / medium / hard` (RPE-ish), inferred from NL or default |
| `source` | yes | `planned_session` or `adhoc` (the scattered calf raises) |
| `rawText` | yes | the original sentence, kept verbatim for audit |

### 3.4 `Workout` (a session)
A generated or freeform session = ordered list of planned exercises + the `SetLog`s that got
attached to it. 3×/week is the target cadence, but ad-hoc sets live outside sessions and
still count toward the ledger.

### 3.5 `MuscleState` (derived, not stored long-term)
Per muscle, computed on the fly: `weeklyVolume`, `volumeStatus` (under/in-band/over),
`readinessPct`, `lastTrained`. This is what the dashboard shows and what Claude reads.

### 3.6 `ClinicalConstraint`
A rule sourced from the health repo (§7). Either a **hard filter** (exclude exercises with a
tag) or a **soft bias** (prefer/deprioritize). Versioned so we can update it as Mike's status
changes.

---

## 4. Natural-language logging pipeline

The headline feature. Mike types or dictates a sentence; the app turns it into `SetLog`s.

```
"just did 3 sets of calf raises and a few rows, went pretty hard on the rows"
        │
        ▼  (Claude API — tool/function calling, structured output)
[ {exercise:"calf raise", sets:3, reps:null, effort:"medium", source:"adhoc"},
  {exercise:"row",        sets:3, reps:null, effort:"hard",   source:"adhoc"} ]
        │
        ▼  exercise resolver (fuzzy-match to library; offer "create new?" if unknown)
        ▼  write SetLogs → recompute MuscleState
        ▼  one-line confirmation toast: "Logged: 3× calf raise (calves), 3× row (back). Tap to edit."
```

Design rules:
- **Never block on missing reps.** "a few sets" → `sets:3, reps:null`. We do not nag.
- **Effort inference** from words ("went hard", "easy", "burned out") → `effort`; else default.
- **Confirmation is glanceable + undoable**, never a form to fill.
- **Voice** via iOS dictation into the same text field (no separate voice pipeline needed v1).
- **Cheap model for the parse** (it's a small structured-extraction task); the expensive
  reasoning is reserved for generation (§6). See §8 for model choices.

---

## 5. The algorithmic core — recovery + volume model

This is where "am I over/under-training?" gets answered, and what Claude reads before writing
a session. Two linked models per muscle group.

> ⚠️ **Numbers below are framework placeholders, not settled science.** The volume landmarks
> and recovery constants need to be evidence-grounded before they ship (hypertrophy
> volume-landmark literature; muscle-size/recovery-time work). Treat the *structure* as the
> design; the *constants* as TODO. Flagged again in Open Questions.

### 5.1 Volume model → the over/under signal
Track **hard sets per muscle per rolling 7 days**, with secondary muscles counted at ×0.5.
Compare to three landmarks per muscle (the standard MEV/MAV/MRV framing):

- **MEV** (minimum effective volume) — below this = *under-training* (red-low).
- **MAV** (maximum adaptive volume) — the target band (green).
- **MRV** (maximum recoverable volume) — above this = *over-training* risk (red-high).

```
calves:  ▓▓▓▓▓▓▓░░░  9 sets/wk   ● IN BAND
back:    ▓░░░░░░░░░  2 sets/wk   ▼ UNDER  (12 days since last)
glutes:  ▓▓▓▓▓▓▓▓▓▓  22 sets/wk  ▲ OVER   (those daily ad-hoc sets add up)
```

This single view is arguably the whole point of the app for Mike. **Counting sets, not reps,
is deliberate** — set-volume is what the over/under question actually hinges on, and it
sidesteps his rep-counting problem entirely.

### 5.2 Recovery model → "X% recovered"
Per muscle, a readiness score that drops after a stimulus and recovers over time:

```
readiness(t) = 100 − drop · exp( −Δt / τ_muscle )

  drop      ∝  Σ (sets × effortWeight × muscleCredit)   for that session
  τ_muscle  =  recovery time-constant (small muscles e.g. calves/forearms recover
               fast; large e.g. glutes/back/legs slow)
  effortWeight: light 0.6 / medium 1.0 / hard 1.4
  muscleCredit: primary 1.0 / secondary 0.5
```

So a hard glute session might read 35% recovered the next day; calves after light work might
be 85%. Claude consumes these numbers directly: *"glutes 35% recovered + already OVER on
weekly volume → skip direct glute work today; hip abductors 90% recovered + UNDER → good
target."*

---

## 6. The Claude generation layer

When Mike taps **"Today's workout,"** the app sends Claude a compact JSON snapshot and asks
for a session back (structured output). Claude does three jobs:

1. **Select** today's muscle targets — favor muscles that are *recovered AND under/in-band on
   volume*, avoid *over-volume or unrecovered* ones, honor the 3×/week rhythm.
2. **Choose exercises** from the library, respecting clinical constraints (§7) and biasing to
   high `comfortRating` movements.
3. **Substitute for freshness** — pick a *different variation from the same
   `equivalenceClass*` than what he did recently. This is the "clamshells two days ago →
   resistance-band walks today, same hip-abductor target" behavior Mike described, done
   explicitly via the equivalence class rather than guessed.

Input snapshot (sketch):
```json
{
  "today": "2026-06-27",
  "cadenceTarget": "3x/week",
  "muscleStates": [
    {"muscle":"hip_abductors","readiness":90,"weeklyVolume":4,"status":"under","lastTrained":"2026-06-25","recent":["clamshell"]},
    {"muscle":"glutes","readiness":35,"weeklyVolume":22,"status":"over","lastTrained":"2026-06-26"}
  ],
  "constraints": ["no_loaded_lumbar_flexion","left_knee_prefer_unilateral_vmo","elbow_avoid_heavy_bracing"],
  "library": [ ... exercises with tags + comfortRating ... ]
}
```

Claude returns a proposed `Workout` **with a one-line rationale per exercise** ("band walks —
abductors under-trained, fresh vs. Tuesday's clamshells; spine-neutral"). Mike can accept,
swap any item (one tap → Claude offers an alternative from the same class), or freeform it.
**Claude proposes; Mike disposes** — it never auto-logs a workout he didn't do.

---

## 7. Clinical constraint layer (sourced from THIS repo)

Encoded from `profile/comprehensive-health-profile.md` and the `conditions/` + `principles/`
files. **These are real, documented constraints — not invented.** Each maps to exercise tags.

| Region | Documented finding | Constraint encoded |
|--------|--------------------|--------------------|
| **Lumbar L5–S1** | Avoid heavy bending with load / end-range lumbar flexion under load; extension-biased moves (glute bridges) are spine-protective; neutral-spine carries 15–25 lb are fine; disc is *sensitive, not fragile* | **Hard:** exclude `loaded_lumbar_flexion`. **Soft:** prefer `spine_neutral` / extension-biased; hinge only with neutral-spine cue |
| **Left knee** (post-ACLR, AMI, TT-TG 24 mm, Outerbridge 2) | VMO activation deficit on the **left**; needs unilateral loading + VMO isolation **before** bilateral; bilateral bodyweight masks the deficit; open-chain knee extension produced patellar clunking | **Soft (strong):** prioritize **left** unilateral + VMO-isolation work; flag/deprioritize loaded open-chain knee extension; favor `knee_safe` patterns |
| **Left calf / medial gastroc** | Under-recruitment / cramp-on-command deficit (open question, not denervation) | **Soft:** include direct left-biased calf work; track separately |
| **Elbows** (bilateral ulnar transpositions) | Avoid heavy arm-as-lever bracing; avoid sustained loaded elbow flexion; left elbow scar still remodeling (early 2026) | **Soft:** deprioritize heavy bracing/lever loads through the arms; watch sustained loaded elbow flexion |
| **Cervical** | Normal MRI; stretch/impact safe; stress → suboccipital guarding | Mostly unrestricted; no special filter |

**Update path:** when the health repo changes (new imaging, a rehab milestone, a cleared
restriction), the constraint set is re-derived. v1 can do this manually; later it can read the
repo directly. Constraints are **versioned** so a workout records which constraint set it was
built under.

> Safety note: this app *assists* training within already-documented limits. It does not
> diagnose, and it doesn't override Mike's clinicians. Anything new/painful routes back to the
> health KB and the relevant provider, not the app.

---

## 7b. The Coach Agent (Claude as a managing agent, not just a generator)

Decided 2026-06-27. Mike wants Claude to be a **persistent coach that manages his fitness** —
not a one-shot workout generator. Architecturally this means Claude runs an **agentic tool-use
loop**: it holds a set of tools that map to the app's data operations, and when Mike talks to
it (or taps a button), it decides which tools to call, does the work, and reports back.

### 7b.1 Surface — chat **and** buttons
- **Chat screen ("Coach"):** Mike talks to it in plain language — *"add a band pull-apart, drop
  tricep extensions, build me today's session, I'm wiped so go easy."* The coach calls the
  relevant tools and explains what it did.
- **Buttons:** the fast common paths (Log, "Today's workout," one-tap swap) stay as buttons that
  invoke the same underlying tools — no need to open a chat for routine actions.
- Both surfaces drive the **same tool layer**, so behavior is consistent.

### 7b.2 The tool set (what the coach can do)
Each maps to a typed operation on the local store. Tier = autonomy (see 7b.3).

| Tool | What it does | Tier |
|------|--------------|------|
| `queryLedger` / `readState` | read muscle volume, readiness, history | auto |
| `logSet` | record a set from NL | auto |
| `generateWorkout` | propose today's session | auto (proposal; not logged until done) |
| `swapExercise` | swap one item for a same-class variant | auto |
| `addExercise` | add a movement to the library (pre-tagged for constraints) | auto |
| `retagExercise` / `setComfort` | adjust tags, comfort rating, equivalence class | auto |
| `suggestProgression` | recommend +reps/+sets/+resistance when ready | auto (suggestion) |
| `adjustPlan` | change the 3×/week template / split structure | **confirm** |
| `scheduleDeload` | insert a rest/deload week | **confirm** |
| `deleteExercise` | remove a movement (esp. one with logged history) | **confirm** |
| `editHistory` / `deleteLog` | change or remove past logged sets | **confirm** |

### 7b.3 Autonomy — "auto small, confirm big"
- **Auto (low-risk, reversible):** logging, generating proposals, adding exercises, retagging,
  swaps, progression *suggestions*. The coach just does these and tells Mike.
- **Confirm (destructive or structural):** deleting an exercise that has history, editing/
  deleting past logs, rewriting the split, scheduling a deload. The coach **proposes and waits
  for a tap** before writing.
- **Everything is logged + undoable** regardless of tier — a change/undo history so Mike can
  always trust and reverse the record. (This directly serves the "I need to trust what's in
  there" requirement.)

### 7b.4 Full management scope (all four areas, per Mike)
1. **Exercise library** — add/delete/retag, comfort, equivalence classes.
2. **Workouts** — generate, swap, modify the plan.
3. **Progression & load over time** — track that he's *progressing, not just maintaining*; flag
   when to add reps/sets/resistance. (Needs a lightweight progression record per exercise.)
4. **React to how he feels + deloads** — daily check-ins ("knee's cranky," "wiped today")
   modify that session; high accumulated fatigue/volume triggers a deload suggestion. *(Note:
   "how I feel" inputs are read as training-readiness signals, NOT clinical assessment — see
   7b.5.)*

### 7b.5 Clinical boundary — the coach defers
**Hard rule:** the Coach Agent trains *within* Mike's documented constraints (§7) but **does not
give clinical advice.** If an input smells like a symptom / injury / pain / medical question
("is my knee okay," "should I be worried about this twinge"), the coach **does not answer it
clinically** — it:
1. acknowledges and, if useful, offers to note it,
2. routes Mike to the **health knowledge base + his clinicians**, and
3. at most adjusts *that day's training* conservatively (e.g. de-load the knee today) without
   making a diagnostic claim.

This keeps the carefully-built clinical system (CLAUDE.md protocol, providers) as the single
place medical reasoning happens, and stops the fitness coach from freelancing medical advice.
Implementation: a lightweight input classifier + a firm system-prompt instruction; the coach
has **no clinical tools**, only training tools.

### 7b.6 Where it reads constraints
The coach loads the §7 constraint set (derived flags, not raw medical text) so its programming
respects the L5–S1 / left-knee / elbow limits by construction. v1: constraint set maintained
manually; later it can re-derive from the health repo.

---

## 8. iOS app architecture

| Layer | Choice | Notes |
|-------|--------|-------|
| UI | **SwiftUI** | native, fast to build, good for the dashboard/charts |
| Local store | **SwiftData** (or Core Data) | offline-first; the log must work with no signal |
| Sync (optional) | **iCloud / CloudKit** | private to Mike's Apple ID; v2 |
| AI calls | **Anthropic Messages API**, direct from app | tool-use for NL parse + generation |
| Secrets | **iOS Keychain** | API key never in code or plaintext; entered once in Settings |
| Charts | Swift Charts | the volume/readiness dashboard |

**Model choices (current as of this doc; verify at build time):**
- **NL log parse** → a fast, cheap model (e.g. **Claude Haiku 4.5**, `claude-haiku-4-5`) — small structured-extraction task.
- **Workout generation/rationale** → a stronger model (e.g. **Claude Sonnet 4.6**, `claude-sonnet-4-6`) — the reasoning step.
- Use **tool use / structured outputs** for both so responses are typed JSON, not prose to parse.

**Data-flow / privacy reality:** logging and generation send the relevant snapshot (exercise
names, set counts, the encoded constraints) to the Anthropic API under Mike's own key. No
raw medical records are sent — only the *derived* constraint flags (e.g.
`no_loaded_lumbar_flexion`), not imaging text. Everything else stays on-device. Mike owns the
key and the data.

---

## 9. Screens (v1)

1. **Log** — big text field + dictation. "What did you do?" → confirmation toast. The home
   screen, because capture is the point.
2. **Balance** — the per-muscle ledger: weekly volume vs. band + readiness bars. The
   "am I over/under-training?" answer.
3. **Today** — tap to generate; review/swap/accept the proposed session; or start freeform.
4. **History** — sessions + ad-hoc sets on a timeline; edit anything.
5. **Settings** — API key (Keychain), exercise library + comfort ratings, cadence target,
   constraint set version.

---

## 10. Build roadmap

| Phase | Deliverable | Why this order |
|-------|-------------|----------------|
| **0** | This design doc + Mike's starter exercise list + agreed muscle taxonomy ✅ *(library seeded in `exercise-library.md`, 2026-06-27)* | align before code |
| **1** | Xcode project, data model, **Log screen + NL parse** working end-to-end. Full build contract: `docs/phase-1-spec.md` | capture is the core value; prove it first |
| **2** | **Balance screen** (volume + readiness from real logged data) | the over/under answer |
| **3** | **Today screen** — Claude generation + swap with clinical constraints | the planner |
| **4** | **Coach Agent** — chat surface + tool layer (§7b), auto/confirm tiers, change-undo log, clinical-deferral guardrail | the "manage my fitness" agent |
| **5** | Progression tracking + deload logic; history/edit, polish, iCloud sync | rounding out |
| **6** | (Later) app reads the health repo directly to auto-refresh constraints | full loop |

---

## 11. Decisions + open questions

Updated 2026-06-27. Resolved items are locked; open items are flagged `OWNER TODO` and do not
block Phase 1 (capture only).

### Resolved (locked)
1. **Starter exercise list — DONE.** `exercise-library.md` (27 movements, pre-tagged). Phase 0 complete.
2. **Effort vs. reps — DROP rep-counting.** Track `light/medium/hard` effort + set count.
   `reps` is nullable; "didn't count" is a first-class valid state.
3. **Split style — full-body 3×/week.** Claude rotates equivalence-class variants for freshness.
4. **App name — Anchor** (still a placeholder Mike can rename). Bundle id `com.mrihm.anchor`
   (placeholder, Mike will change).
6. **Sync — local-first now; iCloud/CloudKit is v2** (Phase 5), not v1.

### Open (OWNER TODO — not blocking Phase 1)
5. **Exercise-science constants** (§5 MEV/MAV/MRV + recovery τ): research and propose
   evidence-grounded per-muscle defaults Mike then adjusts. Needed before Phase 2 (Balance).
7. **Final muscle taxonomy:** reconcile the §3.1 list with the library; see
   `docs/muscle-taxonomy.md`. Phase 2 prerequisite.
8. **Biceps / forearms coverage:** add direct work (note `elbow_monitor` from the ulnar history)
   or leave as secondary-only. See `docs/muscle-taxonomy.md`.

---

*Next step: build **Phase 1** to the contract in `docs/phase-1-spec.md` (Xcode project + data
model + Log screen + NL parse). Compile + Simulator run must happen on a Mac.*
