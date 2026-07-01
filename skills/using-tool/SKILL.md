---
name: using-tool
description: Use when using any skill from this plugin, before executing plugin skill instructions, or when adapting tool-use instructions between Claude Code, Codex, or another agent runtime.
---

# Using Tool

## Overview

`using-tool` is the mandatory runtime-adaptation pre-skill for this plugin. Load it before using any other skill from this plugin so tool-use instructions are interpreted for the current agent runtime.

Core principle: preserve action intent. Treat short aliases and source-runtime tool names as semantic actions to adapt, not as literal commands, JSON schemas, or parameter formats to copy.

## Mandatory Loading Rule

Before using any skill from this plugin:

1. Load `using-tool` first.
2. Load exactly one runtime file for the current runtime.
3. Load or read the requested target skill.
4. Execute the target skill using the runtime file's tool usage patterns.

Do not skip this because the target skill looks simple. Every plugin skill may contain portable tool-action instructions.

## When To Use

Use this skill when:

- You are about to use any skill from this plugin.
- A skill says to use `ask`, `read`, `find`, `edit`, `run`, `todo`, `agent`, or `check`.
- A skill, prompt, or adapter mentions concrete source-runtime tools such as `AskUserQuestion`, `apply_patch`, task tracking, subagents, shell commands, plan/update mechanisms, or verifier tools.
- A tool instruction must move between Claude Code, Codex, or another agent runtime.

Do not use aliases to rename frontmatter metadata, runtime policy names, or exact forbidden tools. For example, a rule that explicitly forbids `EnterPlanMode` should keep that exact runtime name when the current runtime is Claude Code.

## Alias Vocabulary

| Alias | Action intent |
|---|---|
| `ask` | Ask the user for a decision, missing fact, confirmation, or choice. |
| `read` | Read a file, document, notebook, image, or runtime-accessible resource. |
| `find` | Search files, paths, symbols, text, docs, or web resources. |
| `edit` | Create, modify, replace, or delete file content. |
| `run` | Execute a command, script, test, build, validation, or app launch. |
| `todo` | Track work items, progress, dependencies, or checklist state. |
| `agent` | Delegate to a subagent, reviewer, explorer, or parallel worker. |
| `check` | Verify behavior, inspect results, review changes, or confirm evidence. |

Other plugin skills should write portable tool actions as backticked aliases. Example: "Use `ask` before choosing the invocation mode."

## Runtime Files

Load exactly one mapping file for the runtime you are using:

| Runtime | Runtime file |
|---|---|
| Claude Code | `runtimes/claude-code.md` |
| Codex | `runtimes/codex.md` |

Runtime files are operating manuals, not only lookup tables. They should define:

- alias-to-capability mappings;
- instruction shapes and examples;
- important parameters or schema constraints;
- fallbacks when the runtime lacks a capability.

If the runtime is unknown or has no file, infer the closest equivalents from visible tools and the alias table. Do not invent a tool call.

## Adaptation Flow

1. Identify the alias or source-runtime tool instruction.
2. Use the current runtime file to choose the closest available tool, command, or chat behavior.
3. Translate only the semantics needed for the current step; do not copy source-runtime parameters.
4. If no equivalent exists, degrade honestly:
   - use plain chat for `ask`;
   - use a Markdown checklist for `todo`;
   - perform manual inspection for `check` when no verifier exists;
   - state the missing capability for actions that cannot be safely simulated.
5. Report capability gaps as limitations, not as completed tool calls.

For ambiguous translations, state the alias/source, intent, runtime mapping, limitation, and next action. For obvious mappings, act directly.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Treating an alias as a literal command or tool name. | Map it through the current runtime file before acting. |
| Copying another runtime's JSON schema or parameter format. | Use only the current runtime's visible schema, command syntax, or chat pattern. |
| Claiming a missing tool was called successfully. | State the limitation and use the documented fallback. |
| Loading every runtime file. | Load only the current runtime file unless comparing runtimes. |
