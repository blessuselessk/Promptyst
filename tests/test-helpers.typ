// tests/test-helpers.typ
// TDD tests for shorthand helpers (Phase 2).
// 5 test groups verifying helpers produce identical output to core constructors.

#import "../lib.typ": *


// ─────────────────────────────────────────────
// Test 1: ctx() renders identically to p-context()
// ─────────────────────────────────────────────

#let core-ctx = p-context(
  id: "test-ctx",
  entries: (
    (key: "env", value: "prod"),
    (key: "region", value: "us-east-1"),
  ),
)

// Using entry() helper
#let helper-ctx-1 = ctx("test-ctx", entry("env", "prod"), entry("region", "us-east-1"))

// Using tuple shorthand
#let helper-ctx-2 = ctx("test-ctx", ("env", "prod"), ("region", "us-east-1"))

#let core-rendered = render-context(core-ctx)
#let helper-rendered-1 = render-context(helper-ctx-1)
#let helper-rendered-2 = render-context(helper-ctx-2)

#assert(core-rendered == helper-rendered-1, message: "T1: ctx() with entry() renders same as p-context()")
#assert(core-rendered == helper-rendered-2, message: "T1: ctx() with tuples renders same as p-context()")


// ─────────────────────────────────────────────
// Test 2: schema() + field() renders identically to p-schema()
// ─────────────────────────────────────────────

#let core-sch = p-schema(
  id: "test-schema",
  fields: (
    (name: "status", type: "string", description: "Build status"),
    (name: "count", type: "int", description: "Number of items"),
  ),
)

#let helper-sch = schema("test-schema",
  field("status", "string", "Build status"),
  field("count", "int", "Number of items"),
)

#let core-sch-rendered = render-schema(core-sch)
#let helper-sch-rendered = render-schema(helper-sch)

#assert(core-sch-rendered == helper-sch-rendered, message: "T2: schema()+field() renders same as p-schema()")


// ─────────────────────────────────────────────
// Test 3: checkpoint() renders identically to p-checkpoint()
// ─────────────────────────────────────────────

#let core-cp = p-checkpoint(
  id: "verify-step",
  after-step: 2,
  assertion: "Data integrity maintained",
  on-fail: "halt",
)

#let helper-cp = checkpoint("verify-step", 2, "Data integrity maintained", "halt")

#let core-cp-rendered = render-checkpoint(core-cp)
#let helper-cp-rendered = render-checkpoint(helper-cp)

#assert(core-cp-rendered == helper-cp-rendered, message: "T3: checkpoint() renders same as p-checkpoint()")


// ─────────────────────────────────────────────
// Test 4: entry() and field() produce correct dict shapes
// ─────────────────────────────────────────────

#let e = entry("mykey", "myval")
#assert(e.at("key") == "mykey", message: "T4: entry().key")
#assert(e.at("value") == "myval", message: "T4: entry().value")
#assert(e.keys().len() == 2, message: "T4: entry has exactly 2 keys")

#let f = field("name", "string", "A description")
#assert(f.at("name") == "name", message: "T4: field().name")
#assert(f.at("type") == "string", message: "T4: field().type")
#assert(f.at("description") == "A description", message: "T4: field().description")
#assert(f.keys().len() == 3, message: "T4: field has exactly 3 keys")


// ─────────────────────────────────────────────
// Test 5: Full prompt from helpers renders identically to core constructors
// ─────────────────────────────────────────────

// Core version
#let core-full-ctx = p-context(
  id: "full-ctx",
  entries: (
    (key: "mode", value: "test"),
  ),
)

#let core-full-sch = p-schema(
  id: "full-schema",
  fields: (
    (name: "ok", type: "bool", description: "Success flag"),
  ),
)

#let core-full-cp = p-checkpoint(
  id: "final-check",
  after-step: 1,
  assertion: "All good",
  on-fail: "halt",
)

#let core-full-prompt = p-prompt(
  id: "helper-test",
  version: "1.0.0",
  role: "Test agent",
  ctx: core-full-ctx,
  constraints: ("Be correct.",),
  steps: ("Do the thing.",),
  inputs: ((name: "input", type: "string", description: "Test input"),),
  schema: core-full-sch,
  checkpoints: (core-full-cp,),
)

// Helper version
#let helper-full-ctx = ctx("full-ctx", entry("mode", "test"))
#let helper-full-sch = schema("full-schema", field("ok", "bool", "Success flag"))
#let helper-full-cp = checkpoint("final-check", 1, "All good", "halt")

#let helper-full-prompt = p-prompt(
  id: "helper-test",
  version: "1.0.0",
  role: "Test agent",
  ctx: helper-full-ctx,
  constraints: ("Be correct.",),
  steps: ("Do the thing.",),
  inputs: ((name: "input", type: "string", description: "Test input"),),
  schema: helper-full-sch,
  checkpoints: (helper-full-cp,),
)

#let core-full-rendered = render-prompt(core-full-prompt)
#let helper-full-rendered = render-prompt(helper-full-prompt)

#assert(core-full-rendered == helper-full-rendered, message: "T5: full prompt from helpers identical to core")


#align(center)[
  = Helper Tests Passed!
]
