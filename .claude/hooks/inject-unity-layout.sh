#!/bin/bash

# Claude Code SubagentStart hook: give every spawned CCGS agent the Unity folder layout
#
# CLAUDE.md and directory-structure.md carry the layout, but a subagent working
# from a narrow brief weighs its brief over a long standards file, and the
# path-scoped rule (.claude/rules/unity-folders.md) only loads when a matching
# file is READ. This is the one layer that reaches every agent at the moment it
# starts, so the layout cannot be forgotten by omission.
#
# Source of truth: .claude/docs/unity-folder-structure.md. Keep this text a short
# form of that file. If they disagree, fix this one.
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

MSG='CCGS Unity folder layout (full contract: .claude/docs/unity-folder-structure.md). Folders are by feature, not by asset type, and one feature uses the same feature path under every root: Assets/Content/<Feature>/ (content), Assets/Scripts/Core/<Feature>/ (logic), Assets/Scripts/Testing/EditMode|PlayMode/<Feature>/, Assets/Scripts/Debugging/<Feature>/, Assets/Scripts/Editor/<Feature>/, Assets/Configs/<Feature>/.'
MSG="$MSG Never put tests, editor or debug code inside a Core feature folder: each has its own root and asmdef (Debugging is behind the opt-in ENABLE_DEBUGGING symbol, off by default)."
MSG="$MSG 3rd-party code goes in Assets/Plugins/Code/<Vendor>/ and each plugin needs its own asmdef (plus an Editor asmdef for its Editor/ folder); imported packs in Assets/Plugins/Content/<Vendor>/. Engine and game configuration goes in Assets/Settings/."
MSG="$MSG No type-first root folders such as Assets/Prefabs/. Assets/Resources/ exists only when unity.asset_loading is resources; an unset unity.asset_loading is NOT CONFIGURED, ask rather than assume."

# A nested Unity project (unity.project_root): the paths above are relative to it.
if [ -f .claude/scripts/unity-root.sh ]; then
    . .claude/scripts/unity-root.sh 2>/dev/null
    _UDIR=$(unity_root . 2>/dev/null)
    if [ -n "$_UDIR" ]; then
        MSG="$MSG The Unity project is nested: every Assets/ and Packages/ path above lives under ${_UDIR}/ (unity.project_root), so write ${_UDIR}/Assets/..., never a top-level Assets/."
    fi
fi

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}\n' "$MSG"
exit 0
