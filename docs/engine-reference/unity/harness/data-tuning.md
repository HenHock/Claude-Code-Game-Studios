# Unity: Data, not code (harness H4)

Last verified: 2026-10-25 (sources below). Rule: `.claude/docs/agent-harness.md` H4.
Tuning values (speeds, costs, damage, curves) live in external data that loads
at runtime and reloads without a rebuild. An agent then iterates on balance
without compiling, and so can non-programmers.

## Scope

- Applies to **gameplay tuning values** that a designer or agent would change to
  balance the game. It does not apply to structural constants (array sizes,
  protocol versions, math constants), presentation values (tween durations,
  colors, UI spacing), or one-off values nobody will tune.
- Applies when the project has tunable gameplay. It binds values a change adds or
  touches. Do not move every existing constant into data.
- This repo's coding standard already says gameplay values are data-driven
  (`coding-standards.md`). H4 adds the reload requirement.

## Choosing where the data lives

The project picks one mechanism and records it in the Harness Foundation ADR.
The facts below decide what "reload without a rebuild" can mean for each.

| Option | Reload without rebuild | Unity facts |
|---|---|---|
| `ScriptableObject` assets | In the Editor only | Edits made in the Inspector are written to disk and persist between Editor sessions. Changes made by script in Edit mode are not saved automatically (call `EditorUtility.SetDirty`). "In a standalone Player at runtime, you can only read saved data from the ScriptableObject assets." |
| JSON/text files read from disk | Yes, in the Editor and in desktop builds | Parse with the project serializer (default Newtonsoft, see `portable-state.md`). Load from a folder the agent can edit. |
| Google Sheets (or another spreadsheet) as the authoring source | Yes, if a fetch step exports it to a data file | Designers and agents edit numbers without touching code. Do not read the live sheet during runs or tests: the same seed and state can then behave differently on different days, with nothing in git to explain it. Export to a snapshot file (JSON or CSV) that the game and tests read, so a balance change is a diff and a run can name its data version. Reading the sheet directly is acceptable for a project with no tests or replays to protect. A specific fetch plugin is NOT listed: check its fetch method, build support and license first. |
| Remote config / Addressables | Project-specific | NOT SOURCEABLE here. Check the package docs before choosing. |

Notes on file locations:

- `Application.streamingAssetsPath`: on Android it is a URL inside a compressed
  `.apk`, on WebGL no file access is available. Synchronous `System.IO.File`
  cannot be used there; load with `UnityWebRequest`. Files there ship inside the
  build, so editing them in a shipped build is not possible on those platforms.
- `Application.persistentDataPath`: a directory for data kept between runs. On
  the Windows Editor and Player it usually points to
  `%userprofile%\AppData\LocalLow\<company>\<product>`. Pass a full path when
  saving, because some APIs treat relative paths as relative to the project
  folder in the Windows Editor.
- A common arrangement for agent work: tuning files live in the project, the
  Editor and dev builds read them from disk, and a release build uses the
  shipped copy. The project decides this in the ADR.

## Shape

- Read tuning through **one data accessor** with stable keys (for example
  `combat.base_damage`). A new tunable is a new key plus a default, not a new
  constant.
- Provide a **reload command** that re-reads the files while the game runs and
  logs which keys changed. This is the `harness.data_reload` capability. Where it
  cannot be done (a platform that only ships baked data), the capability is NOT
  CONFIGURED, never a pass.
- Validate on load: a missing or malformed key fails loudly with the key name.
  Do not fall back silently to a hardcoded number.
- Keep data files as the simulation layer's input (see
  `sim-presentation-split.md`). The layer reads values; it does not know where
  they came from.

## Sources

- https://docs.unity3d.com/6000.0/Documentation/Manual/class-ScriptableObject.html
- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Application-streamingAssetsPath.html
- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Application-persistentDataPath.html
