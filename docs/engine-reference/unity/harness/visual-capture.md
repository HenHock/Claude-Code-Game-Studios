# Unity: Observable on demand (harness H7)

Last verified: 2026-10-25 (sources below). Rule: `.claude/docs/agent-harness.md` H7.
The game can produce a capture of a given state on command, with presentation
layers (UI, effects, debug) toggled. A visual check compares the capture against
a stored baseline and yields a number, so the agent does not read two full images.

## Scope

- Applies to **player-observable changes**: what a story makes visible. Pure logic
  changes are checked by state tests (H5), not by capture.
- It binds the story that changes the visuals. Do not add capture hooks to every
  existing screen. A story without a way to reach its visual state directly is
  not done (see `.claude/rules/harness.md` H7).
- This repo also requires a retained screenshot in `production/qa/evidence/` for
  visual and UI stories (`coding-standards.md`). H7 adds the baseline and the
  number.

## Reaching the state

A capture needs a start state the agent can load directly: a saved state file
(`portable-state.md`) plus a command script (`commands.md`). The capture command
then loads the state, applies the commands, runs N fixed steps with the seed set
(`determinism.md`), and captures.

For deterministic frame timing, `Time.captureFramerate` is the reciprocal of
`Time.captureDeltaTime`. Assigning one sets the other. The Unity page says
nothing about screenshots, so how it combines with `CaptureScreenshot` is NOT
SOURCEABLE; verify on the pinned editor.

## Capturing

- `ScreenCapture.CaptureScreenshot(filename, superSize)` saves a `.png`, and
  overwrites an existing file. On non-mobile platforms a relative filename
  resolves against the project folder. A `superSize` above 1 makes a larger
  image. NOT SOURCEABLE: whether it includes UI overlays, and when the file is
  written (the page only says it returns immediately on Android). Check on the
  pinned editor, and wait until the file exists before diffing.
- The Unity Editor MCP tools available in this setup (`capture_game_view`,
  `screenshot`) can also capture the Game view. Their availability depends on
  the machine, so the project's `harness.capture` entry must name the command it
  actually uses.

## Layer toggles

- World layers: `Camera.cullingMask` is a bit mask of layers the camera renders.
  Clearing a bit hides objects on that layer, so put debug markers and effects on
  their own layers and clear them for a clean capture.
- UI and other overlays: toggling Canvas objects is general Unity practice, not
  sourced here. The capture command takes a list of layers to hide and the
  project defines what each one switches off.

## Comparing against a baseline

A baseline is a stored capture of the state, committed or kept with the story's
evidence. It is updated only on purpose (H9), never as a side effect of a run.

Candidate diff tool from the article: **odiff** (MIT licence, native, free).

- CLI: `odiff <image1> <image2> [diff.png]`. Install with `npm install odiff-bin`
  (binary is `odiff`) or from the releases page.
- Result: `match: true`, or `match: false` with `diffCount` and `diffPercentage`
  (share of the whole image). That percentage is the number to report.
- Options: `threshold` (0 to 1 colour tolerance), `ignoreRegions` (rectangles to
  exclude, for example a changing timer), `antialiasing`. Reads PNG, JPEG, WebP
  and TIFF; PNG and JPEG can be compared with each other.
- NOT SOURCEABLE: its exit codes (the page does not document them), and whether
  those options exist as CLI flags (the page lists them for the Node.js API).
  Verify on the installed version before wiring it into `harness.image_diff`.
- The percentage is over the whole image. To see a small change clearly, capture
  only the area of interest (a camera framed on it) or ignore the rest.

## Sources

- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/ScreenCapture.CaptureScreenshot.html
- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Camera-cullingMask.html
- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Time-captureFramerate.html
- https://github.com/dmtrKovalenko/odiff
