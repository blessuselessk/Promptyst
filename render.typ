// src/render.typ
// Pure rendering functions: dictionary → Markdown string.
// All render-* functions are public (exported via lib.typ).
// All _md-* and _escape-* helpers are internal.
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


// ─────────────────────────────────────────────
// INTERNAL: Markdown table helpers
// ─────────────────────────────────────────────

#let _md-row(cells) = "| " + cells.join(" | ") + " |"

#let _md-table(headers, rows) = {
  // Separator dashes are at least 3 wide, matching header width if longer.
  let sep = headers.map(h => "-" * calc.max(h.len(), 3))
  (
    (_md-row(headers),) +
    (_md-row(sep),) +
    rows.map(r => _md-row(r))
  ).join("\n")
}

// Pipe characters inside type strings must be escaped for valid Markdown tables.
#let _escape-pipes(s) = s.replace("|", "\\|")


// ─────────────────────────────────────────────
// PUBLIC: render-context
// ─────────────────────────────────────────────

#let render-context(ctx) = {
  if ctx.at("_type", default: none) != "context" {
    panic("promptyst: render-context requires a context dictionary.")
  }
  "## Context: " + ctx.id + "\n" +
  _md-table(("Key", "Value"), ctx.entries.map(e => (e.key, e.value)))
}


// ─────────────────────────────────────────────
// PUBLIC: render-schema
// ─────────────────────────────────────────────

#let render-schema(s) = {
  if s.at("_type", default: none) != "schema" {
    panic("promptyst: render-schema requires a schema dictionary.")
  }
  let rows = s.fields.map(f => (
    f.name,
    _escape-pipes(f.at("type")),
    f.description,
  ))
  "## Output Schema: " + s.id + "\n" +
  _md-table(("Field", "Type", "Description"), rows)
}


// ─────────────────────────────────────────────
// PUBLIC: render-checkpoint
// ─────────────────────────────────────────────

#let render-checkpoint(cp) = {
  if cp.at("_type", default: none) != "checkpoint" {
    panic("promptyst: render-checkpoint requires a checkpoint dictionary.")
  }
  "## Checkpoint: " + cp.id + "\n" +
  _md-table(
    ("Property", "Value"),
    (
      ("after-step", str(cp.after-step)),
      ("assertion",  cp.assertion),
      ("on-fail",    cp.on-fail),
    )
  )
}


// ─────────────────────────────────────────────
// PUBLIC: render-chat-mode
// ─────────────────────────────────────────────

#let render-chat-mode(cm) = {
  if cm.at("_type", default: none) != "chat-mode" {
    panic("promptyst: render-chat-mode requires a chat-mode dictionary.")
  }
  "## Chat Mode: " + cm.id + "\n" +
  _md-table(
    ("Property", "Value"),
    (
      ("turns",  cm.turns),
      ("state",  cm.state),
      ("prompt", cm.prompt-id),
    )
  )
}


// ─────────────────────────────────────────────
// PUBLIC: render-prompt
// Expands context and schema inline. Checkpoints follow schema,
// sorted by (after-step ASC, id ASC) — order established at
// p-prompt construction, not here.
// ─────────────────────────────────────────────

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
    "## Inputs\n"      + _md-table(("Name", "Type", "Description"), input-rows),
    render-schema(p.schema),
  )

  let body = sections.join("\n\n")

  if p.checkpoints.len() > 0 {
    body + "\n\n" + p.checkpoints.map(render-checkpoint).join("\n\n")
  } else {
    body
  }
}
