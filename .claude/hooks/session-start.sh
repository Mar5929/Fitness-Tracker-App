#!/usr/bin/env bash
# SessionStart hook for Anchor.
# Prints orientation so a brand-new Claude Code session is immediately current:
# what the repo is, the reading order, live status, and git state.
# Read-only and fast — never fails the session (always exits 0).

set -uo pipefail
cd "$(dirname "$0")/../.." 2>/dev/null || exit 0

echo "=================================================================="
echo " ANCHOR — clinically-aware iOS strength tracker"
echo "=================================================================="
echo
echo "NEW SESSION ORIENTATION. Before doing anything, read in this order:"
echo "  1. CLAUDE.md            — orientation, codemap, hard rules"
echo "  2. docs/STATUS.md       — LIVE state: current phase, next action, TODOs"
echo "  3. DESIGN.md            — master design doc"
echo "  4. exercise-library.md  — exercise library (source for seed.json)"
echo
echo "Hard rules (full text in CLAUDE.md §4):"
echo "  • TRAINING assistant only — never diagnose/reassure; defer clinical Qs."
echo "  • Track set-count + effort, never reps, never heart rate."
echo "  • Stay within the current phase; don't exceed scope without asking."
echo "  • API key is Keychain-only; secrets never committed."
echo "  • iOS code is often written on Linux (no Xcode) — verify on a Mac."
echo

# --- Live status line(s) from docs/STATUS.md ---
if [ -f docs/STATUS.md ]; then
  echo "------------------------------------------------------------------"
  echo " From docs/STATUS.md:"
  grep -E '^\- \*\*(Last updated|Last session did|Active branch|Current phase):' docs/STATUS.md \
    | sed 's/\*\*//g; s/^- /   /' || true
  echo "------------------------------------------------------------------"
  echo
fi

# --- Git state ---
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  echo "Git: on branch '${branch}'"
  echo "  Expected dev branch: claude/app-planning-build-b7s0tt"
  echo "  Last 3 commits:"
  git log --oneline -3 2>/dev/null | sed 's/^/    /' || true
  changed="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${changed}" != "0" ]; then
    echo "  Uncommitted changes: ${changed} file(s) — run 'git status' for detail."
  else
    echo "  Working tree clean."
  fi
fi

echo
echo "When you finish work: update docs/STATUS.md, then commit + push."
echo "=================================================================="
exit 0
