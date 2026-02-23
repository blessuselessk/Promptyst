# promptyst — Export Boundary Contract

This document defines what is public, what is internal, and what
rules apply to consumers building layers on top of this package.

---

## Layer Model

```
┌─────────────────────────────────────┐
│  External runtime                   │  outside this project
└────────────────┬────────────────────┘
                 │ consumes Markdown output
┌────────────────▼────────────────────┐
│  Adapters (separate package)        │  optional
│  e.g. promptyst-openai              │  imports public API only
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│  Opinionated layer (separate pkg)   │  optional
│  e.g. promptyst-patterns            │  imports public API only
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│  promptyst core (this package)      │
│  lib.typ → src/primitives.typ       │
│          → src/render.typ           │
│          → src/validate.typ         │
└─────────────────────────────────────┘
```

Layers may not collapse. Each layer imports only the layer directly
below it, and only through `lib.typ`. No layer may import
`src/validate.typ`, `src/primitives.typ`, or `src/render.typ` directly.

---

## Public API (10 symbols, immutable contract)

These are the only symbols a consumer may import.
The function signatures and return shapes are stable from v0.1.0.

### Constructors

| Symbol | Input | Returns |
|--------|-------|---------|
| `p-context` | `id`, `entries` | context dict |
| `p-schema` | `id`, `fields` | schema dict |
| `p-checkpoint` | `id`, `after-step`, `assertion`, `on-fail` | checkpoint dict |
| `p-chat-mode` | `id`, `turns`, `state`, `prompt` | chat-mode dict |
| `p-prompt` | `id`, `version`, `role`, `context`, `constraints`, `steps`, `inputs`, `schema`, `checkpoints` | prompt dict |

### Renderers

| Symbol | Input | Returns |
|--------|-------|---------|
| `render-context` | context dict | Markdown string |
| `render-schema` | schema dict | Markdown string |
| `render-checkpoint` | checkpoint dict | Markdown string |
| `render-chat-mode` | chat-mode dict | Markdown string |
| `render-prompt` | prompt dict | Markdown string |

---

## Internal Symbols (never import directly)

| Symbol | Location | Reason |
|--------|----------|--------|
| `_require` | `src/validate.typ` | Validation helper, not a public contract |
| `_require-nonempty` | `src/validate.typ` | Validation helper |
| `_enum-check` | `src/validate.typ` | Validation helper |
| `_md-row` | `src/render.typ` | Formatting detail |
| `_md-table` | `src/render.typ` | Formatting detail |
| `_escape-pipes` | `src/render.typ` | Formatting detail |

The `_` prefix is a naming contract. These symbols may change shape,
be renamed, or be removed in any version. No semver protection applies.

---

## Dictionary Shape Contract

Dictionaries returned by constructors carry a `_type` tag.
This tag is used by render functions and validators for type guards.

| `_type` value | Produced by |
|---------------|-------------|
| `"context"` | `p-context` |
| `"schema"` | `p-schema` |
| `"checkpoint"` | `p-checkpoint` |
| `"chat-mode"` | `p-chat-mode` |
| `"prompt"` | `p-prompt` |

Opinionated layers must not create dictionaries with these `_type` tags.
They must not read `_type` to branch on behavior — that is the render
layer's responsibility. If a layer needs to distinguish dict types, it
must use its own tagging convention in a separate namespace.

---

## What Opinionated Layers May Do

- Call all 10 public symbols.
- Wrap constructors with higher-level builder functions that call the
  core constructors internally.
- Wrap render functions to add outer formatting (e.g. a YAML front
  matter block, a document wrapper).
- Define their own dictionary types for their own purposes.
- Define their own validation logic for their own fields.

## What Opinionated Layers Must Not Do

- Import any `src/*.typ` file directly.
- Read or write the `_type` field.
- Mutate a dict returned by a constructor (Typst value semantics
  prevent mutation, but creating a modified copy with `_type` changed
  is also prohibited).
- Add fields to a core dict and pass the modified dict to a render
  function — undefined behavior.
- Redefine or shadow any of the 10 public symbols.

---

## Versioning Rule

The public API (10 symbols, their signatures, and their Markdown output
contract) is stable within a major version. Any change to the Markdown
output format — even whitespace — is a breaking change and requires a
major version bump. The internal symbols carry no versioning guarantee.
