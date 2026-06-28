# Phase 2 Prep — taxonomy lock + tuning constants (PROPOSAL)

> **Status: PROPOSAL awaiting OWNER approval.** These resolve the OWNER TODOs in
> `DESIGN.md §11` and `docs/muscle-taxonomy.md` that gate Phase 2 (the Balance
> ledger). **Nothing here is baked into `Anchor/Seed/seed.json` yet** — the seed
> still ships zeros. Once you approve (or edit) the numbers, a follow-up change
> writes them into the seed + `MuscleGroup` defaults.
>
> **Scope note:** these are *exercise-science / training* parameters, not clinical
> ones. They set how the volume ledger and readiness score behave. They do **not**
> change the clinical constraint tags (those stay as in `exercise-library.md`).

---

## 0. TL;DR — what I need from you

1. **Taxonomy:** keep the **21 groups** (provisional set in `muscle-taxonomy.md`),
   with **`tibialis` + `neck` flagged as "tracked, not volume-banded"** (rehab/
   balance work — we track frequency, not an over/under signal). ✅ recommend.
2. **Biceps / forearms:** **add one light direct biceps movement** (band/DB curl,
   tagged `elbow_monitor`); leave **forearms secondary-only**. Rows alone leave
   biceps below MEV, so Balance would always read "under" otherwise.
3. **Left/right:** **cue-only for now** (a tag/note), *not* a per-side data split.
   Volume landmarks aren't defined per-side, and splitting doubles the taxonomy.
4. **Constants:** approve the per-group **MEV / MAV / MRV** (weekly sets) and
   **recovery `tau`** (days) in §4. Edit any you disagree with — they're starting
   points, and you're the one in the body.

Reply with "approve" or line-edits and I'll write them into the seed.

---

## 1. The evidence base (and how confident each piece is)

**A. Volume → hypertrophy is dose-dependent, productive roughly 10–20 sets/muscle/week, with diminishing returns.** *(High confidence — peer-reviewed.)*
- Schoenfeld, Ogborn & Krieger (2017), *J Sports Sci* — meta-analysis: muscle
  growth increases with weekly sets; ~+0.37%/set; **10+ sets/week** > lower
  volumes. PMID 27433992, DOI 10.1080/02640414.2016.1210197.
- Pelland, Refalo et al. (2024/25) dose-response meta-regression — confirms a
  continued but **diminishing** return (~+0.24%/set around an average of ~12
  sets/wk), with frequency acting mostly *through* total volume.
  [PubMed 41343037](https://pubmed.ncbi.nlm.nih.gov/41343037/) ·
  [SportRxiv preprint](https://sportrxiv.org/index.php/server/preprint/view/460).

**B. The MEV/MAV/MRV landmark framing + the per-muscle pattern** (small/low-joint-stress muscles like delts, biceps, calves tolerate more weekly sets; big systemically-costly muscles like quads/hams have lower ceilings). *(Moderate confidence — practitioner model, consistent with A.)*
- Renaissance Periodization / Israetel volume landmarks: MEV ≈ 4–8, MAV ≈ 12–20,
  MRV ≈ 18–30 sets/wk for intermediates, varying by muscle.
  [RP Strength — Volume Landmarks](https://rpstrength.com/blogs/articles/training-volume-landmarks-muscle-growth).
  This is a coaching model, *not* peer-reviewed per-muscle — treat the **shape**
  as solid and the **exact per-muscle numbers** as sane defaults to tune.

**C. Recovery: muscle protein synthesis is elevated ~24–48 h post-session (peaks ~24 h, shorter in trained lifters); bigger muscles take longer (quads ~48–72 h, small muscles less).** *(Moderate-high confidence.)*
- MacDougall et al. (1995), *Can J Appl Physiol* — MPS elevated ~24–48 h, peak
  ~24 h. PMID 8563679.
- Trained status shortens the response (Damas et al., 2016). Larger muscle mass
  ⇒ more total damage ⇒ longer recovery
  ([overview](https://biologyinsights.com/do-smaller-muscles-recover-faster-than-larger-ones/)).
- Frequency: 2×/week ≥ 1×/week when weekly volume is equated (Schoenfeld et al.,
  2016, *Sports Med*, PMID 27102172) — our full-body 3×/week keeps each muscle at
  ~2–3×, which is squarely in the supported range.

> Live PubMed lookup was intermittently unavailable while writing this; citations
> were grounded via web sources + known literature. **Please sanity-check the DOIs/
> PMIDs before we treat these as final** (or I can re-pull them when PubMed is up).

---

## 2. How the constants plug into the model (DESIGN §5)

- **Volume ledger:** weekly sets per muscle = Σ over the rolling 7 days of
  `sets × muscleCredit`, where `muscleCredit` = **1.0 primary / 0.5 secondary**.
  Compare to the band: `< MEV` → **UNDER**, `MEV…MAV` → **IN BAND**, `> MRV` →
  **OVER** (the MAV→MRV zone is "productive but approaching the ceiling").
- **Readiness:** `readiness(t) = 100 − drop · exp(−Δt / tau)`, `tau` in **days**.
  Bigger `tau` = slower recovery. `drop` scales with session
  `Σ(sets × effortWeight × muscleCredit)` (effortWeight light 0.6 / med 1.0 /
  hard 1.4, already in `Enums.swift`). The **`drop` scaling factor is a Phase-2
  *implementation* calibration**, not a per-muscle stored constant — only `tau`
  + the three landmarks live on `MuscleGroup`.

---

## 3. Taxonomy decisions (resolving muscle-taxonomy.md OWNER TODOs)

| Question | Recommendation | Why |
|----------|----------------|-----|
| Lock the 21 groups? | **Yes**, as-is | Every library Primary has a home; matches the seed already shipped. |
| `erectors` own group vs. fold into core? | **Keep separate** | Trained directly (back extension, bird-dog) and spine-relevant; folding hides it. |
| `tibialis`, `neck`? | **Keep, but "tracked-not-banded"** | Balance/rehab targets, not hypertrophy drivers. Track frequency/last-trained; don't compute an over/under band (set MEV small, no MRV alarm). |
| Biceps / forearms | **Add 1 direct biceps** (`elbow_monitor`); forearms secondary-only | Otherwise biceps sits under MEV permanently and Balance nags falsely. Forearms get enough indirect grip work. Honors the ulnar-history "keep arm load moderate." |
| Left/right split | **Cue-only tag for now** | No per-side volume science; per-side groups double everything. The `left_bias_target` / `left_knee_priority` tags already carry the cue; revisit if the ledger proves it's needed. |

> If you approve "add 1 direct biceps," I'll add e.g. **Band/DB biceps curl** to
> `exercise-library.md` + the seed, tagged `elbow_monitor`, `equiv: biceps_curl`.

---

## 4. PROPOSED constants (weekly sets; `tau` in days)

Credit reminder: secondary work counts ×0.5, so e.g. a primary-MEV of 8 can be
partly met by rows/presses that hit the muscle secondarily.

**Tier legend** — recovery/fatigue grouping driving `tau`:
F = fast (small, low systemic cost) · M = medium · S = slow (large, costly).

| Muscle | Tier | tau (d) | MEV | MAV | MRV | Confidence | Notes |
|--------|:----:|:------:|:---:|:---:|:---:|------------|-------|
| chest | M | 1.5 | 8 | 16 | 22 | mod | RP-typical. |
| upper_back | S | 2.0 | 8 | 16 | 25 | mod | "Back" split into upper_back+lats; high tolerance. |
| lats | S | 2.0 | 8 | 14 | 22 | mod | Pull/row credit shared with upper_back. |
| traps | F | 1.2 | 4 | 14 | 26 | mod | Tolerate high volume; lots of indirect. |
| front_delts | F | 1.2 | 4 | 10 | 16 | mod | Heavy indirect from all pressing; low direct need. |
| side_delts | F | 1.0 | 8 | 18 | 26 | mod | High tolerance, low joint stress. |
| rear_delts | F | 1.0 | 6 | 14 | 22 | mod | Face pulls / band work; recovers fast. |
| biceps | F | 1.0 | 8 | 15 | 24 | mod | **Assumes 1 direct movement added** (else drop MEV→0 and accept "under"). `elbow_monitor`. |
| triceps | F | 1.1 | 6 | 12 | 18 | mod | Indirect from press; moderate ceiling. `elbow_monitor`. |
| forearms | F | 1.0 | 2 | 10 | 20 | low | Secondary-only; mostly grip/indirect. |
| quads | S | 2.2 | 8 | 14 | 20 | mod | Lower ceiling — systemic leg fatigue. Unilateral bias (left knee). |
| hamstrings | S | 2.0 | 6 | 12 | 18 | mod | — |
| glutes | M | 1.5 | 6 | 14 | 20 | mod | Owner emphasizes (extension-biased, spine-protective). |
| erectors | M | 1.8 | 4 | 10 | 16 | low | Back-extension/anti-extension; keep conservative for L5–S1. |
| hip_abductors | F | 1.0 | 6 | 14 | 22 | low | Rehab-relevant; band work tolerates frequent training. |
| hip_adductors | F | 1.1 | 4 | 10 | 16 | low | Balances abductor work. |
| hip_flexors | F | 1.0 | 2 | 8 | 14 | low | Light; supportive. |
| calves | F | 1.0 | 8 | 14 | 20 | mod | Left-biased tracking (`left_bias_target`). |
| tibialis | F | 0.8 | 2 | — | — | n/a | **Tracked, not banded** — frequency only. |
| core | F | 1.0 | 0 | 16 | 25 | mod | Huge indirect; MEV ~0 (RP). Anti-extension bias for spine. |
| neck | F | 0.8 | 2 | — | — | n/a | **Tracked, not banded** — chin-tucks; stop if it spikes guarding. |

**Reading the rehab biases into the numbers:** quads carry the lowest large-muscle
ceiling + longest `tau` (left-knee unilateral focus means quality over raw volume);
glutes/erectors stay conservative to respect the L5–S1 picture; calves + hip
abductors are set to tolerate frequent left-biased work; `elbow_monitor` muscles
(biceps/triceps/forearms/traps) keep moderate ceilings.

---

## 5. After you approve

1. Write `tau/mev/mav/mrv` into `seed.json` + `MuscleGroup` (replace the zeros).
2. If biceps approved: add the curl to `exercise-library.md` + seed.
3. Add a `banded`/`tracked-not-banded` flag handling so `tibialis`/`neck` show
   frequency, not an over/under bar.
4. Then build the **Balance** screen (Phase 3 in the file order, Phase 2 in the
   roadmap): per-muscle weekly volume vs. band + readiness bars, Swift Charts.

## 6. Open calibration items (Phase-2 *implementation*, not blocking approval)

- The readiness `drop` scaling factor (so one hard session reads a sensible %).
- Rolling-window edge behavior (exactly 7 days vs. decaying weight).
- Whether "secondary ×0.5" should differ for compound-heavy muscles.

These get tuned against your real logged data once Balance is live — they don't
need a number today.
