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


/// Build a context entry dictionary.
///
/// - key (str): Entry key.
/// - value (str): Entry value.
/// -> dictionary
#let entry(key, value) = (key: key, value: value)


/// Build a schema field dictionary.
///
/// Named `typ` (not `type`) to avoid shadowing Typst's `type()` builtin.
///
/// - name (str): Field name.
/// - typ (str): Field type (passed through verbatim).
/// - desc (str): Field description.
/// -> dictionary
#let field(name, typ, desc) = (name: name, type: typ, description: desc)


/// Shorthand for `p-context`. Accepts positional entry dicts or tuple pairs.
///
/// ```typst
/// ctx("my-ctx", entry("k", "v"), entry("k2", "v2"))
/// ctx("my-ctx", ("k", "v"), ("k2", "v2"))  // tuple shorthand
/// ```
///
/// - id (str): Context identifier.
/// - ..entries (arguments): Positional `entry()` dicts or `(key, value)` tuples.
/// -> dictionary
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


/// Shorthand for `p-schema`. Accepts positional field dicts.
///
/// ```typst
/// schema("my-schema", field("name", "string", "A description"))
/// ```
///
/// - id (str): Schema identifier.
/// - ..fields (arguments): Positional `field()` dictionaries.
/// -> dictionary
#let schema(id, ..fields) = p-schema(
  id: id,
  fields: fields.pos(),
)


/// Shorthand for `p-checkpoint`. All positional args for conciseness.
///
/// ```typst
/// checkpoint("verify", 2, "Data is valid", "halt")
/// ```
///
/// - id (str): Checkpoint identifier.
/// - after-step (int): Step number (>= 1) after which to evaluate.
/// - assertion (str): Plain-language assertion statement.
/// - on-fail (str): Either `"halt"` or `"continue"`.
/// -> dictionary
#let checkpoint(id, after-step, assertion, on-fail) = p-checkpoint(
  id:         id,
  after-step: after-step,
  assertion:  assertion,
  on-fail:    on-fail,
)
