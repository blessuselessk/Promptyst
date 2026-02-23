// tests/test.typ
// A simple integration test to ensure promptyst compiles successfully
// without panicking on valid inputs.

#import "../lib.typ": *

#let ctx = p-context(
  id: "test-context",
  entries: (
    (key: "repo", value: "promptyst"),
  ),
)

#let sch = p-schema(
  id: "test-schema",
  fields: (
    (name: "status", type: "string", description: "The build status"),
  ),
)

#let cp = p-checkpoint(
  id: "test-checkpoint",
  after-step: 1,
  assertion: "Ensure tests run.",
  on-fail: "halt"
)

#let my-prompt = p-prompt(
  id:          "ci-test",
  version:     "0.1.0",
  role:        "You are a CI agent.",
  context:     ctx,
  constraints: ("Be fast.",),
  steps:       ("Run code.",),
  inputs:      ((name: "code", type: "string", description: "The code to test."),),
  schema:      sch,
  checkpoints: (cp,)
)

#let rendered = render-prompt(my-prompt)

// Assert that the rendering outputs a string successfully
#assert(type(rendered) == str)

// You can also add specific string match assertions if desired:
#assert(rendered.contains("## Checkpoint: test-checkpoint"))
#assert(rendered.contains("## Output Schema: test-schema"))

#align(center)[
  = Tests Passed Successfully!
]
