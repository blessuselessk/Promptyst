// examples/e2e-pipeline.typ
// End-to-end: TOML in -> partial inspection -> metadata extraction ->
// full prompt render -> Markdown out.
//
// This mirrors the determinate-OCD context-engineering pipeline where
// a Nix build step produces TOML and Promptyst compiles it to Markdown.

#import "../lib.typ": *

// ── Step 1: Ingest TOML ──
// In the real pipeline, this comes from `nix eval` -> nuenv -> file.
#let raw-toml = read("pipeline-aspect.toml")
#let result = from-toml(raw-toml)

// ── Step 2: Inspect partial data ──
// Before rendering the full prompt, you can access individual sections.
// Useful for validation, logging, or routing in the build pipeline.

#let aspect-id = result.aspect.id
#let step-count = result.steps.len()
#let checkpoint-count = result.checkpoints.len()

[
  = Pipeline Report

  *Aspect:* #aspect-id \
  *Steps:* #step-count \
  *Checkpoints:* #checkpoint-count \
]

// ── Step 3: Extract metadata ──
// Metadata (rationale, severity) flows through the dict but never
// reaches the rendered output. The pipeline can use it for changelogs,
// APM prioritization, or audit trails.

#if result.at("meta", default: none) != none [
  == Rationale
  #for (key, val) in result.meta.rationale [
    - *#key:* #val \
  ]
]

#if result.at("constraints-meta", default: none) != none [
  == Constraint Severity
  #for (i, meta) in result.constraints-meta.enumerate() [
    #if meta.keys().len() > 0 [
      - Constraint #(i + 1): #meta.at("severity", default: "unspecified") \
    ]
  ]
]

// ── Step 4: Render the full prompt ──
// This is the final artifact — canonical Markdown suitable for
// CLAUDE.md, AGENTS.md, or any agent context file.

[== Rendered Prompt]

#raw(render-prompt(result.prompt), lang: "markdown")
