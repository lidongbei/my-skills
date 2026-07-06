# Claude Code Runtime Mapping

Use this file when the current runtime is Claude Code. It maps plugin tool-action aliases to Claude Code tools and interaction patterns.

## Mapping Table

| Alias | Claude Code mapping | Notes |
|---|---|---|
| `ask` | `AskUserQuestion` for structured choices; otherwise plain chat. | Use the exact schema visible in the current session. Do not invent fields. |
| `read` | `Read` for known files/resources. | Local file paths must be absolute when the tool requires it. |
| `find` | `Glob` for paths, `Grep` for content, `WebFetch` for URL reading. | Prefer dedicated tools over shell commands when they fit. |
| `edit` | `Edit`, `Write`, or `NotebookEdit`. | Read existing files before editing when the tool requires it. |
| `run` | `Bash`, or a runtime skill such as `run`/`verify` when explicitly applicable. | Follow permission, sandbox, and safety rules. |
| `todo` | `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet`. | Use for multi-step work; skip for trivial one-step tasks. |
| `agent` | `Agent`, or `Workflow` only with explicit user opt-in. | Use agents for independent work; do not use workflows without opt-in. |
| `check` | Tests with `Bash`, inspection with `Read`/`Grep`, or verifier/review skills. | State concrete evidence. |

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
  "offset": 0,
  "limit": 2000
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
  "pattern": "AskUserQuestion|TaskCreate|Workflow",
  "glob": "*.md",
  "output_mode": "content",
  "head_limit": 50
}
```

Use `WebFetch` for URL reading when web access is needed. Do not use shell `cat`, `grep`, or `find` when the dedicated tools fit.

### `edit`

Use `Edit` for exact replacements after reading the file. Typical shape:

```json
{
  "file_path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes\\claude-code.md",
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

If a source instruction says `apply_patch`, preserve the edit intent and use `Edit`/`Write` unless applying a patch through an available command is the safest option. Do not copy another runtime's patch format as if it were a Claude Code tool call.

### `run`

Use `Bash` for commands, tests, builds, and validation. Typical shape:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "description": "Validate plugin shape",
  "timeout": 120000,
  "run_in_background": false,
  "dangerouslyDisableSandbox": false
}
```

Prefer dedicated file/search tools over shell when the intent is only to read or search. Use `Bash` when executing a command is the actual action.

### `todo`

Use task tools only when tracking helps multi-step work. Typical flow:

```json
{
  "title": "Update runtime examples",
  "description": "Add explicit usage shapes for each alias.",
  "status": "pending"
}
```

Then update as work progresses:

```json
{
  "task_id": "<task id from TaskCreate>",
  "status": "in_progress"
}
```

For a single obvious edit, skip task tools and state the work directly.

### `agent`

Use `Agent` for independent exploration, review, or delegated work. Typical shape:

```json
{
  "subagent_type": "Explore",
  "description": "Review runtime examples",
  "prompt": "Read the using-tool runtime files and identify missing alias usage examples. Return only gaps and suggested fixes.",
  "isolation": "worktree",
  "run_in_background": false
}
```

Use `Workflow` only when the user explicitly opts into multi-agent orchestration, for example by asking to “use a workflow”, “fan out agents”, or using the session's workflow opt-in keyword. Do not translate a generic `agent` instruction into `Workflow` by default.

### `check`

Use concrete evidence: command output, inspected files, reviewed diffs, or verifier/review skills. Typical validation command:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "description": "Validate plugin shape after changes",
  "timeout": 120000,
  "run_in_background": false,
  "dangerouslyDisableSandbox": false
}
```

Typical inspection search:

```json
{
  "path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes",
  "pattern": "Typical shape|Source instruction|AskUserQuestion",
  "glob": "*.md",
  "output_mode": "content"
}
```

Do not claim validation without evidence. If a check was skipped, say it was skipped.

## Claude Code Boundaries

- Keep Claude Code frontmatter metadata such as `allowed-tools` as real tool names, not aliases.
- If a user-only skill invocation through `Skill` fails because of `disable-model-invocation: true`, read the matching `skills/<skill-name>/SKILL.md` directly and follow it.
- Do not translate an explicit Claude Code prohibition into an alias. Example: `Do not use EnterPlanMode` means the actual Claude Code plan-mode tool is forbidden.
