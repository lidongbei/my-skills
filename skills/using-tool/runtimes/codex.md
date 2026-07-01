# Codex Runtime Mapping

Use this file when the current runtime is Codex. It maps plugin tool-action aliases to Codex capabilities without assuming Claude Code tool names or schemas exist.

## Mapping Table

| Alias | Codex mapping | Notes |
|---|---|---|
| `ask` | Ask directly in chat and wait for the user's reply. | Use numbered options for structured choices. Do not copy Claude Code `AskUserQuestion` JSON. |
| `read` | Use Codex file-reading support; otherwise bounded shell reads. | Prefer built-in file tools when visible. |
| `find` | Use Codex search support; otherwise `rg`, `find`, or shell/Python search. | Keep searches scoped and report incomplete coverage. |
| `edit` | Use Codex editing/apply-patch mechanisms. | Do not present a patch as applied unless the tool or command succeeded. |
| `run` | Use Codex shell command execution. | Follow sandbox, approval, and safety rules. |
| `todo` | Use Codex plan/update mechanisms when available; otherwise a Markdown checklist. | Do not claim a persistent task tool exists unless visible. |
| `agent` | Use Codex multi-agent/delegation support when available. | Otherwise do the work in the main agent and note the limitation. |
| `check` | Run tests/commands, inspect files or diffs, or manually verify outputs. | Give concrete evidence and command results when possible. |

## Instruction Patterns

### `ask`

Ask in chat. For choices, use a compact numbered list:

```markdown
I need one decision before continuing: <question>

1. <option> — <consequence>
2. <option> — <consequence>

Please reply with 1 or 2, or provide another answer.
```

### `read` / `find`

Use Codex file/search tools if they are visible in the runtime. If not, use bounded shell commands, for example:

```bash
sed -n '1,160p' path/to/file.md
rg -n "pattern" path/to/search
```

Report limits when using partial reads or scoped searches.

### `edit`

Use Codex patch/edit support. If applying a patch through shell or another command, verify it succeeded before saying the file changed. Do not output an unapplied patch as if it were applied.

### `run`

Use shell execution for tests, builds, scripts, validation, and app launches. Respect sandbox and approval constraints, and report the command result honestly.

### `todo`

If Codex exposes plan/update tooling, use it. If not, keep a short Markdown checklist in the response and update it as work progresses.

### `agent`

If Codex exposes multi-agent support, delegate independent work. If not, complete the work in the main agent and state that delegation is unavailable.

### `check`

Prefer concrete evidence: command output, inspected files, reviewed diffs, screenshots, or manual observation notes. If no verifier exists, say what was manually inspected.

## Codex Boundaries

- Preserve the skill's workflow and intent, not Claude Code's tool names.
- When a skill mentions Claude Code-specific tools, translate to the closest Codex capability or degrade honestly.
- If a capability is missing, state the limitation and choose the safe fallback. Do not emit fake tool calls.
