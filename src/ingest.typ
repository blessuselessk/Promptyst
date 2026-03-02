// src/ingest.typ
// Data ingestion layer. Parses TOML/YAML strings into core constructor dicts.
//
// Public symbols: from-toml(raw), from-yaml(raw)
//
// This is a core module — it imports sibling src/primitives.typ directly
// (same layer as render.typ and validate.typ). It calls constructors to
// ensure all validation fires on the parsed data.
//
// Partial data: missing sections produce missing keys in the result dict.
// Full assembly: when all required sections are present, builds a prompt
// via p-prompt(). Metadata ([rationale], constraint severity) is preserved
// in the result but never rendered.

#import "primitives.typ": p-context, p-schema, p-checkpoint, p-prompt
#import "adapters/prose.typ": p-agent, p-instruction, p-skill, p-workflow


// ─────────────────────────────────────────────
// _from-data (private)
//
// data: dictionary — parsed prompt data (from toml() or yaml())
//
// Returns a dictionary with optional keys:
//   context, schema, constraints, steps, inputs, checkpoints,
//   aspect, prompt, meta, constraints-meta
//
// Missing sections → absent keys (no panic).
// Present sections with invalid data → panic via constructor validation.
// ─────────────────────────────────────────────

#let _from-data(data) = {
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

  // ── PROSE: agent ──
  let agent-data = data.at("agent", default: none)
  if agent-data != none {
    let a = p-agent(
      id:          agent-data.at("id"),
      description: agent-data.at("description"),
      tools:       agent-data.at("tools", default: ()),
      handoffs:    agent-data.at("handoffs", default: ()),
      model:       agent-data.at("model", default: none),
      persona:     agent-data.at("persona"),
      expertise:   agent-data.at("expertise"),
      boundaries:  agent-data.at("boundaries"),
      extra-sections: agent-data.at("extra-sections", default: ()),
      references:  agent-data.at("references", default: ()),
    )
    result.insert("agent", a)
  }

  // ── PROSE: instruction ──
  let instr-data = data.at("instruction", default: none)
  if instr-data != none {
    let i = p-instruction(
      id:          instr-data.at("id"),
      apply-to:    instr-data.at("apply-to"),
      description: instr-data.at("description", default: none),
      sections:    instr-data.at("sections"),
      prohibited:  instr-data.at("prohibited", default: ()),
      references:  instr-data.at("references", default: ()),
    )
    result.insert("instruction", i)
  }

  // ── PROSE: skill ──
  let skill-data = data.at("skill", default: none)
  if skill-data != none {
    let s = p-skill(
      name:        skill-data.at("name"),
      description: skill-data.at("description"),
      trigger:     skill-data.at("trigger"),
      rules:       skill-data.at("rules"),
      extra-sections: skill-data.at("extra-sections", default: ()),
      references-preamble: skill-data.at("references-preamble", default: none),
      references:  skill-data.at("references", default: ()),
    )
    result.insert("skill", s)
  }

  // ── PROSE: workflow ──
  let workflow-data = data.at("workflow", default: none)
  if workflow-data != none {
    let w = p-workflow(
      id:          workflow-data.at("id"),
      description: workflow-data.at("description"),
      mode:        workflow-data.at("mode", default: "agent"),
      agent:       workflow-data.at("agent", default: none),
      phases:      workflow-data.at("phases"),
    )
    result.insert("workflow", w)
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


/// Parse a TOML string into a prompt result dictionary.
///
/// Missing sections produce absent keys (no panic). Present sections with
/// invalid data panic via constructor validation. When all required sections
/// are present, a full prompt is assembled via `p-prompt`.
///
/// - raw (str): TOML-encoded prompt data.
/// -> dictionary
#let from-toml(raw) = _from-data(toml(bytes(raw)))


/// Parse a YAML string into a prompt result dictionary.
///
/// Behaves identically to `from-toml` but accepts YAML input.
///
/// - raw (str): YAML-encoded prompt data.
/// -> dictionary
#let from-yaml(raw) = _from-data(yaml(bytes(raw)))
