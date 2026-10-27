# Directory Structure

```text
/
├── CLAUDE.md                    # Master configuration
├── project.yaml                 # Machine-readable project config — engine, modes, stage (source of truth)
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
├── <code root>/                 # Game source code — THE PATH IS ENGINE-SPECIFIC, see below
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tests/                       # Game test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (outside the code root)
├── production/                  # Production management (sprints, milestones, releases)
│   ├── session-state/           # Ephemeral session state (active.md — gitignored)
│   └── session-logs/            # Session audit trail (gitignored)
└── studio-tests/                # QA for the skills/agents themselves — /skill-test, /skill-improve
```

## The code root is `Assets/Scripts/Core/`

**Unity will not build a project whose code sits in `src/`.** This is not a style
preference — it is a hard constraint of the engine's own toolchain:

| `engine.name` | Code root | Why it cannot be `src/` |
|---|---|---|
| **Unity** | `Assets/Scripts/Core/` | C# lives under `Assets/Scripts/`. Unity compiles **only** `Assets/` and `Packages/`. Code outside them is invisible to the compiler. |

**Resolve the code root before writing any source file.** A path shown as
`src/…` alone is a generic example: read it as *"the code root"* and
substitute `Assets/Scripts/Core/`.

**Tests follow the same rule** — the same compiler decides what it sees:

| `engine.name` | Test root | Anywhere else |
|---|---|---|
| **Unity** | `Assets/Scripts/Testing/EditMode/`, `Assets/Scripts/Testing/PlayMode/` | not compiled: "0 tests, Passed" |

Read `tests/unit/[system]/` (or `integration/`) anywhere as the test root plus `[System]/`
(for Unity, `Assets/Scripts/Testing/EditMode/<Feature>/`).

### Unity project below the repo root

If the Unity project is `<repo>/<ProjectName>/` (the repo root holds Claude,
git and non-Unity tooling), set `unity.project_root: <ProjectName>` in
`project.yaml`. `Assets/` and `Packages/` below then live under that folder;
`design/`, `docs/`, `production/` and the rest stay at the repo root. See
`.claude/docs/effects-map.md`, section `unity.project_root`.

## Unity Assets layout: by feature, not by asset type

One feature uses the same feature path under every root (the path after the
aspect root; `Core` is not part of the mirror). Testing, debugging and editor
code never sit inside a Core feature folder.

```text
Assets/
  Content/<Feature>/                 in-game content (Scenes/, Prefabs/, Models/, Materials/, ...)
  Scripts/
    Core/<Feature>/                  gameplay logic        <Project>.Core
    Debugging/<Feature>/             debug logic           <Project>.Debugging (ENABLE_DEBUGGING, off by default)
    Testing/EditMode|PlayMode/<Feature>/                   <Project>.Tests.EditMode / .PlayMode
    Testing/Shared/                  shared test helpers   <Project>.Tests.Shared
    Editor/<Feature>/                editor scripts        <Project>.Editor
  Plugins/Code/<Vendor>/             3rd-party code, each with its own asmdef
  Plugins/Content/<Vendor>/          imported asset packs
  Settings/                          URP, Input, DI, quality, ...
  Configs/<Feature>/                 in-game ScriptableObjects
  Resources/<Feature>/               only when unity.asset_loading is `resources`
```

Example: `Assets/Scripts/Core/Gameplay/Helicopter/` mirrors
`Assets/Content/Gameplay/Helicopter/`, `Assets/Scripts/Testing/EditMode/Gameplay/Helicopter/`
and so on. The full rules, asmdef table and anti-patterns are in
`.claude/docs/unity-folder-structure.md` (the canonical doc).
