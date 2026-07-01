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

For a simple clarification without structured choices, ask directly in chat.

### `read` / `find`

- `Read`: known file, notebook, image, or PDF. Use `offset`/`limit` for large files.
- `Glob`: path discovery such as `skills/**/*.md`.
- `Grep`: content search with `pattern`, `path`, optional `glob`, and `output_mode`.
- `WebFetch`: read a URL when web access is needed.

### `edit`

- Use `Edit` for exact replacements after reading the file.
- Use `Write` for new files or full replacements of files already read.
- `Edit.old_string` must match exactly and be unique unless `replace_all` is intentional.
- Use `NotebookEdit` for notebooks.

### `run`

Use `Bash` for commands, tests, builds, and validation. Include a clear `description`; set `timeout` when commands may take time. Prefer dedicated file/search tools over shell for reading or searching.

### `todo`

Use task tools only when tracking helps the work. Create/update tasks for multi-step changes; do not add overhead for a single obvious action.

### `agent`

Use `Agent` for independent exploration, review, or delegated work. Use `Workflow` only when the user explicitly requests multi-agent orchestration or another loaded instruction allows it.

### `check`

Run the relevant command, inspect the result, review the diff, or use verification/review skills. Do not claim validation without evidence.

## Claude Code Boundaries

- Keep Claude Code frontmatter metadata such as `allowed-tools` as real tool names, not aliases.
- If a user-only skill invocation through `Skill` fails because of `disable-model-invocation: true`, read the matching `skills/<skill-name>/SKILL.md` directly and follow it.
- Do not translate an explicit Claude Code prohibition into an alias. Example: `Do not use EnterPlanMode` means the actual Claude Code plan-mode tool is forbidden.
