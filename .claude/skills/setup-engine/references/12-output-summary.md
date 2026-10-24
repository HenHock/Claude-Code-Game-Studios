# /setup-engine — Section 12: Output Summary

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 12. Output Summary

After setup is complete, output:

```
Engine Setup Complete
=====================
Engine:          Unity [version]
Language:        C#
Knowledge Risk:  [LOW/MEDIUM/HIGH]
Reference Docs:  [created/skipped]
CLAUDE.md:       [updated]
Tech Prefs:      [created/updated]
project.yaml:    [created/updated]
Asset loading:   [addressables/resources/direct]
Folder layout:   [created/already present/skipped - no Unity project yet]
                 (Assets/Content, Scripts/Core|Debugging|Testing|Editor,
                 Plugins, Settings, Configs; see .claude/docs/unity-folder-structure.md)
Assemblies:      [<Project>.Core, .Debugging, .Editor created/skipped]
Agent Config:    [verified]

Next Steps:
1. Review docs/engine-reference/unity/VERSION.md
   (Test assemblies come from /test-setup)
```

Then print **one** Next-Steps list, matching the resolved `workflow` tier:

**`minimal` — the lean 4-step floor (you are on step 1):**
```
2. Run /brainstorm to produce your one-page design/game-brief.md (the lean-tier design artifact)
3. Run /create-stories to turn the brief's MVP list into stories
4. Run /dev-story — first line of game code
```
(No `/map-systems`, `/design-system`, `/prototype`, or `/sprint-plan` at
`minimal` — the brief replaces the GDDs and its build order is the plan.)

**`standard` / `full` — the full pipeline:**
```
2. [If from /brainstorm] Run /map-systems to decompose your concept into individual systems
3. [If from /brainstorm] Run /design-system to author per-system GDDs (guided, section-by-section)
4. [If from /brainstorm] Run /prototype [core-mechanic] to validate the core idea before writing GDDs
5. [If fresh start] Run /brainstorm to discover your game concept
6. Create your first milestone: /sprint-plan new
```

---

Verdict: **COMPLETE** — engine configured and reference docs populated.
