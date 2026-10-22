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
- Do not commit, stage, or otherwise version-control the configuration location; the config-location ignore item exists to keep it out of version control.
- Do not write a value the user has not chosen. For a default, present it as the recommended `ask` option; never pick it silently.
- Do not claim an item is configured without a fresh `check` after writing.

## Delegation From Other Skills

Other plugin skills resolve and read configuration (output root, dispatch; toolchain is registered ahead of its consumers) from the same designated location, but they do not create or repair it. When `coding-workflow`, `subagent-takeover`, or `generating-reqable-docs` reaches a point where it would have written or repaired a managed block, it hands off to this skill. This skill runs the interactive configuration below and returns control **with the Output Contract report**; the invoking skill then continues from the values and states that report names. A delegated run may skip nothing: it reports every registry item, including the config-location ignore item.

## Configuration Registry

The registered project-level configuration items for this plugin. Treat this table as the single source of truth for what "configured" means. When a skill later introduces a new project-level config item, register a row here.

| Config item | Managed block | Required fields | Consumed by | Necessity |
|---|---|---|---|---|
| Output root | `agent-output-root` | `Output root` = an absolute path | `coding-workflow`, `subagent-takeover`, `generating-reqable-docs` | Required |
| Dispatch | `agent-dispatch` | `Backend`; `CLI template` when `Backend: cli`; `Max parallel` (default `1`); `Subagent model` | `subagent-takeover` | Optional (absent → runtime default) |
| Toolchain | `agent-toolchain` | At least one `<tool name>: <version or absolute path>` entry; every value resolves on this machine | Registered for later consumers; no skill consumes it yet | Optional (absent → no pinned toolchain) |
| Config location ignore | none — a version control ignore rule, not a block | The configuration location file itself is excluded by the workspace's version control, so the local config is never committed | the whole registry: a per-developer file that gets committed stops being per-developer | Required |

The configuration location is per-developer, machine-specific state: it holds absolute paths and runtime-specific backend choices, and the runtime mappings state that the location is ignored. That ignore rule is an invariant to verify, not a fact to assume — a fresh workspace usually has no ignore entry for it, and the first `git add .` then commits a machine-specific file into the shared repository. The rule covers exactly the configuration location file: only that file carries machine-specific state, so ignore the file, never its whole parent directory. A directory-wide rule such as `.agents/` also hides sibling content that is meant to be shared.

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

<!-- agent-toolchain:start -->
## Agent Toolchain Configuration

- JDK: <version or absolute path>
- Node: <version or absolute path>
<!-- agent-toolchain:end -->
```

The toolchain block is open-ended: keep one `<tool name>: <version or absolute path>` entry per tool the user pins, and keep only the tools the user actually chooses. The example names above are illustrative, not a fixed field list.

The configuration location is defined by the current runtime's `using-tool` mapping (Claude Code: the repository-root, git-ignored file `.agents/my-skills-local-config.md`). Do not read `CLAUDE.md`, `AGENTS.md`, `.trae/`, or any other file for this configuration.

### Legacy block names

Never read, recognize, migrate, or reuse these blocks. Treat their presence as `legacy-only`, not as configuration, and resolve them only through the user decision in step 4.

| Legacy block | Superseded by |
|---|---|
| `coding-workflow:artifact-root` | `agent-output-root` |

When a skill later retires a managed block name, add it here.

## Workflow

### 1. Resolve context

1. Load `using-tool` and the current runtime mapping; the mapping defines the configuration location.
2. `read` that location. If it does not exist, treat every block-backed registry item as `missing`.
3. Resolve the workspace root: the nearest ancestor of the configuration location that contains a version control root (`.git`). If there is none, the workspace is not under version control.

### 2. Classify each registry item

For each block-backed item, assign exactly one state from the `read` result:

- `missing` — no managed block for the item.
- `valid` — exactly one block, all required fields present and valid.
- `malformed` — duplicated blocks, truncated markers, or an invalid value.
- `legacy-only` — only a block whose name is listed as legacy exists (for example `coding-workflow:artifact-root`). Legacy blocks are not valid configuration and must never be migrated or reused.

For the toolchain item, apply the same four states to the block itself and additionally judge each entry: an entry whose value pins a version that is not installed, or an absolute path that does not exist, makes the block `malformed`. Report the offending entry; do not repair it silently.

Classify the config-location ignore item by asking whether the configuration location **file** is excluded, not its parent directory:

- `valid` — the configuration location file is already excluded by an ignore rule that applies to that exact path, or the workspace is not under a version control root (`.git`), so no ignore rule applies.
- `missing` — the workspace is under a version control root and the configuration location file is not excluded. An ignore rule for the parent directory does not cover this item: the rule must name the file.
- `malformed` — an ignore rule mentions the file path but a later rule re-includes it, so the file is not actually excluded.

### 3. Plan the interactive session

Use `todo` to list every registry item with its state. Report `valid` items too, so the user sees the full picture; do not skip an item because it looks healthy.

### 4. Ask per item

Ask before writing any value; do not re-ask a `valid` item — report it instead.

- `missing` required item: use `ask` to let the user choose the value once. Mark the consumed skill's documented default as the recommended option (output-root default: the repository parent directory + `<project name>__agent`).
- `missing` optional item: use `ask` to let the user set it, skip it, or accept the runtime default; do not write a value silently.
- Toolchain item, `missing`: this item is per-tool, so ask which tools the user wants pinned before writing anything (a multi-select over the common ones — JDK, Node, Python, Maven, Gradle, Go, Rust — plus a free-text "other"). Probe this machine for candidate values first (installed JDK directories, `nvm list`, `py -0`, `which java|node|python|mvn|gradle`) and present the discovered values as the `ask` options; a value the user typed themselves is always allowed. Ask one question per chosen tool so each pin is an explicit choice. Do not pin a tool the user did not choose, and do not invent a version.
- `malformed` or `legacy-only`: do not repair or migrate silently. Use `ask` to present the exact conflict and the candidate resolutions (which block to keep, which to delete, or clear to `missing`) and let the user decide. Apply only what the user chose.
- Config-location ignore item, `missing`: use `ask` to offer adding the ignore rule as the recommended option; do not add it silently. Recommend the rule for the configuration location file (`/.agents/my-skills-local-config.md` under Claude Code) and mark it as the recommended option. If an existing rule ignores a whole parent directory that contains the configuration location, present narrowing it to the file as an alternative option, and do not delete or rewrite the existing rule on your own. This is a workspace-level invariant, so it stays `missing` unless the user chooses it.
- Config-location ignore item, `malformed`: present the conflicting rule and let the user decide what to do with it.

### 5. Write

Use `edit` to write only the managed block(s) the user chose:

- Location absent → create it (and the parent directory) containing only the chosen block(s).
- Block absent → append it.
- Existing block to change → replace only from `<!-- <name>:start -->` through `<!-- <name>:end -->`.

Never touch a block the user did not ask to change, and preserve all content outside the managed blocks.

The toolchain block is open-ended, so editing it never means rewriting the whole block: add, change, or remove only the entry lines for the tools the user chose this run, and preserve every other entry line and the markers exactly.

For the config-location ignore item, use `edit` to add the ignore rule for the configuration location file **only when the user chose it**. Check for an equivalent existing rule first, and append only the missing line: never duplicate an ignore rule or rewrite the file. When the user chose to narrow an existing parent-directory rule instead, replace that one line with the file rule — do not touch any other line.

### 6. Check

`check` by re-`read`ing the location. Verify, per written item:

- the block appears exactly once with intact start/end markers;
- the output root is an absolute path and is an existing directory or a creatable path (an existing file or non-creatable path is invalid);
- `Backend:` is one of `native | cli | sequential | manual`; `CLI template` is present when the backend is `cli`; `Max parallel` is an integer ≥ 1;
- each toolchain entry has a non-empty tool name and value, every pinned version or absolute path resolves on this machine, and no tool name appears twice.

For the config-location ignore item, `check` by re-reading the ignore file and confirming a rule excludes the configuration location **file** (cite the matching rule line, or a `git check-ignore` result naming the file). Do not accept a parent-directory rule as evidence. When the workspace is not under version control, cite that as the evidence instead.

Do not claim an item is configured without this evidence.

### 7. Report

Output the configuration report below. Mark any item you could not resolve as `unresolved` and state what blocks it and what the user must do.

## Output Contract

Always end with this report, one row per registry item:

| Registry item | State before | Action taken | Value written | Validation evidence | Status |
|---|---|---|---|---|---|

- `Status` is `configured`, `already-valid`, `skipped-by-user`, or `unresolved`.
- `Validation evidence` cites the fresh re-`read` result, not an assertion.
- If any item is `unresolved`, do not claim the workspace is configured.
- A delegated run returns control with this report; the invoking skill then consumes the reported values or states.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Silently picking a default output root. | Use `ask`; present the default only as the recommended option. |
| Quietly deleting one of two duplicate blocks. | Present the conflict via `ask`; the user decides. |
| Treating a legacy `artifact-root` block as usable configuration. | Mark it `legacy-only`; never migrate or reuse it. |
| Assuming the configuration location is git-ignored in a fresh workspace. | Verify the ignore rule and add it with the user's consent. |
| Duplicating an existing ignore rule, or rewriting the ignore file. | Append only the missing line; preserve everything else. |
| Ignoring the whole configuration directory (for example `.agents/`). | Ignore the configuration location file itself; a directory-wide rule also hides sibling content meant to be shared. |
| Treating a parent-directory ignore rule as satisfying the config-location ignore item. | Classify the file as `missing`; the rule must name the file. |
| Reporting "configured" without re-reading. | `check` by re-reading; cite the evidence. |
| Editing text outside the managed blocks. | Change only the block content the user chose. |
| Auto-running `git init` on an output root. | Do not; that decision belongs to the user under the consuming skill. |
| Skipping the optional dispatch item. | Report it; let the user set or skip it. |
| Pinning a toolchain version this machine does not have. | Probe first and reject an uninstalled version or a non-existent path; classify the entry `malformed`. |
| Pinning toolchain tools the user did not choose. | Ask which tools to pin first, then one question per chosen tool. |
| Rewriting the open-ended toolchain block. | Edit only the entry lines for the chosen tools; preserve every other entry and the markers. |
