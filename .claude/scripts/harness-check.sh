#!/usr/bin/env bash
# harness-check.sh — report what of the agent harness (.claude/docs/agent-harness.md)
# exists in this project: which harness.* capabilities are set, whether a
# Harness Foundation ADR exists, and whether stories carry a filled Harness block.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/
# emit observations, never verdicts"). It never prints PASS or FAIL. The caller
# applies the workflow tier and decides. In particular, UNSET is not "not
# needed". The caller reports it as NOT CONFIGURED.
#
# Usage: bash .claude/scripts/harness-check.sh [--story <story.md>] [project-root]
#   --story <path>  report the Harness block of one story only (plus the slots)
#   project-root    defaults to the repo root
#
# Output (one observation per line, denominators first):
#   CONFIG: <path> | CONFIG: missing
#   SLOTS: <n>                         how many capabilities were checked
#   SLOT: harness.<key> status=SET|UNSET [form=scalar|os-map]
#   SLOTS_SET: <n> / SLOTS_UNSET: <n>
#   FOUNDATION_ADR: present path=<file> | absent | not-assessed reason=<why>
#   STORIES: <n>                       story files scanned (0 is reported, not hidden)
#   STORY: <path> harness=FILLED|EMPTY|NO_SECTION
#   STORIES_FILLED: <n> / STORIES_EMPTY: <n> / STORIES_NO_SECTION: <n>
#
# A Harness block is EMPTY when every line in it is blank, a comment, or a
# template placeholder ([...]). The story template ships it that way.

set -u

STORY=""
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --story)
      [ $# -ge 2 ] || { echo "harness-check: --story needs a path" >&2; exit 2; }
      STORY="$2"; shift 2 ;;
    *) ROOT_ARG="$1"; shift ;;
  esac
done

if [ -n "$ROOT_ARG" ]; then
  ROOT="$ROOT_ARG"
else
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
cd "$ROOT" 2>/dev/null || { echo "harness-check: cannot enter $ROOT" >&2; exit 2; }

AWK_GET=".claude/scripts/yaml-get.awk"
# Derived from agent-harness.md's capability table, so a key added there is
# checked here without editing this list.
SLOTS=$(grep -oE '^\| `harness\.[a-z_]+`' .claude/docs/agent-harness.md 2>/dev/null \
        | sed 's/^| `harness\.//; s/`$//')
if [ -z "$SLOTS" ]; then
  echo "SLOTS: 0"
  echo "SLOTS_NOT_ASSESSED: reason=no capability table found in .claude/docs/agent-harness.md"
else
  get() { YG_PATH="$1" LC_ALL=C awk -f "$AWK_GET" project.yaml 2>/dev/null; }
  unset_val() { case "$1" in ""|null|"~"|'""'|"''") return 0 ;; *) return 1 ;; esac; }

  if [ -f project.yaml ]; then echo "CONFIG: project.yaml"; else echo "CONFIG: missing"; fi
  echo "SLOTS: $(printf '%s\n' "$SLOTS" | grep -c .)"
  SET=0; UNSET=0
  for k in $SLOTS; do
    status=UNSET; form=""
    if [ -f project.yaml ]; then
      v=$(get "harness.$k")
      if ! unset_val "$v"; then
        status=SET; form=scalar
      else
        # The OS-aware map that commands.* takes: any one OS entry counts.
        for os in default windows linux macos; do
          v=$(get "harness.$k.$os")
          if ! unset_val "$v"; then status=SET; form=os-map; break; fi
        done
      fi
    fi
    if [ "$status" = SET ]; then
      SET=$((SET + 1)); echo "SLOT: harness.$k status=SET form=$form"
    else
      UNSET=$((UNSET + 1)); echo "SLOT: harness.$k status=UNSET"
    fi
  done
  echo "SLOTS_SET: $SET"
  echo "SLOTS_UNSET: $UNSET"
fi

# Foundation ADR: an ADR whose title names the harness foundation.
if [ -d docs/architecture ]; then
  ADR=$(grep -lE '^# ADR-[0-9]+:.*[Hh]arness [Ff]oundation' docs/architecture/*.md 2>/dev/null | head -1)
  if [ -n "$ADR" ]; then echo "FOUNDATION_ADR: present path=$ADR"; else echo "FOUNDATION_ADR: absent"; fi
else
  echo "FOUNDATION_ADR: not-assessed reason=docs/architecture/ does not exist"
fi

# harness_block <file> -> FILLED | EMPTY | NO_SECTION
harness_block() {
  awk '
    /^## Harness[[:space:]]*$/ { sec = 1; seen = 1; next }
    sec && /^## / { sec = 0 }
    sec {
      l = $0; sub(/\r$/, "", l)
      # Strip "**Label:**" labels first: the list-marker strip below would
      # otherwise eat their leading "**" and leave the label looking like content.
      gsub(/\*\*[^*]*\*\*:?/, "", l); sub(/^[ \t>]*([-*][ \t]+)?/, "", l)
      if (l == "" || l ~ /^<!--/ || l ~ /-->$/) next
      gsub(/\[[^]]*\]/, "", l); gsub(/[ \t:|`*-]/, "", l)
      if (l != "") filled = 1
    }
    END { if (!seen) print "NO_SECTION"; else if (filled) print "FILLED"; else print "EMPTY" }
  ' "$1"
}

if [ -n "$STORY" ]; then
  FILES="$STORY"
else
  FILES=$(find production/epics -type f -name 'story-*.md' 2>/dev/null | sort)
fi
N=$(printf '%s\n' "$FILES" | grep -c .)
echo "STORIES: $N"
F=0; E=0; S=0
for f in $FILES; do
  if [ ! -f "$f" ]; then echo "STORY: $f harness=NOT_FOUND"; continue; fi
  r=$(harness_block "$f")
  echo "STORY: $f harness=$r"
  case "$r" in FILLED) F=$((F + 1)) ;; EMPTY) E=$((E + 1)) ;; NO_SECTION) S=$((S + 1)) ;; esac
done
echo "STORIES_FILLED: $F"
echo "STORIES_EMPTY: $E"
echo "STORIES_NO_SECTION: $S"
exit 0
