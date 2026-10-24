# Coding Standards

- All game code must include doc comments on public APIs
- Architecture decisions are recorded as ADRs in `docs/architecture/`. **How many is
  set by `modes.workflow`** — all ADRs at `full`, *critical* ADRs only at `standard`,
  and none required at `minimal`, where the decision log and `design/game-brief.md`
  carry the rationale instead. See `.claude/docs/workflow-modes.md`.
- Gameplay values must be data-driven (external config), never hardcoded
- All public methods must be unit-testable (dependency injection over singletons)
- Commits must reference the relevant design document or task ID
- **Commit messages**: Use Conventional Commits format — `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Reference the story or task ID in the body (e.g., `Story: EPIC-001-S02`).
- **Verification-driven development**: Write tests first when adding gameplay systems.
  For UI changes, verify with screenshots. Compare expected output to actual output
  before marking work complete. Every implementation should have a way to prove it works.
- **A parse check is not a run.** Every story that changes something
  player-observable is launched and observed before it closes, and the
  observation is a retained screenshot in `production/qa/evidence/`. Procedure
  per engine: `.claude/docs/run-and-observe.md`. Not waived at
  `qa.level: minimal` — tests are, the look is not.

# Agent-Legible Game (Harness Principles)

**A change an agent cannot reproduce, observe and measure is not done.** These nine
rules are engine-agnostic; the full form, the verification loop and the
`harness.*` capability keys are in `.claude/docs/agent-harness.md`. Read it before
architecture, story or implementation work.

- **H1 Determinism**: all randomness comes from one injected, seeded source; sim logic never reads the wall clock directly
- **H2 Portable state**: the full simulation state saves to and loads from a file, built in the first sprint
- **H3 Changes are commands**: every state mutation is a serializable, replayable command through one entry point
- **H4 Data, not code**: tuning lives in external data that reloads without a rebuild
- **H5 Sim/presentation split**: the simulation runs and is tested without the renderer; the engine only displays it
- **H6 Uniform entities**: flat composition over deep inheritance; deviations need an ADR
- **H7 Observable**: capture any state on command with layer toggles; compare against a baseline with a numeric diff
- **H8 Measurable as text**: profiling output an agent can read and compare
- **H9 Small steps**: the smallest verifiable change, checked by the loop before the next one

Unset `harness.*` capabilities are **NOT CONFIGURED**, never a pass. At
`modes.workflow: minimal` and in `prototypes/`, H1–H4 are recommended and the rest optional.

# Design Document Standards

- All design docs use Markdown
- Each mechanic has a dedicated document in `design/gdd/`
- **How many of the 8 sections are required depends on `modes.workflow`** —
  all 8 at `full`, 5 (+ Formulas when the system defines numeric rules — rates,
  curves, thresholds, costs; the system's `Category` is a hint, not the test) at
  `standard`, and no
  GDD at all at `minimal`, where `design/game-brief.md` is the design record.
  See `.claude/docs/workflow-modes.md`. The 8 sections:
  1. **Overview** -- one-paragraph summary
  2. **Player Fantasy** -- intended feeling and experience
  3. **Detailed Rules** -- unambiguous mechanics
  4. **Formulas** -- all math defined with variables
  5. **Edge Cases** -- unusual situations handled
  6. **Dependencies** -- other systems listed
  7. **Tuning Knobs** -- configurable values identified
  8. **Acceptance Criteria** -- testable success conditions
- Balance values must link to their source formula or rationale

# Testing Standards

## Test Evidence by Story Type

All stories must have appropriate test evidence before they can be marked Done:

| Story Type | Required Evidence | Location | Default Gate Level |
|---|---|---|---|
| **Logic** (formulas, AI, state machines) | Automated unit test — must pass | `tests/unit/[system]/` | BLOCKING |
| **Integration** (multi-system) | Integration test OR documented playtest | `tests/integration/[system]/` | BLOCKING |
| **Visual/Feel** (animation, VFX, feel) | Retained screenshot + lead sign-off | `production/qa/evidence/` | BLOCKING |
| **UI** (menus, HUD, screens) | Retained screenshot of each screen touched | `production/qa/evidence/` | BLOCKING |
| **Config/Data** (balance tuning) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

The **Default Gate Level** applies when `testing.strict` is not set in
`project.yaml`. A project may override it per test type: `testing.strict.logic`,
`.integration`, `.visual`, `.ui`, and `.config` each take `true` (BLOCKING) or
`false` (ADVISORY). `/story-done`, `/story-readiness`, `/dev-story`,
`/gate-check`, and `/smoke-check` resolve the effective level from that setting,
falling back to the defaults above when it is absent.

> **Why Visual and UI block.** "Retained" is load-bearing — the screenshot must
> still be on disk in `production/qa/evidence/` when the story is closed. One
> that was captured and discarded is an assertion, not evidence. These two rows
> block because for a game the way it looks *is* the product: an advisory visual
> gate gets deferred in favour of whatever does block, and the result is a
> well-tested game that looks wrong.

> **Exception — `/smoke-check`.** The ADVISORY default for **Config/Data** above
> applies to *per-story evidence* gates. `/smoke-check` is a build-health gate,
> not a per-story evidence gate, so its own unset default for
> `testing.strict.config` is **BLOCKING**. The two defaults differ on purpose.

## Automated Test Rules

- **Naming**: per engine — `.claude/rules/test-standards.md`
- **Determinism**: Tests must produce the same result every run — no random seeds, no time-dependent assertions
- **Isolation**: Each test sets up and tears down its own state; tests must not depend on execution order
- **No hardcoded data**: Test fixtures use constant files or factory functions, not inline magic numbers
  (exception: boundary value tests where the exact number IS the point)
- **Independence**: Unit tests do not call external APIs, databases, or file I/O — use dependency injection

## What NOT to Automate

- Visual fidelity (shader output, VFX appearance, animation curves)
- "Feel" qualities (input responsiveness, perceived weight, timing)
- Platform-specific rendering (test on target hardware, not headlessly)
- Full gameplay sessions (covered by playtesting, not automation)

## CI/CD Rules

- Automated test suite runs on every push to main and every PR
- No merge if tests fail — tests are a blocking gate in CI
- Never disable or skip failing tests to make CI pass — fix the underlying issue
- CI command: `game-ci/unity-test-runner@v4` (GitHub Actions), running the Unity Test Framework (NUnit) EditMode and PlayMode suites
