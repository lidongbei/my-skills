# my-skills

A single standard agent skills plugin containing two skills: `team-memory` and `idea-shaping`.

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
│   └── team-memory/
│       ├── SKILL.md
│       └── evals/
│           └── evals.json
├── adapters/                # runtime-specific install notes
└── scripts/                 # validation and sync helpers
```

## Included Skills

- `team-memory` — curates reusable memory into project/team memory or cross-project habits.
- `idea-shaping` — shapes product, feature, project, startup, side-project, or internal-tool ideas when explicitly invoked.

## Canonical Rules

Use `PROJECT_SPEC.md` as the source of truth for adding or changing skills.

Core rules:

- The repository root is the plugin root.
- `.claude-plugin/plugin.json` is the canonical plugin manifest.
- Skills live directly under `skills/<skill-name>/SKILL.md`.
- This plugin currently contains exactly `team-memory` and `idea-shaping`.

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
