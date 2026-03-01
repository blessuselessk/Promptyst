// src/helpers.typ
// Shorthand helpers for building prompts in pure Typst (Phase 2).
//
// Ships in-tree alongside core modules. Imports from sibling primitives.typ
// to avoid cyclic imports (lib.typ re-exports these helpers).
// If extracted to a separate package, would import from lib.typ per Boundary.md.
//
// Public symbols: ctx, schema, field, entry, checkpoint
//
// Named `ctx` not `context` — `context` is a Typst keyword and
// shadowing it risks breakage.

#import "primitives.typ": p-context, p-schema, p-checkpoint


// ─────────────────────────────────────────────
// entry(key, value)
// Convenience for building context entry dicts.
// ─────────────────────────────────────────────

#let entry(key, value) = (key: key, value: value)


// ─────────────────────────────────────────────
// field(name, typ, desc)
// Convenience for building schema field dicts.
// Named `typ` not `type` — avoids shadowing Typst's type() builtin.
// ─────────────────────────────────────────────

#let field(name, typ, desc) = (name: name, type: typ, description: desc)


// ─────────────────────────────────────────────
// ctx(id, ..pairs)
// Shorthand for p-context. Accepts positional entry dicts.
//
//   ctx("my-ctx", entry("k", "v"), entry("k2", "v2"))
//
// Or with inline tuples:
//   ctx("my-ctx", ("k", "v"), ("k2", "v2"))
// ─────────────────────────────────────────────

#let ctx(id, ..entries) = {
  let parsed = entries.pos().map(e => {
    if type(e) == array {
      // Tuple shorthand: ("key", "value")
      (key: e.at(0), value: e.at(1))
    } else {
      // Already a dict from entry()
      e
    }
  })
  p-context(id: id, entries: parsed)
}


// ─────────────────────────────────────────────
// schema(id, ..fields)
// Shorthand for p-schema. Accepts positional field dicts.
//
//   schema("my-schema", field("name", "string", "desc"))
// ─────────────────────────────────────────────

#let schema(id, ..fields) = p-schema(
  id: id,
  fields: fields.pos(),
)


// ─────────────────────────────────────────────
// checkpoint(id, after-step, assertion, on-fail)
// Shorthand for p-checkpoint. Positional args for conciseness.
//
//   checkpoint("verify", 2, "Data is valid", "halt")
// ─────────────────────────────────────────────

#let checkpoint(id, after-step, assertion, on-fail) = p-checkpoint(
  id:         id,
  after-step: after-step,
  assertion:  assertion,
  on-fail:    on-fail,
)
