---
title: "Workout Tracker — Exercise Library (seed v0.1)"
source: "Session — Mike's starter list, 2026-06-27"
date: 2026-06-27
last_updated: 2026-06-27
tags: [workout-tracker, exercise-library, app-design, project, non-clinical]
related:
  - workout-tracker/DESIGN.md
  - profile/comprehensive-health-profile.md
region: meta
status: active
---

# Exercise Library (seed v0.1)

> Canonical, human-readable library for the workout tracker. This is the Phase-0
> deliverable Mike reviews; at Phase 1 it gets exported to the app's JSON seed.
> Built from Mike's starter list (2026-06-27); a few sensible complements added and
> marked **(added)**. Mike sets `comfort` (1–5) later — defaults to 3.

## How to read the tags

- **Primary** = full stimulus credit (×1.0). **Secondary** = partial (×0.5).
- **Equivalence class** = the swap pool. Same class → interchangeable for variety. This is
  what makes "clamshells 2 days ago → band walks today" work (both `hip_abductor_iso`).
- **Pattern** = squat / hinge / press / pull / isolation / carry / core / mobility / cardio.
- **Clinical tags** = derived from `profile/comprehensive-health-profile.md` §7. Conventions:
  - `spine_neutral_req` — fine, but only with a neutral-spine cue (no loaded end-range flexion).
  - `extension_biased` / `spine_protective` — actively good for the L5–S1 picture.
  - `left_knee_priority` — unilateral / VMO-supportive; favor for the left-knee AMI deficit.
  - `bilateral_masks_left` — bilateral bodyweight can hide the left VMO/calf deficit; not bad,
    just don't let it crowd out unilateral + left-biased work.
  - `elbow_monitor` — loads through the arms; keep load moderate given the ulnar-transposition
    history (avoid heavy arm-as-lever bracing / sustained loaded elbow flexion).
  - `left_bias_target` — a muscle where the **left** side is under-recruited (calf/gastroc);
    track and cue the left specifically.

---

## Cardio / conditioning
*Counts toward general activity, not muscle hypertrophy volume. Tracked separately.*

| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Treadmill walking | — (conditioning) | calves | `steady_cardio` | cardio | `spine_protective` (normal walking load is well-tolerated) |
| Stationary bike | quads (light) | — | `steady_cardio` | cardio | `left_knee_priority` (low-impact, knee-friendly) |

## Mobility / stretch
*No volume credit; recovery-neutral to recovery-aiding.*

| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Cat–cow | spinal mobility | core | `spine_mobility` | mobility | unloaded; gentle flexion/extension cycling — fine |
| Open-book stretch | thoracic rotation | — | `thoracic_mobility` | mobility | — |
| World's greatest stretch | hip/thoracic mobility | — | `full_mobility` | mobility | — |

## Lower body — knees / quads / hams
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Air squat | quads | glutes | `squat_pattern` | squat | `bilateral_masks_left` |
| Split squat (DB) | quads | glutes, hams | `unilateral_squat` | squat | `left_knee_priority` |
| Hip hinge | hamstrings | glutes | `hip_hinge` | hinge | `spine_neutral_req` ⚠ the one to cue carefully |
| Leg curl | hamstrings | calves | `knee_flexion_iso` | isolation | knee-flexion (not extension) — `left_knee_priority` ok |
| Back extension (chair/roman) | erectors | glutes, hams | `back_extension` | hinge | `extension_biased`, `spine_protective` |
| Reverse lunge **(added)** | quads | glutes, hams | `unilateral_squat` | squat | `left_knee_priority` (unilateral swap for split squat) |
| Wall sit **(added)** | quads | glutes | `squat_pattern` | squat | low-shear isometric; knee-friendly |

## Lower leg
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Calf raise | calves | — | `calf_raise` | isolation | `left_bias_target` (cue/track the left gastroc) |
| Tibial (tibialis) raise | tibialis anterior | — | `tib_raise` | isolation | anterior-shin balance work |
| Single-leg calf raise **(added)** | calves | — | `calf_raise` | isolation | `left_bias_target` (isolates the under-recruited left) |

## Hips
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Banded hip-abductor work | hip abductors | glutes | `hip_abductor_iso` | isolation | — |
| Clamshell (band around quads) | hip abductors | glutes | `hip_abductor_iso` | isolation | — |
| Resistance-band lateral walk **(added)** | hip abductors | glutes | `hip_abductor_iso` | isolation | direct swap for clams (Mike's own example) |
| Banded hip-flexor / front raise | hip flexors | quads | `hip_flexor_iso` | isolation | — |
| Banded hip-adductor squeeze **(added)** | hip adductors | — | `hip_adductor_iso` | isolation | balances the abductor work |

## Posterior chain / glutes / core
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Glute bridge (floor) | glutes | hams, core | `bridge` | core | `extension_biased`, `spine_protective` (pushes disc content anteriorly) |
| Side bridge / side plank | core (obliques, QL) | hip abductors | `side_core` | core | `spine_neutral_req` |
| Dead bug | deep core (anti-extension) | — | `anti_extension_core` | core | `spine_protective` (trains neutral-spine control) |
| Bird-dog **(added)** | deep core, erectors | glutes | `anti_extension_core` | core | `spine_protective` (hands-and-knees offload) |

## Upper body — push
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Chest press (cable or DB) | chest | front delts, triceps | `horizontal_press` | press | `elbow_monitor` (moderate load) |
| Dumbbell lateral raise | side delts | — | `lateral_raise` | isolation | `elbow_monitor` (light) |
| Tricep extension | triceps | — | `tricep_iso` | isolation | `elbow_monitor` (loaded elbow ext — keep moderate) |

## Upper body — pull / scapular / posterior shoulder
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Machine / cable row | upper back | lats, biceps, rear delts | `horizontal_row` | pull | seated/supported → `spine_neutral`; `elbow_monitor` |
| Cable face pull | rear delts | mid traps, upper back | `rear_delt_face` | pull | `elbow_monitor` (light) |
| Loop-band scapular/delt retraction | rear delts | mid/lower traps | `rear_delt_face` | pull | light; rehab-style |
| Prone W's (DB) | lower traps, rear delts | scapular stabilizers | `prone_scap_raise` | pull | prone, light DBs |
| Dumbbell shrug | upper traps | forearms (grip) | `shrug` | isolation | `elbow_monitor` (grip/bracing load) |
| Prone Y/T raise **(added)** | lower traps, rear delts | — | `prone_scap_raise` | pull | swap partner for prone W's |

## Neck
| Exercise | Primary | Secondary | Equiv. class | Pattern | Clinical tags |
|----------|---------|-----------|--------------|---------|---------------|
| Supine chin-tuck + slight head raise | deep neck flexors | — | `neck_flexor` | isolation | cervical MRI normal → safe; stop if it provokes suboccipital guarding |

---

## Coverage check (which muscle groups have a "home")

✅ quads · hamstrings · glutes · calves · tibialis · hip abductors · hip adductors · hip flexors ·
chest · front delts · side delts · rear delts · triceps · upper back · lats · traps · core · neck

⚠ **Light coverage** (only secondary credit so far) — flag if Balance shows these chronically
under-trained:
- **Biceps** — only hit secondarily via rows. *(Optional add: band/DB curl — but `elbow_monitor`
  applies given the ulnar history; your call.)*
- **Forearms/grip** — secondary via shrugs/rows only.

These are intentional gaps, not oversights — both involve the most arm/elbow loading, so I
left them light pending your call. Easy to add if you want them.

---

## Proposed default split (3×/week full-body)

Full-body each session fits 3×/week best — it keeps every muscle's weekly frequency at ~2–3,
which is where the over/under ledger stays cleanest. Claude rotates equivalence-class variants
each session for freshness. Rough template (Claude adjusts from the live ledger):

| | Day A | Day B | Day C |
|---|---|---|---|
| **Knee/quad** | Split squat (unilateral) | Wall sit / air squat | Reverse lunge (unilateral) |
| **Posterior** | Hip hinge | Back extension | Glute bridge |
| **Hip** | Clamshell | Band lateral walk | Banded abductor + adductor |
| **Push** | Chest press | Lateral raise | Tricep ext |
| **Pull** | Cable row | Face pull | Prone W's / shrug |
| **Core** | Dead bug | Side bridge | Bird-dog |
| **Lower leg** | Calf raise (L-biased) | Tibial raise | Single-leg calf raise |
| **Neck** | Chin-tuck | — | Chin-tuck |
| **Cardio** | Walk | Bike | Walk |

Note the deliberate biases baked in: **left-side unilateral knee + left-biased calf work every
session** (for the AMI deficit), **extension-biased posterior chain** (spine-protective), and
**hip-abductor variety rotated** across the three days.
