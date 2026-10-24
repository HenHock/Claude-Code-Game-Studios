# /test-setup — Phase 3: Create Directory Structure

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Create Directory Structure

**In this file:**

- `tests/README.md`
- `production/qa/evidence/.gitkeep`
- Unity-specific files

After approval, create the following files:

### `tests/README.md`

````markdown
# Test Infrastructure

**Engine**: Unity [version]
**Test Framework**: Unity Test Framework (NUnit)
**CI**: `.github/workflows/tests.yml`
**Setup date**: [date]

## Directory Layout

```
tests/
  smoke/          # Critical path test list for /smoke-check gate
Assets/Scripts/Testing/
  EditMode/<Feature>/   # Isolated unit tests (formulas, state machines, logic)
  PlayMode/<Feature>/   # Cross-system and save/load tests
```

Unit and integration tests live under `Assets/Scripts/Testing/EditMode|PlayMode/[Feature]/`,
mirroring `Assets/Scripts/Core/[Feature]/` (`.claude/docs/unity-folder-structure.md`);
`tests/` keeps this README and `smoke/`. Every `tests/unit/` path below means
that test root.

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

[Unity test commands — see below]

## Test Naming

Names follow `.claude/rules/test-standards.md`:
- class `[System]Tests` in `[System]Tests.cs`, method `[Scenario]_[Expected]`
  — `CombatTests.cs` → `BaseAttack_ReturnsExpectedDamage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
````

The README and this skill's completion summary name the same evidence path —
`production/qa/evidence/` is where `/smoke-check`, `/test-evidence-review`,
`/qa-plan` and the evidence table in `.claude/docs/coding-standards.md` read,
so a `tests/evidence/` would be a directory nothing reads.

### `production/qa/evidence/.gitkeep`

Create it empty. Git does not keep an empty directory, and this is where
`/story-done`, `/smoke-check` and `/test-evidence-review` look for screenshots and
sign-off records — the completion summary lists it, so it must exist.

### Engine-specific files

#### Unity

Tests live under **`Assets/Scripts/Testing/`** — Unity compiles only `Assets/` and
`Packages/`. A test under `tests/` is never compiled, and the run then reports
**0 tests, `Passed`, exit 0** (verified on 6000.3.23f1): a false pass.

First check the Test Framework package:
`grep -q 'com.unity.test-framework' Packages/manifest.json`. Without it
`-runTests` does not fail — it hangs. If absent, ask to add
`"com.unity.test-framework"` to `dependencies` at the version your editor
bundles. Unity 6 releases bundle different ones — 1.6.0 in 6000.3.23f1, 1.5.1 in
6000.1.0f1 — so read it rather than copy a number: on Windows it is the
`version` in `Data/Resources/PackageManager/BuiltInPackages/com.unity.test-framework/package.json`
under the folder that holds `Unity.exe`.

`<Project>` is `project.name` from `project.yaml` (else the project name in `CLAUDE.md`)
with spaces and punctuation removed. `bash .claude/scripts/test-scaffold.sh unity`
writes all three files below with it filled in (and `--dry-run` shows the paths).

Create `Assets/Scripts/Testing/Shared/<Project>.Tests.Shared.asmdef` — shared test
helpers (`/test-helpers`), used by both modes, so no editor-only references:
```json
{
  "name": "<Project>.Tests.Shared",
  "references": ["UnityEngine.TestRunner", "<Project>.Core", "<Project>.Tests.Shared"],
  "includePlatforms": [],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

Create `Assets/Scripts/Testing/EditMode/<Project>.Tests.EditMode.asmdef` — unit tests, no Play Mode:
```json
{
  "name": "<Project>.Tests.EditMode",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner", "<Project>.Core", "<Project>.Tests.Shared"],
  "includePlatforms": ["Editor"],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

Create `Assets/Scripts/Testing/PlayMode/<Project>.Tests.PlayMode.asmdef` — integration tests in a
running scene:
```json
{
  "name": "<Project>.Tests.PlayMode",
  "references": ["UnityEngine.TestRunner", "<Project>.Core"],
  "includePlatforms": [],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
```

> **A test assembly cannot see code in the default `Assembly-CSharp`.** An
> `.asmdef` can reference only other `.asmdef`s. The game's gameplay code lives in
> `Assets/Scripts/Core/` under `<Project>.Core.asmdef`, which `/setup-engine`
> creates (`.claude/docs/unity-folder-structure.md`). If it is missing, ask before
> creating it; the test assemblies do not compile without it. Add any other
> game assembly a test names to both test assemblies' `references`. The
> opt-in `<Project>.Debugging` assembly is behind `ENABLE_DEBUGGING`, so tests
> reference it only under that define.
> Moving scripts into an `.asmdef` changes what they can see, so before creating it:
>
> - **List the packages the scripts use.** `Assembly-CSharp` references every
>   package on its own; an `.asmdef` references only what it names. Read the
>   scripts' `using` lines and add the matching assemblies — commonly
>   `"Unity.InputSystem"`, `"Unity.TextMeshPro"`, `"UnityEngine.UI"`.
>   Name only packages the project has installed.
> - **Give each `Editor/` folder its own `.asmdef`** with
>   `"includePlatforms": ["Editor"]` (editor scripts live in
>   `Assets/Scripts/Editor/<Feature>/` as `<Project>.Editor`). Otherwise
>   editor scripts join the runtime assembly, and `using UnityEditor;` breaks the
>   player build.

Note in the README: **Running Unity tests** (use the editor executable —
`Unity` on `PATH` may be Unity's separate CLI, not the editor)
```
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```
Exit **0** when every test passes, **2** when any fails. Exit 1 or 3 is a FAIL
too: 1 is a compile error, which writes no results file, and 3 a failed run.
So is 4 (an unknown `-testPlatform`), and any other non-zero exit.
Delete `test-results/editmode.xml` before each run so an old file is never read
as a new result. Read the `<test-run>`
element of the results file: `testcasecount="0"` means nothing was compiled or
found — report it as not assessed, never as a pass. Do not add `-quit`;
`-runTests` exits by itself. Play Mode is the second line: a separate run with
its own results file, read the same way, and deleted before each run the same
way. An Edit Mode run never runs the tests in `Assets/Scripts/Testing/PlayMode/`, so
`/smoke-check` runs both whenever that folder holds tests.

---
