#!/usr/bin/env bash
# test-scaffold.sh — creates the files /test-setup scaffolds for Unity,
# never overwriting one that exists, and prints per path whether it was
# created, already there or skipped, then the inputs it still needs.
#
# Replaces the file-by-file creation of a test setup: the README, the evidence
# folder's .gitkeep, the Unity test assembly definitions, the CI
# workflow and the smoke-test seed.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# It reports what it did with each path and what is still missing; whether
# the project may advance a gate on the strength of it is the skill's call.
#
# Usage: bash .claude/scripts/test-scaffold.sh ENGINE [--dry-run | --list] [--root DIR]
#          [--date YYYY-MM-DD]
#   ENGINE          unity (the engine.name value, in any case)
#   --dry-run       print what would be created (WOULD_CREATE), write nothing
#   --list          print the project-relative paths this engine's scaffold
#                   creates, one per line and nothing else, whatever already
#                   exists (the write guard reads it for its never-overwrite rule)
#   --root DIR      the project; defaults to the repo this script is in
#   --date D        the setup date for the README (default: today)
#   -h, --help      this text
#
# Files, in this order (the skill's Phases 3 to 5):
#   all      tests/README.md, production/qa/evidence/.gitkeep
#   unity    Assets/Scripts/Testing/Shared/<Project>.Tests.Shared.asmdef,
#            Assets/Scripts/Testing/EditMode/<Project>.Tests.EditMode.asmdef,
#            Assets/Scripts/Testing/PlayMode/<Project>.Tests.PlayMode.asmdef
#            (layout: .claude/docs/unity-folder-structure.md; <Project> is
#            project.name of project.yaml with everything but letters, digits
#            and underscores removed, "Game" while it is unset)
#   all      .github/workflows/tests.yml, tests/smoke/critical-paths.md
# Unity tests live in the engine's test root because it does not compile code
# under tests/.
# The README carries the setup date and the engine version (engine.version of
# project.local.yaml, then project.yaml). A value that is not known stays as the
# skill writes it in square brackets and is listed as an input still needed.
#
# Output: TSV.
#   engine <name>, mode write|dry-run, then per path
#   CREATED <path> | WOULD_CREATE <path> | EXISTS <path> | SKIPPED <path> <reason>
#   | FAILED <path> <reason>, then created (or would_create) <n>, exists <n>,
#   skipped <n> (and failed <n> when above 0), then
#   NEEDS <id> <file> <what> for each input still needed.
#   EXISTS means the path was there (a file, a folder or a link) and was not
#   touched. A file is written with the shell's noclobber on, so one that
#   appears between the check and the write is left alone too.
#
# Exit codes: 0 every path created or already there; 1 the root cannot be read;
# 2 usage error; 3 a path was skipped (its reason is in the row); 4 a file or
# folder could not be created (FAILED). Never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for sed and the YAML reader.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "test-scaffold: $1 (try --help)" >&2; exit 2; }
TAB=$(printf '\t')

ENGINE=""; MODE=write; ROOT_ARG=""; DATE_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) [ "$MODE" != list ] || usage "--list and --dry-run cannot be combined"; MODE=dry-run; shift ;;
    --list) [ "$MODE" != dry-run ] || usage "--list and --dry-run cannot be combined"; MODE=list; shift ;;
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --date) [ $# -ge 2 ] || usage "--date needs a value"; DATE_ARG="$2"; shift 2 ;;
    --date=*) DATE_ARG="${1#--date=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) usage "unknown argument: $1" ;;
    *) [ -z "$ENGINE" ] || usage "one engine at a time, got $ENGINE and $1"; ENGINE="$1"; shift ;;
  esac
done
[ -n "$ENGINE" ] || usage "no engine: unity"
ENG=$(printf '%s' "$ENGINE" | tr '[:upper:]' '[:lower:]')
case "$ENG" in
  unity) ;;
  *) usage "engine must be unity (the engine.name value), got $ENGINE" ;;
esac
if [ -n "$DATE_ARG" ]; then
  case "$DATE_ARG" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) usage "--date takes YYYY-MM-DD, got $DATE_ARG" ;;
  esac
fi

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "test-scaffold: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "test-scaffold: cannot reach the repo root" >&2; exit 1; }
fi

# ------------------------------------------------------------ names and version
# The engine version, as project-state.sh reads project.yaml: the shared reader.
VER=""
if [ -f "$HERE/yaml-get.awk" ]; then
  for _yf in project.local.yaml project.yaml; do
    if [ -z "$VER" ] && [ -f "$_yf" ]; then
      VER=$(YG_PATH=engine.version awk -f "$HERE/yaml-get.awk" "$_yf")
    fi
  done
fi
# A version goes into file text: keep it to the characters a version has.
case "$VER" in ''|-|*[!A-Za-z0-9._+-]*) VER="" ;; esac

# <Project> for the assembly names: project.name, spaces and punctuation dropped.
PROJ=""
if [ -f "$HERE/yaml-get.awk" ]; then
  for _yf in project.local.yaml project.yaml; do
    if [ -z "$PROJ" ] && [ -f "$_yf" ]; then
      PROJ=$(YG_PATH=project.name awk -f "$HERE/yaml-get.awk" "$_yf" | tr -cd 'A-Za-z0-9_')
    fi
  done
fi
PROJ_SET=1
case "$PROJ" in ''|[0-9]*) PROJ_SET=""; PROJ=Game ;; esac
# The Unity project may sit below the repo root (unity.project_root).
UPRE=""
if [ -f "$HERE/unity-root.sh" ]; then
  . "$HERE/unity-root.sh"
  UPRE=$(unity_root_prefix .) || { echo "test-scaffold: unity.project_root is unusable (absolute or holds ..)" >&2; exit 2; }
fi
ASM_SHARED="${UPRE}Assets/Scripts/Testing/Shared/$PROJ.Tests.Shared.asmdef"
ASM_EDIT="${UPRE}Assets/Scripts/Testing/EditMode/$PROJ.Tests.EditMode.asmdef"
ASM_PLAY="${UPRE}Assets/Scripts/Testing/PlayMode/$PROJ.Tests.PlayMode.asmdef"

ENGNAME=Unity
if [ -n "$VER" ]; then ENGTXT="$ENGNAME $VER"; else ENGTXT="$ENGNAME [version]"; fi
DATE="${DATE_ARG:-$(date +%Y-%m-%d)}"

# ---------------------------------------------------------------------- paths
README=tests/README.md
EVID=production/qa/evidence/.gitkeep
CI=.github/workflows/tests.yml
SMOKE=tests/smoke/critical-paths.md
list_paths() {
  echo "$README"
  echo "$EVID"
  echo "$ASM_SHARED"; echo "$ASM_EDIT"; echo "$ASM_PLAY"
  echo "$CI"
  echo "$SMOKE"
}
if [ "$MODE" = list ]; then
  list_paths
  exit 0
fi

# ------------------------------------------------------------------- contents
# Each file is a function printing it; @TOKENS@ are filled by render.
tpl_readme_unity() {
  cat <<'TPL_README_UNITY'
# Test Infrastructure

**Engine**: @ENGINE@
**Test Framework**: Unity Test Framework
**CI**: `.github/workflows/tests.yml`
**Setup date**: @DATE@

## Directory Layout

Unity compiles only `Assets/` and `Packages/`, so unit and integration tests
live under the engine's test root, not in `tests/`: a test under `tests/` is never
compiled, and the run reports 0 tests and `Passed`, a false pass.

```
Assets/Scripts/Testing/
  EditMode/<Feature>/   # Isolated unit tests (formulas, state machines, logic)
  PlayMode/<Feature>/   # Integration tests in a running scene
```

The feature path mirrors `Assets/Scripts/Core/<Feature>/` (layout:
`.claude/docs/unity-folder-structure.md`).

`tests/` keeps this README and `smoke/`. Every `tests/unit/` path below means
that test root.

```
tests/
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Running Tests

Use the editor executable: `Unity` on `PATH` may be Unity's separate CLI, not
the editor.

```
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml
"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform PlayMode -testResults test-results/playmode.xml
```

Exit 0: every test passed. Exit 2: a test failed. Exit 1, 3 and 4 (a compile
error, a failed run, an unknown `-testPlatform`) and any other non-zero exit
are failures too; a compile error writes no results file. Delete each results
file before its run so an old file is never read as a new result. Read the
`<test-run>` element of the results file: `testcasecount="0"` means nothing was
compiled or found, which is not a pass. Do not add `-quit`; `-runTests` exits by
itself. An Edit Mode run never runs the tests in `Assets/Scripts/Testing/PlayMode/`, so
run both.

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Unity**: class `[System]Tests` in `[System]Tests.cs`, method `[Scenario]_[Expected]`
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
A failed test suite blocks merging. Unity CI needs the `UNITY_LICENSE`
repository secret.
TPL_README_UNITY
}

tpl_ci_unity() {
  cat <<'TPL_CI_UNITY'
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run Unity Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          lfs: true

      - name: Run Edit Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: editmode
          artifactsPath: test-results/editmode

      - name: Run Play Mode Tests
        uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: playmode
          artifactsPath: test-results/playmode

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results
          path: test-results/
TPL_CI_UNITY
}

tpl_smoke() {
  cat <<'TPL_SMOKE'
# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to main menu without crash
2. New game / session can be started from the main menu
3. Main menu responds to all inputs without freezing

## Core Mechanic (update per sprint)

<!-- Add the primary mechanic for each sprint here as it is implemented -->
<!-- Example: "Player can move, jump, and the camera follows correctly" -->
4. [Primary mechanic — update when first core system is implemented]

## Data Integrity

5. Save game completes without error (once save system is implemented)
6. Load game restores correct state (once load system is implemented)

## Performance

7. No visible frame rate drops on target hardware (60fps target)
8. No memory growth over 5 minutes of play (once core loop is implemented)
TPL_SMOKE
}

tpl_asmdef_shared() {
  cat <<'TPL_ASMDEF_SHARED'
{
  "name": "@PROJ@.Tests.Shared",
  "references": ["UnityEngine.TestRunner", "@PROJ@.Core"],
  "includePlatforms": [],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
TPL_ASMDEF_SHARED
}

tpl_asmdef_edit() {
  cat <<'TPL_ASMDEF_EDIT'
{
  "name": "@PROJ@.Tests.EditMode",
  "references": ["UnityEngine.TestRunner", "UnityEditor.TestRunner", "@PROJ@.Core", "@PROJ@.Tests.Shared"],
  "includePlatforms": ["Editor"],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
TPL_ASMDEF_EDIT
}

tpl_asmdef_play() {
  cat <<'TPL_ASMDEF_PLAY'
{
  "name": "@PROJ@.Tests.PlayMode",
  "references": ["UnityEngine.TestRunner", "@PROJ@.Core", "@PROJ@.Tests.Shared"],
  "includePlatforms": [],
  "overrideReferences": true,
  "precompiledReferences": ["nunit.framework.dll"],
  "autoReferenced": false,
  "defineConstraints": ["UNITY_INCLUDE_TESTS"]
}
TPL_ASMDEF_PLAY
}

render() {
  sed -e "s|@ENGINE@|$ENGTXT|g" -e "s|@DATE@|$DATE|g" -e "s|@PROJ@|$PROJ|g"
}
# content_of <path> -- the file's text, ready to write.
content_of() {
  case "$1" in
    "$README")
      tpl_readme_unity | render ;;
    "$CI")
      tpl_ci_unity | render ;;
    "$SMOKE") tpl_smoke ;;
    "$ASM_SHARED") tpl_asmdef_shared | render ;;
    "$ASM_EDIT") tpl_asmdef_edit | render ;;
    "$ASM_PLAY") tpl_asmdef_play | render ;;
    *) : ;;
  esac
}
# write_new <path> -- stdin becomes the file; fails (and writes nothing) if it exists.
write_new() {
  mkdir -p "$(dirname "$1")" 2>/dev/null || return 1
  ( set -C; cat > "$1" ) 2>/dev/null
}

# ----------------------------------------------------------------------- run
printf 'engine\t%s\n' "$ENG"
printf 'mode\t%s\n' "$MODE"
NCREATE=0; NEXIST=0; NSKIP=0; NFAIL=0
CREATED_LIST=""
while IFS= read -r p; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf 'EXISTS\t%s\n' "$p"; NEXIST=$((NEXIST + 1)); continue
  fi
  if [ "$MODE" = dry-run ]; then
    printf 'WOULD_CREATE\t%s\n' "$p"; NCREATE=$((NCREATE + 1)); CREATED_LIST="$CREATED_LIST|$p|"; continue
  fi
  if content_of "$p" | write_new "$p"; then
    printf 'CREATED\t%s\n' "$p"; NCREATE=$((NCREATE + 1)); CREATED_LIST="$CREATED_LIST|$p|"
  else
    printf 'FAILED\t%s\tcould not create the folder or the file\n' "$p"; NFAIL=$((NFAIL + 1))
  fi
done <<EOF
$(list_paths)
EOF
if [ "$MODE" = dry-run ]; then printf 'would_create\t%d\n' "$NCREATE"; else printf 'created\t%d\n' "$NCREATE"; fi
printf 'exists\t%d\nskipped\t%d\n' "$NEXIST" "$NSKIP"
[ "$NFAIL" -eq 0 ] || printf 'failed\t%d\n' "$NFAIL"

# --------------------------------------------------------------------- needs
# A need belongs to a file this run creates (its placeholders are in it), or
# is a check of the project that no file of ours can satisfy.
made() { case "$CREATED_LIST" in *"|$1|"*) return 0 ;; esac; return 1; }
need() { printf 'NEEDS\t%s\t%s\t%s\n' "$1" "$2" "$3"; }
if made "$README" && [ -z "$VER" ]; then
  need engine_version "$README" "set the engine version on the Engine line (project.yaml has no engine.version)"
fi
case "$ENG" in
  unity)
    if [ ! -f "${UPRE}Packages/manifest.json" ] || ! grep -q 'com.unity.test-framework' "${UPRE}Packages/manifest.json"; then
      need unity_test_framework "${UPRE}Packages/manifest.json" 'add "com.unity.test-framework" to dependencies at the version your editor bundles'
    fi
    if made "$CI"; then
      need unity_license "$CI" "add the UNITY_LICENSE secret to the repository (manual)"
    fi
    if made "$ASM_SHARED" || made "$ASM_EDIT" || made "$ASM_PLAY"; then
      if [ -z "$PROJ_SET" ]; then
        need project_name project.yaml "set project.name: the assemblies are named Game.Tests.* and reference Game.Core; rename them to <Project>.* once it is known"
      fi
      # The test assemblies reference <Project>.Core, an asmdef /setup-engine creates.
      if [ ! -f "${UPRE}Assets/Scripts/Core/$PROJ.Core.asmdef" ]; then
        need core_asmdef "${UPRE}Assets/Scripts/Core/$PROJ.Core.asmdef" "the test assemblies reference $PROJ.Core: create it (/setup-engine, .claude/docs/unity-folder-structure.md) or they will not compile"
      fi
    fi ;;
esac

[ "$NFAIL" -eq 0 ] || exit 4
[ "$NSKIP" -eq 0 ] || exit 3
exit 0
