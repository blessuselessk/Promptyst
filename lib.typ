// lib.typ
// promptyst public API entrypoint.
//
// This is the only file consumers import:
//   #import "@preview/promptyst:0.1.0": *
//
// It re-exports exactly the public surface.
// Internal symbols (_require, _md-row, etc.) are not re-exported.
// The _type tagging convention is internal. Do not read or branch on _type
// in consumer code — it is not a stable API contract.
//
// Public constructors:
//   p-context      → context dictionary
//   p-schema       → schema dictionary
//   p-checkpoint   → checkpoint dictionary
//   p-chat-mode    → chat-mode dictionary
//   p-prompt       → prompt dictionary
//
// Public renderers:
//   render-context    context dict    → Markdown string
//   render-schema     schema dict    → Markdown string
//   render-checkpoint checkpoint dict → Markdown string
//   render-chat-mode  chat-mode dict  → Markdown string
//   render-prompt     prompt dict     → Markdown string (full canonical block)
//
// Data ingestion (Phase 1):
//   from-toml      TOML string     → dict (partial or full prompt)
//   from-yaml      YAML string     → dict (partial or full prompt)
//
// Shorthand helpers (Phase 2, v0 — not under immutable 10-symbol contract):
//   ctx            shorthand for p-context (positional entries)
//   schema         shorthand for p-schema (positional fields)
//   field          builds a schema field dict
//   entry          builds a context entry dict
//   checkpoint     shorthand for p-checkpoint (positional args)
//
// Markdown utilities (promoted from internal in v0.2.0):
//   md-table       headers, rows → Markdown table string
//   md-row         cells → single Markdown table row
//   escape-pipes   string → string with | escaped
//
// PROSE adapter layer (Phase 3, evolving — NOT under 10-symbol contract):
//   p-agent, p-instruction, p-skill, p-workflow     constructors
//   render-agent, render-instruction, render-skill, render-workflow  renderers
//   render-prose   TOML string → Markdown string (auto-dispatches by top-level key)

#import "src/primitives.typ": p-context, p-schema, p-checkpoint, p-chat-mode, p-prompt
#import "src/render.typ":     render-context, render-schema, render-checkpoint, render-chat-mode, render-prompt
#import "src/render.typ":     md-table, md-row, escape-pipes
#import "src/adapters/prose.typ": p-agent, p-instruction, p-skill, p-workflow
#import "src/adapters/prose.typ": render-agent, render-instruction, render-skill, render-workflow
#import "src/ingest.typ":     from-toml, from-yaml
#import "src/helpers.typ":    ctx, schema, field, entry, checkpoint

/// Render a PROSE TOML source to Markdown.
///
/// Parses the TOML string via `from-toml`, detects the top-level primitive key
/// (agent, instruction, skill, workflow, prompt, context, schema), and dispatches
/// to the appropriate renderer.
///
/// Panics if no recognized primitive key is found.
///
/// - raw (str): Raw TOML string containing exactly one PROSE primitive.
/// -> str
#let render-prose(raw) = {
  let data = from-toml(raw)
  if data.at("agent", default: none) != none {
    render-agent(data.agent)
  } else if data.at("instruction", default: none) != none {
    render-instruction(data.instruction)
  } else if data.at("skill", default: none) != none {
    render-skill(data.skill)
  } else if data.at("workflow", default: none) != none {
    render-workflow(data.workflow)
  } else if data.at("prompt", default: none) != none {
    render-prompt(data.prompt)
  } else if data.at("context", default: none) != none {
    render-context(data.context)
  } else if data.at("schema", default: none) != none {
    render-schema(data.schema)
  } else {
    panic("promptyst: render-prose found no recognized primitive in TOML input")
  }
}
