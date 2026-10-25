# Skill Spec Test: /create-control-manifest

Date: 2026-10-25
Spec: studio-tests/skills/pipeline/create-control-manifest.md
Overall Verdict: PASS

Evaluated by reading the skill and the spec; the skill was not run.

## Result by section

- Static Assertions: all PASS
- Case 1 (happy path): PASS
- Case 2 (no ADRs): PASS
- Case 3 (mixed statuses): PASS
- Case 4 (regeneration): PASS (the spec's example next-step wording differs from the skill's; the assertion, that the regeneration next-step shows instead of the first-run one, holds)
- Case 5 (TD-MANIFEST REJECT): PASS
- Case 6 (no Accepted ADR / no Status): PASS
- Case 7 (Foundation ADR marks H3 and H5 N/A): PASS after fixes
- Case 8 (no Foundation ADR): PASS after fixes
- Protocol Compliance: all PASS

## Changes made because of this run

- Skill: Phase 4 preview gained a `Harness rules left out:` line; the manifest template gained a `Not applicable:` line and a note that the rules bind code a story adds or touches.
- Skill: Phase 3 now says the Foundation ADR decides H1–H5, and H6 and H9 are sourced to `agent-harness.md`.
- Spec: Case 7 corrected. H6 and H9 take the source `agent-harness.md`, not ADR-0001 (the spec was wrong, not the skill).

## Not covered

An ADR that is Proposed, or that marks a rule N/A without a reason (Coverage Notes).
