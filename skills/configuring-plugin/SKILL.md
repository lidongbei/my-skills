---
name: configuring-plugin
description: Use when configuring this plugin's per-project configuration for the current workspace, including first-time setup in a new workspace, upgrading an existing workspace, repairing missing, malformed, duplicated, or legacy configuration blocks, or when another plugin skill needs a managed configuration block created or repaired.
---

# Configuring Plugin

## Overview

Interactive configuration of this plugin's per-project configuration for the current workspace: first-time setup in a new workspace, or upgrade of an existing workspace whose configuration is missing, malformed, or left over from an older schema.

Core principle: **this skill owns every create and repair of the plugin's project-level configuration.** Other plugin skills resolve and read those values, but they do not create or repair them; when such a skill would write or repair a managed block, it hands off here. Never silently repair, overwrite, migrate, or guess a configuration value.

## Hard Boundaries

- Trigger when the user explicitly invokes this skill, when the user asks to configure, complete, or upgrade this plugin's project configuration for the current workspace, or when another plugin skill delegates a create/repair of a managed configuration block.
- Do not trigger for ordinary work that merely reads a configured value; act only on configuration tasks (first-time setup, upgrade, repair, or an explicit request to complete configuration).
- Configure only the plugin's designated project-level configuration location defined by the current runtime mapping. Do not configure or repair any other file.
- Never silently repair a malformed, duplicated, or legacy configuration. Use `ask` and require the user to decide.
- Do not `git init` the output root or any directory. That decision belongs to the user under the consuming skill's rule.
- Do not change other skills' behavior and do not invent configuration items outside the registry below.
- Do not write a value the user has not chosen. For a default, present it as the recommended `ask` option; never pick it silently.
- Do not claim an item is configured without a fresh `check` after writing.

## Delegation From Other Skills

Other plugin skills resolve and read configuration (output root, dispatch) from the same designated location, but they do not create or repair it. When `coding-workflow`, `subagent-takeover`, or `generating-reqable-docs` reaches a point where it would have written or repaired a managed block, it hands off to this skill. This skill runs the interactive configuration below and returns control; the invoking skill then continues from the configured values.

## Configuration Registry

The registered project-level configuration items for this plugin. Treat this table as the single source of truth for what "configured" means. When a skill later introduces a new project-level config item, register a row here.

| Config item | Managed block | Required fields | Consumed by | Necessity |
|---|---|---|---|---|
| Output root | `agent-output-root` | `Output root` = an absolute path | `coding-workflow`, `subagent-takeover`, `generating-reqable-docs` | Required |
| Dispatch | `agent-dispatch` | `Backend`; `CLI template` when `Backend: cli`; `Max parallel` (default `1`); `Subagent model` | `subagent-takeover` | Optional (absent → runtime default) |

Write managed blocks in exactly this shape:

```markdown
<!-- agent-output-root:start -->
## Agent Output Configuration

- Output root: `<absolute path>`
<!-- agent-output-root:end -->

<!-- agent-dispatch:start -->
## Agent Dispatch Configuration

- Backend: native | cli | sequential | manual
- CLI template: <command that runs one headless agent for one prompt file>
- Max parallel: <integer, default 1>
- Subagent model: inherit | <provider/model>
<!-- agent-dispatch:end -->
```

The configuration location is defined by the current runtime's `using-tool` mapping (Claude Code: the repository-root, git-ignored file `.agents/my-skills-local-config.md`). Do not read `CLAUDE.md`, `AGENTS.md`, `.trae/`, or any other file for this configuration.

## Workflow

### 1. Resolve context

1. Load `using-tool` and the current runtime mapping; the mapping defines the configuration location.
2. `read` that location. If it does not exist, treat every registry item as `missing`.

### 2. Classify each registry item

For each registry item, assign exactly one state from the `read` result:

- `missing` — no managed block for the item.
- `valid` — exactly one block, all required fields present and valid.
- `malformed` — duplicated blocks, truncated markers, or an invalid value.
- `legacy-only` — only a legacy block (for example `coding-workflow:artifact-root`) exists. Legacy blocks are not valid configuration and must never be migrated or reused.

### 3. Plan the interactive session

Use `todo` to list every registry item with its state. Report `valid` items too, so the user sees the full picture; do not skip an item because it looks healthy.

### 4. Ask per item

Ask before writing any value; do not re-ask a `valid` item — report it instead.

- `missing` required item: use `ask` to let the user choose the value once. Mark the consumed skill's documented default as the recommended option (output-root default: the repository parent directory + `<project name>__agent`).
- `missing` optional item: use `ask` to let the user set it, skip it, or accept the runtime default; do not write a value silently.
- `malformed` or `legacy-only`: do not repair or migrate silently. Use `ask` to present the exact conflict and the candidate resolutions (which block to keep, which to delete, or clear to `missing`) and let the user decide. Apply only what the user chose.

### 5. Write

Use `edit` to write only the managed block(s) the user chose:

- Location absent → create it (and the parent directory) containing only the chosen block(s).
- Block absent → append it.
- Existing block to change → replace only from `<!-- <name>:start -->` through `<!-- <name>:end -->`.

Never touch a block the user did not ask to change, and preserve all content outside the managed blocks.

### 6. Check

`check` by re-`read`ing the location. Verify, per written item:

- the block appears exactly once with intact start/end markers;
- the output root is an absolute path and is an existing directory or a creatable path (an existing file or non-creatable path is invalid);
- `Backend:` is one of `native | cli | sequential | manual`; `CLI template` is present when the backend is `cli`; `Max parallel` is an integer ≥ 1.

Do not claim an item is configured without this evidence.

### 7. Report

Output the configuration report below. Mark any item you could not resolve as `unresolved` and state what blocks it and what the user must do.

## Output Contract

Always end with this report, one row per registry item:

| Config item | State before | Action taken | Value written | Validation evidence | Status |
|---|---|---|---|---|---|

- `Status` is `configured`, `already-valid`, `skipped-by-user`, or `unresolved`.
- `Validation evidence` cites the fresh re-`read` result, not an assertion.
- If any item is `unresolved`, do not claim the workspace is configured.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Silently picking a default output root. | Use `ask`; present the default only as the recommended option. |
| Quietly deleting one of two duplicate blocks. | Present the conflict via `ask`; the user decides. |
| Treating a legacy `artifact-root` block as usable configuration. | Mark it `legacy-only`; never migrate or reuse it. |
| Reporting "configured" without re-reading. | `check` by re-reading; cite the evidence. |
| Editing text outside the managed blocks. | Change only the block content the user chose. |
| Auto-running `git init` on an output root. | Do not; that decision belongs to the user under the consuming skill. |
| Skipping the optional dispatch item. | Report it; let the user set or skip it. |
