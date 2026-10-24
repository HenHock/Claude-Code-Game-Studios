# /test-setup — Phase 2: Present Plan

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Present Plan

Based on the existing state, present a plan:

```
## Test Setup Plan — Unity

I will create the following (skipping any that already exist):

tests/
  smoke/          — Critical path test list (15-minute manual gate)
  README.md       — Test framework documentation

Assets/Scripts/Testing/
  EditMode/<Feature>/  — Isolated unit tests for formulas, state, and logic
                         (+ <Project>.Tests.EditMode.asmdef)
  PlayMode/<Feature>/  — Cross-system tests in a running scene, save/load round-trips
                         (+ <Project>.Tests.PlayMode.asmdef)
  [Unity does not compile code in tests/, so unit and integration tests
   live under Assets/Scripts/Testing/; the feature path mirrors
   Assets/Scripts/Core/<Feature>/ — see .claude/docs/unity-folder-structure.md]

production/qa/
  evidence/       — Screenshot and manual test sign-off records

[Unity-specific files — see details below]

.github/workflows/tests.yml  — CI: run tests on every push to main

Estimated time: ~5 minutes to create all files.
```

Ask: "May I create these files? I will not overwrite any test files that
already exist at these paths."

**At `collaborative` and `guided`** — do not proceed without approval. These are
**new** files, and `automation-modes.md:81` gates new-file writes in `guided` too,
so the answer is the same in both modes. **At `autonomous`** — create them and log
the decision; do not block.

---
