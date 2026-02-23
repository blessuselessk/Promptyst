# promptyst

A contract-first Typst DSL for structured AI prompts.  
Five primitives. Deterministic Markdown output. No runtime dependencies.

---

## Install

```typst
#import "@preview/promptyst:0.1.0": *
```

---

## Primitives

Exactly five. No others.

| Constructor | Returns |
|-------------|---------|
| `p-context(id, entries)` | context dict |
| `p-schema(id, fields)` | schema dict |
| `p-checkpoint(id, after-step, assertion, on-fail)` | checkpoint dict |
| `p-chat-mode(id, turns, state, prompt)` | chat-mode dict |
| `p-prompt(id, version, role, context, constraints, steps, inputs, schema, checkpoints?)` | prompt dict |

All constructors return plain Typst dictionaries. No rendering occurs at construction time.

---

## Renderers

| Function | Input | Output |
|----------|-------|--------|
| `render-prompt(p)` | prompt dict | full canonical Markdown block |
| `render-context(ctx)` | context dict | Markdown section string |
| `render-schema(s)` | schema dict | Markdown section string |
| `render-checkpoint(cp)` | checkpoint dict | Markdown section string |
| `render-chat-mode(cm)` | chat-mode dict | Markdown section string |

All renderers are pure functions. Same input always produces byte-identical output.

---

## Usage

```typst
#import "@preview/promptyst:0.1.0": *

#let ctx = p-context(
  id: "my-context",
  entries: (
    (key: "domain", value: "Customer support."),
  ),
)

#let sch = p-schema(
  id: "my-schema",
  fields: (
    (name: "response", type: "string", description: "The reply."),
    (name: "tone",     type: "enum(formal|casual)", description: "Detected tone."),
  ),
)

#let my-prompt = p-prompt(
  id:          "reply-to-ticket",
  version:     "1.0.0",
  role:        "You are a customer support agent.",
  context:     ctx,
  constraints: ("Keep responses under 150 words.",),
  steps:       ("Read the ticket.", "Draft a reply.", "Check tone."),
  inputs:      ((name: "ticket", type: "string", description: "Raw ticket text."),),
  schema:      sch,
)

#raw(render-prompt(my-prompt), lang: "markdown")
```

---

## Field Contracts

### p-context
| Field | Type | Required |
|-------|------|----------|
| id | string | yes |
| entries | array of `(key: string, value: string)` | yes, non-empty |

### p-schema
| Field | Type | Required |
|-------|------|----------|
| id | string | yes |
| fields | array of `(name: string, type: string, description: string)` | yes, non-empty |

Type strings are passed through verbatim. Pipe characters are escaped at render time.

### p-checkpoint
| Field | Type | Required |
|-------|------|----------|
| id | string | yes |
| after-step | int >= 1 | yes |
| assertion | string | yes |
| on-fail | `"halt"` \| `"continue"` | yes |

`after-step` must be within the step count of the containing prompt — validated at `p-prompt` construction.

### p-chat-mode
| Field | Type | Required |
|-------|------|----------|
| id | string | yes |
| turns | `"single"` \| `"multi"` | yes |
| state | `"stateless"` \| `"stateful"` | yes |
| prompt | prompt dictionary | yes |

Carries no runtime semantics. Structural declaration only.

### p-prompt
| Field | Type | Required |
|-------|------|----------|
| id | string | yes |
| version | string | yes |
| role | string | yes |
| context | context dict | yes |
| constraints | array of string | yes, non-empty |
| steps | array of string | yes, non-empty |
| inputs | array of `(name, type, description)` | yes, non-empty |
| schema | schema dict | yes |
| checkpoints | array of checkpoint dicts | no, defaults to `()` |

Checkpoints are sorted at construction by `(after-step ASC, id ASC)`. Declaration order is discarded.

---

## Canonical Prompt Output Order

```
# Prompt: {id}
**Version:** {version}

## Role

## Context: {context.id}

## Constraints

## Steps

## Inputs

## Output Schema: {schema.id}

## Checkpoint: {id}   ← zero or more, sorted (after-step ASC, id ASC)
```

---

## Compile Errors

Every missing required field, out-of-range value, or type mismatch is a compile-time `panic`. There are no warnings, no fallbacks, and no silent defaults.

---

## Layering

```
promptyst (this package)        ← DSL scope only
→ opinionated layers            ← separate package
→ vendor adapters               ← separate package
→ runtime                       ← external, not in scope
```

promptyst has no knowledge of runtimes, vendors, transports, agents, or evaluation pipelines.
