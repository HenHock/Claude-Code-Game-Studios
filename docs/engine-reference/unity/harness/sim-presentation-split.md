# Unity: Simulation layer / presentation split (harness H5)

Last verified: 2026-10-25 (sources below). Rule: `.claude/docs/agent-harness.md` H5.
The game rules live in a pure C# layer between the game logic and the view. It
runs and is tested without the renderer or scene graph. It takes commands (H3),
and exposes state. The engine layer displays state and forwards input, and owns
no game rules.

## The simulation layer is the real game, not a test copy

It is the code that decides gameplay outcomes in the shipped game. A test runs
that same code. Never write a separate "test simulator" that imitates the
rules: the two drift apart and tests pass while the game is broken. The agent
benefit (fast, headless, repeatable runs) follows from building the game this way.

## It is a role, not a name

"Simulation layer" is the term agent-facing docs use for a role. A project's own
names win: `Controllers`, `Logic`, `Model`, `Systems`, `Domain`. Do not create
folders, namespaces or classes literally called `Sim`. The project records which
folder or namespace plays the role (in the Harness Foundation ADR or
`project.yaml`), for example "simulation layer = `Core/<Feature>/Controllers`".

A layer plays the role when it has all of these:

- It holds game rules and state.
- It is pure C#: no scene, no `GameObject`, `Transform`, `MonoBehaviour`,
  `ScriptableObject` references, no wall-clock reads.
- Commands and a time step go in, and state is readable out.
- It runs in a plain test with no scene.

Controllers that are pure C# are the layer. Controllers that touch `MonoBehaviour`
or the scene are not, and H5 applies to them.

## Scope

- Applies to **game rules**: code that decides gameplay outcomes. Presentation
  code (views, animation, VFX, UI, camera, audio playback) is the engine layer
  and may use any Unity type.
- Applies only when the project has such rules. A UI-only tool, a project that is
  mostly physics, animation or feel, or a project with no gameplay logic has
  nothing to split.
- It binds code a change adds or touches. Do not move existing `MonoBehaviour`
  logic into the layer to satisfy H5. New or touched game rules go in the layer.

## Shape

- **Simulation layer**: plain C# classes and structs for state and rules. Input
  is commands, time is a step parameter (see `determinism.md`), output is state or
  a state change.
- **Engine layer**: `MonoBehaviour`s and views that read state each frame,
  translate input into commands, and update visuals. A `MonoBehaviour` may own and
  tick the simulation object; it must not contain the rules.
- `Vector3` or `Mathf` in rules are not the problem. The test is whether the
  layer runs in a unit test with no scene and no `GameObject`. Prefer plain numbers
  or `Unity.Mathematics` types in state so it serializes cleanly (see
  `portable-state.md`).

## Testing

Tests are plain NUnit EditMode tests that construct the layer, apply commands
and assert state. They need no scene and no Play Mode. Rendering and view
behavior are checked by capture (H7), not by logic tests.

## Optional: compiler enforcement

If a project wants the compiler to enforce the boundary, an assembly with
`noEngineReferences: true` (JSON key, default `false`) does not reference the
UnityEditor or UnityEngine assemblies, so engine code in it fails to compile.
This needs the layer in its own assembly, which bends "one asmdef per root"
(`unity-folder-structure.md`), so it requires an ADR. Not a default. NOT
SOURCEABLE here: its interaction with `Unity.Mathematics` and the Test Framework
assemblies; verify on the pinned editor first.

## Sources

- https://docs.unity3d.com/6000.0/Documentation/Manual/assembly-definition-file-format.html (`noEngineReferences`, boolean, default false)
- https://docs.unity.com/en-us/engine/6000.3/manual/programming-environment/script-compilation/assembly-definition-files/class-assembly-definition-importer (No Engine References)
