# Running Anchor (Phase 1)

> The project is hand-authored and **was not compiled on the machine that wrote
> it** (a Linux container with no Xcode/Swift toolchain). The steps below are the
> exact way to open, build, and run it on a Mac. The first `xcodebuild` on a Mac
> is the real acceptance gate (phase-1-spec §9).

## Requirements
- macOS with **Xcode 16+** (the project uses the file-system-synchronized group
  format, `objectVersion = 77`).
- iOS 17+ Simulator (installed with Xcode).

## Open + run in the Simulator (GUI)
1. `open Anchor.xcodeproj`
2. Pick an iPhone simulator in the scheme/destination dropdown (e.g. *iPhone 15*).
3. Press **▶ Run** (`Cmd-R`).

All Swift files, `seed.json`, and the asset catalog are picked up automatically
because the `Anchor/` folder is a synchronized group — you do **not** need to add
files to the target by hand. If you add new source files, just drop them under
`Anchor/` and they're included.

## Build / run from the command line
```bash
# List available simulators
xcrun simctl list devices available

# Build for a simulator
xcodebuild -project Anchor.xcodeproj -scheme Anchor \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# Or build + run the test action (no tests yet in Phase 1)
xcodebuild -project Anchor.xcodeproj -scheme Anchor \
  -destination 'platform=iOS Simulator,name=iPhone 15' -resultBundlePath build/Result test
```

## Smoke test (the Phase 1 acceptance demo)
With **no API key set** (so the on-device mock parser is used):
1. Launch the app — it opens on the **Log** tab.
2. Type: `3 sets of calf raises and a few hard rows`
3. Tap **Log**. You should see a confirmation banner like
   `Logged: 3× Calf raise (Calves), 3× Machine / cable row (Upper Back)` with an
   **Undo**, and two rows appear under **Today** (reps shown as "not counted",
   rows marked **Hard**).
4. Tap a row → the quick-edit screen lets you change sets/effort/source and
   toggle reps on/off.
5. Go to **Settings** → paste an Anthropic key → it's stored in the Keychain and
   the status flips to "API key stored". Subsequent logs use the Claude parser;
   clearing the key falls back to the mock. (No key required for the app to work.)

## Notes
- Bundle id is `com.mrihm.anchor` (placeholder — change in target settings, or
  the project Debug/Release `PRODUCT_BUNDLE_IDENTIFIER`, before archiving).
- If signing complains, set your team under *Signing & Capabilities*; for the
  Simulator, automatic signing with no team is usually fine.
