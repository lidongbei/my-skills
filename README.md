# my-skills

A small personal skills plugin. It provides reusable `SKILL.md` skills that can be installed into Claude Code or copied into other agent runtimes that understand `SKILL.md` directories.

Current skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`

## Install For Claude Code

Claude Code loads user-level skills from:

```text
~/.claude/skills
```

On Windows this usually resolves to:

```text
%USERPROFILE%\.claude\skills
```

Preview what will be installed:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Install all approved skills:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

Install into a custom Claude Code skills directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -Target "C:\Users\you\.claude\skills"
```

The installer validates the plugin first, then replaces the installed copies of the approved skills.

## Use In Claude Code

These built-in skills are user-only skills. They include:

```yaml
disable-model-invocation: true
```

That means the model should not invoke them automatically. Use them explicitly with slash commands or an explicit instruction.

Examples:

```text
/my-skills:coding-workflow implement this feature
```

```text
/coding-workflow fix this bug
```

```text
/my-skills:writing-skills @docs/experience/example.md this is a failed skill-use experience
```

```text
/team-memory remember this as a reusable team convention
```

If a runtime tool rejects a user-only skill because of `disable-model-invocation: true`, the user invocation is still valid. The agent should read the matching `skills/<skill-name>/SKILL.md` file and follow it directly.

## Skill Summary

| Skill | Use explicitly when you want to... |
|---|---|
| `coding-workflow` | Plan, approve, implement, and validate non-trivial coding work with a lightweight workflow. |
| `team-memory` | Turn reusable project/team lessons or cross-project habits into durable memory. |
| `idea-shaping` | Shape a product, feature, project, startup, side-project, or internal-tool idea. |
| `writing-skills` | Create, diagnose, edit, or verify skills with a TDD-style process. |

## Install For Other Agent Runtimes

Other tools can use these skills if they support directories shaped like:

```text
<skill-name>/SKILL.md
```

Copy or symlink selected skill directories from:

```text
skills/<skill-name>
```

into the runtime's skill directory.

Common locations:

```text
~/.agents/skills/<skill-name>
~/.codex/skills/<skill-name>
```

For runtime-specific notes, see:

- `adapters/claude-code/README.md`
- `adapters/agents/AGENTS.md`
- `adapters/codex/AGENTS.md`

## Repository Layout

```text
my-skills/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── coding-workflow/
│   │   └── SKILL.md
│   ├── idea-shaping/
│   │   └── SKILL.md
│   ├── team-memory/
│   │   ├── SKILL.md
│   │   └── evals/
│   └── writing-skills/
│       ├── SKILL.md
│       └── supporting files...
├── adapters/
├── scripts/
├── PROJECT_SPEC.md
└── skills-index.md
```

## Maintain This Plugin

`PROJECT_SPEC.md` is the source of truth for adding or changing skills.

Core rules:

- Keep skills under `skills/<skill-name>/SKILL.md`.
- Keep `.claude-plugin/plugin.json` as the canonical plugin manifest.
- Keep `skills-index.md`, this README, and validation rules in sync after skill changes.
- Built-in skills are Claude Code user-only skills with `disable-model-invocation: true`.
- When creating a future skill, ask whether it should be `user-only` or `model-invocable` before writing frontmatter.

Validate the plugin:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

## Sync Notes

This repository is the source project. Avoid editing installed copies under `~/.claude/skills` independently unless you intentionally sync them back.

If you intentionally changed installed Claude Code skills and want to sync them into this repository, inspect and use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-from-claude.ps1
```
