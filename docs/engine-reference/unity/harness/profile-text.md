# Unity: Measurable as text (harness H8)

Last verified: 2026-10-25 (sources below). Rule: `.claude/docs/agent-harness.md` H8.
Performance and memory data can be exported in a text form an agent can read and
compare between runs, so the agent checks the cost of its own change against the
budget.

## Scope

- Applies to **performance and memory claims**: a story that says it is faster,
  stays within a frame or memory budget, or removes an allocation cites a text
  profile export from before and after.
- A change that makes no performance claim and touches no hot path needs no
  profile. Do not profile every story.
- Budgets come from the project's performance settings (`project.yaml`) and
  `.claude/docs/technical-preferences.md`; this doc does not set numbers.

## The simplest route: read counters into a text file

`Unity.Profiling.ProfilerRecorder` reads data from Profiler markers and counters.
`ProfilerRecorder.StartNew(ProfilerCategory.Memory, "GC Reserved Memory")` creates
and starts one, `LastValue` returns the value from the end of the last frame,
`CurrentValue` the value at the moment of reading, and `Dispose` frees it. The
Unity page says the API works "in Editor and Player builds, including Release
Players".

So a small capture routine can run the verification loop (load state, apply
commands, step N fixed steps), read the chosen counters and marker timings every
frame, and write one line per metric (name, min, mean, max, sample count) to a
text file. Two such files from two runs diff with ordinary text tools. The
project chooses the metrics (frame time, GC allocation, a named marker for the
system under test) and records them in the story's Harness block.

The counter and marker names are not listed in the page used here. NOT
SOURCEABLE: the exact names available on the pinned editor. List them with the
Profiler or check the counters reference before hard-coding.

## Other Unity routes

| Route | Facts | Limit for agents |
|---|---|---|
| Profiler command line | `-profiler-enable` starts profiling at startup. `-profiler-log-file <path.raw>` streams profile data to a `.raw` file, in players and the Editor. `-profiler-capture-frame-count <n>` sets how many frames are captured, players only. `-profiler-maxusedmemory` caps Profiler memory (defaults 16MB player, 256MB Editor). | The `.raw` file is binary, not text. See "Turning a `.raw` file into text" below. A forum report from an old 2020.3 Editor says these flags crashed the Editor; a single report, not an official issue. |
| Profile Analyzer package (1.4 docs) | Aggregates and compares captures. Exports four `;`-separated CSV files: marker table, single frame times (frame index, ms, GC bytes), and two comparison files. GC columns are `0` if the capture lacks the `GC.Alloc` marker. | Export is described as done from the Profile Analyzer window. No command-line or scripting export is documented. NOT SOURCEABLE: whether it can be driven in batch mode. |
| `Profiler.enableBinaryLog` / `Profiler.logFile` | Scripting equivalents of the log-file flag; also set `Profiler.enabled` to true. | Binary output, as above. |
| Unity AI Assistant (Profiler integration) | Analyzes a capture you recorded, from the Profiler window ("Ask Assistant"). | GUI workflow, not a command line. A forum post says it first shipped in 6.5, with a 6.3/6.4 back-port in progress; unverified for the pinned 6.3. |

## Turning a `.raw` file into text

No public API reads a `.raw` stream as is; a Unity staff reply says the only
route is the **undocumented `ProfilerDriver` API**, which loads a `.raw` or
`.data` file inside the **Editor**. It is Editor-only, so a device build captures
and the Editor converts. Expect it to change between Unity versions. The pattern:

1. In an Editor script, `ProfilerDriver.LoadProfile` loads the file.
2. For each frame and thread, `ProfilerDriver.GetRawFrameDataView(frameIndex,
   threadIndex)` gives a `RawFrameDataView` (namespace `UnityEditor.Profiling`).
   Check both `!= null` and `.valid`, or it throws.
3. Read samples with `sampleCount`, `GetSampleName`, `GetSampleTimeMs`,
   `GetSampleMetadataAsLong` (the docs' example sums GC.Alloc sizes), and write
   them as CSV or text.
4. Run it headless with the Editor in batch mode, so no one opens a window:
   `-batchMode -projectPath <p> -logFile <log> -executeMethod <Class.Method>`.
   The batch-mode command shape comes from the ProfilerReader project below;
   this pattern for a custom script is NOT verified here.

Simpler per-frame metrics, from the same forum answer (names to verify on the
pinned editor): `FrameDataView.frameTimeNs` for frame time, counters
`"CPU Main Thread Active Time"` and `"CPU Render Thread Active Time"` (category
Scripts, take the larger per frame), `"GPU Frame Time"` (category Render).

**Ready-made converters (community, not Unity):**

- **ProfilerReader** (`unity3d-jp/ProfilerReader`): reads `.data`/`.raw` and writes
  CSV files per frame and category (main thread, GC.Alloc list and call stacks,
  memory, rendering, GPU, worker threads). Batch command from its README:
  `Unity.exe -batchMode -projectPath <p> -logFile .\Editor.log -executeMethod
  UTJ.ProfilerReader.CUIInterface.ProfilerToCsv -PH.inputFile <file.raw>
  -PH.timeout 2400 -PH.log`. **Its listed Unity versions end at 2022.3**
  (2019.4 to 2022.3, 2022.1 skipped); the pinned 6.3 is not listed, so test
  before relying on it. Its licence text was not visible to me; check
  `LICENSE.md`. Column layouts are not documented; read a generated file.
- **steve3003/unity-profiler-data-exporter** and **liushengliuyun/ProfilerCsvExporter**
  export from the Profiler window in the Editor; found in search results only and
  not examined. They need the GUI.

## Recommendation for this framework

Prefer the first route, `ProfilerRecorder` into a text file from inside the
game: it is documented, works in release players, needs no Editor and no
converter. Use a `.raw` conversion only when a call-tree or per-sample view is
needed (for example finding which function allocates), and then write a small
`ProfilerDriver`-based Editor exporter for the pinned version or test
ProfilerReader first. Record the chosen route in `harness.profile_text`; if none
is tested on the pinned editor, the capability is NOT CONFIGURED.

## About samply (from the article)

samply is a free profiler (Apache-2.0 or MIT) for native processes on macOS,
Linux and Windows. Its page mentions Rust and C++ and says nothing about managed
.NET or Unity code. It opens recordings in profiler.firefox.com, and the page
does not mention plain-text output. It is therefore not a fit for C# gameplay
code by itself. It might help for native plugins; unverified. Do not list it as
`harness.profile_text` for a Unity project without testing it.

## Comparing runs

A baseline profile is stored like a visual baseline (see `visual-capture.md`):
updated only on purpose (H9). The report quotes before and after for each metric
and the budget it is held against. Runs differ with hardware and background load,
so compare on the same machine and report the sample count; a small difference
inside the run-to-run spread is not a result.

## Sources

- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Unity.Profiling.ProfilerRecorder.html
- https://docs.unity3d.com/Manual/profiler-command-line-arguments.html
- https://docs.unity3d.com/Packages/com.unity.performance.profile-analyzer@1.2/manual/index.html
- https://github.com/mstange/samply
- https://docs.unity3d.com/ScriptReference/Profiling.RawFrameDataView.html
- https://docs.unity3d.com/Packages/com.unity.performance.profile-analyzer@1.4/manual/export-data-reference.html
- https://discussions.unity.com/t/how-to-use-profilerdriver-to-read-from-raw-data-i-recorded-from-profiler-logfile/1623915 (Unity staff reply; thread tagged 2021.3)
- https://github.com/unity3d-jp/ProfilerReader
