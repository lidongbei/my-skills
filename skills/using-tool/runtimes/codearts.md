# CodeArts Runtime Mapping

Use this file when the current runtime is CodeArts (华为云码道). It maps plugin tool-action aliases to CodeArts tools and interaction patterns without assuming Claude Code, Codex, or Trae tool names or schemas exist.

## Mapping Table

| Alias | CodeArts mapping | Notes |
|---|---|---|
| `ask` | `question` for structured choices; otherwise plain chat. | Use the exact schema visible in the current session. `questions` is an array; each item needs `question`, `header`, and `options` (array of `{label, description}`). Set `multiple: true` to allow multi-select. |
| `read` | `read` for known files/directories. | Supports text, images (PNG/JPG/etc.), and PDFs. Use `offset`/`limit` for large files. Directory reads return entries one per line. |
| `find` | `glob` for paths, `grep` for content, `CodeSemanticSearch` for semantic "how/where/what", `CodeGraphSearch` for call chains/impact, `webfetch` for URL reading, `RagSearch` for enterprise knowledge bases. | Prefer dedicated tools over shell commands. Use `CodeGraphSearch` for structural impact analysis; use `CodeSemanticSearch` for behavior questions. |
| `edit` | `edit` for exact replacements, `write` for new files or full replacements, `deleteFile` for deletion. | `edit` requires the file to be read first. Use `replaceAll: true` to replace every occurrence. `deleteFile` takes an array of absolute paths. |
| `run` | `bash` for shell execution. | CodeArts runs PowerShell on win32. Use `workdir` instead of `cd <dir> &&`. Default timeout is 120000ms. Avoid `find`/`grep`/`cat`/`sed`/`awk`/`echo` in favor of dedicated tools. |
| `todo` | `todowrite` (only one todo tool). | Use for multi-step work; skip for trivial one-step tasks. Each todo has `content`, `status` (`pending`/`in_progress`/`completed`/`cancelled`), and `priority` (`high`/`medium`/`low`). Only one `in_progress` at a time. |
| `agent` | `task` for delegated work, with `subagent_type` of `explore`, `general`, `bug-fix-agent`, `developer-test-agent`, `spec-design-agent`, `spec-requirement-agent`, `spec-task-agent`, `rule-generator`, `hmos-build-fixer`, or `hmos-logic-coder`. | Use `explore` for read-only codebase exploration, `general` for multi-step work, `bug-fix-agent` for issue resolution, `developer-test-agent` for unit tests. Only one `task` call per response. |
| `check` | Command output via `bash`, file inspection via `read`/`grep`, diffs via git in `bash`, semantic verification via `CodeSemanticSearch`, structural impact via `CodeGraphSearch`, or MCP tools via `tool_search`/`tool_describe`/`tool_call`. | State concrete evidence. Do not claim validation without evidence. |

## Usage Patterns

### `ask`

Use `question` when the user must choose among concrete options. Typical shape:

```json
{
  "questions": [{
    "question": "Which mode should this skill use?",
    "header": "Mode",
    "options": [
      {"label": "user-only", "description": "Only explicit user invocation can use it."},
      {"label": "model-invocable", "description": "The model may load it when triggers match."}
    ],
    "multiple": false
  }]
}
```

A "Type your own answer" option is added automatically when `custom` is enabled (default); do not include catch-all "Other" options.

For a simple clarification without structured choices, ask directly in chat:

```markdown
我需要一个缺失信息才能继续：实际的 agent 行为是什么？
```

### `read` / `find`

Use `read` for a known file or resource. Typical shape:

```json
{
  "filePath": "D:\\AI\\my-skills\\skills\\using-tool\\SKILL.md",
  "offset": 1,
  "limit": 2000
}
```

Use `glob` for path discovery. Typical shape:

```json
{
  "pattern": "skills/using-tool/runtimes/*.md",
  "path": "D:\\AI\\my-skills"
}
```

Use `grep` for content search. Typical shape:

```json
{
  "pattern": "question|todowrite|task",
  "include": "*.md",
  "path": "D:\\AI\\my-skills"
}
```

Use `CodeSemanticSearch` for semantic "how/where/what" questions. Typical shape:

```json
{
  "query": "Where are errors from the client handled?"
}
```

Use `CodeGraphSearch` for structural relevance (call chains, dependencies, impact radius). Typical shape:

```json
{
  "query": "How does a request reach OrderController?",
  "top_k": 10,
  "graph_depth": 2
}
```

Use `webfetch` for URL reading when web access is needed. Use `RagSearch` for enterprise knowledge base retrieval. Do not use shell `cat`, `grep`, or `find` when the dedicated tools fit.

### `edit`

Use `edit` for exact replacements after reading the file. Typical shape:

```json
{
  "filePath": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes\\codearts.md",
  "oldString": "exact text already read from the file",
  "newString": "replacement text",
  "replaceAll": false
}
```

Use `write` for a new file or a full replacement of a file already read. Typical shape:

```json
{
  "filePath": "D:\\AI\\my-skills\\docs\\plans\\example.md",
  "content": "# Plan\n\n..."
}
```

Use `deleteFile` to delete one or more files. Typical shape:

```json
{
  "file_paths": ["D:\\AI\\my-skills\\docs\\plans\\stale.md"]
}
```

If a source instruction says `apply_patch`, preserve the edit intent and use `edit`/`write` unless applying a patch through an available command is the safest option. Do not copy another runtime's patch format as if it were a CodeArts tool call.

### `run`

Use `bash` for commands, tests, builds, and validation. Typical shape:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "description": "Validate plugin shape",
  "workdir": "D:\\AI\\my-skills",
  "timeout": 120000
}
```

CodeArts runs PowerShell on win32. Use the `workdir` parameter instead of `cd <dir> && <command>` patterns. Run independent commands in parallel by issuing multiple `bash` tool calls in a single message; chain dependent commands with `&&`. Avoid `find`/`grep`/`cat`/`head`/`tail`/`sed`/`awk`/`echo` in `bash` when dedicated tools fit.

### `todo`

Use `todowrite` for multi-step work. Typical flow to create a new list:

```json
{
  "todos": [
    {"content": "Diagnose missing runtime examples", "status": "pending", "priority": "high"},
    {"content": "Update CodeArts mapping examples", "status": "pending", "priority": "high"},
    {"content": "Run validation", "status": "pending", "priority": "high"}
  ]
}
```

Update an item by replacing the full `todos` array with the new state:

```json
{
  "todos": [
    {"content": "Diagnose missing runtime examples", "status": "completed", "priority": "high"},
    {"content": "Update CodeArts mapping examples", "status": "in_progress", "priority": "high"},
    {"content": "Run validation", "status": "pending", "priority": "high"}
  ]
}
```

Only one todo is `in_progress` at a time. Skip todo tracking for trivial one-step tasks. If a source instruction names Claude Code `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet` or Trae `TodoWrite` with `merge`, translate the tracking intent to a single `todowrite` call with the full updated list; do not claim those other tools exist in CodeArts.

### `agent`

Use `task` for independent exploration, review, or delegated work. Typical read-only shape:

```json
{
  "subagent_type": "explore",
  "description": "Review runtime examples",
  "prompt": "Read the using-tool runtime files and identify missing alias usage examples. Return only gaps and suggested fixes."
}
```

Typical write/edit shape:

```json
{
  "subagent_type": "general",
  "description": "Apply skill fixes",
  "prompt": "Apply the planned edits to skills/coding-workflow/SKILL.md and report the diff."
}
```

Available `subagent_type` values:

- `explore` — read-only codebase exploration (quick/medium/very thorough).
- `general` — multi-step research and execution.
- `bug-fix-agent` — issue analysis, fault localization, patch implementation.
- `developer-test-agent` — unit test generation, repair, coverage optimization.
- `spec-design-agent` / `spec-requirement-agent` / `spec-task-agent` — spec-driven development pipeline.
- `rule-generator` — rule generation.
- `hmos-build-fixer` / `hmos-logic-coder` — HarmonyOS/ArkTS toolchain.

Only one `task` call per response; do not invoke multiple `task` tools in parallel. There is no `Workflow` orchestration primitive — do not invent one. To resume a previous subagent session, pass `task_id`.

### `check`

Use concrete evidence: command output, inspected files, reviewed diffs, semantic/structural search results, or MCP tool results. Typical validation command:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "description": "Validate plugin shape after changes",
  "workdir": "D:\\AI\\my-skills",
  "timeout": 120000
}
```

Typical inspection search:

```json
{
  "pattern": "Typical shape|question|todowrite",
  "include": "*.md",
  "path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes"
}
```

For MCP-backed checks, discover tools with `tool_search`, inspect schemas with `tool_describe`, then execute with `tool_call`. For scheduled-task verification, use `cronList`. For image-based verification, use `analyzeImage`. Do not claim validation without evidence. If a check was skipped, say it was skipped.

## CodeArts Boundaries

- CodeArts exposes a single `todowrite` tool, not the Claude Code `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet` family. Translate tracking intent instead of copying the four-tool pattern.
- CodeArts subagents are dispatched through `task` with a `subagent_type` from the fixed list above. There is no Claude Code `Agent`/`Explore` type and no `Workflow` orchestration tool. Only one `task` call per response.
- `bash` runs in a sandboxed PowerShell session on win32. Use `workdir` instead of `cd <dir> &&`. Default timeout is 120000ms. Avoid shell `find`/`grep`/`cat`/`sed`/`awk`/`echo` when dedicated tools fit.
- `edit` requires the file to have been read in the same session; otherwise it fails. `oldString` must be unique unless `replaceAll: true`.
- `read` supports images and PDFs as attachments; lines longer than 2000 characters are truncated.
- `deleteFile` takes an array of absolute paths and only deletes files, not directories.
- `question` auto-adds a "Type your own answer" option when `custom` is enabled (default); do not include catch-all "Other" options.
- `CodeSemanticSearch` and `CodeGraphSearch` are CodeArts-native search tools. Use them instead of `grep`/`glob` for behavioral and structural questions.
- If a user-only skill invocation through `skill` fails because of `disable-model-invocation: true`, read the matching `skills/<skill-name>/SKILL.md` directly and follow it.
- Do not translate an explicit CodeArts prohibition into an alias. Example: `Do not use EnterPlanMode` means the actual plan-mode tool is forbidden; `Only one task call per response` is a real CodeArts constraint, not a stylistic preference.