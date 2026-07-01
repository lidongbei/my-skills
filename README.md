# my-skills

`my-skills` is a single Claude Code plugin that packages five agent skills.

The plugin root is this repository. Its canonical plugin manifest is:

```text
.claude-plugin/plugin.json
```

Included skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`
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

- `coding-workflow`, `team-memory`, `idea-shaping`, and `writing-skills` are user-only skills. Their frontmatter includes `disable-model-invocation: true`, so the model should not invoke them automatically.
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
| `team-memory` | user-only | You explicitly want to turn reusable project/team lessons or cross-project habits into durable memory. |
| `idea-shaping` | user-only | You explicitly want to shape a product, feature, project, startup, side-project, or internal-tool idea. |
| `writing-skills` | user-only | You explicitly want to create, diagnose, edit, or verify skills with a TDD-style process. |
| `using-tool` | model-invocable | Before using any skill from this plugin, to adapt portable tool-use instructions to the current runtime. |

## Optional: Sync Skills Into Claude Code User Skills

The preferred Claude Code path is plugin loading with `--plugin-dir`. If you specifically need user-level skill copies under `~/.claude/skills`, use the helper script.

Preview the sync:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Copy approved skills into `~/.claude/skills`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

Copy into a custom target directory:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -Target "C:\Users\you\.claude\skills"
```

This script validates the plugin first, then replaces the installed skill copies. Treat this as a sync/copy workflow, not the primary plugin workflow.

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
│   └── plugin.json
├── skills/
│   ├── coding-workflow/
│   │   └── SKILL.md
│   ├── idea-shaping/
│   │   └── SKILL.md
│   ├── team-memory/
│   │   ├── SKILL.md
│   │   └── evals/
│   ├── using-tool/
│   │   ├── SKILL.md
│   │   └── runtimes/
│   │       ├── claude-code.md
│   │       └── codex.md
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
