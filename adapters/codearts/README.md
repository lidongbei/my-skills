# CodeArts Adapter

This adapter targets CodeArts (华为云码道), the Huawei Cloud code agent. CodeArts loads `SKILL.md`-based skills when this repository is opened as a CodeArts workspace, and also maintains a local state directory at:

```text
.codeartsdoer/
```

This directory must be ignored by version control; the repository's `.gitignore` already excludes it.

## Install

### Option 1: In-workspace (recommended)

No separate install step is required when the repository is the active CodeArts workspace. The skills under `skills/` are picked up directly via the plugin manifest at `.claude-plugin/plugin.json`.

### Option 2: Copy into another project (recommended for CodeArts)

Copy selected skill directories as **real files** into the target project's CodeArts skill location:

```text
<Target>\.codeartsdoer\skills\<skill-name>
```

Use the helper script:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-codearts.ps1 -WhatIf -Target "D:\other-project"
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-codearts.ps1 -Target "D:\other-project"
```

The script validates the plugin first, then **copies real files** (not junctions) for each approved skill and writes `ProjectSkillStatus.txt` with one `<skill-name>=true` line per skill so CodeArts registers them as enabled.

> Why copy, not link: CodeArts does not follow directory junctions or symlinks when discovering skills. Real files are required. Re-run the script to refresh copies after updating skills in this source repository.

### Option 3: Shared cross-runtime location

Copy or symlink selected skill directories into:

```text
~/.agents/skills/<skill-name>
```

See `adapters/agents/AGENTS.md` for the shared portable layout.

## Approved Skills

- `coding-workflow`
- `generating-reqable-docs`
- `team-memory`
- `idea-shaping`
- `session-handoff-save`
- `session-handoff-load`
- `writing-skills`
- `using-tool`

## Tool Mapping Notes

Before using any skill from this plugin in CodeArts, load `using-tool`, then use:

```text
skills/using-tool/runtimes/codearts.md
```

That runtime file maps portable tool-action aliases (`ask`, `read`, `find`, `edit`, `run`, `todo`, `agent`, `check`) to CodeArts tools such as `question`, `read`, `glob`, `grep`, `edit`, `write`, `deleteFile`, `bash`, `todowrite`, `task`, `webfetch`, `CodeSemanticSearch`, `CodeGraphSearch`, `RagSearch`, `analyzeImage`, `skill`, `cronCreate`/`cronDelete`/`cronList`, and `tool_search`/`tool_describe`/`tool_call`.

## CodeArts-Specific Capabilities

CodeArts provides several tools that have no direct equivalent in Claude Code, Codex, or Trae:

| CodeArts tool | Use for |
|---|---|
| `CodeSemanticSearch` | Semantic "how/where/what" code questions. Prefer over `grep` for behavioral queries. |
| `CodeGraphSearch` | Structural relevance: call chains, dependencies, impact radius. Use `graph_depth` 1 for direct callers, 2 for transitive context, 3 for broad impact. |
| `RagSearch` | Enterprise knowledge base retrieval. |
| `analyzeImage` | Image analysis (OCR, objects, layout, colors, safety). |
| `skill` | Load specialized skills (system and cloud_enterprise scopes). |
| `cronCreate`/`cronDelete`/`cronList` | Scheduled task management. |
| `tool_search`/`tool_describe`/`tool_call` | MCP tool discovery and invocation. |
| `browser` | Open URLs in the built-in browser. |

## CodeArts Constraints

- Only one `task` call per response; do not invoke multiple `task` tools in parallel.
- `bash` runs PowerShell on win32. Use `workdir` instead of `cd <dir> &&`.
- `edit` requires the file to have been read in the same session.
- `question` auto-adds a "Type your own answer" option; do not include catch-all "Other" options.
- `deleteFile` only deletes files, not directories.
- Communication must be in Simplified Chinese per project CLAUDE.md.
- **Skill discovery requires real files.** CodeArts does not follow directory junctions or symlinks. The install script copies real files and writes `ProjectSkillStatus.txt` (`<skill-name>=true` per line) to register skills.

## Policy

`D:\AI\my-skills` is the source project for this single plugin. Avoid duplicating the skills into a second location; if a copy is required, sync it back from this repository rather than editing it in place.