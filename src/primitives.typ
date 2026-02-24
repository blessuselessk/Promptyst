// src/primitives.typ
// The five core primitives. Each returns a plain dictionary.
// No rendering occurs here. Rendering is owned by src/render.typ.
//
// Internal dictionary shape contract:
//   Every dict carries a _type key. This is an INTERNAL tag used by
//   primitives and renderers to guard against wrong-type arguments.
//   _type is NOT part of the public API. Consumers must not read or
//   branch on it. Its values and presence may change in patch releases.

#import "validate.typ": _require, _require-nonempty, _enum-check


// ─────────────────────────────────────────────
// p-context
//
// id:      string — unique identifier
// entries: array of (key: string, value: string) — ordered, non-empty
// ─────────────────────────────────────────────

#let p-context(id: none, entries: none) = {
  let id      = _require(id, "context.id")
  let entries = _require-nonempty(entries, "context.entries")
  for e in entries {
    let _ = _require(e.at("key",   default: none), "context.entries[].key")
    let _ = _require(e.at("value", default: none), "context.entries[].value")
  }
  (_type: "context", id: id, entries: entries)
}


// ─────────────────────────────────────────────
// p-schema
//
// id:     string — unique identifier
// fields: array of (name: string, type: string, description: string) — non-empty
//         type strings are passed through verbatim. Pipes are escaped at render time.
// ─────────────────────────────────────────────

#let p-schema(id: none, fields: none) = {
  let id     = _require(id, "schema.id")
  let fields = _require-nonempty(fields, "schema.fields")
  for f in fields {
    let _ = _require(f.at("name",        default: none), "schema.fields[].name")
    let _ = _require(f.at("type",        default: none), "schema.fields[].type")
    let _ = _require(f.at("description", default: none), "schema.fields[].description")
  }
  (_type: "schema", id: id, fields: fields)
}


// ─────────────────────────────────────────────
// p-checkpoint
//
// id:         string — unique identifier
// after-step: int >= 1 — must be within the step count of the containing prompt
//             (enforced at p-prompt construction, not here)
// assertion:  string — plain-language statement; not evaluated by the DSL
// on-fail:    "halt" | "continue"
// ─────────────────────────────────────────────

#let p-checkpoint(
  id:         none,
  after-step: none,
  assertion:  none,
  on-fail:    none,
) = {
  let id         = _require(id,         "checkpoint.id")
  let after-step = _require(after-step, "checkpoint.after-step")
  let assertion  = _require(assertion,  "checkpoint.assertion")
  let on-fail    = _enum-check(
    _require(on-fail, "checkpoint.on-fail"),
    ("halt", "continue"),
    "checkpoint.on-fail"
  )
  if type(after-step) != int or after-step < 1 {
    panic("promptyst: checkpoint.after-step must be a positive integer.")
  }
  (
    _type:      "checkpoint",
    id:         id,
    after-step: after-step,
    assertion:  assertion,
    on-fail:    on-fail,
  )
}


// ─────────────────────────────────────────────
// p-chat-mode
//
// id:     string — unique identifier
// turns:  "single" | "multi"
// state:  "stateless" | "stateful"
// prompt: prompt dictionary — only prompt.id is retained in the output dict.
//         The full prompt block does not expand inside chat-mode.
//         This is a structural declaration only; carries no runtime semantics.
// ─────────────────────────────────────────────

#let p-chat-mode(
  id:     none,
  turns:  none,
  state:  none,
  prompt: none,
) = {
  let id    = _require(id, "chat-mode.id")
  let turns = _enum-check(
    _require(turns, "chat-mode.turns"),
    ("single", "multi"),
    "chat-mode.turns"
  )
  let state = _enum-check(
    _require(state, "chat-mode.state"),
    ("stateless", "stateful"),
    "chat-mode.state"
  )
  let p = _require(prompt, "chat-mode.prompt")
  if p.at("_type", default: none) != "prompt" {
    panic("promptyst: chat-mode.prompt must be a prompt dictionary.")
  }
  (
    _type:     "chat-mode",
    id:        id,
    turns:     turns,
    state:     state,
    prompt-id: p.id,
  )
}


// ─────────────────────────────────────────────
// p-prompt
//
// id:          string — unique identifier
// version:     string — semver recommended, not enforced
// role:        string — system role declaration
// ctx:         context dictionary
// constraints: array of string — non-empty, rendered as ordered list
// steps:       array of string — non-empty, rendered as ordered list, order preserved
// inputs:      array of (name: string, type: string, description: string) — non-empty
// schema:      schema dictionary
// checkpoints: array of checkpoint dictionaries — optional, defaults to ()
//              Stored sorted by (after-step ASC, id ASC). Declaration order discarded.
//              Boundary rule: after-step must be <= steps.len()
// ─────────────────────────────────────────────

#let p-prompt(
  id:          none,
  version:     none,
  role:        none,
  ctx:         none,
  constraints: none,
  steps:       none,
  inputs:      none,
  schema:      none,
  checkpoints: (),
) = {
  let id          = _require(id,          "prompt.id")
  let version     = _require(version,     "prompt.version")
  let role        = _require(role,        "prompt.role")
  let ctx         = _require(ctx,         "prompt.ctx")
  let constraints = _require-nonempty(constraints, "prompt.constraints")
  let steps       = _require-nonempty(steps,        "prompt.steps")
  let inputs      = _require-nonempty(inputs,       "prompt.inputs")
  let sch         = _require(schema,      "prompt.schema")

  if ctx.at("_type", default: none) != "context" {
    panic("promptyst: prompt.context must be a context dictionary.")
  }
  if sch.at("_type", default: none) != "schema" {
    panic("promptyst: prompt.schema must be a schema dictionary.")
  }
  for inp in inputs {
    let _ = _require(inp.at("name",        default: none), "prompt.inputs[].name")
    let _ = _require(inp.at("type",        default: none), "prompt.inputs[].type")
    let _ = _require(inp.at("description", default: none), "prompt.inputs[].description")
  }

  let step-count = steps.len()
  for cp in checkpoints {
    if cp.at("_type", default: none) != "checkpoint" {
      panic("promptyst: prompt.checkpoints must contain checkpoint dictionaries.")
    }
    if cp.after-step > step-count {
      panic(
        "promptyst: checkpoint '" + cp.id + "' references after-step " +
        str(cp.after-step) + " but prompt only has " + str(step-count) + " steps."
      )
    }
  }

  // Sort: id ascending first (tiebreaker), then after-step ascending (primary).
  // Two-pass required — Typst's .sorted() is not guaranteed stable.
  // Result: deterministic order regardless of declaration sequence.
  let sorted-checkpoints = checkpoints.sorted(key: cp => cp.id)
  let sorted-checkpoints = sorted-checkpoints.sorted(key: cp => cp.after-step)

  (
    _type:       "prompt",
    id:          id,
    version:     version,
    role:        role,
    "context":     ctx,
    constraints: constraints,
    steps:       steps,
    inputs:      inputs,
    schema:      sch,
    checkpoints: sorted-checkpoints,
  )
}
