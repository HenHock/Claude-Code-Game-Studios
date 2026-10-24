# Agent-Legible Game — the Harness Principles

**The game is the agent's harness.** An agent sees code as written. It does not
see assets, scenes, tuning values or runtime state unless the game exposes them.
Most failures in AI-driven game work come from that gap, not from the model. These
principles close the gap by making the game itself something an agent can
**reproduce, drive, observe and measure** without a human acting as its eyes.

This file is the single source of truth. `coding-standards.md` carries the
one-line form, `.claude/rules/harness.md` the code-level do/don't,
`.claude/hooks/inject-harness.sh` the reminder every subagent receives. When they
disagree, this file wins; fix the others.

Source: Kyle Kukshtel, *Your Game Is A Harness* —
https://kylekukshtel.com/ai-harness-engineering-game-development-claude-code.
Everything here is **engine-agnostic**. How a given engine meets a capability is
recorded per engine in `docs/engine-reference/<engine>/` and in the `harness.*`
keys of `project.yaml` — never assumed from training data.

## The rule

**A change an agent cannot reproduce, observe and measure is not done.**

## The nine principles

| # | Principle | Requirement | Why an agent needs it |
|---|---|---|---|
| H1 | **Determinism** | All randomness flows from one seeded source, injected into the simulation. Simulation logic never reads ambient randomness or wall-clock time directly; time arrives as a parameter (fixed or recorded step). | The same inputs give the same state, so a bug reproduces and a fix can be proved. |
| H2 | **Portable state** | The full simulation state can be saved to and loaded from a file **from the first sprint**, with no "add it later". Loading a save gives an exactly equal state. | Any bug, test fixture or start point becomes a file the agent can jump straight to. |
| H3 | **Changes are commands** | Every mutation of simulation state is a serializable command object with a stable text form. Input, AI, network and tests all go through the same command entry point. | Sessions can be logged and replayed. An agent can write a command script and run it against a live build with **no recompile**. |
| H4 | **Data, not code** | Tuning values (speeds, costs, damage, curves) live in external data loaded at runtime and reloadable without a rebuild. | The agent iterates on balance without compiling. Non-programmers can too. |
| H5 | **Simulation / presentation split** | The simulation is a module that runs and is tested **without the engine's renderer or scene graph**. It takes commands and reports state or state diffs. The engine layer displays and forwards input, and owns no game rules. | Logic tests run with plain tooling, fast and headless. Anything can drive the game: tests, replays, network, an agent. |
| H6 | **Uniform entity model** | Prefer one flat entity shape (data + type tag + composition) over deep inheritance trees. Deviations need an ADR. | One source of truth that serializes trivially and leaves nothing ambiguous for the agent to infer. |
| H7 | **Observable on demand** | The game can produce a capture of a given state on command, with toggles to hide presentation layers (UI, effects, debug). Visual checks compare against a stored **baseline** and yield a **numeric similarity** for the region of change, not two raw images. | The agent checks a visual change with one number instead of scanning full screenshots, which also keeps its context clean. |
| H8 | **Measurable as text** | Performance and memory data can be exported in a text form an agent can read and compare between runs. | The agent can check the cost of its own change against the budget. |
| H9 | **Small steps, stable baseline** | Each change is the smallest that can be verified, and is verified by the **loop** below before the next one starts. Baselines (saves, captures, profiles) are updated only on purpose, never as a side effect. | Errors are caught one step after they appear, not ten. Technical debt stays low. |

## The verification loop

```text
load state (H2) → apply commands / data (H3, H4) → simulate N fixed steps (H1, H5)
  → capture + diff against baseline (H7) → profile as text (H8) → compare → report
```

The loop is the agent-facing definition of *done* for a story that changes game
behaviour. It runs in seconds, so it runs on **every** change, not only on big
ones. Its pieces are the abstract **capabilities** below.

## Capabilities — the abstract contract

Each capability is a `harness.*` key in `project.yaml`, holding the command or
path that provides it. **This framework ships them unset.** An unset key means
**NOT CONFIGURED**, never "not needed" and never a pass (see
`.claude/rules/skill-authoring.md`, obligation 2). Engine-specific values are a
later step and are filled from `docs/engine-reference/`, never guessed.

| Key | Capability | Serves |
|---|---|---|
| `harness.rng_seed` | How a seed is supplied to a run (flag, config key, command) | H1 |
| `harness.state_save` | Command that writes the current simulation state to a file | H2 |
| `harness.state_load` | Command that starts a run from a state file | H2 |
| `harness.command_replay` | Command that runs a command script/log against a running or headless build | H3 |
| `harness.data_reload` | How tuning data is reloaded without a rebuild | H4 |
| `harness.sim_test` | Command that runs simulation tests without the renderer | H5 |
| `harness.capture` | Command that captures a state to an image, with layer toggles | H7 |
| `harness.image_diff` | Command that compares two images and prints a similarity number | H7 |
| `harness.profile_text` | Command that exports a profile as text | H8 |

`.claude/scripts/harness-check.sh` reports which keys are set and which harness
artifacts exist. It emits observations, never a verdict.

## Where the principles enter the workflow

| Stage | What carries the principles |
|---|---|
| Architecture | `/create-architecture` maps the simulation/presentation boundary and command surface, and requires a **Harness Foundation ADR** (H1–H5 decisions). Every ADR has a **Harness Impact** section. |
| Planning | `/sprint-plan` puts the harness foundation (seeded randomness, save/load, command entry point) in the **first** implementation sprint. |
| Stories | `/create-stories` fills each story's **Harness** block: start state, commands to apply, what is observed and with which metric. |
| Implementation | `/dev-story` passes the Harness block to the implementer and runs the loop with the capabilities that exist. |
| Review | `/code-review` checks the H-rules. `/story-done` reports the loop result. A story whose Harness block is empty is **NOT ASSESSED**, not passed. |
| Every subagent | `inject-harness.sh` (SubagentStart) adds the short form to each spawned agent's context. |

## Scale

The author's own caveat applies: a small project may not need all of this.

- `modes.workflow: minimal` and `prototypes/`: H1–H4 are **recommended**, the
  rest optional. A prototype is throwaway (see `.claude/rules/prototype-code.md`).
- `standard` and `full`: all nine apply. Deviating from one needs an ADR that
  names the principle and says what replaces it.

## Anti-patterns

- Simulation code that reads a global random source or the system clock.
- State that exists only in live engine objects, so a save can't capture it.
- Gameplay changes made by calling scattered setters instead of issuing a command.
- Tuning numbers compiled into code, or reachable only through the editor UI.
- Game rules inside engine callbacks, scene scripts or UI handlers.
- Deep inheritance plus polymorphic serialization for entities ("there be dragons").
- Visual checks done by putting two full screenshots in context with no diff.
- A capability that silently does nothing when unset. It must say NOT CONFIGURED.
