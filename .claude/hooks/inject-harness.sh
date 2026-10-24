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
MSG="$MSG H1 one seeded randomness source, no direct wall-clock reads in sim logic. H2 full state saves/loads to a file. H3 every state change is a serializable, replayable command."
MSG="$MSG H4 tuning in external reloadable data. H5 simulation runs and is tested without the renderer. H6 flat entities over deep inheritance."
MSG="$MSG H7 capture on command and compare to a baseline with a numeric diff. H8 profiling output as text. H9 smallest verifiable step, checked by the loop: load state, apply commands, simulate, capture, diff, profile."
MSG="$MSG An unset harness.* capability in project.yaml is NOT CONFIGURED: say so in your report, never treat it as a pass. Prototypes and modes.workflow minimal: H1-H4 recommended, the rest optional."

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}\n' "$MSG"
exit 0
