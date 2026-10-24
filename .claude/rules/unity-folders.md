---
paths:
  - "Assets/**"
---

# Unity Folder Layout Rules

Short form of `.claude/docs/unity-folder-structure.md`, which is the source of
truth. Folders are by feature, not by asset type, and one feature uses the same
feature path under every root.

- Put first-party content in `Assets/Content/<Feature>/`, split by type inside
  the feature (`Models/`, `Prefabs/`, `Materials/`, ...).
- Put logic in `Assets/Scripts/Core/<Feature>/`, split by concern inside the
  feature (`Movement/`, `Interaction/`, ...). `Core` is not part of the mirror.
- Put tests in `Assets/Scripts/Testing/EditMode|PlayMode/<Feature>/`, debug code
  in `Assets/Scripts/Debugging/<Feature>/` (asmdef constraint `ENABLE_DEBUGGING`,
  off by default) and editor code in `Assets/Scripts/Editor/<Feature>/`. Never
  inside a Core feature folder. Shared test helpers go in
  `Assets/Scripts/Testing/Shared/` (asmdef `<Project>.Tests.Shared`).
- Put 3rd-party code in `Assets/Plugins/Code/<Vendor>/`, each with its own
  asmdef (create one if the vendor ships none, and an Editor asmdef for any
  `Editor/` folder in it). Imported packs go in `Assets/Plugins/Content/<Vendor>/`.
- Put engine and game configuration in `Assets/Settings/` and in-game
  ScriptableObjects in `Assets/Configs/<Feature>/`.
- `Assets/Resources/<Feature>/` exists only when `unity.asset_loading: resources`.
- Do not create type-first root folders (`Assets/Prefabs/`, `Assets/Materials/`).
- Do not create a new top-level `Assets/<X>/` outside Content, Scripts, Plugins,
  Settings, Configs, Resources (engine-reserved folders are fine).

## Example

**Correct**:

```text
Assets/Scripts/Core/Gameplay/Helicopter/Movement/HeliMove.cs
Assets/Content/Gameplay/Helicopter/Prefabs/Helicopter.prefab
Assets/Scripts/Testing/EditMode/Gameplay/Helicopter/HeliMoveTests.cs
Assets/Scripts/Debugging/Gameplay/Helicopter/HeliGizmos.cs
Assets/Configs/Gameplay/Helicopter/HeliStats.asset
```

**Incorrect**:

```text
Assets/Helicopter/HeliMove.cs                                  # code outside Assets/Scripts
Assets/Prefabs/Helicopter.prefab                               # type-first root folder
Assets/Scripts/Core/Gameplay/Helicopter/Tests/HeliTests.cs     # tests inside Core
Assets/Scripts/Core/Gameplay/Helicopter/HeliDebugDraw.cs       # debug code outside the Debugging asmdef
Assets/Plugins/Code/DOTween/                                   # (no .asmdef in it)
```
