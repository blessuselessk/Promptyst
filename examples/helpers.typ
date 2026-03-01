// examples/helpers.typ
// Same prompt as basic.typ, built with shorthand helpers.

#import "../lib.typ": *

#let my-ctx = ctx("support-ctx",
  entry("domain", "Customer support"),
  entry("tone",   "Professional but friendly"),
)

#let my-schema = schema("reply-schema",
  field("response", "string",             "The reply text"),
  field("tone",     "enum(formal|casual)", "Detected tone"),
  field("escalate", "bool",                "Whether to escalate"),
)

#let my-checkpoint = checkpoint("tone-check", 2,
  "Response tone matches the context tone guideline",
  "continue",
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

// Export as raw Markdown (typst query --root . examples/helpers.typ "<output>" --field value --one)
#metadata(md) <output>
