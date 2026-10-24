---
paths:
  - "Assets/**/*.cs"
---

# Harness Rules (Agent-Legible Game)

Code-level form of `.claude/docs/agent-harness.md`, which is the source of truth.
These rules apply to every system in every engine. They sit above the
per-system rules (`gameplay-code.md`, `engine-code.md`, …) and agree with them.

- **H1** Take randomness from an injected, seeded source. Never call a global
  random function or read the system clock inside simulation logic. Time comes
  in as a step parameter.
- **H2** Every piece of simulation state must be reachable by the save routine.
  A new system adds itself to save/load **in the same story** that creates it,
  with a round-trip test (save → load → equal).
- **H3** Mutate simulation state only by issuing a command through the single
  command entry point. A command is plain data with a stable text form. Input,
  AI, network and tests issue the same commands.
- **H4** Read tuning values from external data. A new tunable is a data key, not
  a constant.
- **H5** Simulation code must not depend on engine scene, rendering or UI types.
  The engine layer reads state and forwards input. It holds no game rules.
  Simulation tests run without the renderer.
- **H6** Model entities as flat data plus a type tag and components. A new
  inheritance level for entities needs an ADR.
- **H7** Anything a story makes visible must be reachable by a direct start
  state and capturable on command. Presentation layers (UI, effects, debug) can
  be toggled for capture.
- **H8** Performance claims cite a text profile export, before and after.
- **H9** Keep the change to the smallest step the verification loop can check.

## Example (pseudocode, any engine)

**Correct**:

```text
sim.apply(Command("move", entity=7, dx=1))     # one entry point, serializable
damage = data["combat.base_damage"] * rng.next_float()   # injected rng + data
```

**Incorrect**:

```text
player.position += 1                            # mutation outside a command
damage = 10 * random()                          # magic number + ambient RNG
if clock.now() > deadline: ...                  # wall clock in sim logic
```

Prototypes (`prototypes/**`) and `modes.workflow: minimal`: H1–H4 recommended,
the rest optional.
