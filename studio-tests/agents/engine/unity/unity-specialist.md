# Agent Test Spec: unity-specialist

## Agent Summary
Domain: Unity-specific architecture patterns, MonoBehaviour vs DOTS decisions, and subsystem selection (Addressables, New Input System, UI Toolkit, Cinemachine, etc.).
Does NOT own: language-specific deep dives (delegates to unity-dots-specialist, unity-ui-specialist, etc.).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Unity patterns / MonoBehaviour / subsystem decisions)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition acknowledges the sub-specialist routing table (DOTS, UI, Shader, Addressables)

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Should I use MonoBehaviour or ScriptableObject for storing enemy configuration data?"
**Expected behavior:**
- Produces a pattern decision tree covering:
  - MonoBehaviour: for runtime behavior, needs to be attached to a GameObject, has Update() lifecycle
  - ScriptableObject: for pure data/configuration, exists as an asset, shared across instances, no scene dependency
- Recommends ScriptableObject for enemy configuration data (stateless, reusable, designer-friendly)
- Notes that MonoBehaviour can reference the ScriptableObject for runtime use
- Provides a concrete example of what the ScriptableObject class definition looks like (does not produce full code — refers to engine-programmer or gameplay-programmer for implementation)

### Case 2: Foreign-engine concepts
**Input:** "Set up a Node scene tree with signals for this enemy system."
**Expected behavior:**
- Does NOT produce node-tree or signal code from another engine
- Identifies node trees and signals as another engine's concepts
- Maps the concepts to Unity: node tree → GameObject hierarchy with composed MonoBehaviours; signal → C# event or UnityEvent (consistent with its own rule to use events instead of `SendMessage()` / `Find()`)
- Does not hand the request to a non-Unity specialist — its Agent grant covers only the four Unity sub-specialists

### Case 3: Unity version API flag
**Input:** "Use the new Unity 6 GPU resident drawer for batch rendering."
**Expected behavior:**
- Checks `docs/engine-reference/unity/VERSION.md` and `docs/engine-reference/unity/modules/rendering.md` before answering, not training data (the version file places Unity 6 past the model's knowledge cutoff)
- States what the reference documents: GPU Resident Drawer is a Unity 6+ feature enabled in the URP Asset (Rendering > GPU Resident Drawer), so it requires an SRP project
- Flags the installed-version gap: when `Installed at pin time` in the version file is not determined, asks which editor version is installed before recommending the feature
- Does NOT assume the installed editor is Unity 6 because the reference is pinned to it
- Proposes the URP Asset change and asks before editing it; routes render pipeline customization beyond the setting to `unity-shader-specialist`

### Case 4: DOTS vs. MonoBehaviour conflict
**Input:** "The combat system uses MonoBehaviour for state management, but we want to add a DOTS-based projectile system. Can they coexist?"
**Expected behavior:**
- Recognizes this as a hybrid architecture scenario
- Explains the coexistence mechanism at architecture level, as `docs/engine-reference/unity/plugins/dots-entities.md` documents it: authoring MonoBehaviours baked into entities by a `Baker<T>`, projectile data held in `IComponentData`, processed by an `ISystem`
- Notes the performance and complexity trade-offs of mixing the two patterns
- Recommends escalating the architecture decision to `lead-programmer` or `technical-director`
- Defers to `unity-dots-specialist` for the DOTS-side implementation details

### Case 5: Context pass — Unity version
**Input:** Project context provided: Unity 6.3 LTS, keyboard/mouse and gamepad targets. Request: "Configure the new Input System for this project."
**Expected behavior:**
- Applies the Unity 6.3 LTS context from `docs/engine-reference/unity/modules/input.md`: the Input System package (`com.unity.inputsystem`) with Active Input Handling set to the new system
- Does NOT produce legacy Input Manager code (`Input.GetKeyDown()`, `Input.GetAxis()`) — the engine reference lists these as deprecated
- Defines actions in an `.inputactions` asset, uses the Player Input component or a generated C# class, and prefers action callbacks (`performed`, `canceled`) over polling in `Update()`
- Sets up keyboard+mouse and gamepad control schemes with automatic switching
- Routes UI navigation and input-prompt work to `unity-ui-specialist`
- Treats adding the package as a dependency decision needing `technical-director` sign-off, and asks before writing any settings or asset

---

## Protocol Compliance

- [ ] Stays within declared domain (Unity architecture decisions, pattern selection, subsystem routing)
- [ ] Treats another engine's patterns as foreign: answers with the Unity equivalent, never emits non-Unity code
- [ ] Redirects DOTS implementation to unity-dots-specialist
- [ ] Redirects UI implementation to unity-ui-specialist
- [ ] Checks `docs/engine-reference/unity/` (pinned version and `Installed at pin time`) before suggesting a version-gated API, and confirms the installed version when it is not recorded
- [ ] Returns structured pattern decision guides, not freeform opinions

---

## Coverage Notes
- MonoBehaviour vs. ScriptableObject (Case 1) should be documented as an ADR if it results in a project-level decision
- Version flag (Case 3) confirms the agent checks the pinned and installed Unity version rather than assuming the latest
- DOTS hybrid (Case 4) verifies the agent escalates architecture conflicts rather than resolving them unilaterally
