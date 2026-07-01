# Claude Code Adapter

Claude Code loads user-level skills from:

```text
~/.claude/skills
```

On this machine:

```text
C:\Users\Administrator\.claude\skills
```

## Install

Preview installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Install the approved skills:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

The script installs:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`
- `using-tool`

## Tool Mapping Notes

Before using any skill from this plugin in Claude Code, load `using-tool`, then use:

```text
skills/using-tool/runtimes/claude-code.md
```

That runtime file maps portable tool-action instructions to Claude Code tools, usage shapes, parameters, and fallbacks.

## Policy

`D:\AI\my-skills` is the source project for this single plugin. Avoid editing installed copies under `~/.claude/skills` independently unless you intentionally sync them back with `scripts/sync-from-claude.ps1`.
