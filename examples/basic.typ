// examples/basic.typ
// Build a prompt using the five core constructors, then render to Markdown.

#import "../lib.typ": *

#let my-ctx = p-context(
  id: "support-ctx",
  entries: (
    (key: "domain", value: "Customer support"),
    (key: "tone",   value: "Professional but friendly"),
  ),
)

#let my-schema = p-schema(
  id: "reply-schema",
  fields: (
    (name: "response", type: "string",              description: "The reply text"),
    (name: "tone",     type: "enum(formal|casual)",  description: "Detected tone"),
    (name: "escalate", type: "bool",                 description: "Whether to escalate"),
  ),
)

#let my-checkpoint = p-checkpoint(
  id:         "tone-check",
  after-step: 2,
  assertion:  "Response tone matches the context tone guideline",
  on-fail:    "continue",
)

#let my-prompt = p-prompt(
  id:          "reply-to-ticket",
  version:     "1.0.0",
  role:        "You are a customer support agent.",
  ctx:         my-ctx,
  constraints: (
    "Keep responses under 150 words.",
    "Never promise refunds without manager approval.",
  ),
  steps: (
    "Read the ticket.",
    "Draft a reply.",
    "Check tone against guidelines.",
  ),
  inputs: (
    (name: "ticket", type: "string", description: "Raw ticket text"),
  ),
  schema:      my-schema,
  checkpoints: (my-checkpoint,),
)

// Render to Markdown
#let md = render-prompt(my-prompt)

// Display as PDF (typst compile)
#raw(md, lang: "markdown")

// Export as raw Markdown (typst query --root . examples/basic.typ "<output>" --field value --one)
#metadata(md) <output>
