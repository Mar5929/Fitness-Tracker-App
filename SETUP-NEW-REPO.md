# How to move this folder into its own GitHub repo

This `workout-tracker/` folder is self-contained (README, design docs, `.gitignore`) and ready
to become a standalone repo. Claude couldn't create the repo directly — its GitHub access this
session is scoped to the health-knowledge-base repo only — so run one of these on your Mac.
Pick **Option A** (simplest).

> Replace `anchor-workout-tracker` with whatever name you want, and `--private` with `--public`
> if you prefer. Assumes the GitHub CLI (`gh`) is installed and authenticated (`gh auth login`).

---

## Option A — fresh repo, no history (recommended, ~30 sec)

History of these few design commits doesn't matter for a brand-new project.

```bash
# 1. From wherever you keep code:
gh repo create anchor-workout-tracker --private --clone
cd anchor-workout-tracker

# 2. Copy the folder contents in (adjust the source path to your health-kb checkout):
cp -R /path/to/Health-Knowledge-Base/workout-tracker/. .

# 3. Commit + push
git add -A
git commit -m "Initial import: Anchor workout tracker design + exercise library"
git push
```

Done — `anchor-workout-tracker` now holds the design doc, exercise library, README, and
`.gitignore`, separate from your medical repo.

---

## Option B — preserve the git history of just this folder (subtree split)

If you want the commit history of `workout-tracker/` to carry over:

```bash
# In your Health-Knowledge-Base checkout, on the branch that has workout-tracker/:
git subtree split --prefix=workout-tracker -b workout-tracker-export

# Create the empty repo (no clone):
gh repo create anchor-workout-tracker --private

# Push the split branch as the new repo's main:
git push https://github.com/<your-username>/anchor-workout-tracker.git workout-tracker-export:main

# (optional) clean up the temporary branch:
git branch -D workout-tracker-export
```

---

## After the repo exists

- Tell Claude the new repo name. In a session whose GitHub scope includes it, Claude can then
  push the **Phase 1 Xcode scaffold** (data models + Log screen + NL parse) straight into it.
- Until then, Claude can still *write* all the app code in this folder on the health-kb branch,
  and you copy it across with the same `cp -R` step.

## Should I also delete `workout-tracker/` from the health-kb repo afterward?

Optional. Once it lives in its own repo you can remove it from health-knowledge-base to keep
that repo purely medical:

```bash
# in Health-Knowledge-Base:
git rm -r workout-tracker
git commit -m "Move workout tracker to its own repo"
git push
```

Leave it if you'd rather keep a copy in both places for now — your call.
