# my-skills

A single standard agent skills plugin containing four skills: `coding-workflow`, `team-memory`, `idea-shaping`, and `writing-skills`.

## Layout

```text
my-skills/
├── .claude-plugin/
│   └── plugin.json          # canonical plugin manifest
├── PROJECT_SPEC.md          # rules for maintaining this plugin
├── skills-index.md          # human-readable skill index
├── skills/
│   ├── coding-workflow/
│   │   └── SKILL.md
│   ├── idea-shaping/
│   │   └── SKILL.md
│   ├── team-memory/
│   │   ├── SKILL.md
│   │   └── evals/
│   │       └── evals.json
│   └── writing-skills/
│       ├── SKILL.md
│       ├── anthropic-best-practices.md
│       ├── graphviz-conventions.dot
│       ├── persuasion-principles.md
│       ├── testing-skills-with-subagents.md
│       └── examples/
│           └── CLAUDE_MD_TESTING.md
├── adapters/                # runtime-specific install notes
└── scripts/                 # validation and sync helpers
```

## Included Skills

All built-in skills are Claude Code user-only skills: they require explicit user invocation and include `disable-model-invocation: true` so the model cannot invoke them on its own. For future skills, choose `user-only` or `model-invocable` during skill creation.

`writing-skills` uses agent-mode planning: it clarifies with the user interactively and outputs modification plans directly, without Claude Code plan mode.

- `coding-workflow` — runs the approved coding workflow only when explicitly invoked.
- `team-memory` — curates reusable memory into project/team memory or cross-project habits only when explicitly invoked.
- `idea-shaping` — shapes product, feature, project, startup, side-project, or internal-tool ideas when explicitly invoked.
- `writing-skills` — creates, edits, and verifies skills with a TDD-style workflow only when explicitly invoked.

## Canonical Rules

Use `PROJECT_SPEC.md` as the source of truth for adding or changing skills.

Core rules:

- The repository root is the plugin root.
- `.claude-plugin/plugin.json` is the canonical plugin manifest.
- Skills live directly under `skills/<skill-name>/SKILL.md`.
- This plugin currently contains exactly `coding-workflow`, `team-memory`, `idea-shaping`, and `writing-skills`.
- The built-in skills are Claude Code user-only skills with `disable-model-invocation: true`; future skills must ask the user to choose `user-only` or `model-invocable` during creation.
- Skill descriptions must require explicit invocation and must not use broad semantic task categories as auto-trigger descriptions.

## Validation

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

## Claude Code Usage

Claude Code user-level skills live under:

```text
~/.claude/skills
```

Install this plugin's skills with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

Preview installation with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

## Codex And Shared Agent Usage

Tools that consume `SKILL.md` directories can copy or symlink selected directories from `skills/` into their runtime skill directories. See `adapters/` for runtime-specific notes.
