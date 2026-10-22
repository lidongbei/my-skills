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

## Subagent Dispatch Capability

| Aspect | Codex value |
|---|---|
| Native subagent tool | Not guaranteed. Probe the visible tools before relying on delegation; if it is absent, delegation does not exist in this runtime. |
| Blocking form | Not applicable without a native subagent tool. If one is visible, dispatch in a form that returns the result inside the same turn. |
| Parallel dispatch | Not guaranteed. Assume one at a time unless the runtime documents otherwise. |
| Resume by handle | No documented handle-based resume in this mapping. The on-disk feedback file is the only recovery path. |
| Subagent model | A spawned CLI process carries its own model/provider configuration; this is why the `cli` backend is the portable choice when models sit behind a local proxy. |
| Default backend | `cli` when a headless Codex entry point exists; otherwise `sequential`. |
| CLI fallback | `codex exec "<task>"` for a headless one-shot run; confirm the current subcommand with `codex --help` before use. |

Rules:

- Do not emit a Claude Code `Agent` call, `subagent_type`, or `run_in_background` parameter here.
- Without handle resume, a subtask whose feedback file is missing or truncated can only be re-dispatched as a fresh process — inspect what landed on disk first.
- When the `cli` backend is used, the coordinator must wait for the spawned process and read its feedback file, not its stdout alone.

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
- The configuration location file `.agents/my-skills-local-config.md` is kept out of version control by an ignore rule that names that file: the output root is per-developer, machine-specific state and must never be committed into the shared `CLAUDE.md`/`AGENTS.md`. Verifying and adding that rule is `configuring-plugin`'s job, not the consuming skill's.
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

## Shared Agent Toolchain Configuration

The same `.agents/my-skills-local-config.md` can carry a third managed block, pinning the tool versions a workspace's runs should use when the machine has several of a tool installed:

```markdown
<!-- agent-toolchain:start -->
## Agent Toolchain Configuration

- <tool name>: <version or absolute path>
<!-- agent-toolchain:end -->
```

- Same location and same read/append/replace rules as the other blocks; editing one block must preserve the others.
- The block is open-ended: one `<tool name>: <version or absolute path>` entry per pinned tool, and only the tools the user chose. Never invent a tool or a version.
- A pinned version or absolute path must resolve on this machine; an uninstalled version or a stale path is malformed, not a value to keep.
- This item is registered ahead of its consumers: no skill reads it yet. Creating or repairing it is `configuring-plugin`'s job, not the consuming skill's.

## Codex Boundaries

- Preserve the skill's workflow and intent, not Claude Code's tool names.
- When a skill mentions Claude Code-specific tools, translate to the closest Codex capability or degrade honestly.
- If a capability is missing, state the limitation and choose the safe fallback. Do not emit fake tool calls.
