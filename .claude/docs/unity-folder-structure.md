# Unity Assets Folder Layout

The single source of truth for where every Unity file goes. Short forms of it:
`.claude/docs/directory-structure.md` (always loaded), `.claude/rules/unity-folders.md`
(loads on `Assets/**`), `.claude/hooks/inject-unity-layout.sh` (every spawned
agent) and the advisory layout rule in `.claude/scripts/write-guard.sh`. If they
disagree, this file wins.

**Folders are organised by feature, not by asset type, and one feature uses the
same feature path under every root.**

## The tree

```text
Assets/
  Content/<Feature>/             all in-game content: the visual aspect
                                   (Scenes/, Prefabs/, Models/, Materials/, Sprites/, Audio/, ...)
  Scripts/                       all logic, including debug and test logic: the logic aspect
    Core/<Feature>/              main gameplay logic          asmdef <Project>.Core
    Debugging/<Feature>/         debug logic                  asmdef <Project>.Debugging
    Testing/Shared/              shared test helpers          asmdef <Project>.Tests.Shared
    Testing/EditMode/<Feature>/  edit-mode tests              asmdef <Project>.Tests.EditMode
    Testing/PlayMode/<Feature>/  play-mode tests              asmdef <Project>.Tests.PlayMode
    Editor/<Feature>/            all editor scripts           asmdef <Project>.Editor
  Plugins/                       all 3rd-party solutions and imported ready resources
    Code/<Vendor>/               code plugins (DOTween, UniTask, ...)
    Content/<Vendor>/            imported asset packs (models, prefabs, audio, ...)
  Settings/                      engine and game configuration (URP assets, Input, DI settings, quality, ...)
  Configs/<Feature>/             in-game ScriptableObjects, usually loaded through Addressables
  Resources/<Feature>/           ONLY if the project's main loading method is the Resources API
```

Plugin names are examples only.

## The mirroring rule

The **feature path** is the path after the aspect root (`Core/`, `Content/`,
`Debugging/`, `Testing/EditMode/`, `Testing/PlayMode/`, `Editor/`, `Configs/`).
`Core` is **not** part of the mirror: it is the root, not the feature.

A feature has the same feature path under every root it uses. Example, the
feature `Gameplay/Helicopter`:

```text
Assets/Scripts/Core/Gameplay/Helicopter/Movement/HeliMove.cs
Assets/Scripts/Core/Gameplay/Helicopter/Rotation/HeliRotate.cs
Assets/Content/Gameplay/Helicopter/Models/ · Prefabs/ · Materials/
Assets/Scripts/Testing/EditMode/Gameplay/Helicopter/
Assets/Scripts/Testing/PlayMode/Gameplay/Helicopter/
Assets/Scripts/Debugging/Gameplay/Helicopter/
Assets/Scripts/Editor/Gameplay/Helicopter/
Assets/Configs/Gameplay/Helicopter/
```

Inside a feature, **scripts split by concern** (`Movement/`, `Rotation/`,
`Interaction/`) and **content splits by type** (`Models/`, `Prefabs/`,
`Materials/`, ...). A root only has a feature folder when the feature has
something there; do not create empty mirrors.

**Exception to "by feature in the same folder":** testing, debugging and editor
logic never sit inside a Core feature folder. They live in their own roots with
their own asmdefs. Testing, Debugging and Editor code never ships in a release
build by default.

## Assembly definitions

| asmdef | includePlatforms | defineConstraints | references |
|---|---|---|---|
| `<Project>.Core` | all (runtime) | none | what Core needs |
| `<Project>.Debugging` | all | `["ENABLE_DEBUGGING"]` | `<Project>.Core` |
| `<Project>.Tests.Shared` | all | `["UNITY_INCLUDE_TESTS"]` | `<Project>.Core`, `nunit.framework` (precompiled), `UnityEngine.TestRunner` (no editor-only references, so PlayMode can use it) |
| `<Project>.Tests.EditMode` | `["Editor"]` | `["UNITY_INCLUDE_TESTS"]` | `<Project>.Core`, `<Project>.Tests.Shared`, `nunit.framework` (precompiled), `UnityEngine.TestRunner`, `UnityEditor.TestRunner` |
| `<Project>.Tests.PlayMode` | all | `["UNITY_INCLUDE_TESTS"]` | `<Project>.Core`, `<Project>.Tests.Shared`, `nunit.framework` (precompiled), `UnityEngine.TestRunner` |
| `<Project>.Editor` | `["Editor"]` | none | `<Project>.Core` |

- `ENABLE_DEBUGGING` is an **opt-in** scripting symbol, **off by default**. The
  Debugging assembly is therefore excluded from builds unless a developer adds
  the symbol in Player Settings. Debug code lives only in this assembly.
- Shared test helpers (assertions, factories, mocks) live in
  `Assets/Scripts/Testing/Shared/` under `<Project>.Tests.Shared`, referenced by
  both test assemblies. A player assembly such as PlayMode must not reference an
  editor assembly, so Shared and PlayMode omit `UnityEditor.TestRunner`.
- The Debugging, Testing and Editor assemblies reference Core. Core never
  references them.
- Place each asmdef at the root of its folder (`Assets/Scripts/Core/`,
  `Assets/Scripts/Debugging/`, ...), one per root, not one per feature.
- `<Project>` is the project's namespace prefix (`project.name`).

## Plugins

- `Plugins/Code/<Vendor>/`: code plugins. **Each one MUST have its own asmdef.**
  If the vendor ships none, create one. If the vendor has an `Editor/` folder,
  also create an Editor asmdef for it (`includePlatforms: ["Editor"]`) so editor
  code does not leak into player builds.
- `Plugins/Content/<Vendor>/`: imported asset packs (models, prefabs, audio, ...).
  Leave their internal structure alone; first-party content does not go here.
- A plugin's own `Editor/` folder is allowed inside `Plugins/`. Nowhere else
  under `Assets/` may an `Editor/` folder exist outside `Assets/Scripts/Editor/`.

## Settings, Configs, Resources

- `Settings/`: engine and game configuration assets (URP assets, Input actions,
  DI settings, quality profiles). Not per feature.
- `Configs/<Feature>/`: in-game ScriptableObjects (balance, definitions),
  usually loaded through Addressables. Per feature, mirrored.
- `Resources/<Feature>/`: exists **only** when `unity.asset_loading: resources`.
  Anything in a `Resources/` folder is included in every build, so it is not
  created by default.

## Asset loading: `unity.asset_loading`

The project's main loading method, recorded in `project.yaml`:

| Value | Meaning |
|---|---|
| `addressables` | Content and Configs are loaded through Addressables. No `Resources/` folder |
| `resources` | Loaded through the Resources API. `Assets/Resources/<Feature>/` exists |
| `direct` | Referenced directly from scenes and prefabs. No `Resources/` folder |

Set by `/setup-engine` (or edited by hand in `project.yaml`). Unset means
NOT CONFIGURED: `/setup-engine` asks, and nothing scaffolds
`Resources/` until it is `resources`. Never assume `resources`.

## Engine-reserved top-level folders

Unity and its packages create these under `Assets/`. They are allowed and are
not part of the layout: `StreamingAssets`, `Editor Default Resources`,
`Gizmos`, `AddressableAssetsData`, `TextMesh Pro`.

## Anti-patterns

- A type-first root folder: `Assets/Prefabs/`, `Assets/Materials/`,
  `Assets/Textures/`, `Assets/Sprites/`, `Assets/Models/`.
- Tests, editor code or debug code inside a Core feature folder
  (`Assets/Scripts/Core/Gameplay/Helicopter/Tests/`).
- Debug code outside the `<Project>.Debugging` assembly, or debug code in Core
  that is not behind the `ENABLE_DEBUGGING` constraint.
- A code plugin without its own asmdef, or a plugin `Editor/` folder with no
  Editor asmdef.
- A feature whose paths do not mirror (scripts under `Gameplay/Helicopter` but
  content under `Vehicles/Heli`).
- First-party C# outside `Assets/Scripts/`, or first-party content under
  `Assets/Plugins/`.
- A `Resources/` folder when `unity.asset_loading` is not `resources`.

## Enforcement

Advisory only; nothing blocks. `.claude/scripts/write-guard.sh check` (run by
`validate-write.sh` before every Write or Edit) warns when a path under
`Assets/` breaks the layout: a `.cs` outside `Assets/Scripts/` and
`Assets/Plugins/`, a test path outside `Assets/Scripts/Testing/`, an `Editor/`
path outside `Assets/Scripts/Editor/` and `Assets/Plugins/`, or a new top-level
folder that is not in the tree above or engine-reserved. The check looks at the
path only, so it does not verify asmdef contents or that a feature's roots
mirror; mirroring is checked by code review and this path check only. A path outside `Assets/` is
never checked by it.
