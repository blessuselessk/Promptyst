// tests/test-ingest.typ
// TDD tests for from-toml ingestion layer (Phase 1).
// 8 test groups covering full round-trip, partials, metadata, sorting, equivalence.

#import "../lib.typ": *

// ─────────────────────────────────────────────
// Test 1: Full prompt round-trip
// from-toml → render-prompt → assert sections present
// ─────────────────────────────────────────────

#let full-raw = read("fixtures/full-prompt.toml")
#let full = from-toml(full-raw)

// Must have a prompt key (all required sections present)
#assert(full.at("prompt", default: none) != none, message: "T1: full prompt should assemble")

#let full-rendered = render-prompt(full.prompt)
#assert(type(full-rendered) == str, message: "T1: rendered output must be a string")
#assert(full-rendered.contains("# Prompt: ocd.networking"), message: "T1: prompt header")
#assert(full-rendered.contains("## Role"), message: "T1: role section")
#assert(full-rendered.contains("## Context: networking-ctx"), message: "T1: context section")
#assert(full-rendered.contains("## Constraints"), message: "T1: constraints section")
#assert(full-rendered.contains("## Steps"), message: "T1: steps section")
#assert(full-rendered.contains("## Inputs"), message: "T1: inputs section")
#assert(full-rendered.contains("## Output Schema: networking-output"), message: "T1: schema section")
#assert(full-rendered.contains("## Checkpoint: verify-loopback"), message: "T1: checkpoint section")


// ─────────────────────────────────────────────
// Test 2: Context-only partial
// Has context key, no prompt key
// ─────────────────────────────────────────────

#let ctx-raw = read("fixtures/context-only.toml")
#let ctx-result = from-toml(ctx-raw)

#assert(ctx-result.at("context", default: none) != none, message: "T2: context key present")
#assert(ctx-result.at("prompt", default: none) == none, message: "T2: no prompt key for partial")
#assert(ctx-result.context.id == "standalone-ctx", message: "T2: context id correct")

// Context can be rendered standalone
#let ctx-rendered = render-context(ctx-result.context)
#assert(ctx-rendered.contains("## Context: standalone-ctx"), message: "T2: context renders")
#assert(ctx-rendered.contains("production"), message: "T2: entry value present")


// ─────────────────────────────────────────────
// Test 3: Schema-only partial
// Has schema key, no prompt key
// ─────────────────────────────────────────────

#let sch-raw = read("fixtures/schema-only.toml")
#let sch-result = from-toml(sch-raw)

#assert(sch-result.at("schema", default: none) != none, message: "T3: schema key present")
#assert(sch-result.at("prompt", default: none) == none, message: "T3: no prompt key for partial")
#assert(sch-result.schema.id == "deploy-output", message: "T3: schema id correct")

// Schema can be rendered standalone
#let sch-rendered = render-schema(sch-result.schema)
#assert(sch-rendered.contains("## Output Schema: deploy-output"), message: "T3: schema renders")
#assert(sch-rendered.contains("timestamp"), message: "T3: field name present")


// ─────────────────────────────────────────────
// Test 4: Metadata preservation
// rationale exists in meta, severity in constraints-meta,
// NEITHER appears in rendered output
// ─────────────────────────────────────────────

#let meta-raw = read("fixtures/with-metadata.toml")
#let meta-result = from-toml(meta-raw)

// Rationale preserved in meta
#assert(meta-result.at("meta", default: none) != none, message: "T4: meta key present")
#assert(meta-result.meta.at("rationale", default: none) != none, message: "T4: rationale in meta")
#assert(meta-result.meta.rationale.at("design", default: none) != none, message: "T4: rationale.design present")

// Constraint severity preserved in constraints-meta
#assert(meta-result.at("constraints-meta", default: none) != none, message: "T4: constraints-meta present")
#assert(meta-result.constraints-meta.at(0).at("severity", default: none) == "security", message: "T4: first constraint severity")
#assert(meta-result.constraints-meta.at(1).at("severity", default: none) == "performance", message: "T4: second constraint severity")

// Rendered output must NOT contain metadata
#let meta-rendered = render-prompt(meta-result.prompt)
#assert(not meta-rendered.contains("rationale"), message: "T4: rationale not in rendered output")
#assert(not meta-rendered.contains("severity"), message: "T4: severity not in rendered output")
#assert(not meta-rendered.contains("security"), message: "T4: security tag not in rendered output")


// ─────────────────────────────────────────────
// Test 5: Checkpoint sort order
// alpha(1) before beta(1) before zulu(1), gamma(2), delta(3)
// ─────────────────────────────────────────────

#let sort-raw = read("fixtures/checkpoints.toml")
#let sort-result = from-toml(sort-raw)

#assert(sort-result.at("prompt", default: none) != none, message: "T5: full prompt assembled")

// Checkpoints in the assembled prompt are sorted by p-prompt
#let sorted-cps = sort-result.prompt.checkpoints
#assert(sorted-cps.len() == 5, message: "T5: all 5 checkpoints present")

// after-step=1: alpha, beta, zulu (id ascending)
#assert(sorted-cps.at(0).id == "alpha", message: "T5: first is alpha (step 1, id a)")
#assert(sorted-cps.at(1).id == "beta",  message: "T5: second is beta (step 1, id b)")
#assert(sorted-cps.at(2).id == "zulu",  message: "T5: third is zulu (step 1, id z)")
// after-step=2: gamma
#assert(sorted-cps.at(3).id == "gamma", message: "T5: fourth is gamma (step 2)")
// after-step=3: delta
#assert(sorted-cps.at(4).id == "delta", message: "T5: fifth is delta (step 3)")

// Verify sort order in rendered output: alpha appears before zulu
#let sort-rendered = render-prompt(sort-result.prompt)
#let alpha-pos = sort-rendered.position("Checkpoint: alpha")
#let zulu-pos  = sort-rendered.position("Checkpoint: zulu")
#let gamma-pos = sort-rendered.position("Checkpoint: gamma")
#let delta-pos = sort-rendered.position("Checkpoint: delta")
#assert(alpha-pos < zulu-pos,  message: "T5: alpha before zulu in output")
#assert(zulu-pos < gamma-pos,  message: "T5: step-1 before step-2 in output")
#assert(gamma-pos < delta-pos, message: "T5: step-2 before step-3 in output")


// ─────────────────────────────────────────────
// Test 6: Partial steps + constraints only
// No full prompt assembled
// ─────────────────────────────────────────────

#let partial-raw = read("fixtures/steps-and-constraints.toml")
#let partial-result = from-toml(partial-raw)

#assert(partial-result.at("constraints", default: none) != none, message: "T6: constraints present")
#assert(partial-result.at("steps", default: none) != none, message: "T6: steps present")
#assert(partial-result.at("prompt", default: none) == none, message: "T6: no prompt (partial)")
#assert(partial-result.constraints.len() == 2, message: "T6: two constraints")
#assert(partial-result.steps.len() == 3, message: "T6: three steps")
#assert(partial-result.steps.at(0) == "Back up current state", message: "T6: first step text")


// ─────────────────────────────────────────────
// Test 7: Equivalence — hand-built vs from-toml
// Both produce identical render-prompt output
// ─────────────────────────────────────────────

// Hand-build the same prompt as full-prompt.toml
#let hand-ctx = p-context(
  id: "networking-ctx",
  entries: (
    (key: "firewall", value: "Ports 443 (HTTPS) and 22 (SSH) open externally"),
    (key: "gateway-port", value: "18789 loopback-only (proxied by Caddy)"),
  ),
)

#let hand-sch = p-schema(
  id: "networking-output",
  fields: (
    (name: "applied", type: "bool", description: "Whether the config was applied"),
  ),
)

#let hand-cp = p-checkpoint(
  id: "verify-loopback",
  after-step: 2,
  assertion: "Gateway port 18789 is not in allowedTCPPorts",
  on-fail: "halt",
)

#let hand-prompt = p-prompt(
  id:          "ocd.networking",
  version:     "0.1.0",
  role:        "OpenClaw-aware networking aspect",
  ctx:         hand-ctx,
  constraints: (
    "Gateway and webhook ports stay loopback-only",
    "All external traffic must route through Caddy",
  ),
  steps:       (
    "Configure NetworkManager",
    "Open firewall ports 443, 22",
  ),
  inputs:      (
    (name: "hostname", type: "string", description: "Target machine hostname"),
  ),
  schema:      hand-sch,
  checkpoints: (hand-cp,),
)

#let hand-rendered = render-prompt(hand-prompt)
#let toml-rendered = render-prompt(full.prompt)

#assert(hand-rendered == toml-rendered, message: "T7: hand-built and from-toml render identically")


// ─────────────────────────────────────────────
// Test 8: Return type structure
// Always has meta key when rationale present;
// prompt key only when complete
// ─────────────────────────────────────────────

// Full prompt: has prompt key
#assert(type(full) == dictionary, message: "T8: result is a dictionary")
#assert(full.at("prompt", default: none) != none, message: "T8: full has prompt key")
#assert(full.at("aspect", default: none) != none, message: "T8: full has aspect key")
#assert(full.at("context", default: none) != none, message: "T8: full has context key")
#assert(full.at("schema", default: none) != none, message: "T8: full has schema key")

// Context-only: no prompt key, no meta key (no rationale in fixture)
#assert(type(ctx-result) == dictionary, message: "T8: partial is a dictionary")
#assert(ctx-result.at("prompt", default: none) == none, message: "T8: partial has no prompt")
#assert(ctx-result.at("meta", default: none) == none, message: "T8: partial has no meta")

// With-metadata: has both prompt and meta
#assert(meta-result.at("prompt", default: none) != none, message: "T8: metadata result has prompt")
#assert(meta-result.at("meta", default: none) != none, message: "T8: metadata result has meta")


// ─────────────────────────────────────────────
// Test 9: YAML round-trip
// from-yaml → render-prompt → assert sections present
// (mirrors T1 but uses YAML fixture + from-yaml)
// ─────────────────────────────────────────────

#let yaml-raw = read("fixtures/full-prompt.yaml")
#let yaml-full = from-yaml(yaml-raw)

// Must have a prompt key (all required sections present)
#assert(yaml-full.at("prompt", default: none) != none, message: "T9: YAML full prompt should assemble")

#let yaml-rendered = render-prompt(yaml-full.prompt)
#assert(type(yaml-rendered) == str, message: "T9: rendered output must be a string")
#assert(yaml-rendered.contains("# Prompt: ocd.networking"), message: "T9: prompt header")
#assert(yaml-rendered.contains("## Role"), message: "T9: role section")
#assert(yaml-rendered.contains("## Context: networking-ctx"), message: "T9: context section")
#assert(yaml-rendered.contains("## Constraints"), message: "T9: constraints section")
#assert(yaml-rendered.contains("## Steps"), message: "T9: steps section")
#assert(yaml-rendered.contains("## Inputs"), message: "T9: inputs section")
#assert(yaml-rendered.contains("## Output Schema: networking-output"), message: "T9: schema section")
#assert(yaml-rendered.contains("## Checkpoint: verify-loopback"), message: "T9: checkpoint section")


// ─────────────────────────────────────────────
// Test 10: YAML↔TOML equivalence
// from-yaml and from-toml produce identical render-prompt output
// ─────────────────────────────────────────────

#let toml-rendered-t10 = render-prompt(full.prompt)
#let yaml-rendered-t10 = render-prompt(yaml-full.prompt)

#assert(toml-rendered-t10 == yaml-rendered-t10, message: "T10: YAML and TOML render identically")


#align(center)[
  = Ingest Tests Passed!
]
