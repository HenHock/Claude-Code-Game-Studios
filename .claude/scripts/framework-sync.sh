#!/usr/bin/env bash
# framework-sync.sh — bring framework updates from the template repo into a game
# project, without touching the game's own files.
#
# Which paths are the framework's is `.claude/framework-manifest.txt`. This
# script fetches the template, compares those paths with the working tree, and
# with --apply stages the owned ones (git checkout <ref> -- <files>). It never
# commits, never deletes a file, and never touches a `merge` file: those it only
# lists, because they hold your settings too.
#
# Usage: bash .claude/scripts/framework-sync.sh [--remote NAME] [--branch B]
#          [--url URL] [--no-fetch] [--apply] [--root DIR]
#   --remote NAME  the git remote that is the template (default: template)
#   --branch B     its branch (default: unity-engine)
#   --url URL      add the remote with this URL when it does not exist yet
#   --no-fetch     compare against what was fetched last time
#   --apply        stage the owned files that changed upstream (default: only report)
#   --root DIR     the project; defaults to the repo this script is in
#   -h, --help     this text
#
# Output: TSV, one row per path.
#   ref        <remote/branch> <commit>
#   owned      <A|M> <path> <ok|local-edit|dirty|unknown>
#                A = new upstream, M = changed upstream.
#                local-edit: you changed it since the last sync (baseline:
#                  .claude/framework-sync.last); --apply skips it.
#                dirty: uncommitted changes in the working tree; --apply skips it.
#                unknown: no baseline yet (first sync); --apply takes it. It is
#                  staged, not committed, so `git restore --staged --worktree`
#                  undoes it.
#   local-only owned folder, file not in the template (yours); never deleted
#   merge      <M|A|D> <path>   changed upstream; merge by hand
#   applied    <count> files staged
#   skipped    <count> files left alone, with the reason rows above
#
# After --apply: review with `git diff --cached --stat`, then commit. The
# baseline file .claude/framework-sync.last is updated and staged with them.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Exit codes: 0 ran; 1 the root is not a git repo or the fetch failed;
# 2 usage error or no template remote; 3 the manifest is missing.
#
# bash 3.2 and BWK awk safe, no Python. Everything runs inside main, because
# --apply can replace this very file and bash reads a script as it goes.

set -u
LC_ALL=C
export LC_ALL

main() {
  local remote=template branch=unity-engine url="" fetch=1 apply=0 root=""
  local HERE; HERE="$(cd "$(dirname "$0")" && pwd)"
  usage() { echo "framework-sync: $1 (try --help)" >&2; exit 2; }
  while [ $# -gt 0 ]; do
    case "$1" in
      --remote) [ $# -ge 2 ] || usage "--remote needs a name"; remote="$2"; shift 2 ;;
      --branch) [ $# -ge 2 ] || usage "--branch needs a name"; branch="$2"; shift 2 ;;
      --url)    [ $# -ge 2 ] || usage "--url needs a value"; url="$2"; shift 2 ;;
      --no-fetch) fetch=0; shift ;;
      --apply)  apply=1; shift ;;
      --root)   [ $# -ge 2 ] || usage "--root needs a value"; root="$2"; shift 2 ;;
      -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) usage "unknown argument: $1" ;;
    esac
  done
  if [ -n "$root" ]; then cd "$root" 2>/dev/null || { echo "framework-sync: cannot read root $root" >&2; exit 1; }
  else cd "$HERE/../.." 2>/dev/null || { echo "framework-sync: cannot reach the repo root" >&2; exit 1; }; fi
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "framework-sync: not a git repository" >&2; exit 1; }

  local manifest=.claude/framework-manifest.txt
  [ -f "$manifest" ] || { echo "framework-sync: $manifest is missing" >&2; exit 3; }

  if ! git remote | grep -qx "$remote"; then
    if [ -n "$url" ]; then git remote add "$remote" "$url" || exit 1
    else echo "framework-sync: no remote '$remote'; pass --url <template repo>" >&2; exit 2; fi
  fi
  if [ "$fetch" = 1 ]; then
    git fetch --quiet --tags "$remote" "$branch" || { echo "framework-sync: fetch of $remote $branch failed" >&2; exit 1; }
  fi
  local ref="$remote/$branch" sha
  sha=$(git rev-parse --verify --quiet "$ref^{commit}") || { echo "framework-sync: $ref not found; fetch first" >&2; exit 1; }
  printf 'ref\t%s\t%s\n' "$ref" "$sha"

  local last=""; [ -f .claude/framework-sync.last ] && last=$(tr -d ' \r\n' < .claude/framework-sync.last)
  git cat-file -e "$last^{commit}" 2>/dev/null || last=""

  # One diff of the whole tree, classified against the manifest.
  local rows; rows=$(git diff --name-status --no-renames HEAD "$ref" | awk -F'\t' -v MF="$manifest" '
    function rule_of(p,    i, r, best) {
      best = ""
      for (i = 1; i <= n; i++) {
        r = path[i]
        if ((substr(r, length(r)) == "/" && index(p, r) == 1) || p == r) {
          if (kind[i] == "skip") return "skip"
          if (best == "" || kind[i] == "merge") best = kind[i]
        }
      }
      return best
    }
    BEGIN { while ((getline l < MF) > 0) { sub(/\r$/, "", l); if (l ~ /^[[:space:]]*(#|$)/) continue
              split(l, f, /[[:space:]]+/); n++; kind[n] = f[1]; path[n] = f[2] } }
    { k = rule_of($2); if (k == "owned" || k == "merge") print k "\t" $1 "\t" $2 }')

  local napplied=0 nskipped=0 k st p state files=""
  while IFS="$(printf '\t')" read -r k st p; do
    [ -n "$k" ] || continue
    if [ "$k" = merge ]; then printf 'merge\t%s\t%s\n' "$st" "$p"; continue; fi
    if [ "$st" = D ]; then printf 'local-only\t-\t%s\n' "$p"; continue; fi
    state=ok
    if [ -z "$last" ]; then state=unknown
    elif ! git diff --quiet "$last" HEAD -- "$p" 2>/dev/null; then state=local-edit; fi
    if [ -n "$(git status --porcelain -- "$p" 2>/dev/null)" ]; then state=dirty; fi
    printf 'owned\t%s\t%s\t%s\n' "$st" "$p" "$state"
    case "$state" in
      ok|unknown) files="$files$p
" ;;
      *) nskipped=$((nskipped + 1)) ;;
    esac
  done <<EOF
$rows
EOF

  if [ "$apply" = 1 ]; then
    if [ -n "$files" ]; then
      printf '%s' "$files" | git checkout "$ref" --pathspec-from-file=- || { echo "framework-sync: checkout failed" >&2; exit 1; }
      napplied=$(printf '%s' "$files" | grep -c .)
    fi
    printf '%s\n' "$sha" > .claude/framework-sync.last
    git add .claude/framework-sync.last 2>/dev/null
    printf 'applied\t%s\tfiles staged\n' "$napplied"
    printf 'skipped\t%s\tfiles left alone (local-edit or dirty)\n' "$nskipped"
  else
    printf 'applied\t0\tdry run; pass --apply to stage the owned files\n'
  fi
  exit 0
}
main "$@"
exit 0
