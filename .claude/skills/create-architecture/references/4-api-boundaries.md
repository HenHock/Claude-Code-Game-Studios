# /create-architecture — Phase 4: API Boundaries

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: API Boundaries

Define the public contracts between modules. For each boundary:

- What is the interface a module exposes to the rest of the system?
- What are the entry points (functions/signals/properties)?
- What invariants must callers respect?
- What must the module guarantee to callers?

Write in pseudocode or the project's actual language (from technical preferences).
These become the contracts programmers implement against.

**Harness boundary** (`.claude/docs/agent-harness.md`, H3 and H5). Define two
boundaries before any other:
- **Simulation ↔ presentation.** Which modules form the simulation that runs
  and is tested without the renderer, and what the engine layer reads (state or
  state diffs) and forwards (input as commands). A module that holds game rules
  and engine types together is flagged, not accepted.
- **The command surface.** The single entry point through which every state
  change arrives (input, AI, network, tests, replay), and the command's
  serializable text form.
At `workflow: minimal` these are recommended. Say which you recorded.

**Engine awareness check**: If any interface uses engine-specific types (e.g.
`MonoBehaviour`, `ScriptableObject`, `UnityEvent`), flag the version and verify the type
exists and has not changed signature in the target engine version.

Get user approval on the API boundaries, then record them in
`production/session-state/active.md`; they are written at Phase 7.

---
