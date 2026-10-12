---
name: subagent-takeover
description: Use when coding-workflow selected the multiple-subagents execution mode and routed here, or when the user explicitly invokes /my-skills:subagent-takeover, invokes /subagent-takeover, or explicitly instructs the agent to use subagent-takeover to split an approved plan into reviewed subtasks.
---

# Subagent Takeover

## Overview

Take over after an approved `coding-workflow` plan when the chosen execution mode is **multiple subagents**. Split the approved plan into a human-reviewable subtask document, execute the subtasks through a **resolved dispatch backend**, and validate each subtask's structured feedback against the plan's traceability rows before claiming completion.

Core principle: the saved plan is the only source of truth. Subagents do not re-decide confirmed choices; the coordinator does not trust unverified subagent self-reports.

Second principle: **delegation is not portable, the contract is**. Runtimes differ in whether a native subagent exists, whether dispatch can block, how many may run at once, and whether one can be resumed by handle. The subtask document, the dispatch prompt content, the feedback file, and the status table are identical across runtimes; only the execution mechanism changes. See `Dispatch Backend`.

## Hard Boundaries

- Trigger only in these cases:
  - `coding-workflow` Step 5 selected the "多个子 agent 分工" execution mode and routed here. In that case trigger immediately after that selection, without asking the user to invoke this skill again.
  - The user explicitly invokes `/my-skills:subagent-takeover`, invokes `/subagent-takeover`, or explicitly instructs the agent to use `subagent-takeover`.
- Do not auto-trigger from phrases such as "拆分任务", "并行执行", "派发子 agent", "分工", or "分给多个 agent". If the user has not invoked this skill and coding-workflow has not routed to it, continue normally or suggest the slash command.
- Do not run without an approved, saved plan file under `<output root>/plans/YYYY-MM-DD-<topic>.md`. If no saved plan exists, stop and ask the user to run `coding-workflow` first.
- Do not edit the saved plan file. It is read-only for this skill. To revise the plan, return to `coding-workflow` Step 3 (修改已保存方案).
- Do not dispatch any subagent before the subtask document is approved by the user through the mandatory review gate.
- Do not dispatch before resolving and recording the dispatch backend per `Dispatch Backend`. Never silently fall through to a different backend mid-flow, and never report a subtask as executed by a mechanism that was not available.
- Do not claim a subtask complete based on a subagent's self-report alone. The coordinator must `check` the returned structured feedback against the corresponding traceability row.
- On a runtime with no delegation capability, do not pretend a subagent ran. Use the declared or resolved backend, including `sequential`, and say plainly which mechanism executed the subtask.
- Never dispatch a subagent and then end the turn on a bare agent handle. There is no blocking-wait primitive for external work: the coordinator is only re-invoked when the runtime injects a completion event, and an exited process breaks that notification chain. Dispatch blocking per Step 4, and never close with a row still in `dispatched` state. The only exception is the `manual` backend, whose rows end the turn in `awaiting-user`, not `dispatched`.
- Never treat a subagent's final message as a durable artifact. The message arrives through the same completion notification, so it is lost with the process. The feedback file on disk is the only record the coordinator may validate from.
- When invoked by the user directly rather than routed from `coding-workflow`, the approved saved plan requirement still applies: without it, stop and ask the user to run `coding-workflow` first.

## Output Root

Resolve the output root exactly as `coding-workflow` does. Read and honor the same managed block in the current runtime's designated project-level configuration location (Claude Code: `.agents/my-skills-local-config.md`):

```markdown
<!-- agent-output-root:start -->
## Agent Output Configuration

- Output root: `<absolute path>`
<!-- agent-output-root:end -->
```

Use the same resolution order and the same invalid-configuration rule as `coding-workflow`. Do not re-derive a different root. Do not read, recognize, migrate, or reuse legacy `coding-workflow:artifact-root` blocks. When the output root is missing or needs repair, delegate the create/repair to `configuring-plugin`; this skill only reads the value.

Paths under the output root for this skill:

```text
<output root>/subTasks/YYYY-MM-DD-<topic>.md
<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md
<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-dispatch.md
```

The per-subtask feedback files are durable records, not scratch output. They must survive the coordinator process and be written by the subtask executor itself; see Step 5 and the Resume Protocol. The dispatch-prompt file is written only for the `manual` backend, where the prompt must be handed to a different session or client.

Git: apply the same output-root git rule as `coding-workflow`. Commit the subtask document in the output-root repository only when the output root is a git repository; otherwise skip the commit and treat it as ignored. Do not commit into the working repository.

## Dispatch Backend

Do not assume the current runtime has a native subagent with any particular dispatch semantics. Resolve exactly one backend **before** splitting, and record it in the subtask document.

Read the managed block in the same project-level configuration file used for the output root (Claude Code: `.agents/my-skills-local-config.md`):

```markdown
<!-- agent-dispatch:start -->
## Agent Dispatch Configuration

- Backend: native | cli | sequential | manual
- CLI template: <command that runs one headless agent for one prompt file>
- Max parallel: <integer, default 1>
- Subagent model: inherit | <provider/model>
<!-- agent-dispatch:end -->
```

Resolution order:

1. If the block declares a valid `Backend`, use it.
2. Otherwise take the default backend from the current runtime file's `Subagent Dispatch Capability` section under `skills/using-tool/runtimes/`.
3. If neither is available, resolve `native` → `cli` → `sequential` → `manual`, taking the first backend the runtime can actually perform.

`CLI template` is required for the `cli` backend and is a free-form command declared by the user or the project; do not invent a headless command for a runtime that does not document one. `Max parallel` defaults to `1` when absent, which is the correct default when the model is served behind a local proxy. `Subagent model` records whether the subtask runs on the same model as the coordinator; when it is not `inherit` and the runtime cannot pin a model, prefer `cli`, because a spawned process carries its own model configuration.

Creating or repairing the `agent-dispatch` managed block is owned by `configuring-plugin`. When the user wants a non-default backend persisted, or the block is missing, malformed, or duplicated, delegate that create/repair to `configuring-plugin`; this skill resolves the backend from the resulting block or the runtime default, and never writes the block itself.

| Backend | How a subtask is executed | Turn-ending state |
|---|---|---|
| `native` | The runtime's own subagent tool, dispatched in its blocking form per the runtime file. | none — result consumed in the same turn |
| `cli` | `run` launches the declared CLI template once per subtask with absolute prompt and feedback paths; the coordinator waits for the process and reads the feedback file. | none — result consumed in the same turn |
| `sequential` | No delegation. The coordinator executes the subtask itself, then immediately writes the feedback file itself. | none — the row advances inside the turn |
| `manual` | The coordinator writes `SUB-<nn>-dispatch.md` for the user to run in another session or client. | `awaiting-user` |

All four backends produce the same artifacts and the same status transitions; only the executor differs. A subtask's `Backend` must be stated in the subtask document, and the `Subtask Status` table must show the mechanism used when it is not `native`.

## Workflow

### 0. Prerequisites

Before splitting:

1. Use `read` to load the approved saved plan `<output root>/plans/YYYY-MM-DD-<topic>.md`. If it is missing, stop and use `ask` to tell the user to run `coding-workflow` first.
2. Confirm the `<topic>` (kebab-case) used by the saved plan filename; reuse it for the subtask document filename.
3. Resolve the output root per the `Output Root` section above.
4. Resolve the dispatch backend per `Dispatch Backend`, including `Max parallel` and `Subagent model`, and read the current runtime file's `Subagent Dispatch Capability` section. If the resolved backend is `cli`, confirm the `CLI template` exists before splitting; if no template is declared and the runtime has no native subagent, resolve to `sequential` instead of improvising a command.
5. State the resolved backend to the user in one line as part of the review gate, so a degradation is visible before any work is dispatched, not after.

### 1. Split Into Subtasks

Derive subtasks from the saved plan's `Implementation Handoff` ordered steps and `Requirements Traceability` rows — not from chat. Each subtask must be:

- Independent enough to be dispatched to one subagent without blocking another, unless an explicit dependency is recorded.
- Anchored to the plan's traceability: every subtask cites at least one traceability row (requirement → implementation location → acceptance condition → validation).
- Self-contained: the subagent receives the files/symbols, invariants, explicit non-changes, success/failure/boundary behavior, and validation target without needing to re-read the full plan.

If a plan step cannot be split into an independent subtask (it touches shared state, has an unavoidable ordering dependency, or its validation depends on another step's output), keep it as a sequential subtask and record its dependency on the predecessor subtask id. Do not force parallelism.

### 2. Write The Subtask Document

Use `edit` to create `<output root>/subTasks/YYYY-MM-DD-<topic>.md` with the required template below. Use the current local date. Use the same `<topic>` as the saved plan.

In the same step, create the per-subtask feedback skeleton at `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md` for every subtask. The skeleton contains the complete feedback structure with every value replaced by the literal placeholder `未填`. This is the **skeleton-first rule**: the executor's job becomes replacing placeholders rather than generating a structure, which is the difference between working and not working on a small model served behind a local proxy. A generated-structure contract fails far more often than a fill-in-the-blank contract.

The skeleton must open with this machine-checkable head block, so the coordinator can verify the basics before reading prose:

```markdown
status: 未填
files: 未填
validation-ran: 未填
validation-result: 未填
```

Creating a skeleton does not authorize a subtask to be marked complete: an executor that writes no file, or leaves placeholders in place, is `partial` or `blocked` per Step 5.

### 3. Mandatory Review Gate

After writing the subtask document, stop and use `ask` to make the user choose exactly one path before dispatching any subagent.

The `ask` prompt must be:

> 子任务拆分文档已生成，请选择下一步（必须明确选择其中一项）：

When the resolved backend is anything other than `native`, or the plan has more than one dependency-free subtask while `Max parallel` is 1, the prompt must state the execution mechanism and the concurrency in the same message, for example: 「本次执行后端：sequential（当前运行时无子 agent / 本地代理模型），并发上限 1，本次为串行执行」。Do not let a degradation be discovered after dispatch.

Present these Chinese options in this order:

| Option | Meaning | Next action |
|---|---|---|
| 1. 批准并开始派发 | 用户接受拆分方案。 | Commit the subtask document if the output root is a git repository, then proceed to Step 4. |
| 2. 修改拆分方案 | 用户希望调整子任务划分。 | Ask for the requested changes, revise the subtask document, then return to this gate. Do not dispatch. |
| 3. 返回 coding-workflow 修改方案 | 拆分暴露了方案本身的问题。 | Stop this skill. Tell the user to re-run `coding-workflow` Step 3 (修改已保存方案). Do not dispatch. |

Do not treat silence, "ok", "继续", "确认", or generic approval as permission to dispatch. Only option 1 (or equivalent explicit wording) authorizes dispatch.

### 4. Dispatch Subagents

Dispatch each subtask through the backend resolved in Step 0. The backend changes **how** the subtask is executed, never **what** the executor receives or must produce. Ordering is governed by the subtask's `Dependencies` field in every backend:

- Subtasks with no dependencies may be dispatched concurrently, up to `Max parallel`.
- A subtask with a dependency is dispatched only after its predecessor's feedback has been `check`-ed and accepted.

| Backend | Dispatch action |
|---|---|
| `native` | Call the runtime's subagent tool once per subtask, in the blocking form declared by the current runtime file. |
| `cli` | Use `run` to launch the declared `CLI template` once per subtask, passing the subtask's absolute prompt and feedback paths; wait for the process to exit, then read the feedback file. A non-zero exit is not a `completed` subtask. |
| `sequential` | Do not delegate. Execute the subtask yourself in this turn, then write the feedback file yourself and mark the row `feedback-received` in the same turn. Step 5 then reviews the change as coordinator evidence, not as a self-report. |
| `manual` | Write the prompt to `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-dispatch.md`, set the row to `awaiting-user`, and tell the user exactly which subtasks to run and where to put the feedback files. Re-enter via the Resume Protocol when they return. |

**Execution must be turn-bound.** For `native`, `cli`, and `sequential`, the result is produced and consumed inside the same turn. Do not dispatch background work and then end the turn on the returned handles. There is no blocking-wait primitive for external work in this architecture — the coordinator is only re-invoked when the runtime injects a completion event, and an exited process breaks that chain — so a background dispatch followed by a silent turn end can lose the subtask's result and the rest of the flow permanently. `awaiting-user` is the only legal turn-ending state, and only for the `manual` backend.

Rules:

1. Concurrency is capped by `Max parallel` (default 1). Never dispatch more subtasks at once than the backend can actually run.
2. On a runtime whose capability table limits dispatch to one call per response, or when `Max parallel` is 1, dispatch one subtask, consume its feedback, then dispatch the next. Do not translate a parallel plan into simultaneous calls.
3. Only when `Max parallel` is greater than 1 **and** the runtime file permits multiple dispatch calls per response may independent subtasks go in ONE message as multiple calls, so they run concurrently while the coordinator stays inside the same turn.
4. For `native`, always pass the runtime's blocking form (Claude Code: `run_in_background: false`; DSH: `run_in_background: false`). Background dispatch is allowed only when the coordinator still has other concrete work to do in the same turn before consuming the result — never as the final action of a turn.
5. Record every dispatch in the subtask document's `Subtask Status` table before relying on its result: mechanism used, executor handle or process reference when one exists, dispatch time, and state `dispatched`. Update the row to `feedback-received` as each feedback file lands.
6. If a dispatch returns no usable result, or the executor dies, do not end the turn silently. Apply the Resume Protocol below.
7. Never end a turn, and never report progress to the user, while any row is still `dispatched` with no feedback file on disk.

Each dispatch prompt MUST contain, at minimum:

1. The subtask id, title, and goal.
2. The files/symbols/locations to change and the explicit change.
3. The invariants and explicit non-changes from the plan (copy verbatim from the subtask document).
4. The success, failure, error, and boundary behavior.
5. The validation target and acceptance condition.
6. The instruction: "You may use `read`, `find`, `edit`, `run`, and `check` as needed to complete this subtask. Do not re-decide confirmed choices. If source evidence contradicts the subtask, stop and report the contradiction instead of improvising."
7. The instruction: "Do not attempt to make multiple tool calls in one message. Complete the work one step at a time."
8. The instruction: "`<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md` already exists as a skeleton. Use `edit` to REPLACE each `未填` placeholder in place. Do not restructure the file, do not delete sections, and do not replace the whole file. Write the file even if you are blocked or partial, and leave any placeholder you genuinely cannot fill."
9. Keep the prompt short. The subtask document on disk carries the detail; the prompt carries paths and the fill-in instruction. Do not paste the whole plan into the prompt — small local models have small context windows.

For `native` and `cli`, also include: "Before your final message, ensure the feedback file above is complete. The file is the durable record; the message may be lost, so never rely on the message alone."

Do not give an executor freedom to change scope, contracts, or explicit non-changes. If an executor reports a contradiction or a prerequisite unavailable, stop that subtask and return to the plan-revision path via `coding-workflow` Step 3.

The dispatch prompt text is recorded in the subtask document's `Dispatch prompt` field for every backend, including `sequential`, where it becomes the coordinator's own execution brief.

### 5. Receive And Validate Structured Feedback

Every subtask executor MUST leave its result as this structured feedback in the feedback file. A result that is prose without this structure is treated as incomplete — including when the executor is the coordinator itself under the `sequential` backend.

Durable record first: the authoritative feedback is the file `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md` written by the executor, not its final message. Read the file with `read` before validating. If either is missing or truncated, treat the subtask as `partial` or `blocked` and apply the Resume Protocol instead of guessing.

If the process never re-invoked the coordinator, the feedback file still exists on disk. Recovery never depends on the coordinator's in-memory handle.

Validate the machine-checkable head block first, so a weak model's empty output is caught by a command rather than by judgement:

1. Use `find`/`read` to confirm the file exists and is non-empty.
2. Read the head block. Any value still equal to `未填`, or any missing key, means the subtask is `partial` or `blocked` — do not proceed to the prose.
3. Only then read the body.

```markdown
status: completed | partial | blocked
files: <comma-separated paths, or none>
validation-ran: <command or check>
validation-result: <pass | fail | not-run + one-line evidence>

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
- Every acceptance condition is verified as met with concrete evidence, not the executor's assertion.
- Evidence must be command-level: an exit code, a file that exists with the expected content, a `grep` hit, or a test result. When the coordinator itself runs on a local-proxy model, "looks correct" and "appears to satisfy the requirement" are not acceptable evidence, and a self-authored feedback file under `sequential` is never sufficient on its own.
- Any deviation is compared against the plan's invariants and explicit non-changes. A material deviation without prior approval is rejected; the coordinator returns to `coding-workflow` Step 3 for plan revision.
- If validation is expensive, run narrow validation first (the subtask's own acceptance condition), then broader validation before a completion claim or task switch, per `coding-workflow` Step 6 risk-sized loops.

Record the validation result in the subtask document's `Subtask Status` table.

### 6. Completion Gate

After all subtasks are `check`-ed and accepted:

1. Update the subtask document's `Subtask Status` table so every row is `completed` with validation evidence.
2. Report final `Validation` per `coding-workflow` Step 7 (Ran / Result / Not run / Reason).
3. Apply `coding-workflow` Step 8 post-validation completion gate if this workflow produced uncommitted file changes in the working repository. Completion records go under `<output root>/complete/YYYY-MM-DD-<topic>.md` and must link to both the saved plan and the subtask document.

Do not claim completion with "should be fixed", "looks fine", or no evidence. Do not let an executor's "completed" status override a failed coordinator `check`. When the backend was `sequential` or `manual`, state that in the completion report so the user knows no independent executor was involved.

### 7. Resume Protocol

Use this whenever the coordinator is re-invoked after an interruption, when a row is stuck in `dispatched` or `awaiting-user` with no usable feedback file, or when an executor died mid-write.

1. Use `read` on `<output root>/subTasks/YYYY-MM-DD-<topic>.md` to recover the subtask, the resolved backend, and the `Subtask Status` state. Never rely on remembered state; a new coordinator invocation may start with no context.
2. For each row not yet `completed`, use `find`/`read` to check whether `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md` exists and is a complete block with no remaining `未填` placeholder in the head block.
3. If a complete feedback file exists, validate it per Step 5 and update the row. Do not re-dispatch a subtask whose feedback file is complete and valid.
4. If the file is missing or truncated, re-dispatch that subtask only, **using the same backend recorded in the subtask document**. Do not silently upgrade the backend on recovery:
   - `native`: prefer the runtime's resume-by-handle form with the recorded handle; if the handle is gone, dispatch a fresh subagent with the same subtask prompt.
   - `cli`: re-run the recorded `CLI template` for that subtask.
   - `sequential`: execute the subtask yourself and write the feedback file yourself.
   - `manual`: re-issue `SUB-<nn>-dispatch.md` and return the row to `awaiting-user`.
   Re-dispatching is safe only after `check`-ing what already landed on disk, so a partially applied change is not duplicated.
5. Never re-dispatch a subtask whose changes you have not inspected. A dead executor may have left a half-applied edit.
6. After recovery, continue the normal Step 4 → Step 5 → Step 6 flow. Record the interruption and the recovery action in the subtask document's `Coordinator Validation Summary`.

A subtask document alone is not enough to prevent this failure. The three defenses are: turn-bound dispatch (Step 4), the on-disk feedback file (Step 5), and this re-entry protocol. All three are required; removing any one re-opens the same loss.

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
- Dispatch backend: native | cli | sequential | manual
- Backend source: declared in `.agents/my-skills-local-config.md` / runtime default (`<runtime>`) / resolution order
- Max parallel: <n>
- Subagent model: inherit | <provider/model> | unknown

## Subtask Split Principles

- <how the plan's ordered steps and traceability rows were mapped to subtasks>
- <which subtasks are concurrent and which are sequential, and why>
- <how the resolved backend and `Max parallel` constrain that concurrency>

## Subtasks

### SUB-<nn> — <subtask title>

- Goal: <what this subtask accomplishes>
- Executor / backend: <native subagent | cli process | coordinator | user, plus the backend name>
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
- Feedback file: `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md`
- Dispatch prompt file (`manual` backend only): `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-dispatch.md`
- Dispatch prompt: <the full prompt given to the executor, including the fill-in-place feedback instruction and, for native/cli, the feedback-file requirement>

## Subtask Status

`State` is the dispatch lifecycle: `pending` → `dispatched` → `feedback-received` → `completed`. A row must never be left in `dispatched` at the end of a turn, and `completed` requires a validated feedback file. The `manual` backend adds one legal turn-ending state: `dispatched` → `awaiting-user` → `feedback-received` → `completed`.

| Subtask | State | Backend | Executor handle / process | Dispatched at | Validation evidence | Deviation | Notes |
|---|---|---|---|---|---|---|---|
| SUB-01 | pending | <backend> | — | — | — | — | — |
| SUB-02 | pending | <backend> | — | — | — | — | — |

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

The structured feedback is a REQUIRED field of the subtask's delivered result, and its authoritative form is the file on disk written by the executor — not a prose summary and not the executor's final message. If the executor leaves the file incomplete:

- Treat the subtask as `partial` or `blocked`.
- Do not mark the subtask `completed` in the `Subtask Status` table.
- For a placeholder still equal to `未填`, or a missing section, re-dispatch with the explicit instruction to replace placeholders in place, or let the coordinator fill the fields manually and record them as coordinator-verified in `Coordinator Validation Summary`.
- Under the `sequential` backend the coordinator is both author and validator. Say so explicitly in the subtask document and require command-level evidence in Step 5; do not present a self-authored feedback file as independent verification.

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
| Dispatching background subagents, then ending the turn | Dispatch blocking (`run_in_background: false`) and consume the result in the same turn |
| Treating the subagent's final message as the record | Require the on-disk feedback file; validate from the file, not the message |
| Leaving a row in `dispatched` with no feedback file | Apply the Resume Protocol before ending the turn or reporting progress |
| Re-dispatching after an interruption without checking disk | Inspect what landed first; a dead subagent may have left a half-applied edit |
| Assuming the runtime has a native subagent with blocking dispatch | Resolve the dispatch backend and read the runtime file's Subagent Dispatch Capability before splitting |
| Parallel dispatch on a runtime limited to one call per response | Serialize; on CodeArts only one `task` call per response is allowed |
| Parallel dispatch against a local-proxy model server | Keep `Max parallel` at 1 unless the server is known to serve concurrent requests |
| Upgrading the backend during recovery | Re-dispatch with the backend recorded in the subtask document |
| Asking the executor to generate the feedback structure | Pre-create the skeleton in Step 2 and require in-place placeholder replacement |
| Treating a self-authored feedback file as independent verification | Under `sequential`, require command-level evidence and say the coordinator was both author and validator |
| Dispatching without knowing which model the executor runs on | Record `Subagent model`; when the runtime cannot pin the proxy model, prefer the `cli` backend, which carries its own model configuration |

## Red Flags - STOP

- "方案差不多，直接拆吧" — no, split strictly from the saved plan's handoff and traceability.
- "子 agent 说完成了，那就完成了" — no, `check` the returned feedback against the traceability row.
- "这个子任务有依赖，但先并行派了再说" — no, honor `Dependencies`.
- "拆分时发现方案有问题，我自己改一下方案" — no, return to `coding-workflow` Step 3.
- "审阅太慢，先派发再补审阅" — no, the review gate is mandatory before any dispatch.
- "先后台派发，等通知来了再收" — no, dispatch blocking; there is no guarantee the waiting process survives to receive the notification.
- "子 agent 消息里有反馈就够了" — no, require the on-disk feedback file; the message dies with the process.
- "主 Agent 断了就重跑整个skill" — no, run the Resume Protocol and recover from `Subtask Status` plus the feedback files.
- "这个客户端没有子 agent，我就当有子 agent 用吧" — no, resolve the backend and use `sequential` or `cli`; say plainly which mechanism ran.
- "本地模型也能开 4 个并行" — no, `Max parallel` defaults to 1; local inference servers usually serve one request at a time.
- "反馈格式让子 agent 自己写" — no, pre-create the skeleton and require in-place replacement.
- "反馈文件里写 completed 就是完成了" — no, `check` command-level evidence; a self-authored file is not verification.
- "恢复时换个更快的后端" — no, re-dispatch with the backend recorded in the subtask document.

遇到这些想法，停止并回到对应的工作流步骤。
