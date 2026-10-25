# Unity: Determinism (harness H1)

Last verified: 2026-10-24 (sources below). Rule: `.claude/docs/agent-harness.md` H1.
Randomness is set up in one place and reproducible on demand: every random
source is seeded from one configuration point, the run records its seed, and
simulation logic does not read the wall clock.

## One seed, one setup point

- `Random.InitState(seed)` seeds the built-in `UnityEngine.Random`. Call it at the
  single setup point (launch argument, config value or test setup).
- Unity otherwise seeds it from the OS at startup, so every run differs.
- The seed cannot be read back from the generator. The setup point must **log the
  seed** it used so the run can be repeated.
- `Random.state` gets and sets the full generator state. Useful for H2: save it
  with the game state and restore it on load.
- Other generators (`System.Random`, `Unity.Mathematics.Random`, ...) are fine.
  Construct each from the same run seed, e.g. one derived seed per system
  (`hash(runSeed, "combat")`), so one seed still reproduces everything.

## Time

- `Time.captureDeltaTime` makes `Time.time` advance by a fixed interval regardless
  of real time. Use it for capture and replay runs. It does not affect
  `Time.unscaledTime`.
- Simulation logic receives time as a step parameter. It does not read
  `DateTime.Now`, `Time.realtimeSinceStartup` or `Stopwatch`.

## Scope: only randomness that affects logic and behavior

H1 covers anything that changes **simulation outcomes**: gameplay rolls, AI
choices, spawn order, ids, physics that gameplay depends on. It does not cover
presentation-only randomness (particles, VFX jitter, camera shake, audio
variation). Those differ between runs without breaking reproduction, so do not
control them.

H1 applies only where the project actually has such logic. A project, or a part
of it, with no simulation randomness has nothing to enforce. Do not rewrite
existing code to satisfy H1, and do not fail a review for pre-existing code the
change did not touch.

## Physics: only when it drives gameplay

Ignore physics determinism unless gameplay outcomes depend on physics.

- **Project uses ECS/DOTS** (the user said so, or `unity-dots-specialist` is in
  play): use Unity Physics (or Havok Physics), which are designed to be
  deterministic. Conditions: bodies created in the same order every run, a fixed
  step, no floating-point results fed in as inputs. Unity states results can
  still differ across CPU architectures (x86 vs ARM), so test on each target
  architecture before promising cross-platform replay.
- **Project does not use ECS**: do not chase physics determinism. Built-in PhysX
  is not guaranteed deterministic even with a fixed step. If a project needs
  reproducible physics anyway, treat that as a design decision for an ADR, not
  a default.
- Either way: keep `FixedUpdate` on a constant `Time.fixedDeltaTime` and never
  step physics with frame-dependent `Time.deltaTime`.
- No 3D "Enhanced Determinism" setting exists in the Unity 6 docs. The 6.3
  "enhanced determinism" wording refers to the new Box2D v3 low-level 2D physics API.

## Hidden randomness checklist (simulation logic only)

- `Dictionary` / `HashSet` iteration order: do not let it decide simulation
  outcomes (for example which entity acts first); sort or use ordered lists.
- `FindObjectsByType` with `FindObjectsSortMode.None`: the docs say only that
  not sorting saves time and do not define an order. Do not rely on it; sort the
  result by a stable key.
- `DateTime.Now`, `Time.realtimeSinceStartup`, `Stopwatch` in game logic.
- `Guid.NewGuid()` in simulation state: derive ids from the seeded generator or a counter.

Removed: `ParticleSystem` seeds (`useAutoRandomSeed`). Particles carry no logic or
behavior here, so they are out of scope.

## Sources

- https://docs.unity3d.com/ScriptReference/Random.InitState.html
- https://docs.unity3d.com/ScriptReference/Random-state.html
- https://docs.unity3d.com/6000.2/Documentation/Manual/class-random.html
- https://docs.unity3d.com/ScriptReference/Time-captureDeltaTime.html
- https://docs.unity3d.com/ScriptReference/Physics.Simulate.html
- https://docs.unity3d.com/6000.5/Documentation/Manual/physics-optimization-cpu-manual-simulation.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/class-PhysicsManager.html
- https://docs.unity3d.com/6000.6/Documentation/Manual/WhatsNewUnity63.html
- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Object.FindObjectsByType.html
- https://unity.com/solutions/programming-physics (Unity Physics / Havok deterministic, CPU-architecture caveat; older page, re-check against current Burst notes)
- https://github.com/Kimbatt/unity-deterministic-physics (community conditions for deterministic ECS physics)
