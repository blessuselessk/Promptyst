// src/render.typ
// Pure rendering functions: dictionary → Markdown string.
// All render-* functions are public (exported via lib.typ).
// md-table, md-row, escape-pipes are public utilities (promoted in v0.2.0).
//
// Canonical Prompt output section order (Phase 1 contract):
//   # Prompt: {id}
//   **Version:** {version}
//   ## Role
//   ## Context: {id}
//   ## Constraints
//   ## Steps
//   ## Inputs
//   ## Output Schema: {id}
//   ## Checkpoint: {id}  ← zero or more, sorted by (after-step ASC, id ASC)


/// Format an array of cells as a single Markdown table row.
///
/// - cells (array): List of cell strings.
/// -> str
#let md-row(cells) = "| " + cells.join(" | ") + " |"

/// Render a complete Markdown table from headers and rows.
///
/// Generates a separator row with dashes at least 3 characters wide,
/// matching header width when longer.
///
/// - headers (array): Column header strings.
/// - rows (array): List of row arrays (each the same length as `headers`).
/// -> str
#let md-table(headers, rows) = {
  // Separator dashes are at least 3 wide, matching header width if longer.
  let sep = headers.map(h => "-" * calc.max(h.len(), 3))
  (
    (md-row(headers),) +
    (md-row(sep),) +
    rows.map(r => md-row(r))
  ).join("\n")
}

/// Escape pipe characters for use inside Markdown table cells.
///
/// - s (str): Input string potentially containing `|` characters.
/// -> str
#let escape-pipes(s) = s.replace("|", "\\|")


/// Render a context dictionary as a Markdown section with a key-value table.
///
/// - ctx (dictionary): A context dictionary (from `p-context`).
/// -> str
#let render-context(ctx) = {
  if ctx.at("_type", default: none) != "context" {
    panic("promptyst: render-context requires a context dictionary.")
  }
  (
    "## Context: " + ctx.id + "\n" +
    md-table(("Key", "Value"), ctx.entries.map(e => (e.key, e.value)))
  )
}


/// Render a schema dictionary as a Markdown section with a field table.
///
/// Pipe characters in type strings are escaped automatically.
///
/// - s (dictionary): A schema dictionary (from `p-schema`).
/// -> str
#let render-schema(s) = {
  if s.at("_type", default: none) != "schema" {
    panic("promptyst: render-schema requires a schema dictionary.")
  }
  let rows = s.fields.map(f => (
    f.name,
    escape-pipes(f.at("type")),
    f.description,
  ))
  (
    "## Output Schema: " + s.id + "\n" +
    md-table(("Field", "Type", "Description"), rows)
  )
}


/// Render a checkpoint dictionary as a Markdown section with a property table.
///
/// - cp (dictionary): A checkpoint dictionary (from `p-checkpoint`).
/// -> str
#let render-checkpoint(cp) = {
  if cp.at("_type", default: none) != "checkpoint" {
    panic("promptyst: render-checkpoint requires a checkpoint dictionary.")
  }
  (
    "## Checkpoint: " + cp.id + "\n" +
    md-table(
      ("Property", "Value"),
      (
        ("after-step", str(cp.after-step)),
        ("assertion",  cp.assertion),
        ("on-fail",    cp.on-fail),
      )
    )
  )
}


/// Render a chat-mode dictionary as a Markdown section with a property table.
///
/// - cm (dictionary): A chat-mode dictionary (from `p-chat-mode`).
/// -> str
#let render-chat-mode(cm) = {
  if cm.at("_type", default: none) != "chat-mode" {
    panic("promptyst: render-chat-mode requires a chat-mode dictionary.")
  }
  (
    "## Chat Mode: " + cm.id + "\n" +
    md-table(
      ("Property", "Value"),
      (
        ("turns",  cm.turns),
        ("state",  cm.state),
        ("prompt", cm.prompt-id),
      )
    )
  )
}


/// Render a full prompt dictionary as canonical Markdown.
///
/// Produces the complete prompt document with fixed section order:
/// Role, Context, Constraints, Steps, Inputs, Schema, Checkpoints.
/// Context and schema are expanded inline. Checkpoints appear sorted
/// by `(after-step ASC, id ASC)` as established at construction time.
///
/// - p (dictionary): A prompt dictionary (from `p-prompt`).
/// -> str
#let render-prompt(p) = {
  if p.at("_type", default: none) != "prompt" {
    panic("promptyst: render-prompt requires a prompt dictionary.")
  }

  let constraints-md = p.constraints
    .enumerate()
    .map(pair => str(pair.first() + 1) + ". " + pair.last())
    .join("\n")

  let steps-md = p.steps
    .enumerate()
    .map(pair => str(pair.first() + 1) + ". " + pair.last())
    .join("\n")

  let input-rows = p.inputs.map(inp => (
    inp.name,
    inp.at("type"),
    inp.description,
  ))

  let sections = (
    "# Prompt: "    + p.id,
    "**Version:** " + p.version,
    "## Role\n"     + p.role,
    render-context(p.context),
    "## Constraints\n" + constraints-md,
    "## Steps\n"       + steps-md,
    "## Inputs\n"      + md-table(("Name", "Type", "Description"), input-rows),
    render-schema(p.schema),
  )

  let body = sections.join("\n\n")

  if p.checkpoints.len() > 0 {
    body + "\n\n" + p.checkpoints.map(render-checkpoint).join("\n\n")
  } else {
    body
  }
}
