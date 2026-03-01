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

#import "src/primitives.typ": p-context, p-schema, p-checkpoint, p-chat-mode, p-prompt
#import "src/render.typ":     render-context, render-schema, render-checkpoint, render-chat-mode, render-prompt
#import "src/ingest.typ":     from-toml, from-yaml
#import "src/helpers.typ":    ctx, schema, field, entry, checkpoint
