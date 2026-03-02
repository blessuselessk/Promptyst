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


/// Construct an agent dictionary for PROSE agent primitives.
///
/// Agents have a persona, domain expertise, and operational boundaries.
/// Extra sections and references are optional.
///
/// - id (str): Unique agent identifier.
/// - description (str): Short description (used in frontmatter).
/// - tools (array): Tool names the agent can use. Default: `()`.
/// - handoffs (array): Agent IDs this agent can hand off to. Default: `()`.
/// - model (str): Preferred model identifier. Default: `none`.
/// - persona (str): Introductory paragraph defining the agent's voice.
/// - expertise (array): Non-empty list of domain expertise strings.
/// - boundaries (dictionary): Dict with `can`, `cannot`, and `approval` string keys.
/// - extra-sections (array): List of `(heading: str, body: str)` dicts. Default: `()`.
/// - references (array): List of `(label: str, path: str)` dicts. Default: `()`.
/// -> dictionary
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


/// Construct an instruction dictionary for PROSE instruction primitives.
///
/// Each section must have exactly one of `items` (bullet list) or `body` (raw Markdown).
/// If a section is named "Prohibited", the auto-appended Prohibited section is skipped.
///
/// - id (str): Unique instruction identifier.
/// - apply-to (str): Glob pattern for files this instruction applies to.
/// - description (str): Short description (used in frontmatter). Default: `none`.
/// - sections (array): Non-empty list of `(heading: str, items?: array, body?: str)` dicts.
/// - prohibited (array): List of prohibited-action strings. Default: `()`.
/// - references (array): List of `(label: str, path: str)` dicts. Default: `()`.
/// -> dictionary
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


/// Construct a skill dictionary for PROSE skill primitives.
///
/// Skills define trigger conditions, quick rules, and optional detailed references.
///
/// - name (str): Skill name (used in frontmatter).
/// - description (str): Skill description (can be multiline, rendered as YAML block scalar).
/// - trigger (str): Condition that activates this skill.
/// - rules (array): Non-empty list of rule strings (rendered as numbered list).
/// - extra-sections (array): List of `(heading: str, body: str)` dicts. Default: `()`.
/// - references-preamble (str): Prose paragraph before reference links. Default: `none`.
/// - references (array): List of `(label: str, path: str)` dicts. Default: `()`.
/// -> dictionary
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


/// Construct a workflow dictionary for PROSE workflow primitives.
///
/// Workflows define phased execution plans. Each phase has a name, steps,
/// and an optional checkpoint string.
///
/// - id (str): Unique workflow identifier.
/// - description (str): Workflow description (used in frontmatter).
/// - mode (str): Execution mode. Default: `"agent"`.
/// - agent (str): Agent identifier to execute this workflow. Default: `none`.
/// - phases (array): Non-empty list of `(name: str, steps: array, checkpoint?: str)` dicts.
/// -> dictionary
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


/// Render an agent dictionary as Markdown with YAML frontmatter.
///
/// Outputs frontmatter (description, tools, optional handoffs/model),
/// persona, expertise list, boundaries, extra sections, and references.
///
/// - a (dictionary): An agent dictionary (from `p-agent`).
/// -> str
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


/// Render an instruction dictionary as Markdown with YAML frontmatter.
///
/// Sections with `items` render as bullet lists; sections with `body` render as raw Markdown.
/// If a section is named "Prohibited", the auto-appended Prohibited section is skipped.
///
/// - instr (dictionary): An instruction dictionary (from `p-instruction`).
/// -> str
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


/// Render a skill dictionary as Markdown with YAML frontmatter.
///
/// Outputs frontmatter (name, block-scalar description), trigger section,
/// numbered rules, extra sections, and optional detailed references.
///
/// - sk (dictionary): A skill dictionary (from `p-skill`).
/// -> str
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


/// Render a workflow dictionary as Markdown with YAML frontmatter.
///
/// Each phase renders as a numbered heading with its steps.
/// Phases with a `checkpoint` key append a bold checkpoint line.
///
/// - wf (dictionary): A workflow dictionary (from `p-workflow`).
/// -> str
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
