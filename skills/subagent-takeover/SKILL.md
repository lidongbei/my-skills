---
name: subagent-takeover
description: Use when coding-workflow selected the multiple-subagents execution mode and routed here, or when the user explicitly invokes /my-skills:subagent-takeover, invokes /subagent-takeover, or explicitly instructs the agent to use subagent-takeover to split an approved plan into reviewed subtasks.
---

# Subagent Takeover

## Overview

Take over after an approved `coding-workflow` plan when the chosen execution mode is **multiple subagents**. Split the approved plan into a human-reviewable subtask document, dispatch subagents that may use any available tool, and validate each subagent's structured feedback against the plan's traceability rows before claiming completion.

Core principle: the saved plan is the only source of truth. Subagents do not re-decide confirmed choices; the coordinator does not trust unverified subagent self-reports.

## Hard Boundaries

- Trigger only in these cases:
  - `coding-workflow` Step 5 selected the "多个子 agent 分工" execution mode and routed here. In that case trigger immediately after that selection, without asking the user to invoke this skill again.
  - The user explicitly invokes `/my-skills:subagent-takeover`, invokes `/subagent-takeover`, or explicitly instructs the agent to use `subagent-takeover`.
- Do not auto-trigger from phrases such as "拆分任务", "并行执行", "派发子 agent", "分工", or "分给多个 agent". If the user has not invoked this skill and coding-workflow has not routed to it, continue normally or suggest the slash command.
- Do not run without an approved, saved plan file under `<output root>/plans/YYYY-MM-DD-<topic>.md`. If no saved plan exists, stop and ask the user to run `coding-workflow` first.
- Do not edit the saved plan file. It is read-only for this skill. To revise the plan, return to `coding-workflow` Step 3 (修改已保存方案).
- Do not dispatch any subagent before the subtask document is approved by the user through the mandatory review gate.
- Do not claim a subtask complete based on a subagent's self-report alone. The coordinator must `check` the returned structured feedback against the corresponding traceability row.
- When invoked by the user directly rather than routed from `coding-workflow`, the approved saved plan requirement still applies: without it, stop and ask the user to run `coding-workflow` first.

## Output Root

Resolve the output root exactly as `coding-workflow` does. Read and honor the same managed block in the current runtime's designated project-level configuration location (Claude Code: `.agents/my-skills-local-config.md`):

```markdown
<!-- agent-output-root:start -->
## Agent Output Configuration

- Output root: `<absolute path>`
<!-- agent-output-root:end -->
```

Use the same resolution order and the same invalid-configuration rule as `coding-workflow`. Do not re-derive a different root. Do not read, recognize, migrate, or reuse legacy `coding-workflow:artifact-root` blocks.

Paths under the output root for this skill:

```text
<output root>/subTasks/YYYY-MM-DD-<topic>.md
```

Git: apply the same output-root git rule as `coding-workflow`. Commit the subtask document in the output-root repository only when the output root is a git repository; otherwise skip the commit and treat it as ignored. Do not commit into the working repository.

## Workflow

### 0. Prerequisites

Before splitting:

1. Use `read` to load the approved saved plan `<output root>/plans/YYYY-MM-DD-<topic>.md`. If it is missing, stop and use `ask` to tell the user to run `coding-workflow` first.
2. Confirm the `<topic>` (kebab-case) used by the saved plan filename; reuse it for the subtask document filename.
3. Resolve the output root per the `Output Root` section above.

### 1. Split Into Subtasks

Derive subtasks from the saved plan's `Implementation Handoff` ordered steps and `Requirements Traceability` rows — not from chat. Each subtask must be:

- Independent enough to be dispatched to one subagent without blocking another, unless an explicit dependency is recorded.
- Anchored to the plan's traceability: every subtask cites at least one traceability row (requirement → implementation location → acceptance condition → validation).
- Self-contained: the subagent receives the files/symbols, invariants, explicit non-changes, success/failure/boundary behavior, and validation target without needing to re-read the full plan.

If a plan step cannot be split into an independent subtask (it touches shared state, has an unavoidable ordering dependency, or its validation depends on another step's output), keep it as a sequential subtask and record its dependency on the predecessor subtask id. Do not force parallelism.

### 2. Write The Subtask Document

Use `edit` to create `<output root>/subTasks/YYYY-MM-DD-<topic>.md` with the required template below. Use the current local date. Use the same `<topic>` as the saved plan.

### 3. Mandatory Review Gate

After writing the subtask document, stop and use `ask` to make the user choose exactly one path before dispatching any subagent.

The `ask` prompt must be:

> 子任务拆分文档已生成，请选择下一步（必须明确选择其中一项）：

Present these Chinese options in this order:

| Option | Meaning | Next action |
|---|---|---|
| 1. 批准并开始派发 | 用户接受拆分方案。 | Commit the subtask document if the output root is a git repository, then proceed to Step 4. |
| 2. 修改拆分方案 | 用户希望调整子任务划分。 | Ask for the requested changes, revise the subtask document, then return to this gate. Do not dispatch. |
| 3. 返回 coding-workflow 修改方案 | 拆分暴露了方案本身的问题。 | Stop this skill. Tell the user to re-run `coding-workflow` Step 3 (修改已保存方案). Do not dispatch. |

Do not treat silence, "ok", "继续", "确认", or generic approval as permission to dispatch. Only option 1 (or equivalent explicit wording) authorizes dispatch.

### 4. Dispatch Subagents

For each subtask, use `agent` to dispatch one subagent. The dispatch is governed by the subtask's `Dependencies` field:

- Subtasks with no dependencies may be dispatched in parallel.
- A subtask with a dependency is dispatched only after its predecessor's feedback has been `check`-ed and accepted.

Each subagent dispatch prompt MUST contain, at minimum:

1. The subtask id, title, and goal.
2. The files/symbols/locations to change and the explicit change.
3. The invariants and explicit non-changes from the plan (copy verbatim from the subtask document).
4. The success, failure, error, and boundary behavior.
5. The validation target and acceptance condition.
6. The instruction: "You may use `read`, `find`, `edit`, `run`, and `check` as needed to complete this subtask. Do not re-decide confirmed choices. If source evidence contradicts the subtask, stop and report the contradiction instead of improvising."
7. The required structured feedback contract (see Step 5) the subagent must return in its final message.

Do not give a subagent freedom to change scope, contracts, or explicit non-changes. If a subagent reports a contradiction or a prerequisite unavailable, stop that subtask and return to the plan-revision path via `coding-workflow` Step 3.

### 5. Receive And Validate Structured Feedback

Every subagent MUST return its final result as this structured feedback. A subagent that returns prose without this structure is treated as incomplete.

```markdown
## Subagent Feedback

- Subtask id: <id>
- Status: completed | partial | blocked
- Files changed:
  - `<path>` — <what changed>
- Validation:
  - Ran: <command or check>
  - Result: <pass/fail + evidence>
  - Not run: <check>
  - Reason: <why not run>
- Acceptance conditions met:
  - <condition>: met / not met — <evidence>
- Deviations:
  - <none, or describe any deviation from the subtask and why>
- Blockers:
  - <none, or the exact contradiction / missing prerequisite / open question>
```

The coordinator then uses `check` to validate each returned feedback against the subtask's traceability row:

- Every file/symbol the subtask claims to have changed is inspected to confirm the change matches the plan's intended change.
- Every acceptance condition is verified as met with concrete evidence, not the subagent's assertion.
- Any deviation is compared against the plan's invariants and explicit non-changes. A material deviation without prior approval is rejected; the coordinator returns to `coding-workflow` Step 3 for plan revision.
- If validation is expensive, run narrow validation first (the subtask's own acceptance condition), then broader validation before a completion claim or task switch, per `coding-workflow` Step 6 risk-sized loops.

Record the validation result in the subtask document's `Subtask Status` table.

### 6. Completion Gate

After all subtasks are `check`-ed and accepted:

1. Update the subtask document's `Subtask Status` table so every row is `completed` with validation evidence.
2. Report final `Validation` per `coding-workflow` Step 7 (Ran / Result / Not run / Reason).
3. Apply `coding-workflow` Step 8 post-validation completion gate if this workflow produced uncommitted file changes in the working repository. Completion records go under `<output root>/complete/YYYY-MM-DD-<topic>.md` and must link to both the saved plan and the subtask document.

Do not claim completion with "should be fixed", "looks fine", or no evidence. Do not let a subagent's "completed" status override a failed coordinator `check`.

## Required Subtask Document Template

Every subtask document must use this structure. Unknown content must be written as `未知，需复核`; do not omit the section.

```markdown
# <Title>

Plan: [<plan title>](../plans/YYYY-MM-DD-<topic>.md)

## Summary

- Plan topic: <kebab-case topic>
- Saved plan: `<output root>/plans/YYYY-MM-DD-<topic>.md`
- Subtask count: <n>
- Created: YYYY-MM-DD

## Subtask Split Principles

- <how the plan's ordered steps and traceability rows were mapped to subtasks>
- <which subtasks are parallel and which are sequential, and why>

## Subtasks

### SUB-<nn> — <subtask title>

- Goal: <what this subtask accomplishes>
- Traceability rows: <requirement / decision id(s) from the plan>
- Files / symbols / locations:
  - `<path>:<symbol or line range>` — <intended change>
- Invariants (copy from plan):
  - <invariant>
- Explicit non-changes (copy from plan):
  - <explicit non-change>
- Success / failure / error / boundary behavior:
  - <observable behavior>
- Validation target:
  - <command or check> — <acceptance condition>
- Dependencies:
  - <none, or SUB-<mm> must be completed and accepted first>
- Dispatch prompt: <the full prompt sent to the subagent, including the structured feedback contract>

## Subtask Status

| Subtask | Status | Validation evidence | Deviation | Notes |
|---|---|---|---|---|
| SUB-01 | pending | — | — | — |
| SUB-02 | pending | — | — | — |

## Review Gate

- Selected: <not yet reviewed / 批准并开始派发 / 修改拆分方案 / 返回 coding-workflow 修改方案>
- Reviewer: <user>
- Date: YYYY-MM-DD

## Coordinator Validation Summary

- <filled in as each subtask is checked; one entry per subtask with Ran / Result / acceptance met / deviation>

## Completion

- All subtasks completed: yes / no
- Final validation: <Ran / Result / Not run / Reason>
- Completion record: `<output root>/complete/YYYY-MM-DD-<topic>.md`
```

## Subagent Feedback Contract

The structured feedback block in Step 5 is a REQUIRED field of the subtask's final output, not a prose summary. If a subagent returns without it:

- Treat the subtask as `partial` or `blocked`.
- Do not mark the subtask `completed` in the `Subtask Status` table.
- Re-dispatch with an explicit instruction to return the structured feedback block, or collect the missing fields manually and mark them as coordinator-verified.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Dispatching without a saved plan | Require `coding-workflow` to produce and save the plan first |
| Splitting from chat instead of the plan | Derive every subtask from the plan's ordered steps and traceability rows |
| Skipping the review gate | Use `ask` after writing the subtask document; only option 1 authorizes dispatch |
| Letting a subagent re-decide confirmed choices | Copy invariants and explicit non-changes verbatim into the dispatch prompt |
| Trusting subagent self-report | The coordinator must `check` each claim against the traceability row |
| Parallel dispatch of dependent subtasks | Honor the `Dependencies` field; wait for predecessor acceptance |
| Accepting a silent deviation | Compare against invariants; reject or return to plan revision |
| Completion without evidence | Report Ran / Result / Not run / Reason per `coding-workflow` Step 7 |
| Editing the saved plan | The plan is read-only; to revise, return to `coding-workflow` Step 3 |

## Red Flags - STOP

- "方案差不多，直接拆吧" — no, split strictly from the saved plan's handoff and traceability.
- "子 agent 说完成了，那就完成了" — no, `check` the returned feedback against the traceability row.
- "这个子任务有依赖，但先并行派了再说" — no, honor `Dependencies`.
- "拆分时发现方案有问题，我自己改一下方案" — no, return to `coding-workflow` Step 3.
- "审阅太慢，先派发再补审阅" — no, the review gate is mandatory before any dispatch.

遇到这些想法，停止并回到对应的工作流步骤。
