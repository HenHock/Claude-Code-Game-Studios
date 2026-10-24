# /setup-engine — Section 2: Guided Mode

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Guided Mode (No Arguments)

**In this file:**

- Check for existing game concept
- Gather version-relevant context
- Produce a version recommendation

The engine is fixed: this framework is Unity-only (C#, Unity Test Framework).
What is open at first init is the **Unity version** (none is pinned in the
template), plus any Unity-specific choices that follow from the game: render
pipeline, UI stack, input system. Run this guided mode when no version was given.

### Check for existing game concept
Read the design artifact for the resolved tier (see **Tier awareness** above), by
section: find the headings you need with the Grep tool (pattern `^#`, content
mode) and Read those ranges with offset and limit:
- **`standard` / `full`**: read `design/gdd/game-concept.md` if it exists —
  extract genre, scope, platform targets, art style, and team size.
- **`minimal`**: read `design/game-brief.md` if it exists — extract genre,
  scope, platform, and art direction from its fields. Its absence is **expected**
  at `minimal` (the brief is authored *after* engine setup in the minimal path), so
  do not treat a missing brief as a gap — proceed straight to the questions.
- If no concept **or** brief exists, inform the user:
  > "No game concept found. Consider running `/brainstorm` first to discover what
  > you want to build. Or tell me about your game and I can help you choose a
  > Unity version and render pipeline."

  (At `minimal` this is optional, not a prerequisite — you can pin the version now
  and write the brief next.)

### Gather version-relevant context

**Question 1 — Installed editor** (ask first, via `AskUserQuestion`):
- Prompt: "Which Unity editor version do you have installed or plan to use?"
- Options: `Latest Unity 6 release` / `A specific version (I'll type it)` / `Not installed yet — recommend one`
- If they name a version → use it; Section 3 verifies it against the machine.

**Question 2 — Target platform** (via `AskUserQuestion`; platform constrains the version and render pipeline):
- Prompt: "What platforms are you targeting for this game?"
- Options: `PC (Steam / Epic)` / `Mobile (iOS / Android)` / `Console` / `Web / Browser` / `Multiple platforms`
- Feeds the recommendation: Mobile → URP; Web → check WebGL / WebGPU support in the chosen version; Console → check the platform module is available for that version.

**Question 3 — Game profile** (only if no concept or brief answered it):
1. 2D, 3D, or both?
2. Primary input method? (keyboard/mouse, gamepad, touch, or mixed — informs Input System setup)
3. Team size and experience?

### Produce a recommendation

Reason through the user's profile and present one recommended Unity version
(normally the latest LTS / Unity 6 release line available) with the honest
tradeoffs:

- **LTS release** — long support window, stable API; the default for a project that will ship.
- **Newest non-LTS / tech stream** — newest features, shorter support; only if the game needs a specific new feature.
- **Render pipeline** — URP for most 2D/3D, mobile, and web projects; HDRP for high-end PC/console visuals; Built-in is legacy.
- **UI stack** — UI Toolkit for new runtime UI where the version supports it; UGUI for existing workflows and world-space UI.

**Recommendation format:**
1. Give the primary recommendation with honest reasoning, plus the render pipeline and UI stack that fit the game.
2. Name the best alternative and when to choose it instead.
3. Use `AskUserQuestion` to confirm: "Does this recommendation feel right?"
   - Options: `[Primary version] (Recommended)` / `[Alternative version]` / `Explore further` / `Type something`

**If the user picks "Explore further":**
Use `AskUserQuestion` with concept-specific deep-dive topics generated from the user's actual concept — not generic options. Cover at minimum the primary version's limitations for this concept, the alternative's tradeoffs, and any concept-specific technical concern (e.g., open-world streaming, multiplayer netcode, adaptive audio). Answer each selected topic in depth before returning to the confirmation question.

---
