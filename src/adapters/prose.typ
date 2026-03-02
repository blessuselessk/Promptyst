// src/adapters/prose.typ
// PROSE primitive constructors and renderers (adapter layer, Phase 3).
//
// These symbols are NOT under the immutable 10-symbol contract.
// Signatures may change between minor versions.
//
// Constructors:
//   p-agent        → agent dictionary
//   p-instruction  → instruction dictionary
//   p-skill        → skill dictionary
//   p-workflow     → workflow dictionary
//
// Renderers:
//   render-agent       agent dict       → Markdown string (with YAML frontmatter)
//   render-instruction instruction dict → Markdown string (with YAML frontmatter)
//   render-skill       skill dict       → Markdown string (with YAML frontmatter)
//   render-workflow    workflow dict     → Markdown string (with YAML frontmatter)

#import "../validate.typ": _require, _require-nonempty


// ─────────────────────────────────────────────
// INTERNAL: YAML frontmatter helpers
// ─────────────────────────────────────────────

// Wrap a value in double quotes for YAML scalar output.
#let _yaml-str(s) = "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

// Render a YAML list (flow style for short arrays, block style for longer).
#let _yaml-list(items) = {
  if items.len() == 0 { "[]" }
  else {
    "[" + items.map(i => "'" + i + "'").join(", ") + "]"
  }
}

// Render a YAML block scalar (literal style) for multiline strings.
#let _yaml-block(s) = "|\n  " + s.split("\n").join("\n  ")


// ═════════════════════════════════════════════
// CONSTRUCTORS
// ═════════════════════════════════════════════


// ─────────────────────────────────────────────
// p-agent
//
// id:          string (required)
// description: string (required)
// tools:       array of string (optional, default ())
// handoffs:    array of string (optional, default ())
// model:       string (optional, default none)
// persona:     string (required — the introductory paragraph)
// expertise:   array of string (required)
// boundaries:  dict with can, cannot, approval keys (required)
// extra-sections: array of (heading, body) dicts (optional, default ())
//              Rendered after Boundaries, before References. Body is raw Markdown.
// references:  array of (label, path) dicts (optional, default ())
// ─────────────────────────────────────────────

#let p-agent(
  id:          none,
  description: none,
  tools:       (),
  handoffs:    (),
  model:       none,
  persona:     none,
  expertise:   none,
  boundaries:  none,
  extra-sections: (),
  references:  (),
) = {
  let id          = _require(id, "agent.id")
  let description = _require(description, "agent.description")
  let persona     = _require(persona, "agent.persona")
  let expertise   = _require-nonempty(expertise, "agent.expertise")
  let boundaries  = _require(boundaries, "agent.boundaries")

  let _ = _require(boundaries.at("can", default: none), "agent.boundaries.can")
  let _ = _require(boundaries.at("cannot", default: none), "agent.boundaries.cannot")
  let _ = _require(boundaries.at("approval", default: none), "agent.boundaries.approval")

  (
    _type:       "agent",
    id:          id,
    description: description,
    tools:       tools,
    handoffs:    handoffs,
    model:       model,
    persona:     persona,
    expertise:   expertise,
    boundaries:  boundaries,
    extra-sections: extra-sections,
    references:  references,
  )
}


// ─────────────────────────────────────────────
// p-instruction
//
// id:         string (required)
// apply-to:   string glob (required)
// description: string (optional, default none)
// sections:   array of (heading, items|body) dicts (required)
//             each section has exactly one of:
//               items: array of string → rendered as bullet list
//               body:  string → rendered as raw Markdown
// prohibited: array of string (optional, default ())
// references: array of (label, path) dicts (optional, default ())
// ─────────────────────────────────────────────

#let p-instruction(
  id:          none,
  apply-to:    none,
  description: none,
  sections:    none,
  prohibited:  (),
  references:  (),
) = {
  let id       = _require(id, "instruction.id")
  let apply-to = _require(apply-to, "instruction.apply-to")
  let sections = _require-nonempty(sections, "instruction.sections")

  for s in sections {
    let _ = _require(s.at("heading", default: none), "instruction.sections[].heading")
    let has-items = s.at("items", default: none) != none
    let has-body  = s.at("body", default: none) != none
    if has-items and has-body {
      panic("promptyst: instruction section '" + s.heading + "' has both items and body — pick one.")
    }
    if not has-items and not has-body {
      panic("promptyst: instruction section '" + s.heading + "' needs items or body.")
    }
    if has-items {
      let _ = _require-nonempty(s.items, "instruction.sections[].items")
    }
    if has-body {
      let _ = _require(s.body, "instruction.sections[].body")
    }
  }

  (
    _type:       "instruction",
    id:          id,
    apply-to:    apply-to,
    description: description,
    sections:    sections,
    prohibited:  prohibited,
    references:  references,
  )
}


// ─────────────────────────────────────────────
// p-skill
//
// name:        string (required)
// description: string (required, can be multiline)
// trigger:     string (required)
// rules:       array of string (required)
// extra-sections: array of (heading, body) dicts (optional, default ())
//              Rendered after Quick Rules, before Detailed References.
// references-preamble: string (optional, default none)
//              Prose paragraph before the reference links.
// references:  array of (label, path) dicts (optional, default ())
// ─────────────────────────────────────────────

#let p-skill(
  name:        none,
  description: none,
  trigger:     none,
  rules:       none,
  extra-sections: (),
  references-preamble: none,
  references:  (),
) = {
  let name        = _require(name, "skill.name")
  let description = _require(description, "skill.description")
  let trigger     = _require(trigger, "skill.trigger")
  let rules       = _require-nonempty(rules, "skill.rules")

  (
    _type:       "skill",
    name:        name,
    description: description,
    trigger:     trigger,
    rules:       rules,
    extra-sections: extra-sections,
    references-preamble: references-preamble,
    references:  references,
  )
}


// ─────────────────────────────────────────────
// p-workflow
//
// id:          string (required)
// description: string (required)
// mode:        string (optional, default "agent")
// agent:       string (optional, default none)
// phases:      array of (name, steps) dicts (required)
//              each phase may optionally include checkpoint: string
// ─────────────────────────────────────────────

#let p-workflow(
  id:          none,
  description: none,
  mode:        "agent",
  agent:       none,
  phases:      none,
) = {
  let id          = _require(id, "workflow.id")
  let description = _require(description, "workflow.description")
  let phases      = _require-nonempty(phases, "workflow.phases")

  for ph in phases {
    let _ = _require(ph.at("name", default: none), "workflow.phases[].name")
    let _ = _require-nonempty(ph.at("steps", default: none), "workflow.phases[].steps")
  }

  (
    _type:       "workflow",
    id:          id,
    description: description,
    mode:        mode,
    agent:       agent,
    phases:      phases,
  )
}


// ═════════════════════════════════════════════
// RENDERERS
// Each produces Markdown with YAML frontmatter.
// ═════════════════════════════════════════════


// ─────────────────────────────────────────────
// render-agent
// ─────────────────────────────────────────────

#let render-agent(a) = {
  if a.at("_type", default: none) != "agent" {
    panic("promptyst: render-agent requires an agent dictionary.")
  }

  let fm-lines = (
    "---",
    "description: " + _yaml-str(a.description),
    "tools: " + _yaml-list(a.tools),
  )

  if a.handoffs.len() > 0 {
    fm-lines = fm-lines + ("handoffs: " + _yaml-list(a.handoffs),)
  }

  if a.model != none {
    fm-lines = fm-lines + ("model: " + a.model,)
  }

  fm-lines = fm-lines + ("---",)
  let frontmatter = fm-lines.join("\n")

  let expertise-md = a.expertise.map(e => "- " + e).join("\n")

  let boundaries-md = (
    "- **CAN**: " + a.boundaries.can,
    "- **CANNOT**: " + a.boundaries.cannot,
    "- **APPROVAL REQUIRED**: " + a.boundaries.approval,
  ).join("\n")

  let sections = (
    frontmatter,
    a.persona,
    "## Domain Expertise\n" + expertise-md,
    "## Boundaries\n" + boundaries-md,
  )

  for es in a.extra-sections {
    sections = sections + ("## " + es.heading + "\n" + es.body,)
  }

  if a.references.len() > 0 {
    let refs-md = a.references.map(r => "- [" + r.label + "](" + r.path + ")").join("\n")
    sections = sections + ("## References\n" + refs-md,)
  }

  sections.join("\n\n") + "\n"
}


// ─────────────────────────────────────────────
// render-instruction
// ─────────────────────────────────────────────

#let render-instruction(instr) = {
  if instr.at("_type", default: none) != "instruction" {
    panic("promptyst: render-instruction requires an instruction dictionary.")
  }

  let fm-lines = (
    "---",
    "applyTo: " + _yaml-str(instr.apply-to),
  )

  if instr.description != none {
    fm-lines = fm-lines + ("description: " + _yaml-str(instr.description),)
  }

  fm-lines = fm-lines + ("---",)
  let frontmatter = fm-lines.join("\n")

  let section-blocks = instr.sections.map(s => {
    if s.at("body", default: none) != none {
      "## " + s.heading + "\n" + s.body
    } else {
      let items-md = s.items.map(i => "- " + i).join("\n")
      "## " + s.heading + "\n" + items-md
    }
  })

  let sections = (frontmatter,) + section-blocks

  // Skip auto-appended Prohibited if a section already covers it
  let has-prohibited-section = instr.sections.any(s => s.heading == "Prohibited")
  if instr.prohibited.len() > 0 and not has-prohibited-section {
    let prohibited-md = instr.prohibited.map(p => "- " + p).join("\n")
    sections = sections + ("## Prohibited\n" + prohibited-md,)
  }

  if instr.references.len() > 0 {
    let refs-md = instr.references.map(r => "- [" + r.label + "](" + r.path + ")").join("\n")
    sections = sections + ("## References\n" + refs-md,)
  }

  sections.join("\n\n") + "\n"
}


// ─────────────────────────────────────────────
// render-skill
// ─────────────────────────────────────────────

#let render-skill(sk) = {
  if sk.at("_type", default: none) != "skill" {
    panic("promptyst: render-skill requires a skill dictionary.")
  }

  let frontmatter = (
    "---",
    "name: " + sk.name,
    "description: " + _yaml-block(sk.description),
    "---",
  ).join("\n")

  let rules-md = sk.rules
    .enumerate()
    .map(pair => str(pair.first() + 1) + ". " + pair.last())
    .join("\n")

  let sections = (
    frontmatter,
    "## When This Skill Triggers\n\n" + sk.trigger,
    "## Quick Rules\n\n" + rules-md,
  )

  for es in sk.extra-sections {
    sections = sections + ("## " + es.heading + "\n\n" + es.body,)
  }

  if sk.references.len() > 0 {
    let refs-md = sk.references.map(r => "- [" + r.label + "](" + r.path + ")").join("\n")
    let refs-block = if sk.references-preamble != none {
      "## Detailed References\n\n" + sk.references-preamble + "\n" + refs-md
    } else {
      "## Detailed References\n\n" + refs-md
    }
    sections = sections + (refs-block,)
  }

  sections.join("\n\n") + "\n"
}


// ─────────────────────────────────────────────
// render-workflow
// ─────────────────────────────────────────────

#let render-workflow(wf) = {
  if wf.at("_type", default: none) != "workflow" {
    panic("promptyst: render-workflow requires a workflow dictionary.")
  }

  let fm-lines = (
    "---",
    "description: " + _yaml-str(wf.description),
    "mode: " + wf.mode,
  )

  if wf.agent != none {
    fm-lines = fm-lines + ("agent: " + wf.agent,)
  }

  fm-lines = fm-lines + ("---",)
  let frontmatter = fm-lines.join("\n")

  let phase-blocks = wf.phases.enumerate().map(pair => {
    let idx = pair.first()
    let ph = pair.last()
    let steps-md = ph.steps
      .enumerate()
      .map(sp => str(sp.first() + 1) + ". " + sp.last())
      .join("\n")
    let block = "## Phase " + str(idx + 1) + ": " + ph.name + "\n" + steps-md
    let cp = ph.at("checkpoint", default: none)
    if cp != none {
      block + "\n\n**CHECKPOINT**: " + cp
    } else {
      block
    }
  })

  let sections = (frontmatter,) + phase-blocks
  sections.join("\n\n") + "\n"
}
