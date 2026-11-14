# Agent Ecosystem

This folder is the single home for project knowledge, specialised agent roles,
normative rules, repeatable skills, and templates. `../AGENTS.md` is the
entry point; everything here is loaded on demand by OpenCode.

**Read `.opencode/rules/authority.md` first. It is absolute and overrides all
other guidance.**

## Layout

```text
.opencode/
  opencode.jsonc       Project config: default agent and skill paths.
  README.md            How the ecosystem works.
  .opencode/              Agent role cards (OpenCode agents).
  rules/               Normative project rules.
  skills/              Repeatable procedures (add provider, artwork, verify, publish).
  templates/           Copy-paste scaffolds.
  context/             Architecture, decisions, roadmap, known issues.
```

## How the pieces relate

- A **rule** is a constraint. It says "must" or "must not" and wins over
  convenience.
- An **agent** is a role. It says what to focus on, what to read first, and when
  to stop and report.
- A **skill** is a procedure. It is a numbered workflow with checks and an exit
  condition.
- A **template** is a scaffold. Copy it, then delete the guidance comments.
- **context** is memory. It records architecture, decisions, and open work so a
  fresh agent does not rediscover everything.

When a task spans areas, load the narrowest rule set and one agent role, then
only the skills the task actually needs.

## Load order

1. `../AGENTS.md`
2. One agent role from `.opencode/`
3. The rule files listed in that role
4. One or more skills from `skills/`
5. `context/architecture.md` and `context/roadmap.md` if the task is larger than
   a single edit

## Adding an agent

1. Copy `templates/agent.md.template` to `.opencode/<name>.md`.
2. Give it one clear responsibility and an explicit "do not" list.
3. List the rules and skills it should load.
4. Add it to the routing table in `../AGENTS.md`.

## Adding a rule

1. Copy `templates/rule.md.template` to `rules/<topic>.md`.
2. State the rule, why it exists, and how to verify compliance.
3. Reference the rule from the agent roles that depend on it.

Rules must describe constraints already implied by the code or the user's
requirements. Do not invent policy that the project does not follow.

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` from `templates/skill.md.template`.
2. Give it YAML frontmatter with `name` and `description` so it stays
   compatible with skill-aware tooling.
3. Include trigger conditions, numbered steps, verification, and failure modes.
4. Add it to the routing table in `../AGENTS.md` if it is commonly needed.

## Adding a template

Place it in `templates/`. Name it after the artifact it produces, for example
`provider.ps1.template`. Templates must be copy-safe: no absolute user paths and
no project-specific secrets.

## Conventions

- Markdown files are ASCII-only, like the PowerShell sources.
- Use `backticks` for file names, flags, functions, and config keys.
- Prefer relative paths from the repository root.
- Keep each file focused. Split a rule when it grows past a screen or two.
- Update `context/decisions.md` when a durable choice is made.
- Update `context/roadmap.md` when work starts or finishes.

## Research standards

All agents must follow `.opencode/rules/research-standards.md`: no guesswork,
no fabrication, research first, verify every claim.

