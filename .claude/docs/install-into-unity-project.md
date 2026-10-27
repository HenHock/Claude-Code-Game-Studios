# Install CCGS into an existing Unity project

Runbook for an agent (or a person) installing this framework into a game repo that
already exists, and keeping it updated afterwards. Follow it in order. Stop and report
at any step marked **STOP**; do not improvise past it.

Applies to the layout this was written for, but works for the flat one too:

```text
<repo>/                  git root, Claude is launched here
  .claude/  CLAUDE.md  project.yaml  design/  docs/  production/  (framework)
  <tooling>/             non-Unity tools (code generators ...)
  <ProjectName>/         the Unity project  -> unity.project_root: <ProjectName>
    Assets/  Packages/  ProjectSettings/
```

If `Assets/` is directly in the repo root, skip every `unity.project_root` step.

## 0. Inputs and rules

Collect these first; ask the user for any you cannot read from the repo.

| Input | How to find it |
|---|---|
| `TEMPLATE_URL` | The framework repo (fork) to install from. The user names it. |
| `TEMPLATE_REF` | Branch or tag. It **must contain** `unity.project_root` support (`.claude/scripts/unity-root.sh`). A ref without that file is too old: **STOP**. |
| `UNITY_DIR` | The folder holding `Assets/`, relative to the repo root (`<ProjectName>`), or `.` |
| `PROJECT_NAME` | The game's name (letters and digits; used for asmdef names) |

Rules while installing:

- **No commits and no pushes** unless the user says so. Stage, show `git diff --cached --stat`, stop.
- Work from the **repo root**. Every path below is relative to it.
- Never run `git clean`, `git reset --hard` or force-push. Never delete the user's files.
- A file that exists in the repo and is also in the template is a **merge**, not an overwrite. Section 3 lists them.
- Never touch anything under `UNITY_DIR/` except what step 6 names (`Assets/Scripts/...` asmdefs, created by `/setup-engine` or `/test-setup` later, with the user's approval).

## 1. Preflight

```bash
git rev-parse --show-toplevel      # must be the repo root you were told
git status --short                 # note anything already modified; do not mix it in
test -d "<UNITY_DIR>/Assets" && echo ok
bash --version | head -1           # bash is required; hooks do not run without it
python --version || python3 --version || py --version   # Python 3 required for config reads
```

Windows: use Git Bash. If `.claude/` already exists in the repo, **STOP** and ask: it may hold the user's own agents, skills or hooks. Back up nothing silently; list what is there.

Check the user's global instructions for clashes before installing, and tell the user about any (do not edit them):

- a global commit-message rule (the framework's `validate-commit.sh` and `coding-standards.md` expect Conventional Commits `feat:` / `fix:` ... with a story or task ID in the body);
- global Unity skills with their own folder layout (the framework enforces `Assets/Content|Scripts|Plugins|Settings|Configs/<Feature>/`; see `.claude/docs/unity-folder-structure.md`).

## 2. Bring the framework in

The target repo has no shared history with the template, so use a selective checkout (this is `UPGRADING.md` Strategy A2). It stages files; it does not commit.

```bash
git remote add template "<TEMPLATE_URL>"          # skip if `git remote -v` already lists it
git fetch --tags template "<TEMPLATE_REF>"

# Framework-owned folders and files, plus the seed data the skills expect
git checkout "template/<TEMPLATE_REF>" -- \
  .claude \
  .worktreeinclude \
  docs/CLAUDE.md docs/WORKFLOW-GUIDE.md docs/COLLABORATIVE-DESIGN-PRINCIPLE.md \
  docs/engine-reference docs/architecture docs/registry \
  design/CLAUDE.md design/registry \
  production/session-state/.gitkeep
```

Do **not** check out `studio-tests/`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`, `.github/`, `src/` or `UPGRADING.md`. They belong to the template, not the game. (`src/` is not a code root in this Unity fork.)

Verify: `ls .claude/scripts/unity-root.sh .claude/scripts/framework-sync.sh .claude/framework-manifest.txt` all exist.

## 3. Merge the files that are the user's too

For each, if the repo has none, copy the template's; if it has one, **merge by hand**, keeping the user's content, and show the diff.

| File | What to do |
|---|---|
| `CLAUDE.md` | Template's content is the framework's instructions. If the repo already has a `CLAUDE.md`, keep the user's text and add the template's `@.claude/docs/...` import lines and Collaboration Protocol sections. Do not duplicate headings. |
| `project.yaml` | Take the template's. Then set the keys in step 4. If the repo already has one, merge keys; never drop the user's. |
| `.claude/settings.json` | Already arrived with `.claude/`. If the repo had its own, merge the `hooks`, `permissions` and `worktree` blocks by hand (a hook entry listed twice runs twice). |
| `.gitignore` | Append, if missing: `.claude/settings.local.json`, `CLAUDE.local.md`, `project.local.yaml`, `production/session-logs/`, `production/session-state/`, `.scratch/`, `.claude/agent-memory/`, `.claude/worktrees/`, `/test-results/`. Do not remove the user's Unity ignores (`Library/`, `Temp/`, `Logs/`, `UserSettings/`). They live under `UNITY_DIR/`; check the user's `.gitignore` covers `UNITY_DIR/Library/` etc. and report if not. |
| `.gitattributes` | Append the template's rules if missing. `*.sh text eol=lf` is mandatory on Windows, or the hooks break on CRLF. Then run `git add --renormalize .claude`. |

## 4. Point the framework at the Unity project

Edit `project.yaml` (not `project.local.yaml`; the key is repo-wide):

```yaml
engine:
  name: unity
project:
  name: <PROJECT_NAME>
unity:
  project_root: <UNITY_DIR>      # omit this key if Assets/ is in the repo root
```

Use `bash .claude/scripts/config-set.sh unity.project_root <UNITY_DIR> --dry-run` first if you prefer the helper; it checks the key is known. The value must be a relative folder: no leading `/`, no drive letter, no `..`.

## 5. Verify (all must pass before reporting done)

```bash
bash .claude/scripts/unity-root.sh                        # prints <UNITY_DIR>; exit 0
bash .claude/scripts/project-state.sh --root . | grep -E '^(engine|code_root|source_files)'
#   expect: engine unity ... / code_root <UNITY_DIR>/Assets ... / source_files N (the real .cs count)
bash .claude/scripts/asset-scan.sh --root . | head -5     # expect a `base <UNITY_DIR>` row and root Assets present
bash .claude/scripts/write-guard.sh --root . check "<UNITY_DIR>/Assets/Prefabs/x.prefab"
#   expect a LAYOUT row: top-level folder Assets/Prefabs/ is not Content, Scripts, ...
bash .claude/scripts/write-guard.sh --root . check "Assets/Prefabs/x.prefab"
#   expect NO layout row (a top-level Assets/ is not the Unity project here)
bash .claude/hooks/detect-gaps.sh | head                  # must not print "NEW PROJECT" when the project has code
```

If `code_root` prints `-` or `unset`, read `.claude/docs/code-root-resolution.md`; the usual causes are a misspelled `UNITY_DIR`, `engine.name` missing, or an unusable `unity.project_root` (the script prints why on stderr).

Then start Claude Code **from the repo root** (hooks and deny rules load only there) and confirm the session-start output shows the framework context with no `WARNING:` line about `unity.project_root`.

## 6. First-run configuration (the user drives this)

These need the user's decisions; do not run them on their behalf:

1. `/setup-engine`: pins the Unity version, asks `unity.asset_loading` (addressables | resources | direct), fills `project.yaml`. Tell it the Unity project is under `UNITY_DIR`; it must create `Assets/` content under `<UNITY_DIR>/Assets/...`, never at the repo root.
2. `/test-setup`: scaffolds the test asmdefs under `<UNITY_DIR>/Assets/Scripts/Testing/...` and requires `com.unity.test-framework` in `<UNITY_DIR>/Packages/manifest.json`.
3. `/start` or `/adopt`: for an existing game, `/adopt` audits what the repo already has against the framework and gives a migration plan. Prefer it over `/start`.

If the existing code does not follow the by-feature layout, do **not** move it. Report it; `/adopt` plans that.

## 7. Updating later

```bash
bash .claude/scripts/framework-sync.sh                      # report only; fetches the template
bash .claude/scripts/framework-sync.sh --no-fetch --apply   # stage framework-owned files
git diff --cached --stat                                    # review, then the user commits
```

- The remote and branch default to `template` / `unity-engine`; pass `--remote` / `--branch` if you used others. `--url` adds the remote the first time.
- `.claude/framework-manifest.txt` decides what is framework-owned. `merge` rows (`CLAUDE.md`, `project.yaml`, `settings.json`, `.gitignore`, `.gitattributes`) are only listed; merge them by hand with `git diff HEAD template/<branch> -- <file>`.
- A file the user edited since the last sync is reported `local-edit` and skipped. A `dirty` file (uncommitted change) is skipped too. Restore or merge those deliberately.
- The first sync after step 2 has no baseline (`unknown`): review the staged diff before the user commits. `.claude/framework-sync.last` records the synced commit; commit it with the sync.
- The session-start "new release" notice checks the upstream repo, not the fork. Set `updates.check=false` (`/settings --local updates.check=false`).
- If the sync script itself changed, run it once more so the new version does the work.

## 8. Report back

Give the user: the files staged (`git diff --cached --stat`), each merge you did by hand, the step 5 outputs, any global-instruction clashes from step 1, and the next command (`/setup-engine`). Say plainly if a check was not run or failed. Nothing is committed.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Hooks print `\r` errors or do nothing on Windows | CRLF in `.sh` files. Add the `.gitattributes` rule, then `git add --renormalize .claude`. |
| `code_root` unset, checks say NOT ASSESSED | `engine.name` not `unity`, or `unity.project_root` wrong/unusable. Fix `project.yaml`. |
| New files appear at `<repo>/Assets/` | An agent ignored the nested root. The `SubagentStart` hook tells agents the root; check `.claude/settings.json` still registers `inject-unity-layout.sh`. Move the files into `<UNITY_DIR>/Assets/` and keep the `.meta` files with them. |
| `framework-sync.sh: no remote 'template'` | Pass `--url <TEMPLATE_URL>` once. |
| `test-run` says the Unity Test Framework is absent | Add `com.unity.test-framework` to `<UNITY_DIR>/Packages/manifest.json`; the check looks there, not at the repo root. |
