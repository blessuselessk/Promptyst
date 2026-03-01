// examples/toml-ingestion.typ
// Parse a TOML file and render the assembled prompt.

#import "../lib.typ": *

#let result = from-toml(read("prompt.toml"))

// from-toml returns a dict. When all required sections are present,
// the "prompt" key holds the assembled prompt dict.
#raw(render-prompt(result.prompt), lang: "markdown")
