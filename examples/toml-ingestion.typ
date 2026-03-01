// examples/toml-ingestion.typ
// Parse a TOML file and render the assembled prompt.

#import "../lib.typ": *

#let result = from-toml(read("prompt.toml"))

// from-toml returns a dict. When all required sections are present,
// the "prompt" key holds the assembled prompt dict.
#let md = render-prompt(result.prompt)

// Display as PDF (typst compile)
#raw(md, lang: "markdown")

// Export as raw Markdown (typst query --root . examples/toml-ingestion.typ "<output>" --field value --one)
#metadata(md) <output>
