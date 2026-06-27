# Muscle Taxonomy — reconciliation + provisional set

> Granular detail for [`../DESIGN.md`](../DESIGN.md) §3.1. The whole app reasons in muscle
> groups, so there must be exactly **one** canonical list. Right now there are two slightly
> different lists in the repo. This file reconciles them and gives a **provisional** set Phase 1
> can seed from.
>
> **Status: OWNER TODO — taxonomy is not finalized** (owner chose to leave it flagged, 2026-06-27).
> Final taxonomy is a prerequisite for Phase 2 (the volume/readiness ledger), not for Phase 1.

---

## The two existing lists

**DESIGN.md §3.1 (17):** chest, upper_back, lats, traps, front_delts, side_delts, rear_delts,
biceps, triceps, forearms, quads, hamstrings, glutes, hip_abductors, hip_adductors, calves, core.

**exercise-library.md coverage check (18):** quads, hamstrings, glutes, calves, **tibialis**,
hip_abductors, hip_adductors, **hip_flexors**, chest, front_delts, side_delts, rear_delts,
triceps, upper_back, lats, traps, core, **neck**.

### Mismatches to settle
- In the library but **not** in §3.1: `tibialis`, `hip_flexors`, `neck`.
- In §3.1 but **not** in the library's "has a home" list: `biceps`, `forearms` (the library hits
  these only as **secondary** credit via rows/shrugs, and flags them as light-coverage gaps).
- The library's Primary column also names targets that map to no group yet: **`erectors`**
  (back extension, bird-dog), `obliques/QL` and `deep core` (fold into `core`?), `deep neck
  flexors` (fold into `neck`?).

---

## Provisional canonical set (Phase 1 seed only)

Use this to seed the store so logging works. **Not final.** 21 groups:

```
chest · upper_back · lats · traps · front_delts · side_delts · rear_delts ·
biceps · triceps · forearms · quads · hamstrings · glutes · erectors ·
hip_abductors · hip_adductors · hip_flexors · calves · tibialis · core · neck
```

Notes on the provisional choices:
- Added `erectors`, `hip_flexors`, `tibialis`, `neck` so every library Primary has a home.
- `biceps` and `forearms` are kept (they exist as secondary-credit targets) but stay
  light-coverage until the owner decides whether to add direct work.
- `obliques/QL` and `deep core` fold into `core`; `deep neck flexors` fold into `neck`.

---

## OWNER TODO (decide before Phase 2)

1. **Lock the final group list.** Confirm or adjust the 21 above. Specifically:
   - Keep `erectors` as its own group, or fold into `core` / a `spinal` group?
   - Keep `tibialis` and `neck` as tracked groups, or out of scope for the ledger?
2. **Biceps / forearms:** add direct movements (the library flags `elbow_monitor` given the ulnar
   history), or leave them as secondary-only and accept they may read "under-trained"?
3. **Left-bias tracking:** the library tags `calves` (and the left knee/VMO work) for left-side
   under-recruitment. Decide whether left/right is a per-group split or a cue-only note.
4. **Tuning constants per group** (DESIGN.md §5, still placeholders): recovery `tau`, and volume
   landmarks `MEV` / `MAV` / `MRV`. These need evidence-grounded defaults before the Balance
   ledger means anything. This is the §11 Q5 item.

Until these are settled, the Balance screen (Phase 2) cannot give a trustworthy over/under signal.
Phase 1 (capture only) is unaffected.
