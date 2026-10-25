---
paths:
  - "Assets/**/*.cs"
---

# Harness Rules (Agent-Legible Game)

Code-level form of `.claude/docs/agent-harness.md`, which is the source of truth.
These rules apply to every system in every engine. They sit above the
per-system rules (`gameplay-code.md`, `engine-code.md`, …) and agree with them.

- **H1** Seed every random source from one setup point and record the seed, so
  the same seed reproduces the run (any generator type is fine). Never read the
  system clock inside simulation logic. Time comes in as a step parameter.
  Applies only to randomness that affects logic or behavior (not particles or
  VFX) and only to code you write or touch; do not rewrite existing code for it.
  Physics determinism matters only for ECS/DOTS projects whose gameplay depends
  on physics.
  Unity mechanisms: `docs/engine-reference/unity/harness/determinism.md`.
- **H2** Every piece of simulation state must be reachable by the save routine.
  A new system adds itself to save/load **in the same story** that creates it,
  with a round-trip test (save → load → equal). Applies to simulation state
  only (not presentation) and to code you write or touch; do not retrofit
  existing systems. Unity mechanisms:
  `docs/engine-reference/unity/harness/portable-state.md`.
- **H3** Mutate simulation state only by issuing a command through the single
  command entry point. A command is plain data with a stable text form. Input,
  AI, network and tests issue the same commands. Applies to simulation state
  only (not UI, VFX or editor tools) and to code you write or touch; do not
  retrofit existing setters. Unity notes:
  `docs/engine-reference/unity/harness/commands.md`.
- **H4** Read gameplay tuning values from external data. A new tunable is a data
  key, not a constant. Applies to values a designer would balance, not to
  structural, presentation or one-off constants, and only to values you add or
  touch. Unity notes: `docs/engine-reference/unity/harness/data-tuning.md`.
- **H5** Game rules live in a pure C# layer that must not depend on engine scene,
  rendering or UI types. The engine layer reads state and forwards input. It
  holds no game rules. Tests of the rules run without the renderer. "Simulation
  layer" is a role: use the project's own names (`Controllers`, `Logic`, ...),
  never a folder or class called `Sim`. Applies to game rules in code you write
  or touch; views, animation, VFX and UI may use any Unity type. Do not move
  existing `MonoBehaviour` logic out to satisfy it. Unity notes:
  `docs/engine-reference/unity/harness/sim-presentation-split.md`.
- **H6** Model simulation entities as flat data plus a type tag and components. A
  new inheritance level for entities needs an ADR. Applies to entity types you add
  or touch, not to Unity scene objects or existing hierarchies. Unity notes:
  `docs/engine-reference/unity/harness/entity-model.md`.
- **H7** Anything a story makes visible must be reachable by a direct start
  state and capturable on command. Presentation layers (UI, effects, debug) can
  be toggled for capture. Applies to the visual change a story makes, not to
  existing screens. Unity notes:
  `docs/engine-reference/unity/harness/visual-capture.md`.
- **H8** Performance claims cite a text profile export, before and after. Applies
  only to stories that make a performance or memory claim. Unity notes:
  `docs/engine-reference/unity/harness/profile-text.md`.
- **H9** Keep the change to the smallest step the verification loop can check.
  Update a baseline (save, capture, profile) only on purpose, never to make a
  failing check pass. Unity notes: `docs/engine-reference/unity/harness/small-steps.md`.

## Example (pseudocode, any engine)

**Correct**:

```text
sim.apply(Command("move", entity=7, dx=1))     # one entry point, serializable
rng = rngFactory.For("combat")                  # derived from the run seed, set up once
damage = data["combat.base_damage"] * rng.next_float()   # seeded rng + data
```

**Incorrect**:

```text
player.position += 1                            # mutation outside a command
damage = 10 * random()                          # magic number + unseeded RNG
if clock.now() > deadline: ...                  # wall clock in sim logic
```

Prototypes (`prototypes/**`) and `modes.workflow: minimal`: H1–H4 recommended,
the rest optional.
