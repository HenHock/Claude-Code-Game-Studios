# /create-architecture — Phase 6: Missing ADR List

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Missing ADR List

Based on the full architecture, produce a complete list of ADRs that should exist
but don't yet. Group by priority:

**Must have before coding starts (Foundation & Core decisions):**
- **Harness Foundation**, always listed unless an ADR titled `Harness Foundation`
  already exists (`bash .claude/scripts/harness-check.sh` reports
  `FOUNDATION_ADR:`). It decides H1–H5 of `.claude/docs/agent-harness.md`: the
  seeded randomness source, the save/load format, the command entry point and
  text form, where tuning data lives and how it reloads, and the
  simulation/presentation split. Title it `ADR-NNNN: Harness Foundation` so the
  check finds it.
- [e.g. "Scene management and scene loading strategy"]
- [e.g. "Event bus vs direct signal architecture"]

**Should have before the relevant system is built:**
- [e.g. "Inventory serialisation format"]

**Can defer to implementation:**
- [e.g. "Specific shader technique for water"]

---
