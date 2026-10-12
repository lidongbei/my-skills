# DSH Runtime Mapping

Use this file when the current runtime is DeepSeek Harness (DSH). It maps plugin tool-action aliases to the DSH tool surface without assuming Claude Code tool names or schemas exist.

## Mapping Table

| Alias | DSH mapping | Notes |
|---|---|---|
| `ask` | `ask_user_question` for structured choices; otherwise plain chat. | Options are `{label, description}` objects; put the recommended option first and append "(Recommended)" to its label. Do not invent fields. |
| `read` | `read` for known text files, `read_image` for images. | `read` returns line-numbered content; continue with `offset`/`limit`. |
| `find` | `glob` for paths, `grep` for content, `web_search`/`web_fetch` for web. | Prefer these over shell `find`/`grep`/`cat`. |
| `edit` | `edit` for literal replacements, `write` for a new file or a full replacement. | Read an existing file before editing it. `edit` matches literal text, not regex. |
| `run` | `pwsh`. | One fresh process per call: pass `workdir` instead of `cd`. Report `[exit code: N]` failures honestly. |
| `todo` | `todo_write`. | Replaces the whole list each call; keep exactly one item `in_progress` unless items genuinely run in parallel. |
| `agent` | `subagent` (or `subagent_fork` to inherit this conversation); `workflow` only with explicit user opt-in. | Blocking form is `run_in_background: false`; background is the default, so the blocking form must be passed explicitly. |
| `check` | `pwsh` for commands and tests, `read`/`grep` for inspection, `job_output` for background jobs. | Exit codes, file contents, and grep hits are evidence; prose assessment is not. |

## Usage Patterns

### `ask`

Use `ask_user_question` when the user must choose among concrete options:

```json
{
  "questions": [{
    "id": "mode",
    "header": "Mode",
    "question": "Which invocation mode should this skill use?",
    "options": [
      {"label": "user-only (Recommended)", "description": "Only explicit user invocation can use it."},
      {"label": "model-invocable", "description": "The model may load it when triggers match."}
    ]
  }]
}
```

For a simple clarification without structured choices, ask directly in chat.

### `read` / `find` / `edit`

`read` a known file with bounded ranges:

```json
{"file_path": "D:\\AI\\my-skills\\skills\\using-tool\\SKILL.md", "offset": 1, "limit": 200}
```

Discover paths with `glob`, search content with `grep`, then `read` a matched file for surrounding context before editing it.

`edit` replaces literal text and must appear exactly once unless `replace_all` is set:

```json
{
  "file_path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes\\dsh.md",
  "old_string": "exact text already read from the file",
  "new_string": "replacement text"
}
```

Do not present an edit as applied unless the tool call succeeded.

### `run`

Use `pwsh` for commands, tests, builds, and validation:

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "description": "Validate plugin shape",
  "workdir": "D:\\AI\\my-skills"
}
```

Each call is a fresh `pwsh -Command` process; shell state does not persist between calls. Long output is truncated to its tail and the full output is written to a file whose path is reported — read that path instead of re-running with smaller output.

### `todo`

Use `todo_write` for multi-step work. Each call replaces the complete list:

```json
{
  "todos": [
    {"content": "Diagnose the missing runtime mapping", "status": "completed"},
    {"content": "Add the DSH dispatch capability section", "status": "in_progress"},
    {"content": "Run scripts/validate.ps1", "status": "pending"}
  ]
}
```

Skip todo tracking for trivial one-step tasks.

### `agent`

Use `subagent` for independent exploration, review, or delegated work:

```json
{
  "description": "Review runtime examples",
  "prompt": "Read the using-tool runtime files and identify missing alias usage examples. Return only gaps and suggested fixes.",
  "run_in_background": false
}
```

`subagent` runs in the background by default. When the next step depends on the result, pass `run_in_background: false` and consume the result inside the same turn. A background subagent returns a handle immediately and is collected with `job_output` (or `send_message`/`list_agents` once it has settled); the completion notice arrives in-session, so do not busy-poll and do not end a turn on a handle whose result the next step needs.

Use `subagent_fork` when the subtask must build on this conversation's context. Use `workflow` only when the user explicitly asks for a workflow or for large multi-agent orchestration — never translate a generic `agent` instruction into `workflow` by default.

### `check`

Use concrete evidence: command exit codes, inspected files, reviewed diffs, or `grep` hits.

```json
{
  "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1",
  "description": "Validate plugin shape after changes",
  "workdir": "D:\\AI\\my-skills"
}
```

Inspection example:

```json
{"path": "D:\\AI\\my-skills\\skills\\using-tool\\runtimes", "pattern": "Subagent Dispatch Capability", "include": "*.md"}
```

Do not claim validation without evidence. If a check was skipped, say it was skipped.

## Subagent Dispatch Capability

| Aspect | DSH value |
|---|---|
| Native subagent tool | Yes — `subagent`, plus `subagent_fork` for context-inheriting children. |
| Blocking form | `run_in_background: false`. Background is the default; the blocking form must be explicit. |
| Parallel dispatch | Yes — several `subagent` calls in one assistant message run concurrently while the coordinator stays inside the turn. Several background handles may also be tracked as jobs. |
| Resume by handle | Yes — `send_message` continues a settled child; `list_agents` enumerates children; `interrupt_agent` stops one. |
| Subagent model | A plain `subagent` inherits the harness profile's provider/model. Per-agent `provider`/`model` overrides exist only inside the `workflow` tool's `agent()` options. |
| Default backend | `native`. |
| CLI fallback | `dsh headless "<task>"` answers one task, prints the result, and exits. Pass a prompt-file path in the task string and require the feedback file on disk, because the printed result is not a durable record. |

Rules:

- Never dispatch with the default background form and then end the turn when the next step needs the result.
- A DSH subagent's final message is not a durable artifact. Require the subtask's feedback file on disk and validate from that file.
- If the configured backend is `cli`, the coordinator launches `dsh headless` with `run` and waits for the process, using the same profile that serves the configured model.

## Shared Agent Output Configuration

For shared output-root persistence used by `coding-workflow` and `generating-reqable-docs`, the project-level configuration location is the repository-root, git-ignored local file `.agents/my-skills-local-config.md`. The consuming skill reads/writes this managed block:

```markdown
<!-- agent-output-root:start -->
## Agent Output Configuration

- Output root: `<absolute path>`
<!-- agent-output-root:end -->
```

- Use `read` to inspect only this file for the managed block defined by the consuming skill.
- If a resolved, validated output root must be persisted and the file does not exist, use `edit` to create the `.agents/` directory and a file containing exactly that managed block.
- If it exists, use `edit` to append the block when absent, or replace only the content from `<!-- agent-output-root:start -->` through `<!-- agent-output-root:end -->` when exactly one valid block is present. Preserve all content outside that block.
- `.agents/` is git-ignored: the output root is per-developer, machine-specific state and must never be committed into the shared `CLAUDE.md`/`AGENTS.md`.
- Do not read, recognize, migrate, or reuse `coding-workflow:artifact-root` blocks. Do not read or use `CLAUDE.md`, `AGENTS.md`, `.trae/`, or any other file for this configuration.

## Shared Agent Dispatch Configuration

`subagent-takeover` persists its dispatch backend in the same `.agents/my-skills-local-config.md` file, as a second managed block:

```markdown
<!-- agent-dispatch:start -->
## Agent Dispatch Configuration

- Backend: native | cli | sequential | manual
- CLI template: <command that runs one headless agent for one prompt file>
- Max parallel: <integer, default 1>
- Subagent model: inherit | <provider/model>
<!-- agent-dispatch:end -->
```

- Same location, same read/append/replace rules as the output-root block; the two blocks are independent, and editing one must preserve the other.
- `Backend` is one of the four values, `CLI template` is required when `Backend: cli`, `Max parallel` defaults to `1`, and `Subagent model` is `inherit` or a `provider/model` pair.
- This block is optional: when it is absent, `subagent-takeover` uses this runtime file's `Subagent Dispatch Capability` default backend. Never invent a value to fill it.
- Creating or repairing either block is `configuring-plugin`'s job, not the consuming skill's. This file defines only where the blocks live and what shape they take.

## DSH Boundaries

- The harness chooses the model and provider. Do not claim a model or provider was switched unless the visible tool accepted that parameter.
- File policy and approval settings are harness-level. If a file operation is denied by policy, report the denial instead of retrying another way.
- Under a confined file sandbox, capturing another program's output through piped stdio can fail; prefer `stdio: inherit`/`ignore` or restructure the command rather than retrying the same shape.
- A user-only skill (`disable-model-invocation: true`) is rejected by the `skill` tool. A user slash-command invocation is still valid: read the matching `skills/<skill-name>/SKILL.md` directly and follow it.
- Do not invent a tool call. If DSH exposes no equivalent for an alias, state the missing capability and use the documented fallback.
