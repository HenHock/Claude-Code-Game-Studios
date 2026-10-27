#!/usr/bin/env bash
# unity-root.sh — where the Unity project sits, relative to the repo root.
#
# The framework is launched from the repo root, and `Assets/` and `Packages/`
# are normally directly under it. When the Unity project is nested one level
# down (`<repo>/<ProjectName>/Assets`), `unity.project_root` in project.yaml
# names that folder, and every path the framework builds for Assets/ or
# Packages/ is prefixed with it.
#
# Usage: bash .claude/scripts/unity-root.sh [--root DIR]
#   prints  the folder relative to the repo root, with no leading or trailing
#           slash; an empty line when the Unity project is at the repo root
#   exit    0 resolved (empty counts), 1 the configured value is unusable
#           (absolute, holds `..`, or is not a folder name); the reason goes
#           to stderr and stdout stays empty
# Reads project.yaml only: the folder is a fact about the repo, shared by the
# whole team, so project.local.yaml cannot override it (config-set.sh agrees).
# Sourced scripts call `unity_root_prefix`, which prints the same
# folder with a trailing slash (or nothing).
#
# EMITS AN OBSERVATION, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Whether a missing folder stops the work is the caller's call.
#
# bash 3.2 and BWK awk safe, no Python.

_UR_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# unity_root_raw ROOTDIR -> the configured value, "" when unset
_unity_root_raw() {
  local f v
  for f in "$1/project.yaml"; do
    [ -f "$f" ] || continue
    v=$(YG_PATH=unity.project_root LC_ALL=C awk -f "$_UR_HERE/yaml-get.awk" "$f" 2>/dev/null | tr -d '\r')
    if [ -n "$v" ]; then printf '%s' "$v"; return 0; fi
  done
  return 0
}

# unity_root [ROOTDIR] -> normalized folder; non-zero when the value is unusable
unity_root() {
  local root="${1:-.}" v
  v=$(_unity_root_raw "$root")
  # Backslashes are slashes; drop leading ./ and surrounding slashes.
  v=$(printf '%s' "$v" | tr '\\' '/' | sed 's#^\(\./\)*##; s#^/*##; s#/*$##')
  case "$v" in
    ''|.) return 0 ;;
    [A-Za-z]:*) echo "unity-root: unity.project_root must be relative to the repo root, got '$v'" >&2; return 1 ;;
  esac
  # A raw value that began with / was absolute: the sed above stripped it, so
  # re-check the original.
  case "$(_unity_root_raw "$root")" in
    /*|\\*) echo "unity-root: unity.project_root must be relative to the repo root" >&2; return 1 ;;
  esac
  case "/$v/" in
    */../*) echo "unity-root: unity.project_root may not contain '..'" >&2; return 1 ;;
  esac
  printf '%s' "$v"
}

# unity_root_prefix [ROOTDIR] -> "<folder>/" or nothing
unity_root_prefix() {
  local v
  v=$(unity_root "${1:-.}") || return 1
  [ -n "$v" ] && printf '%s/' "$v"
  return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  ROOT="."
  while [ $# -gt 0 ]; do
    case "$1" in
      --root) ROOT="${2:-.}"; shift 2 ;;
      -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) echo "unity-root: unknown argument '$1' (try --help)" >&2; exit 2 ;;
    esac
  done
  v=$(unity_root "$ROOT") || exit 1
  printf '%s\n' "$v"
fi
