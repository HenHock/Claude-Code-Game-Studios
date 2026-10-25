# Unity: Small steps, stable baseline (harness H9)

Last verified: 2026-10-25. Rule: `.claude/docs/agent-harness.md` H9.
Each change is the smallest one that can be verified, and is verified by the
loop before the next one starts. Baselines (saves, captures, profiles) are
updated only on purpose, never as a side effect.

This is a working rule, not an engine feature, so there are no Unity API facts to
source here. The Unity-specific part is which checks make up the loop.

## Scope

- Applies to changes that alter game behavior or what the player sees. A
  documentation edit, a rename, or a comment needs no loop.
- It governs how an agent works on a task. It is not a reason to split a story
  into artificial pieces. A step is "the smallest change a check can tell right
  from wrong", which can be a few files.
- At `modes.workflow: minimal` and in `prototypes/` it is a recommendation.

## The loop for a step

Use the checks the project has configured, in this order, and stop at the first
failure:

1. **Compiles** with no new errors.
2. **Logic tests** pass: EditMode tests for the rules layer (`sim-presentation-split.md`),
   including the save/load round-trip (`portable-state.md`) and command tests
   (`commands.md`).
3. **Run from a known state**: load the start state, apply the command script,
   step N fixed steps with the seed set (`determinism.md`).
4. **Visual diff** if the step changes what is shown (`visual-capture.md`).
5. **Profile as text** if the step makes a performance claim (`profile-text.md`).

A check whose `harness.*` capability is unset is reported **NOT CONFIGURED**. It
is never counted as passed. A long manual check (a Play Mode session, a device
build) goes to the user rather than being run unasked.

## Baselines

- A baseline is a stored reference: a state file, a capture image, a profile text
  file, or an expected command-script result.
- Update one only when the step is meant to change it. The report says which
  baseline changed and why, and shows the diff.
- A failing check is never fixed by regenerating the baseline to match the new
  output. Decide first whether the new output is the intended result.
- Never update a baseline in the same step that is still being debugged.

## Reporting

At the end of a step, the report lists each check as passed, failed or NOT
CONFIGURED, with the numbers (test counts, diff percentage, metric before and
after). It does not say "verified" for a check that did not run.
