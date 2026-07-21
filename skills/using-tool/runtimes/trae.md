# Trae IDE Runtime Mapping

Use this file when the current runtime is Trae IDE. It maps plugin tool-action aliases to Trae IDE tools and interaction patterns.

## Mapping Table

| Alias | Trae mapping | Notes |
|---|---|---|
| `ask` | `AskUserQuestion` for structured choices; otherwise plain chat. | Use the exact schema visible in the current session. Do not invent fields. |
| `read` | `Read` for known files/resources. | Local file paths must be absolute. The tool also accepts image files (PNG/JPG/GIF/WEBP, up to 10MB). |
| `find` | `Glob` for paths, `Grep` for content, `LS` for directory listing, `SearchCodebase` for semantic search, `WebFetch` for URL reading, `WebSearch` for web search. | Prefer dedicated tools over shell commands when they fit. |
| `edit` | `Edit` for exact replacements, `Write` for new files or full replacements. | `Edit` requires the file to be read first. Use `replace_all: true` for renames. |
| `run` | `RunCommand` for shell execution; `CheckCommandStatus`/`StopCommand` for async commands. | Trae runs PowerShell. The terminal is sandboxed via `trae-sandbox`; non-idle terminals will kill running commands. |
| `todo` | `TodoWrite` (only one todo tool). | Use for multi-step work; skip for trivial one-step tasks. There is no separate `TaskList`/`TaskUpdate` — pass `merge: true` to update existing items. |
| `agent` | `Task` for delegated work, with `subagent_type` of `general_purpose_task`, `search`, or `browser_use`. | Reserve `browser_use` for actual browser tasks. Use `search` for read-only exploration; `general_purpose_task` for write/edit work. |
| `check` | Command output via `RunCommand`, file inspection via `Read`/`Grep`, diffs via git in `RunCommand`, or `run_mcp` for MCP tools. | State concrete evidence. |

## Usage Patterns

### `ask`

Use `AskUserQuestion` when the user must choose among concrete options. Typical shape:

```json
{
  "questions": [{
    "question": "Which mode should this skill use?",
    "header": "Mode",
    "multiSelect": false,
    "options": [
      {"label": "user-only", "description": "Only explicit user invocation can use it."},
      {"label": "model-invocable", "description": "The model may load it when triggers match."}
    ]
  }]
}
```

For a simple clarification without structured choices, ask directly in chat:

```markdown
I need one missing fact before continuing: what was the actual agent behavior?
```

### `read` / `find`

Use `Read` for a known file or resource. Typical shape:

```json
{
  "file_path": "D:\\AI\\my-skills\\skills\\using-tool\\SKILL.md",
  "limit": 2000,
  "offset": 0
}
```

Use `Glob` for path discovery. Typical shape:

```json
{
  "path": "D:\\AI\\my-skills",
  "pattern": "skills/using-tool/runtimes/*.md"
}
```

Use `Grep` for content search. Typical shape:

```json
{
  "path": "D:\\AI\\my-skills",
  "pattern": "AskUserQuestion|TodoWrite|run_mcp",
  "glob": "*.md",
  "output_mode": "content",
  "head_limit": 50
}
```

Use `SearchCodebase` for semantic "how/where/what" questions. Use `WebFetch` for URL reading. Do not use shell `cat`, `grep`, or `find` when the dedicated tools fit.

### `edit`

Use `Edit` for exact replacements after reading the file. Typical shape:

```json
{
  "file_path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes\\trae.md",
  "old_string": "exact text already read from the file",
  "new_string": "replacement text",
  "replace_all": false
}
```

Use `Write` for a new file or a full replacement of a file already read. Typical shape:

```json
{
  "file_path": "D:\\AI\\my-skills\\docs\\plans\\example.md",
  "content": "# Plan\n\n..."
}
```

If a source instruction says `apply_patch`, preserve the edit intent and use `Edit`/`Write` unless applying a patch through an available command is the safest option. Do not copy another runtime's patch format as if it were a Trae tool call.

### `run`

Use `RunCommand` for commands, tests, builds, and validation. Typical shape:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "cwd": "D:\\AI\\my-skills",
  "requires_approval": false,
  "command_type": "short_running_process",
  "blocking": true
}
```

For long-running servers, set `blocking: false`, then poll with `CheckCommandStatus` using the returned `command_id`. Use `StopCommand` to terminate. The terminal is stateful across sequential `RunCommand` calls.

When the intent is only file search or file reading, prefer dedicated tools over shell. Use `RunCommand` only when executing a command is the actual action.

### `todo`

Use `TodoWrite` for multi-step work. Typical flow to create a new list:

```json
{
  "merge": false,
  "todos": [
    {"content": "Diagnose missing runtime examples", "id": "1", "priority": "high", "status": "pending"},
    {"content": "Update Trae mapping examples", "id": "2", "priority": "high", "status": "pending"},
    {"content": "Run validation", "id": "3", "priority": "high", "status": "pending"}
  ]
}
```

Update an existing item by `id`:

```json
{
  "merge": true,
  "todos": [
    {"id": "1", "status": "completed", "summary": "Identified gaps in the Trae mapping."}
  ]
}
```

Only one todo is `in_progress` at a time. Skip todo tracking for trivial one-step tasks. If a source instruction names Claude Code `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet`, translate the tracking intent to `TodoWrite`; do not claim those Claude Code tools exist.

### `agent`

Use `Task` for independent exploration, review, or delegated work. Typical read-only shape:

```json
{
  "description": "Review runtime examples",
  "query": "Read the using-tool runtime files and identify missing alias usage examples. Return only gaps and suggested fixes.",
  "subagent_type": "search",
  "response_language": "zh"
}
```

Typical write/edit shape:

```json
{
  "description": "Apply skill fixes",
  "query": "Apply the planned edits to skills/coding-workflow/SKILL.md and report the diff.",
  "subagent_type": "general_purpose_task",
  "response_language": "zh"
}
```

For browser-based verification, use `subagent_type: "browser_use"`. There is no `Workflow` tool — do not invent a multi-agent orchestration primitive.

### `check`

Use concrete evidence: command output, inspected files, reviewed diffs, or MCP tool results. Typical validation command:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "cwd": "D:\\AI\\my-skills",
  "requires_approval": false,
  "command_type": "short_running_process",
  "blocking": true
}
```

Typical inspection search:

```json
{
  "path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes",
  "pattern": "Typical shape|AskUserQuestion|TodoWrite",
  "glob": "*.md",
  "output_mode": "content"
}
```

For MCP-backed checks, use `run_mcp` with the matching server and tool names. Do not claim validation without evidence. If a check was skipped, say it was skipped.

## Trae Boundaries

- Trae exposes a single `TodoWrite` tool, not the Claude Code `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet` family. Translate tracking intent instead of copying the four-tool pattern.
- Trae subagents are dispatched through `Task` with `subagent_type` of `general_purpose_task`, `search`, or `browser_use`. There is no `Explore` subagent type and no `Workflow` orchestration tool.
- `RunCommand` runs in a sandboxed PowerShell terminal. Long-running commands must be non-blocking and polled with `CheckCommandStatus`. Non-idle terminals will kill running commands.
- `Edit` requires the file to have been read in the same session; otherwise it fails.
- `Read` ignores `offset`/`limit` for image files and has a 10MB image cap.
- If a user-only skill invocation through `Skill` fails because of `disable-model-invocation: true`, read the matching `skills/<skill-name>/SKILL.md` directly and follow it.
- Do not translate an explicit Trae prohibition into an alias. Example: `Do not use Workflow` would mean there is no Workflow tool, so do not invent one.
