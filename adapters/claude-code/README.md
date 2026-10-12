# Claude Code Adapter

This repository is a single Claude Code plugin. The plugin root is the repository root, and its manifest is `.claude-plugin/plugin.json`.

## Install the Plugin

For a temporary development load in the current session:

```powershell
claude --plugin-dir D:\AI\my-skills
```

For a persistent user-level installation of the whole plugin, validate first, then register the repository's local marketplace and install the plugin with Claude Code's native commands:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
claude plugin marketplace add D:\AI\my-skills
claude plugin install my-skills@my-skills
```

This installs one `my-skills@my-skills` plugin containing all seven skills, rather than copying separate skills into `~/.claude/skills`.

Add `--scope project` or `--scope local` to either native command when the plugin should be limited to a project or local configuration:

```powershell
claude plugin install my-skills@my-skills --scope project
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

## Output Root Configuration

`coding-workflow` and `generating-reqable-docs` share an output root. The value is machine-specific and stored per-developer in the git-ignored `.agents/my-skills-local-config.md` as an `agent-output-root` managed block, read/written through the `using-tool` runtime mapping. It is never written into the shared `CLAUDE.md`.

## Skill Directory Install And Sync Helper

`~/.claude/skills` is a legacy user-skill directory. The plugin installer does not write there. If another runtime specifically needs copied skill directories, use `scripts/install-agent-skills.ps1` (which links or copies skill directories into agent tool roots), or `scripts/sync-from-claude.ps1` (which copies skill directories back from `~/.claude/skills` into this repository), and treat those copies as independent from the installed plugin.

## Policy

`D:\AI\my-skills` is the source project for this single plugin. Prefer updating the source repository and reinstalling/updating the plugin instead of editing installed copies independently.
