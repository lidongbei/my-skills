---
name: coding-workflow
description: Use only when the user explicitly invokes /my-skills:coding-workflow, invokes /coding-workflow, or explicitly instructs the agent to use coding-workflow.
disable-model-invocation: true
---

# Coding Workflow

## Overview

Plan first, work in risk-sized loops, and claim completion only with evidence. Lightweight: no full TDD, mandatory reviews, branch finishing, or required subagents.

## Hard Boundaries

- Trigger only when the user explicitly invokes `/my-skills:coding-workflow`, invokes `/coding-workflow`, or explicitly instructs the agent to use `coding-workflow`.
- Do not auto-trigger for ordinary implementation, bug fix, refactor, test/build failure, multi-file change, or plan-continuation requests.
- Do not use this skill for Q&A, tiny mechanical edits, explicit “no plan needed” requests, or continued execution of the same approved plan when scope is unchanged.

## Invocation Scope

After explicit invocation, use for features, bug fixes, refactors, failures, multi-file changes, multiple approaches, or “continue / next step / implement the plan / 按方案做” on non-trivial work.

Non-trivial means a wrong edit could affect behavior, touch multiple files, require design choice, depend on uncertain cause/motivation, or need validation.

## Workflow

### 1. Plan First

Before editing, produce:

```markdown
## Plan Conclusion
- Problem / request:
- Root cause / motivation / current constraint:
- Goal:
- Non-goals:
- Implementation approach:
- Validation:
- Risks / open questions:
```

Emphasis: bugs → root cause; features → motivation/constraints; refactors → friction/safety; workflows/skills → behavior gap/principle. Missing facts? Investigate, then ask if still unclear.

### 2. Self-Review Before Human Review

```markdown
## Self-Review
- Clear cause / motivation / constraint:
- Over-designed:
- Missed requirements:
- User choice needed:
- Validation sufficient:
- Blockers:
```

Fix gaps, investigate, or ask. Do not implement yet.

### 3. Mandatory Plan Response Gate

After `Plan Conclusion` and `Self-Review`, stop and use using-tool's `ask` action to make the user choose exactly one response path before saving, committing, choosing execution mode, or editing files.

The `ask` prompt must be:

> 请选择下一步（必须明确选择其中一项）：

Present these Chinese options in this order without changing their existing semantics:

| Option | Meaning | Next action |
|---|---|---|
| 1. 按推荐确认方案 | 用户接受 agent 推荐的计划方向。 | 按推荐已被接受的前提再次审查计划：确认每个决策是否可由推荐安全覆盖；任何未解决的 Human-required decision 仍必须逐个询问。 |
| 2. 逐个确认问题 | 用户希望逐个解决开放问题或决策。 | 询问第一个未解决的 Human-required question，等待回答，逐个继续，然后更新并再次审查计划。 |
| 3. 改动方案，输入改动内容 | 用户希望在批准前修改方案。 | 要求用户输入要调整的内容，修订 `Plan Conclusion` 和 `Self-Review`，然后回到本 gate。 |

Do not treat silence, “ok”, “继续”, “确认”, or generic approval as permission to skip this gate unless the user explicitly selected one of the three paths or gave equivalent wording.

### 4. Decision Review

After the user chooses “Confirm recommended plan” or completes “Confirm questions one by one”, scan the plan for open questions that affect implementation choices.

Classify each decision point:

| Class | Criteria |
|---|---|
| Agent-recommended | Low-risk, reversible, technical detail with clear best practice; state the choice and proceed unless the user objects |
| Human decision required | Scope change, irreversible action, tradeoff with no clear winner, user-preference-dependent, or needs business context |

Present Human-required items one at a time using using-tool's `ask`. Wait for an answer before moving to the next. Do not batch multiple questions into one message.

For each Human-required item, use this content shape to build the `ask` question and options:

```markdown
Decision: <what needs to be decided>
Impact:   <how it affects implementation>
Options:  <concrete choices if applicable>
My lean:  <Agent recommendation if any>
```

`ask` mapping:

- Use `Decision` as the question.
- Convert each concrete option into one `ask` option.
- Put the recommended option first when there is a clear recommendation, and mark it with “（推荐）”.
- Put option impact/tradeoff in the option description.
- Ask only this one decision; do not include other decisions in the same `ask`.
- Use Chinese labels and descriptions when the surrounding conversation is Chinese.

If there are no Human-required items, state that explicitly and continue.

Do not save, commit, or ask for execution mode until all Human-required decisions are resolved.

### 5. Save, Commit, Ask User To Choose Mode

After explicit approval: save the plan under `docs/plans/YYYY-MM-DD-<topic>.md`, commit the plan to git, then use using-tool's `ask` action to make the user choose the execution mode before implementation unless the user has already explicitly specified it.

Do not ask the user to type `Main agent`, `Single subagent`, or `Multiple subagents` in free text. The execution mode choice must be a structured `ask` choice.

The `ask` prompt must be:

> 请选择实现执行模式：

Present these Chinese options in this order without changing their existing semantics:

| Option | Meaning | Use when |
|---|---|---|
| 1. 主会话直接实现 | Main agent | Small, low-risk, few files |
| 2. 单个子 agent 实现 | Single subagent | Medium, multi-file, or clean main context |
| 3. 多个子 agent 分工 | Multiple subagents | Independent parallel subtasks |

Subagents are optional.

### 6. Single Subagent Worktree Lifecycle

Use this subsection when execution mode is “单个子 agent 实现” and the subagent works in an isolated worktree.

Required lifecycle:

1. Use `agent` to request a candidate implementation in the isolated worktree. The subagent must return changed files, key design notes, and validation evidence; it must not claim the main worktree was changed.
2. Use `check` to review the returned result before accepting it: inspect the diff or summary, compare it with the approved plan, and decide whether the candidate is accepted, needs revision, or is discarded.
3. If accepted, create an implementation commit in the isolated worktree before bringing the work back. Do not merge uncommitted worktree changes into the main worktree.
4. Use `run` / `check` to merge or otherwise bring that commit into the main worktree, then verify the main worktree contains the expected commit and files.
5. After the main worktree has the accepted commit, clean up the isolated worktree. If cleanup is not possible in the runtime, report the leftover worktree path or limitation explicitly.

Do not treat “subagent finished in an isolated worktree” as completion. Completion means the accepted commit is present in the main worktree, validation evidence is reported, and the isolated worktree has been cleaned up or the cleanup limitation has been disclosed.

### 7. Risk-Sized Loops

A step is small enough to identify responsibility and large enough to deserve validation.

| Change | Validation rhythm |
|---|---|
| Mechanical: rename, move, format, copy | Batch validation |
| Behavior: logic, data flow, errors, API | Validate one observable unit |
| Integration: combined behavior, task switch, completion claim | Broader validation |

Use narrow validation first when full validation is expensive. Before completion claims, task switches, or implementation commits, validate strongly enough to support the claim.

### 8. Evidence Before Completion Claims

Final reports must include:

```markdown
## Validation
- Ran:
- Result:
- Not run:
- Reason:
```

Say “not validated” or “validation failed” when true. Do not claim completion with “should be fixed,” “looks fine,” or no evidence.

### 9. Post-Validation Completion Gate

After completing edits and reporting `Validation`, if this workflow produced uncommitted file changes and the user has not already specified the completion action, stop and use using-tool's `ask` action.

Completion results, when recorded, go under:

```text
docs/complete/YYYY-MM-DD-<topic>.md
```

Use the same `<topic>` as the saved plan when one exists; otherwise use a concise kebab-case task topic. If the workflow has a saved plan file, start the completion record with a link to that plan.

The `ask` prompt must be:

> 修改和验证已完成，请选择下一步（必须明确选择其中一项）：

Present these Chinese options in this order. For options 2 and 3, include the concrete planned result path in the option description:

| Option | Meaning | Next action |
|---|---|---|
| 1. 提交 | 只提交本次完成的改动。 | Use `run` to inspect status, commit relevant changes, then report the commit hash. |
| 2. 记录结果并提交 | 将完成结果保存到 `docs/complete/YYYY-MM-DD-<topic>.md`，然后提交。 | Use `edit` to create/update the completion record, use `run` to commit relevant changes, then report the result path and commit hash. |
| 3. 记录结果 | 将完成结果保存到 `docs/complete/YYYY-MM-DD-<topic>.md`，但不提交。 | Use `edit` to create/update the completion record, then report the result path and state that changes remain uncommitted. |
| 4. 保持现状 | 不记录结果、不提交、不推送。 | Report changed files and validation evidence; state that changes remain uncommitted. |

Completion record template:

```markdown
# <Title>

Plan: [<plan title>](../plans/YYYY-MM-DD-<topic>.md) <!-- include only when a saved plan exists -->

## Summary

- 

## Changed Files

- 

## Validation

- Ran:
- Result:
- Not run:
- Reason:

## Completion Choice

- Selected:
- Commit:
```

Do not commit, push, or write a completion record silently. If there are no uncommitted changes, state that and skip this gate.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Immediate edits | Plan and self-review first |
| Treating plan output as approval | After plan and self-review, present the mandatory three-option response gate and wait |
| Guessed cause as fact | Mark uncertainty or investigate |
| Heavy ceremony | Keep lightweight |
| Testing every tiny edit | Use risk-sized validation |
| Choosing execution mode silently | Use using-tool's `ask` action to make the user choose mode after approval unless already specified |
| Asking for execution mode as free text | Use structured `ask` options; do not require the user to type `Main agent`, `Single subagent`, or `Multiple subagents` |
| Saving before resolving decisions | Review human-required decisions after plan approval and resolve them before saving or committing |
| Completion without evidence | Report checks and results |
| Treating isolated subagent work as done | Main agent must review, commit in the isolated worktree, bring the accepted commit into the main worktree, verify it there, and clean up the isolated worktree |
| Ending with uncommitted changes | After validation, use the post-validation completion gate to offer commit / record result and commit / record result / keep current state |
