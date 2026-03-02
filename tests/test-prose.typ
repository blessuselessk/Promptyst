// tests/test-prose.typ
// Tests for PROSE primitive constructors and renderers (Phase 3 adapter layer).
// 8 test groups covering round-trips, frontmatter, optional fields, body sections.

#import "../lib.typ": *


// ─────────────────────────────────────────────
// Test 1: Agent round-trip
// TOML → from-toml → render-agent → expected Markdown
// ─────────────────────────────────────────────

#let agent-raw = read("fixtures/agent.toml")
#let agent-result = from-toml(agent-raw)

#assert(agent-result.at("agent", default: none) != none, message: "T1: agent key present")

#let agent-rendered = render-agent(agent-result.agent)
#assert(type(agent-rendered) == str, message: "T1: rendered output is a string")
#assert(agent-rendered.contains("---"), message: "T1: has frontmatter delimiters")
#assert(agent-rendered.contains("description: \"Dendritic aspect author"), message: "T1: frontmatter description")
#assert(agent-rendered.contains("tools: ['read'"), message: "T1: frontmatter tools")
#assert(agent-rendered.contains("## Domain Expertise"), message: "T1: expertise section")
#assert(agent-rendered.contains("Nix module system"), message: "T1: expertise item")
#assert(agent-rendered.contains("## Boundaries"), message: "T1: boundaries section")
#assert(agent-rendered.contains("**CAN**: Create aspects"), message: "T1: boundaries.can")
#assert(agent-rendered.contains("**CANNOT**: Modify"), message: "T1: boundaries.cannot")
#assert(agent-rendered.contains("**APPROVAL REQUIRED**: Adding new flake inputs"), message: "T1: boundaries.approval")
#assert(agent-rendered.contains("## References"), message: "T1: references section")
#assert(agent-rendered.contains("[Dendritic instructions]"), message: "T1: reference label")


// ─────────────────────────────────────────────
// Test 2: Instruction round-trip
// TOML → from-toml → render-instruction → expected Markdown
// ─────────────────────────────────────────────

#let instr-raw = read("fixtures/instruction.toml")
#let instr-result = from-toml(instr-raw)

#assert(instr-result.at("instruction", default: none) != none, message: "T2: instruction key present")

#let instr-rendered = render-instruction(instr-result.instruction)
#assert(type(instr-rendered) == str, message: "T2: rendered output is a string")
#assert(instr-rendered.contains("applyTo: \"modules/**/*.nix\""), message: "T2: frontmatter applyTo")
#assert(instr-rendered.contains("description: \"Dendritic aspect authoring"), message: "T2: frontmatter description")
#assert(instr-rendered.contains("## Aspect Structure"), message: "T2: first section heading")
#assert(instr-rendered.contains("- One aspect per file"), message: "T2: first section item")
#assert(instr-rendered.contains("## Path Conventions"), message: "T2: second section heading")
#assert(instr-rendered.contains("## Prohibited"), message: "T2: prohibited section")
#assert(instr-rendered.contains("No `specialArgs`"), message: "T2: prohibited item")
#assert(instr-rendered.contains("## References"), message: "T2: references section")


// ─────────────────────────────────────────────
// Test 3: Skill round-trip
// TOML → from-toml → render-skill → expected Markdown
// ─────────────────────────────────────────────

#let skill-raw = read("fixtures/skill.toml")
#let skill-result = from-toml(skill-raw)

#assert(skill-result.at("skill", default: none) != none, message: "T3: skill key present")

#let skill-rendered = render-skill(skill-result.skill)
#assert(type(skill-rendered) == str, message: "T3: rendered output is a string")
#assert(skill-rendered.contains("name: primitive-composability"), message: "T3: frontmatter name")
#assert(skill-rendered.contains("description: |"), message: "T3: frontmatter block scalar")
#assert(skill-rendered.contains("## When This Skill Triggers"), message: "T3: trigger section")
#assert(skill-rendered.contains("## Quick Rules"), message: "T3: rules section")
#assert(skill-rendered.contains("1. **Check the tier**"), message: "T3: first rule")
#assert(skill-rendered.contains("5. **Only agents can hand off**"), message: "T3: last rule")
#assert(skill-rendered.contains("## Detailed References"), message: "T3: references section")
#assert(skill-rendered.contains("[Composability schema]"), message: "T3: reference label")


// ─────────────────────────────────────────────
// Test 4: Workflow round-trip
// TOML → from-toml → render-workflow → expected Markdown
// ─────────────────────────────────────────────

#let wf-raw = read("fixtures/workflow.toml")
#let wf-result = from-toml(wf-raw)

#assert(wf-result.at("workflow", default: none) != none, message: "T4: workflow key present")

#let wf-rendered = render-workflow(wf-result.workflow)
#assert(type(wf-rendered) == str, message: "T4: rendered output is a string")
#assert(wf-rendered.contains("description: \"End-to-end workflow"), message: "T4: frontmatter description")
#assert(wf-rendered.contains("mode: agent"), message: "T4: frontmatter mode")
#assert(wf-rendered.contains("agent: nix-aspect-author"), message: "T4: frontmatter agent")
#assert(wf-rendered.contains("## Phase 1: Discovery"), message: "T4: phase 1 heading")
#assert(wf-rendered.contains("## Phase 2: Implementation"), message: "T4: phase 2 heading")
#assert(wf-rendered.contains("## Phase 3: Validation"), message: "T4: phase 3 heading")
#assert(wf-rendered.contains("**CHECKPOINT**: Namespace and file path"), message: "T4: phase 1 checkpoint")
#assert(wf-rendered.contains("**CHECKPOINT**: All checks green"), message: "T4: phase 3 checkpoint")


// ─────────────────────────────────────────────
// Test 5: Agent YAML equivalence
// Hand-built p-agent → render-agent matches TOML ingest path
// ─────────────────────────────────────────────

#let hand-agent = p-agent(
  id: "nix-aspect-author",
  description: "Dendritic aspect author — creates and modifies NixOS aspects following den conventions",
  tools: ("read", "edit", "write", "glob", "grep", "bash"),
  handoffs: ("context-author",),
  model: "sonnet",
  persona: "You are a NixOS aspect author working within the determinate-OCD flake.\nYou create and modify dendritic aspects — one `.nix` file per feature,\nauto-imported by `import-tree`.",
  expertise: (
    "Nix module system (options, config, lib)",
    "den framework (namespaces, includes, provides, angle-bracket syntax)",
    "flake-parts perSystem and top-level modules",
    "agenix secrets management",
  ),
  boundaries: (
    can: "Create aspects, modify existing aspects, wire includes/provides",
    cannot: "Modify `flake.nix` directly (use `nix run .#write-flake`), commit secrets to the store",
    approval: "Adding new flake inputs, changing host declarations",
  ),
  references: (
    (label: "Dendritic instructions", path: "../instructions/dendritic.instructions.md"),
    (label: "Stack reference", path: "../context/stack.context.md"),
  ),
)

#let hand-agent-rendered = render-agent(hand-agent)
#let toml-agent-rendered = render-agent(agent-result.agent)

#assert(hand-agent-rendered == toml-agent-rendered, message: "T5: hand-built and from-toml agent render identically")


// ─────────────────────────────────────────────
// Test 6: Frontmatter correctness
// YAML frontmatter starts with --- and ends with ---
// ─────────────────────────────────────────────

// Agent frontmatter
#assert(agent-rendered.starts-with("---\n"), message: "T6a: agent starts with ---")
#let agent-second-sep = agent-rendered.position(regex("---\n\n"))
#assert(agent-second-sep != none, message: "T6a: agent has closing ---")

// Instruction frontmatter
#assert(instr-rendered.starts-with("---\n"), message: "T6b: instruction starts with ---")

// Skill frontmatter
#assert(skill-rendered.starts-with("---\n"), message: "T6c: skill starts with ---")

// Workflow frontmatter
#assert(wf-rendered.starts-with("---\n"), message: "T6d: workflow starts with ---")


// ─────────────────────────────────────────────
// Test 7: Optional fields omitted gracefully
// Agent without handoffs, model, references
// Instruction without description, prohibited, references
// ─────────────────────────────────────────────

#let minimal-agent = p-agent(
  id: "minimal",
  description: "A minimal agent",
  persona: "You are minimal.",
  expertise: ("Being minimal",),
  boundaries: (can: "exist", cannot: "be complex", approval: "none needed"),
)

#let minimal-agent-rendered = render-agent(minimal-agent)
#assert(not minimal-agent-rendered.contains("handoffs:"), message: "T7a: no handoffs in output")
#assert(not minimal-agent-rendered.contains("model:"), message: "T7b: no model in output")
#assert(not minimal-agent-rendered.contains("## References"), message: "T7c: no references section")

#let minimal-instr = p-instruction(
  id: "minimal-instr",
  apply-to: "**/*.nix",
  sections: ((heading: "Basics", items: ("Do the thing",)),),
)

#let minimal-instr-rendered = render-instruction(minimal-instr)
#assert(not minimal-instr-rendered.contains("description:"), message: "T7d: no description in frontmatter")
#assert(not minimal-instr-rendered.contains("## Prohibited"), message: "T7e: no prohibited section")
#assert(not minimal-instr-rendered.contains("## References"), message: "T7f: no references section")
#assert(minimal-instr-rendered.contains("## Basics"), message: "T7g: section heading present")


// ─────────────────────────────────────────────
// Test 8: Instruction with body sections
// body sections render raw Markdown (tables, code blocks)
// Prohibited as inline section skips auto-append
// ─────────────────────────────────────────────

#let body-instr = p-instruction(
  id: "body-test",
  apply-to: "**/*.md",
  description: "Test body sections",
  sections: (
    (heading: "Table Section", body: "\n| A | B |\n|---|---|\n| 1 | 2 |"),
    (heading: "Prose Section", body: "\nSome introductory text.\n\n- bullet one\n- bullet two"),
    (heading: "Prohibited", body: "\n- Do not do X\n- Do not do Y"),
    (heading: "Code Section", body: "\nExample:\n```nix\n{ pkgs }: pkgs.hello\n```"),
  ),
)

#let body-rendered = render-instruction(body-instr)

// Body content renders as raw Markdown
#assert(body-rendered.contains("## Table Section\n\n| A | B |"), message: "T8a: table body renders with blank line")
#assert(body-rendered.contains("| 1 | 2 |"), message: "T8b: table rows present")
#assert(body-rendered.contains("## Prose Section\n\nSome introductory text."), message: "T8c: prose body")
#assert(body-rendered.contains("- bullet one"), message: "T8d: bullets in body")
#assert(body-rendered.contains("## Prohibited\n\n- Do not do X"), message: "T8e: inline Prohibited section")
#assert(body-rendered.contains("```nix"), message: "T8f: code block in body")

// Prohibited section is inline — no auto-appended Prohibited
#let prohibited-count = body-rendered.matches("## Prohibited").len()
#assert(prohibited-count == 1, message: "T8g: exactly one Prohibited section (inline, no auto-append)")

// No References section (none specified)
#assert(not body-rendered.contains("## References"), message: "T8h: no references section")

// Mixed: body + items in same instruction
#let mixed-instr = p-instruction(
  id: "mixed-test",
  apply-to: "**/*.nix",
  sections: (
    (heading: "Rules", items: ("Rule one", "Rule two")),
    (heading: "Details", body: "\n| Col1 | Col2 |\n|------|------|\n| a | b |"),
  ),
  prohibited: ("No bad things",),
)

#let mixed-rendered = render-instruction(mixed-instr)
#assert(mixed-rendered.contains("## Rules\n- Rule one"), message: "T8i: items section in mixed")
#assert(mixed-rendered.contains("## Details\n\n| Col1 | Col2 |"), message: "T8j: body section in mixed")
#assert(mixed-rendered.contains("## Prohibited\n- No bad things"), message: "T8k: auto-appended Prohibited in mixed (no inline)")


#align(center)[
  = PROSE Tests Passed!
]
