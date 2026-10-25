# Unity: Uniform entity model (harness H6)

Last verified: 2026-10-25 (sources below). Rule: `.claude/docs/agent-harness.md` H6.
Prefer one flat entity shape (data, a type tag, and composition) over deep
inheritance trees. A deviation needs an ADR. The reason is serialization: flat
data saves, loads and diffs trivially (H2, H3), and leaves nothing for the agent
to infer from a class hierarchy.

## Scope

- Applies to **simulation entities**: the things the rules layer creates, saves
  and sends commands to (units, items, buildings, projectiles). It does not apply
  to Unity's own scene objects. `GameObject` plus components is already
  composition, and views may use it freely.
- Applies when the project has such entities. It binds entity types a change adds
  or touches. Do not flatten existing hierarchies to satisfy H6.
- The trigger for an ADR is a **new inheritance level** for entities, not every
  use of `abstract` or an interface.

## Shape

- One entity record: `id`, `type` (a string tag), and a set of components. A
  component is a small plain-data struct or class (health, position, inventory).
  Behaviors differ by which components an entity has and by the rules that read
  them, not by subclass.
- Different kinds of entity are different data, not different classes: an "orc"
  and a "goblin" are two entries with the same shape and different values (see
  `data-tuning.md`).
- Entities refer to each other by `id`, never by object reference, so the state
  file stays flat (see `portable-state.md`).

## Serialization of variants

When components or entity kinds vary, the file needs a way to say which kind it
holds. Use an explicit type tag field that the project owns and maps to a C#
type in one place. That keeps the file readable and stable when classes are
renamed.

Newtonsoft's `TypeNameHandling` can write .NET type names into JSON and use them
to create the right type on load. The Newtonsoft documentation page states that
it must be specified on deserialization "for security". It does not explain the
risk. NOT SOURCEABLE here: its exact security guidance. Do not enable it on
files from outside the project (downloads, user-edited saves, mods) without
checking the Json.NET docs first. An explicit tag mapped by the project avoids
the question.

## Sources

- https://www.newtonsoft.com/json/help/html/SerializeTypeNameHandling.htm
