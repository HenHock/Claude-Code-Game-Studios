# Skill Test Spec: /setup-engine

## Skill Summary

`/setup-engine` pins the project's Unity version and records the project's
Unity configuration. The engine is always Unity and the language is always C#;
no version is pinned in advance, so the version is chosen here at first init.
It accepts `[version]`, `refresh`, `upgrade [old] [new]`, or no argument for
guided selection. It then:

- writes the Technology Stack and the `ENGINE-REFERENCE-IMPORT` line to
  `CLAUDE.md` after "May I write these engine settings to `CLAUDE.md`?"
- fills `.claude/docs/technical-preferences.md` (the legacy mirror: naming
  conventions, specialist routing table, input/platform, performance budgets)
  after the user approves the presented defaults
- dual-writes the `engine`, `specialists`, `naming` and `commands` blocks to
  `project.yaml` — the primary config store — after "May I write the `engine`,
  `specialists`, `naming`, and `commands` blocks to `project.yaml`?"
- updates or creates `docs/engine-reference/unity/`, never scaffolds Unity
  project files (the user creates the project in Unity Hub), and reads
  everything back with `project-coherence.sh`

On a re-run it edits existing `project.yaml` blocks in place rather than
duplicating them. No director gates apply. The verdict is COMPLETE when the
engine is configured.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language before writing `CLAUDE.md` and before writing the `project.yaml` blocks
- [ ] Has a next-step handoff (Section 12 prints one tier-matched Next-Steps list, e.g. `/brainstorm` at `minimal`)

---

## Director Gate Checks

None. `/setup-engine` is a technical configuration skill. No director gates apply.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Unity + C# — Full engine configuration

**Fixture:**
- Placeholders only in `technical-preferences.md`; no `engine` block in `project.yaml`
- No `design/gdd/game-concept.md` and no `design/game-brief.md`
- No Unity version is pinned yet; the user supplies the version and the build target when asked
- The user approves every write

**Input:** `/setup-engine`

**Expected behavior:**
1. The version is asked for and confirmed with the user — the skill does not assume one
2. No language question (Unity is C#); CLAUDE.md Language is `C#`
3. Skill shows the Technology Stack and asks "May I write these engine settings to `CLAUDE.md`?"
4. Naming: PascalCase classes/methods, `_camelCase` private fields
5. Routing: `.cs` → unity-specialist, `.shader`/`.shadergraph` → unity-shader-specialist,
   `.unity`/`.prefab` → unity-specialist, `.uxml`/`.uss` → unity-ui-specialist
6. Because no design artifact exists, the skill asks the project-shape question
   (2D/3D, render pipeline) instead of writing `URP`/`PhysX` from the engine name
7. `commands.build` target is asked (no hardcoded `StandaloneLinux64`);
   `commands.test` is the Unity Test Framework command
8. Skill asks "May I write the `engine`, `specialists`, `naming`, and `commands` blocks to `project.yaml`?"
9. Section 6 reads its coverage table: a Unity version past the model's
   cutoff gets a HIGH knowledge risk
10. `docs/engine-reference/unity/VERSION.md` is created or refreshed for the chosen
    version, and its `Installed at pin time` row is written from the Section 3 probe
11. No Unity project is scaffolded; the user is told to create it in Unity Hub; verdict COMPLETE

**Assertions:**
- [ ] `engine.name` is Unity and `engine.language` is C# in `project.yaml`
- [ ] Naming conventions reflect C# conventions
- [ ] Routing table includes `.cs` and `.unity` entries
- [ ] The rendering/physics shape is asked, not inferred from the engine name
- [ ] The Unity version is asked for, not assumed
- [ ] "May I write" is asked before `CLAUDE.md` and before `project.yaml` are written
- [ ] No Unity project files are written
- [ ] Verdict is COMPLETE

---

### Case 2: Re-run on a Configured Project — blocks edited in place

**Fixture:**
- `project.yaml` already has `engine` (Unity, a pinned version), `specialists`, `naming`, a
  `modes` block, and a `commands` block missing its `smoke` key
- `docs/engine-reference/unity/VERSION.md` pins the same version

**Input:** `/setup-engine unity [same version]`

**Expected behavior:**
1. Skill reads `project.yaml` before editing it
2. Each existing block is edited in place; `commands.smoke` is added to the
   partial block; no second copy of any block is appended
3. `modes` and every other non-engine block are preserved untouched
4. VERSION.md pins the same version → nothing to regenerate: Engine Version,
   Project Pinned and Last Docs Verified are left as they are, and only the
   `Installed at pin time` row is written with the Section 3 probe result
5. Verdict COMPLETE

**Assertions:**
- [ ] No block is duplicated in `project.yaml`, and the missing `commands.smoke` key is added
- [ ] `modes` (and all other non-engine content) is unchanged
- [ ] For a same-version pin, Engine Version, Project Pinned and Last Docs Verified are untouched and `Installed at pin time` is written
- [ ] Verdict is COMPLETE

---

### Case 3: Director Gate Check — No gate; setup-engine is a utility skill

**Fixture:**
- Fresh project with no engine configured

**Input:** `/setup-engine`

**Expected behavior:**
1. Skill completes full engine configuration
2. No director agents are spawned at any point
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

### Case 4: Installed Editor Older Than the Chosen Version — ask, then record

**Fixture:**
- As Case 2; `docs/engine-reference/unity/VERSION.md` pins a newer version than the installed editor
- The Section 3 probe (the installed editor or `ProjectSettings/ProjectVersion.txt`) reports an older version
- The user picks "pin the newer one and upgrade later"

**Input:** `/setup-engine unity [newer version]`

**Expected behavior:**
1. Section 3 probes the installed editor and finds the older version — a mismatch
2. Skill states both versions and asks, offering three options: pin the
   installed version, pin the newer one and upgrade later, or pin the newer one
   deliberately
3. The answer is recorded; the skill does not pick for the user
4. VERSION.md already pins the newer version, so nothing is regenerated, but its
   `Installed at pin time` row is written with the installed version
5. Verdict COMPLETE

**Assertions:**
- [ ] Both versions are stated and all three options are offered
- [ ] The skill waits for the user's choice rather than picking silently
- [ ] `Installed at pin time` records the installed version — the same-version branch does not skip it
- [ ] Engine Version, Project Pinned and Last Docs Verified are not restamped

---

### Case 5: Unity editor not on PATH — the probed executable goes into `commands.*`

**Fixture:**
- As Case 1, on Windows; no `Unity` executable on `PATH`
- The probe finds `C:/Program Files/Unity/Hub/Editor/<version>/Editor/Unity.exe`, which reports the version
- The user names the build target `StandaloneWindows64`

**Input:** `/setup-engine`

**Expected behavior:**
1. Section 3 reads the version from the executable it found — it does not report "no engine installed"
2. `build`, `test`, `run` and `smoke` each start with the quoted full path, as single-quoted scalars; `build` quotes its target with double quotes
3. `test` runs the Unity Test Framework in batch mode after the path
4. `engine.path` records the executable
5. Verdict COMPLETE

**Assertions:**
- [ ] No `commands.*` value names a bare `Unity` that does not resolve
- [ ] Every Unity command value is a single-quoted scalar and none holds both quote types
- [ ] `engine.path` records the editor executable
- [ ] Variant — the probe finds nothing and the user does not know where Unity is: the bare executable is kept under a `# TODO: Unity is not on PATH here` comment, and the skill says the commands will not run until the path is set

---

### Case 6: A skipped question is not an answer

**Fixture:**
- Fresh project: no engine configured, no `project.yaml` engine block
- The version question comes back skipped: the user closes it, or a headless run
  returns every question as skipped
- The sandbox carries the framework's `CLAUDE.md`. The rule this case checks is
  stated there ("A skipped or dismissed question is not an answer") and in
  `.claude/docs/automation-modes.md`, not in `/setup-engine`'s own files; a rule
  `CLAUDE.md` loads counts as the skill's own (`/skill-test` spec mode, Step 3),
  so a sandbox without it is set up wrong, not a skill FAIL

**Input:** `/setup-engine`

**Expected behavior:**
1. The skill does not choose a version itself
2. It asks again in plain text, saying what is waiting on the answer, and waits
3. Nothing is written to `CLAUDE.md`, `project.yaml`, `technical-preferences.md`
   or `VERSION.md` before the user answers
4. In a run where nobody can answer, it stops and reports what is waiting

**Assertions:**
- [ ] No version is picked on the user's behalf
- [ ] The question is asked again in plain text
- [ ] No file is written before an answer arrives

---

## Protocol Compliance

- [ ] Presents draft configuration before asking to write
- [ ] Asks "May I write" before writing `CLAUDE.md` and the `project.yaml` blocks; technical preferences are written only after the user approves the presented defaults
- [ ] Respects a version argument when provided (skips guided selection)
- [ ] Dual-writes `project.yaml` and `technical-preferences.md`, then reads `project.yaml` back to confirm they agree
- [ ] On re-run, edits existing `project.yaml` blocks in place without duplicating them
- [ ] Writes the probed editor path into `commands.*` whenever the Unity executable is not on `PATH` — never a bare executable that does not resolve
- [ ] Never defaults the Unity build target — asks for it
- [ ] Writes the Section 3 probe into VERSION.md's `Installed at pin time` row whatever the outcome, after asking "May I record `Installed at pin time: …` in `docs/engine-reference/unity/VERSION.md`?"
- [ ] Verdict is COMPLETE after configuration is written

---

## Coverage Notes

- The `refresh` and `upgrade` subcommands (Sections 10–11) are not tested here.
- The Linux and macOS `commands` blocks (chosen by `uname -s`) are not
  fixture-tested; Case 5 pins Windows.
- Section 6 is a lookup against the skill's own coverage table, asserted in
  Case 1. The Section 7 reference docs for a version with no reference set yet
  depend on WebSearch results; not assertion-tested.
- A probe that cannot run reports `installed version NOT DETERMINED` — never
  "no engine installed"; not separately tested.
