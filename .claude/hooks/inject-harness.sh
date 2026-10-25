#!/bin/bash

# Claude Code SubagentStart hook: give every spawned CCGS agent the harness rules
#
# CLAUDE.md and coding-standards.md already carry the H-rules, but a subagent
# working from a narrow brief weighs its brief over a long standards file, and a
# path-scoped rule only loads when a matching file is READ (see
# .claude/docs/rules-reference.md). This is the one layer that reaches every
# agent at the moment it starts, so the rules cannot be skipped by omission.
#
# Source of truth: .claude/docs/agent-harness.md. Keep this text a short form
# of that file. If they disagree, fix this one.
#
# Output: hookSpecificOutput.additionalContext only. No systemMessage: the user
# would otherwise see this text on every spawn. Not hook_warn (yaml-helper.sh)
# for the same reason: it sets both.
#
# Always exits 0. A reminder must never block a spawn.

INPUT=$(cat)

# Claude Code's own internal agents (prompt suggestions, /btw side questions)
# report agent_type as an empty string. They are not CCGS work: skip them, as
# log-agent.sh does.
if printf '%s' "$INPUT" | grep -qE '"agent_type"[[:space:]]*:[[:space:]]*""'; then
    exit 0
fi

MSG='CCGS harness rules (full contract: .claude/docs/agent-harness.md). A change an agent cannot reproduce, observe and measure is not done.'
MSG="$MSG H1 randomness that affects game logic or behavior is seeded from one setup point, the run records its seed so the same seed reproduces it, no wall-clock reads in game-rules logic (presentation randomness such as particles is out of scope). H2 simulation state saves/loads to a file. H3 simulation state changes are serializable, replayable commands."
MSG="$MSG H4 gameplay tuning values in external reloadable data. H5 game rules live in a pure C# layer (use the project's own layer name, never create a Sim folder) that runs and is tested without the renderer. H6 flat simulation entities over deep inheritance."
MSG="$MSG H7 a visual change is capturable on command and compared to a baseline with a numeric diff. H8 a performance claim cites a text profile, before and after. H9 smallest verifiable step, checked by the loop: load state, apply commands, simulate, capture, diff, profile."
MSG="$MSG Scope: the rules bind the code you add or touch, only where the project has that kind of logic. Do not rewrite or retrofit existing code to satisfy them, and do not turn untouched code into a finding. Physics determinism matters only for ECS/DOTS projects whose gameplay depends on physics."
MSG="$MSG An unset harness.* capability in project.yaml is NOT CONFIGURED: say so in your report, never treat it as a pass. Prototypes and modes.workflow minimal: H1-H4 recommended, the rest optional."

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}\n' "$MSG"
exit 0
