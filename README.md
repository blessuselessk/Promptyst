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
| `p-context(id: str, entries: array)` | context dict |
| `p-schema(id: str, fields: array)` | schema dict |
| `p-checkpoint(id: str, after-step: int, assertion: str, on-fail: str)` | checkpoint dict |
| `p-chat-mode(id: str, turns: str, state: str, prompt: dict)` | chat-mode dict |
| `p-prompt(id: str, version: str, role: str, ctx: dict, constraints: array, steps: array, inputs: array, schema: dict, checkpoints?: array)` | prompt dict |

All parameters are **named** (keyword arguments). All constructors return plain Typst dictionaries. No rendering occurs at construction time.

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

## TOML Ingestion

```typst
#let result = from-toml(read("my-prompt.toml"))
#raw(render-prompt(result.prompt), lang: "markdown")
```

`from-toml(raw)` parses a TOML string and returns a dictionary. If all required sections are present, the `prompt` key contains a fully assembled prompt dict. Partial TOML (e.g. only `[context]`) returns only the sections found — no panic for missing sections.

Available keys in the result: `aspect`, `context`, `schema`, `constraints`, `steps`, `inputs`, `checkpoints`, `prompt`, `meta`, `constraints-meta`.

Metadata (`[rationale]`, constraint `severity`) is preserved in the result but never rendered.

See `tests/fixtures/full-prompt.toml` for the full TOML schema.

---

## Shorthand Helpers

Lighter syntax for building prompts in pure Typst. These are `v0` — not under the immutable 10-symbol contract.

| Helper | Equivalent to |
|--------|---------------|
| `entry(key, value)` | `(key: key, value: value)` |
| `field(name, typ, desc)` | `(name: name, type: typ, description: desc)` |
| `ctx(id, ..entries)` | `p-context(id: id, entries: ...)` |
| `schema(id, ..fields)` | `p-schema(id: id, fields: ...)` |
| `checkpoint(id, after-step, assertion, on-fail)` | `p-checkpoint(id: ..., ...)` |

```typst
// Before (core constructors)
#let my-ctx = p-context(
  id: "net-ctx",
  entries: (
    (key: "firewall", value: "443 + 22 open"),
    (key: "gateway",  value: "18789 loopback"),
  ),
)

// After (helpers)
#let my-ctx = ctx("net-ctx",
  entry("firewall", "443 + 22 open"),
  entry("gateway",  "18789 loopback"),
)
```

`ctx` is named `ctx` not `context` — `context` is a Typst keyword.

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
  ctx:         ctx,
  constraints: ("Keep responses under 150 words.",),
  steps:       ("Read the ticket.", "Draft a reply.", "Check tone."),
  inputs:      ((name: "ticket", type: "string", description: "Raw ticket text."),),
  schema:      sch,
)

#raw(render-prompt(my-prompt), lang: "markdown")
```

---

## Markdown Output

`typst compile` produces PDF. To get raw Markdown, add a metadata label to your `.typ` file:

```typst
#let md = render-prompt(my-prompt)
#metadata(md) <output>
```

Then extract with `typst query`:

```bash
typst query --root . my-file.typ "<output>" --field value --one | jq -r . > output.md
```

All files in `examples/` are wired this way. To regenerate all `.md` outputs at once:

```bash
for f in examples/*.typ; do
  typst query --root . "$f" "<output>" --field value --one | jq -r . > "${f%.typ}.md"
done
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
| ctx | context dict | yes |
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

## Context: {ctx.id}

## Constraints

## Steps

## Inputs

## Output Schema: {schema.id}

## Checkpoint: {id}   <- zero or more, sorted (after-step ASC, id ASC)
```

---

## Compile Errors

Every missing required field, out-of-range value, or type mismatch is a compile-time `panic`. There are no warnings, no fallbacks, and no silent defaults.

---

## Layering

```
promptyst (this package)        <- DSL scope only
  -> opinionated layers            <- separate package
  -> vendor adapters               <- separate package
  -> runtime                       <- external, not in scope
```

promptyst has no knowledge of runtimes, vendors, transports, agents, or evaluation pipelines.
