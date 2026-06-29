# my-skills

A single standard agent skills plugin containing three skills: `team-memory`, `idea-shaping`, and `writing-skills`.

## Layout

```text
my-skills/
├── .claude-plugin/
│   └── plugin.json          # canonical plugin manifest
├── PROJECT_SPEC.md          # rules for maintaining this plugin
├── skills-index.md          # human-readable skill index
├── skills/
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

- `team-memory` — curates reusable memory into project/team memory or cross-project habits.
- `idea-shaping` — shapes product, feature, project, startup, side-project, or internal-tool ideas when explicitly invoked.
- `writing-skills` — creates, edits, and verifies skills with a TDD-style workflow before deployment.

## Canonical Rules

Use `PROJECT_SPEC.md` as the source of truth for adding or changing skills.

Core rules:

- The repository root is the plugin root.
- `.claude-plugin/plugin.json` is the canonical plugin manifest.
- Skills live directly under `skills/<skill-name>/SKILL.md`.
- This plugin currently contains exactly `team-memory`, `idea-shaping`, and `writing-skills`.

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
