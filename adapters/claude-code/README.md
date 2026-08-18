# Claude Code Adapter

This repository is a single Claude Code plugin. The plugin root is the repository root, and its manifest is `.claude-plugin/plugin.json`.

## Install the Plugin

For a temporary development load in the current session:

```powershell
claude --plugin-dir D:\AI\my-skills
```

For a persistent user-level installation of the whole plugin, preview first:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Then install:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

The helper registers the repository's local marketplace and invokes Claude Code's native plugin installer. It installs one `my-skills@my-skills` plugin containing all eight skills, rather than copying separate skills into `~/.claude/skills`.

Use `-Scope project` or `-Scope local` when the plugin should be limited to a project or local configuration:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -Scope project
```

Inspect or remove the persistent installation with native commands:

```powershell
claude plugin list
claude plugin details my-skills
claude plugin uninstall my-skills@my-skills
```

## Tool Mapping Notes

Before using any skill from this plugin in Claude Code, load `using-tool`, then use:

```text
skills/using-tool/runtimes/claude-code.md
```

That runtime file maps portable tool-action instructions to Claude Code tools, usage shapes, parameters, and fallbacks.

## Separate Skill Copy Utility

`~/.claude/skills` is a legacy user-skill directory. The plugin installer does not write there. If another runtime specifically needs copied skill directories, use the separate sync utilities and treat those copies as independent from the installed plugin.

## Policy

`D:\AI\my-skills` is the source project for this single plugin. Prefer updating the source repository and reinstalling/updating the plugin instead of editing installed copies independently.
