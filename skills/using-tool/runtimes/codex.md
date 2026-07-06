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
I need one decision before continuing: Which mode should this skill use?

1. user-only — Only explicit user invocation can use it.
2. model-invocable — The model may load it when triggers match.

Please reply with 1 or 2, or provide another answer.
```

If the source instruction provides Claude Code `AskUserQuestion` JSON, preserve only the question, options, and consequences. Do not copy the JSON schema into Codex.

### `read` / `find`

Use Codex file/search tools if they are visible in the runtime. If not, use bounded shell commands.

Known file read fallback:

```bash
sed -n '1,200p' skills/using-tool/SKILL.md
```

Path discovery fallback:

```bash
rg --files skills/using-tool/runtimes
```

Content search fallback:

```bash
rg -n "AskUserQuestion|TaskCreate|Workflow" skills/using-tool
```

Report limits when using partial reads or scoped searches.

### `edit`

Use Codex patch/edit support. A typical patch shape is:

```diff
*** Begin Patch
*** Update File: skills/using-tool/runtimes/codex.md
@@
-old text
+new text
*** End Patch
```

If applying a patch through shell or another command, verify it succeeded before saying the file changed. If the source instruction says Claude Code `Edit.old_string`, translate the intent to a precise Codex edit; do not copy Claude Code's `Edit` JSON schema.

### `run`

Use shell execution for tests, builds, scripts, validation, and app launches. Typical command:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

Respect sandbox and approval constraints. Report the command result honestly. If the intent is only file search or file reading, prefer visible Codex search/read tools or bounded `rg`/`sed` fallbacks.

### `todo`

If Codex exposes plan/update tooling, use it. If not, keep a short Markdown checklist in the response:

```markdown
- [ ] Diagnose missing runtime examples
- [ ] Update Claude Code mapping examples
- [ ] Update Codex mapping examples
- [ ] Run validation
```

Update the checklist as work progresses. If the source instruction names Claude Code `TaskCreate` or `TaskUpdate`, preserve the tracking intent; do not claim those tools exist in Codex unless they are visible.

### `agent`

If Codex exposes multi-agent support, delegate independent work. If not, complete the work in the main agent and state the limitation:

```markdown
Delegation is unavailable in this runtime, so I will perform the review directly and note that no subagent was used.
```

If the source instruction names Claude Code `Agent`, `subagent_type`, or `Workflow`, preserve the intent: independent exploration, review, or explicit multi-agent orchestration. Do not copy Claude Code parameters. Use workflow-like orchestration only if Codex has an equivalent and the user opted in.

### `check`

Prefer concrete evidence: command output, inspected files, reviewed diffs, screenshots, or manual observation notes.

Validation example:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

Inspection examples:

```bash
rg -n "Typical shape|AskUserQuestion|TaskCreate" skills/using-tool/runtimes

git diff -- skills/using-tool/runtimes/claude-code.md skills/using-tool/runtimes/codex.md
```

If no verifier exists, say what was manually inspected. Do not claim a missing verifier, task, or agent tool was called.

## Codex Boundaries

- Preserve the skill's workflow and intent, not Claude Code's tool names.
- When a skill mentions Claude Code-specific tools, translate to the closest Codex capability or degrade honestly.
- If a capability is missing, state the limitation and choose the safe fallback. Do not emit fake tool calls.
