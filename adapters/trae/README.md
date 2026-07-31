# Trae IDE Adapter

Trae IDE can load `SKILL.md`-based skills when this repository is open as a Trae workspace. The skill directory layout matches what the plugin uses:

```text
D:\AI\my-skills\skills\<skill-name>\SKILL.md
```

Trae also maintains a local IDE state directory at:

```text
.trae/
```

This directory must be ignored by version control; the repository's `.gitignore` already excludes it.

## Install

No separate install step is required when the repository is the active Trae workspace. The skills under `skills/` are picked up directly.

To use the skills from another location, copy or symlink selected skill directories from:

```text
D:\AI\my-skills\skills\<skill-name>
```

into the target location Trae is configured to scan.

Current approved skills:

- `coding-workflow`
- `generating-reqable-docs`
- `team-memory`
- `idea-shaping`
- `writing-skills`
- `using-tool`

## Tool Mapping Notes

Before using any skill from this plugin in Trae IDE, load `using-tool`, then use:

```text
skills/using-tool/runtimes/trae.md
```

That runtime file maps portable tool-action aliases (`ask`, `read`, `find`, `edit`, `run`, `todo`, `agent`, `check`) to Trae IDE tools such as `Read`, `Edit`, `Write`, `Glob`, `Grep`, `LS`, `SearchCodebase`, `WebFetch`, `WebSearch`, `RunCommand`, `CheckCommandStatus`, `StopCommand`, `TodoWrite`, `Task`, `AskUserQuestion`, and `run_mcp`. It also documents the boundaries (single `TodoWrite` tool, `Task` subagent types `general_purpose_task` / `search` / `browser_use`, sandboxed PowerShell terminal).

## Policy

`D:\AI\my-skills` is the source project for this single plugin. Avoid duplicating the skills into a second location; if a copy is required, sync it back from this repository rather than editing it in place.
