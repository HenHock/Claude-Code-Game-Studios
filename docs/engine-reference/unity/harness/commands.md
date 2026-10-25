# Unity: Changes are commands (harness H3)

Last verified: 2026-10-25. Rule: `.claude/docs/agent-harness.md` H3.
Every change to simulation state is a serializable command with a stable text
form, issued through one entry point. Input, AI, network and tests all use it.
Sessions can then be logged and replayed, and an agent can run a command script
against a live build without recompiling.

This is a design pattern, not a Unity API. Unity supplies no command system, so
there are no engine facts to source here; the Unity-specific parts are the
serializer (see `portable-state.md`) and where the entry point lives.

## Scope

- Applies to **simulation state** changes: what decides gameplay outcomes.
  Presentation changes (animation, VFX, UI, camera) are not commands.
- Applies only when the project has a simulation worth replaying. UI-only tools,
  editor scripts and `prototypes/` are out of scope.
- It binds code a change adds or touches. Do not rewrite existing setters or
  systems into commands. New or touched state changes go through the entry point.

## Shape

- **Command**: plain data, no logic and no scene references. A type tag plus
  fields, for example `{"type":"move","entity":7,"dx":1}`.
- **Entry point**: one method, such as `Apply(command)`, that validates the
  command, mutates state, and reports success or a rejection reason. Nothing else
  mutates simulation state.
- **Stable text form**: JSON through the same serializer as the state file
  (default `com.unity.nuget.newtonsoft-json`, see `portable-state.md`). The type
  tag is the stable name; renaming a C# class must not change it.
- **Command log**: the entry point can append each applied command to a file, with
  the step number it was applied on. Replaying the log from a saved state (H2)
  with the same seed (H1) reproduces the run.

## Who issues commands

Player input, AI, network messages, tests and agent scripts all create commands
and call the same entry point. Input handlers translate a key press into a
command and nothing more; they do not touch state.

## Time

Commands apply on a simulation step. Time arrives as the step (see
`determinism.md`), so a replay does not depend on the wall clock.

## Rejected commands

A command that fails validation changes nothing and returns a reason. An expected
gameplay rejection is a normal result, not an exception.

## Test

A command test builds a state, applies a command, and asserts the resulting
state, without the renderer (H5). A replay test applies a logged script and
asserts the final state equals the stored one.
