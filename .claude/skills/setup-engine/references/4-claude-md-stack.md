# /setup-engine — Section 4: Update CLAUDE.md Technology Stack

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Update CLAUDE.md Technology Stack

Read `CLAUDE.md` and show the user the proposed Technology Stack changes.
Ask: "May I write these engine settings to `CLAUDE.md`?"

Wait for confirmation before making any edits.

Update the Technology Stack section, replacing the placeholders with the actual values:

```markdown
- **Engine**: Unity [version]
- **Language**: C#
- **Build System**: Unity Build Pipeline
- **Asset Pipeline**: Unity Asset Import Pipeline + Addressables
```

### Engine reference import

In the same CLAUDE.md write, set the **Engine Version Reference** import to the
Unity reference. Find the line marked `ENGINE-REFERENCE-IMPORT` (an
`@docs/engine-reference/unity/VERSION.md` line under its comment) and confirm it
points at `@docs/engine-reference/unity/VERSION.md`; Edit it if it does not. The
operation is idempotent. (The target `docs/engine-reference/unity/` directory is
created in Section 7, Populate Engine Reference Docs, if it does not yet exist.)

---
