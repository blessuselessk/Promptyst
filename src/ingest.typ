// src/ingest.typ
// TOML ingestion layer. Parses TOML strings into core constructor dicts.
//
// Public symbol: from-toml(raw)
//
// This is a core module — it imports sibling src/primitives.typ directly
// (same layer as render.typ and validate.typ). It calls constructors to
// ensure all validation fires on the parsed data.
//
// Partial TOML: missing sections produce missing keys in the result dict.
// Full assembly: when all required sections are present, builds a prompt
// via p-prompt(). Metadata ([rationale], constraint severity) is preserved
// in the result but never rendered.

#import "primitives.typ": p-context, p-schema, p-checkpoint, p-prompt


// ─────────────────────────────────────────────
// from-toml
//
// raw: string — TOML-encoded prompt data
//
// Returns a dictionary with optional keys:
//   context, schema, constraints, steps, inputs, checkpoints,
//   aspect, prompt, meta, constraints-meta
//
// Missing TOML sections → absent keys (no panic).
// Present sections with invalid data → panic via constructor validation.
// ─────────────────────────────────────────────

#let from-toml(raw) = {
  let data = toml(bytes(raw))
  let result = (:)

  // ── aspect metadata ──
  let aspect-data = data.at("aspect", default: none)
  if aspect-data != none {
    result.insert("aspect", aspect-data)
  }

  // ── context ──
  let ctx-data = data.at("context", default: none)
  if ctx-data != none {
    let ctx = p-context(
      id: ctx-data.at("id"),
      entries: ctx-data.at("entries"),
    )
    result.insert("context", ctx)
  }

  // ── schema ──
  let schema-data = data.at("schema", default: none)
  if schema-data != none {
    let sch = p-schema(
      id: schema-data.at("id"),
      fields: schema-data.at("fields"),
    )
    result.insert("schema", sch)
  }

  // ── constraints (extract text, preserve severity as metadata) ──
  let constraints-data = data.at("constraints", default: none)
  if constraints-data != none {
    let constraint-texts = constraints-data.map(c => c.at("text"))
    result.insert("constraints", constraint-texts)

    // Preserve per-constraint metadata (severity, etc.)
    let has-meta = constraints-data.any(c => c.keys().len() > 1)
    if has-meta {
      let meta-list = constraints-data.map(c => {
        let m = (:)
        for key in c.keys() {
          if key != "text" {
            m.insert(key, c.at(key))
          }
        }
        m
      })
      result.insert("constraints-meta", meta-list)
    }
  }

  // ── steps (extract text) ──
  let steps-data = data.at("steps", default: none)
  if steps-data != none {
    let step-texts = steps-data.map(s => s.at("text"))
    result.insert("steps", step-texts)
  }

  // ── inputs ──
  let inputs-data = data.at("inputs", default: none)
  if inputs-data != none {
    result.insert("inputs", inputs-data)
  }

  // ── checkpoints ──
  let checkpoints-data = data.at("checkpoints", default: none)
  if checkpoints-data != none {
    let cps = checkpoints-data.map(c => p-checkpoint(
      id:         c.at("id"),
      after-step: c.at("after-step"),
      assertion:  c.at("assertion"),
      on-fail:    c.at("on-fail"),
    ))
    result.insert("checkpoints", cps)
  }

  // ── rationale (metadata, not rendered) ──
  let rationale-data = data.at("rationale", default: none)
  if rationale-data != none {
    let meta = result.at("meta", default: (:))
    meta.insert("rationale", rationale-data)
    result.insert("meta", meta)
  }

  // ── full prompt assembly ──
  // Only when all required sections are present.
  let has-aspect      = result.at("aspect", default: none) != none
  let has-context     = result.at("context", default: none) != none
  let has-constraints = result.at("constraints", default: none) != none
  let has-steps       = result.at("steps", default: none) != none
  let has-inputs      = result.at("inputs", default: none) != none
  let has-schema      = result.at("schema", default: none) != none

  if has-aspect and has-context and has-constraints and has-steps and has-inputs and has-schema {
    let a = result.at("aspect")
    let prompt = p-prompt(
      id:          a.at("id"),
      version:     a.at("version"),
      role:        a.at("role"),
      ctx:         result.at("context"),
      constraints: result.at("constraints"),
      steps:       result.at("steps"),
      inputs:      result.at("inputs"),
      schema:      result.at("schema"),
      checkpoints: result.at("checkpoints", default: ()),
    )
    result.insert("prompt", prompt)
  }

  result
}
