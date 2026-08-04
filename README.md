# my-skills

`my-skills` is a single Claude Code plugin that packages eight agent skills.

The plugin root is this repository. Its canonical plugin manifest is:

```text
.claude-plugin/plugin.json
```

Included skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `session-handoff-save`
- `session-handoff-load`
- `writing-skills`
- `generating-reqable-docs`
- `using-tool`

## Use As A Claude Code Plugin

From the parent directory of this repository, start Claude Code with this plugin directory:

```powershell
claude --plugin-dir ./my-skills
```

From inside this repository, use:

```powershell
claude --plugin-dir .
```

You can also pass an absolute path:

```powershell
claude --plugin-dir D:\AI\my-skills
```

During development, reload changed plugins from inside Claude Code:

```text
/reload-plugins
```

List loaded plugins:

```text
/plugin list
```

## Use The Skills

Invocation modes:

- `coding-workflow`, `generating-reqable-docs`, `team-memory`, `idea-shaping`, `session-handoff-save`, `session-handoff-load`, and `writing-skills` are user-only skills. Their frontmatter includes `disable-model-invocation: true`, so the model should not invoke them automatically.
- `using-tool` is model-invocable and mandatory before using any skill from this plugin. Agents must load it first, then load the runtime mapping file for the current agent/runtime before executing the target skill.

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

| Skill | Mode | Use when... |
|---|---|---|
| `coding-workflow` | user-only | You explicitly want to plan, approve, implement, and validate non-trivial coding work with a lightweight workflow. |
| `generating-reqable-docs` | user-only | You explicitly want to generate a Reqable Collection 3.0 JSON interface document from an API definition or reference collection. |
| `team-memory` | user-only | You explicitly want to turn reusable project/team lessons or cross-project habits into durable memory. |
| `idea-shaping` | user-only | You explicitly want to shape a product, feature, project, startup, side-project, or internal-tool idea. |
| `session-handoff-save` | user-only | You explicitly want to save a temporary current-session handoff for a future session. |
| `session-handoff-load` | user-only | You explicitly want to choose and load an indexed temporary session handoff. |
| `writing-skills` | user-only | You explicitly want to create, diagnose, edit, or verify skills with a TDD-style process. |
| `using-tool` | model-invocable | Before using any skill from this plugin, to adapt portable tool-use instructions to the current runtime. |

## Optional: Persistently Install This Claude Code Plugin

The preferred development path is loading the repository for the current session:

```powershell
claude --plugin-dir .
```

To persistently install the entire repository as one Claude Code plugin, run:

Preview the installation without changing Claude Code configuration:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Install for the current user (the default, available across projects):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

Install with another Claude Code scope:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -Scope project
```

The script validates the repository, registers its local marketplace, and runs Claude Code's native `plugin install` command. It installs one `my-skills` plugin containing all eight skills; it does not copy separate skill directories into `~/.claude/skills`.

Inspect or remove the persistent installation with Claude Code's native commands:

```powershell
claude plugin list
claude plugin details my-skills
claude plugin uninstall my-skills@my-skills
```

## Optional: Sync Skills Into Claude Code User Skills

If you specifically need user-level skill copies under `~/.claude/skills` for a non-plugin runtime, use the legacy copy helper. This is separate from the primary Claude Code plugin installation workflow.

Preview the sync:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-from-claude.ps1 -WhatIf
```

This script is a copy/sync utility, not the plugin installer.

## Use With Other Agent Runtimes

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

Before using any skill from this plugin in another agent runtime, load `using-tool` first, then load the matching runtime file under `skills/using-tool/runtimes/`. The runtime file explains how portable tool-action aliases such as `ask`, `read`, `find`, `edit`, `run`, `todo`, `agent`, and `check` map to that runtime's actual tools or interaction patterns.

For runtime-specific notes, see:

- `adapters/claude-code/README.md`
- `adapters/agents/AGENTS.md`
- `adapters/codex/AGENTS.md`

## Repository Layout

```text
my-skills/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   ├── coding-workflow/
│   │   └── SKILL.md
│   ├── generating-reqable-docs/
│   │   └── SKILL.md
│   ├── idea-shaping/
│   │   └── SKILL.md
│   ├── session-handoff-load/
│   │   └── SKILL.md
│   ├── session-handoff-save/
│   │   └── SKILL.md
│   ├── team-memory/
│   │   ├── SKILL.md
│   │   └── evals/
│   ├── using-tool/
│   │   ├── SKILL.md
│   │   └── runtimes/
│   │       ├── claude-code.md
│   │       ├── codex.md
│   │       └── trae.md
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

- The repository root is the plugin root.
- Keep `.claude-plugin/plugin.json` as the canonical plugin manifest.
- Keep runtime skills under `skills/<skill-name>/SKILL.md`.
- Keep `skills-index.md`, this README, and validation rules in sync after skill changes.
- Existing user-only skills must remain user-only with `disable-model-invocation: true` unless the user explicitly approves a behavior change.
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
