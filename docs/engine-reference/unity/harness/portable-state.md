# Unity: Portable state (harness H2)

Last verified: 2026-10-25 (sources below). Rule: `.claude/docs/agent-harness.md` H2.
The full simulation state saves to a file and loads back to an exactly equal
state, so any bug or test start point becomes a file an agent can jump to.

## Scope

- Applies to **simulation state**: the data that decides gameplay outcomes
  (entities, resources, progress, timers, the RNG state). It does not apply to
  presentation (animation poses, particles, UI layout, camera), which is rebuilt
  from state on load.
- Applies when a project has such state worth saving. A project with no
  persistent simulation state has nothing to enforce.
- It binds code a change adds or touches. Do not rewrite existing systems to
  satisfy H2; a new system joins the save routine in the story that creates it.

## What goes in the file

- Plain data only: ids, numbers, strings, lists of those. No references to
  `GameObject`, `Transform`, `MonoBehaviour` or scene objects. Refer to entities
  by stable id and re-link after load.
- The RNG state from H1 (see below), so a loaded run continues the same sequence.
- A format version number, so an old state file fails loudly instead of loading wrong.
- Text format (JSON) by default. An agent can read and edit it, and a diff shows
  what changed.

## Serializer choice (Unity facts)

| Option | Fits | Limits |
|---|---|---|
| `com.unity.nuget.newtonsoft-json` (package 3.2.2, Json.NET 13.0.2) — **default** | Dictionaries, polymorphism, richer state | Extra package dependency. IL2CPP/AOT behavior and Unity types such as `Vector3` are NOT SOURCEABLE here: the package page does not cover them. Check the package changelog or Json.NET docs. |
| `JsonUtility` (built in) | Small, flat `[Serializable]` classes and structs | Serializes fields only. `Dictionary<>` is not supported. Top-level arrays and primitives must be wrapped in a class. No polymorphism. `FromJson` throws for `MonoBehaviour`/`ScriptableObject` (use `FromJsonOverwrite`). |

**Default: `com.unity.nuget.newtonsoft-json`.** It is Unity's official package,
and it handles dictionaries, polymorphism and null, which state files need.
Add it with the package manager when the project first needs a state file.
Keep state as plain data (H6) regardless, so the serializer stays swappable.
Use `JsonUtility` only for a tiny, flat state. Record the choice in the Harness
Foundation ADR.

Before relying on it, verify on the pinned editor and target platform (NOT
SOURCEABLE here, see the table): an IL2CPP build round-trips the state, and any
`Vector3`/`Quaternion` fields are stored as plain numbers rather than Unity
types.

## RNG state (ties to H1)

- `Random.state` is a `Random.State`, documented as serializable "so that
  determinism can be preserved across sessions". Save it with the game state and
  assign it back on load.
- A `Random.State` cannot be constructed by hand and the seed cannot be read back
  from the generator, so save the state, not just the seed.
- Other generators (`System.Random`, `Unity.Mathematics.Random`): save their own
  state. `Unity.Mathematics.Random` exposes its state as a `uint`. NOT SOURCEABLE
  here beyond that: verify against the package before use.

## The round-trip test

Each system that owns simulation state ships one test: build a state, save,
load, assert equal. Compare the saved text of both states, or compare field by
field. A save that loads without error is not a pass; equality is the test.

## Sources

- https://docs.unity3d.com/6000.0/Documentation/Manual/json-serialization.html
- https://docs.unity3d.com/ScriptReference/Random-state.html
- https://docs.unity3d.com/Packages/com.unity.nuget.newtonsoft-json@3.2/manual/index.html
