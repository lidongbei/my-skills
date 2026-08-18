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

### Artifact Root

Plan and completion records are saved under a configurable **artifact root**, not inside the working repository.

Default artifact root: the parent of the current repository root plus `<project name>.agent`, where `<project name>` is the repository directory name. Example: repository `D:\AI\my-skills` → default `D:\AI\my-skills.agent`.

Each runtime mapping defines one project-level location for `coding-workflow` configuration. Read and update only that location; do not guess, scan, or modify other instruction/configuration files. The managed configuration block is:

```markdown
<!-- coding-workflow:artifact-root:start -->
## Coding Workflow Configuration

- Artifact root: `<absolute path>`
<!-- coding-workflow:artifact-root:end -->
```

Resolve the artifact root for the current session, in this order:

1. If a root was already resolved in this session and the user has not explicitly supplied a different path, reuse it.
2. If the user explicitly gave a directory in the invocation or an earlier message, use it and update the current runtime's managed configuration block after validating it.
3. Otherwise, read the current runtime mapping's project-level location. If it contains exactly one valid managed block with a nonempty absolute `Artifact root` path, use that path after validating it.
4. If the current runtime's designated location contains no managed block, the first time a plan or completion record needs to be saved, use using-tool's `ask` action to choose the artifact root once, marking the default as the recommended option. After validation, append the managed configuration block before saving the plan or completion record. If one or more managed blocks exist but do not satisfy step 3, follow the invalid-configuration rule below instead.

If the configured block is malformed, duplicated, or names a root that fails validation, do not silently repair it, fall back to another file, or overwrite the designated location. Use `ask` to explain that persistence is blocked and require the user to resolve the configuration. Do not persist a new root until the designated location contains either no managed block (then append one) or exactly one valid managed block (then replace only that block). Preserve all content outside that block.

Paths under the artifact root:

```text
<artifact root>/plans/YYYY-MM-DD-<topic>.md
<artifact root>/complete/YYYY-MM-DD-<topic>.md
```

Git: the artifact root must be a standalone git repository outside the working repository. Before first writing into it, run `git -C "<artifact root>" rev-parse --show-toplevel`. If it fails, run `git init` in the artifact root. If it resolves to a directory other than the artifact root, do not use or commit into that parent repository; use using-tool's `ask` action to require a separate artifact root. Commit plans and completion records in the artifact-root repository, not the working repository.

### 1. Plan First

Before editing, produce one detailed working plan. It is the source for the approval discussion and, after approval, the saved plan file. It must be specific enough that a later implementation agent can execute it without re-deciding confirmed choices or reconstructing the important context.

```markdown
# <Plan title>

## Plan Conclusion

### Summary
- Problem / request:
- Goal:
- Expected outcome:

### Context and Constraints
- Current behavior / root cause / motivation:
- Existing behavior or components to preserve:
- Constraints and assumptions:

### Source Evidence and Current State
- Evidence anchors:
  - `<path>:<symbol or line range>` — <observed current behavior or constraint>
- Existing flow:
  1. <current step> — <observable behavior or handoff>
- Dependencies and integration points:
  - <caller / callee / external system / job / schema / config>
- Unknowns requiring verification:
  - <fact> — <why it is not yet confirmed>

### Scope
- In scope:
- Out of scope:

### Detailed Implementation
#### <Area / component 1>
- Current state / trigger:
- Change:
- Files / symbols / locations:
- Success, failure, error, and boundary behavior:

#### <Area / component 2>
- Current state / trigger:
- Change:
- Files / symbols / locations:
- Success, failure, error, and boundary behavior:

### Interface and Data Contract
- API / CLI / UI contract:
- Request and response / input and output:
- Data model, persistence, migration, retention, or cleanup:
- Authorization, compatibility, rollback, and failure semantics:

### Requirements Traceability
| Requirement / confirmed decision | Implementation area / file / symbol | Observable acceptance condition | Validation |
|---|---|---|---|
| | | | |

### Implementation Handoff
#### Invariants and non-negotiables
- <confirmed behavior, compatibility, authorization, data, performance, or operational constraint that must remain true>

#### Ordered implementation steps
1. <step> — <files / symbols> — <dependency or precondition> — <expected observable result>

#### Explicit non-changes
- <nearby code, behavior, endpoint, schema, or subsystem that must not change>

#### Deviation protocol
- Treat confirmed decisions, contracts, invariants, and explicit non-changes as implementation constraints; do not re-decide or replace them because another option appears simpler.
- If source evidence contradicts this plan, a prerequisite is unavailable, or a new material trade-off appears: stop the affected step; report the exact contradiction, impacted decision, and viable options; then return to the plan-revision path. Do not silently change scope.

### Validation Plan
- Unit:
- Integration / end-to-end:
- Manual or operational checks:
- Explicitly not run / reason:

### Key Decisions and Changes
| Decision / change | Final choice | Basis / source | Implementation impact | Rejected alternative / reason |
|---|---|---|---|---|
| | | | | |

### Risks and Open Questions
- Risk / mitigation:
- Open question / owner / blocking status:
```

Detail rules:

- Fill only relevant sections. If an interface, data, compatibility, or explicit non-change section is not applicable, write `N/A — <reason>`; do not invent detail to fill the template.
- For every behavior-affecting implementation area, state the current state or trigger, concrete change, location, and observable success/failure/boundary behavior. “Modify related code” is not sufficient.
- Anchor every design-relevant current-state claim to an observed file path plus symbol or line range. Mark unverified facts as `Unknown` or `Assumption`; never write an inference as confirmed fact.
- Record every confirmed decision that affects scope, architecture, API, data, validation, risk treatment, or an agent/user-recommended direction in `Key Decisions and Changes`. Record its final choice, basis/source, implementation impact, and a rejected alternative only when one was explicitly rejected. Do not transcript chat or record irrelevant/repeated discussion.
- Map every in-scope confirmed requirement and key decision in `Requirements Traceability` to an implementation location, observable acceptance condition, and validation. Do not allow an implementation agent to infer this mapping afresh.
- For multi-file, stateful, interface, data, permission, compatibility, cleanup, or asynchronous work, make the ordered steps, dependencies, invariants, and protected adjacent scope explicit in `Implementation Handoff`.
- Every validation target must correspond to an acceptance condition or state why it cannot be run. Do not silently shrink user-confirmed validation scope.

Emphasis: bugs → root cause; features → motivation/constraints; refactors → friction/safety; workflows/skills → behavior gap/principle. Missing facts? Investigate, then ask if still unclear. Match exploration tool to task scope: one `find` (Grep or MCP `search_code`) before dispatching `agent` (Explore); reserve `agent` for genuinely cross-module or uncertain-scope investigation.

### 2. Self-Review Before Human Review

Append this section to the same working plan before presenting it for approval:

```markdown
## Self-Review
- Clear cause / motivation / constraint:
- Evidence and current-state anchors sufficient:
- Scope, invariants, and explicit non-changes clear:
- Requirements traceability complete:
- Key decisions and changes captured:
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
| 3. 改动方案，输入改动内容 | 用户希望在批准前修改方案。 | 要求用户输入要调整的内容，修订完整 working plan（包括受影响的需求追踪、交接约束和关键决策），然后回到本 gate。 |

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

After explicit approval:

1. Render the approved working plan as the detailed saved plan under `<artifact root>/plans/YYYY-MM-DD-<topic>.md`.
2. Before saving or committing, use `check` to verify that:
   - every in-scope confirmed requirement and key decision has a traceability row, implementation location, acceptance condition, and validation or an explicit reason it cannot be validated;
   - confirmed conversation decisions, including user-modified or rejected directions, are captured in `Key Decisions and Changes`;
   - design-relevant current-state claims have evidence anchors or are explicitly marked `Unknown` / `Assumption`;
   - relevant interface, data, authorization, migration/retention/cleanup, compatibility, and failure semantics are explicit;
   - ordered steps, dependencies, invariants, and explicit non-changes are sufficient for a later agent to implement without re-deciding confirmed choices;
   - no unconfirmed fact is presented as a confirmed decision.
3. Fix missing detail or ask the necessary question before saving. Do not save a summary-only plan.
4. Commit the checked plan in the artifact-root repository (resolving and initializing it per the `Artifact Root` step), then use using-tool's `ask` action to make the user choose the execution mode before implementation unless the user has already explicitly specified it.

Do not ask the user to type `Main agent`, `Single subagent`, or `Multiple subagents` in free text. The execution mode choice must be a structured `ask` choice.

The `ask` prompt must be:

> 请选择实现执行模式：

Present these Chinese options in this order without changing the existing semantics of options 1–3:

| Option | Meaning | Use when / next action |
|---|---|---|
| 1. 主会话直接实现 | Main agent | Small, low-risk, few files |
| 2. 单个子 agent 实现 | Single subagent | Medium, multi-file, or clean main context |
| 3. 多个子 agent 分工 | Multiple subagents | Independent parallel subtasks |
| 4. 修改已保存方案 | Revise saved plan | Do not implement. If changes were not supplied with the selection, ask for them; revise the complete working plan, then return to Step 3. |

Only options 1, 2, and 3 authorize implementation. Option 4 is a plan-revision path, not implementation authorization. Do not edit implementation files, start implementation agents, create or enter an implementation worktree, or run implementation validation until the user explicitly selects option 1, 2, or 3, or explicitly specified an equivalent execution mode before this ask. Silence, “继续”, “尽快做”, “直接开始”, “确认”, generic approval, or any other non-equivalent wording is not implementation authorization.

After the user chooses option 4:

1. Stop the execution path. Do not perform any implementation step.
2. If the user did not supply the requested changes with option 4, use `ask` to collect them.
3. Use the saved plan file as the read-only source for a complete working plan. Revise every affected section, including `Requirements Traceability`, `Implementation Handoff`, `Key Decisions and Changes`, and `Self-Review`; the prior approval is no longer valid. Do not update the saved plan file yet.
4. Return to Step 3. After the user reapproves and all Step 4 Human-required decisions are resolved, update the same saved plan file and create a new plan-revision commit in the artifact-root repository; do not amend or overwrite the prior plan commit.
5. Ask the execution-mode question again. Do not implement until the user selects option 1, 2, or 3.

Subagents are optional.

### 6. Single Subagent Worktree Lifecycle

Use this subsection when execution mode is “单个子 agent 实现” and the subagent works in an isolated worktree.

Required lifecycle:

1. Use `agent` to request a candidate implementation in the isolated worktree. Give the agent the saved plan path and require it to `read` the entire plan before implementation. The agent must treat `Requirements Traceability`, `Key Decisions and Changes`, `Implementation Handoff`, and the deviation protocol as implementation constraints, not suggestions. Its return must include: fulfilled requirements/acceptance conditions; changed files and symbols; protected scopes left unchanged; every plan deviation (or `None`); and validation evidence. It must not claim the main worktree was changed.
2. Use `check` to review the returned result before accepting it: inspect the diff and summary, compare them with the approved plan and its traceability rows, verify each confirmed decision and protected scope was honored, and decide whether the candidate is accepted, needs revision, is returned to plan revision, or is discarded. Reject any unapproved material deviation or scope expansion.
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
<artifact root>/complete/YYYY-MM-DD-<topic>.md
```

Use the same `<topic>` as the saved plan when one exists; otherwise use a concise kebab-case task topic. If the workflow has a saved plan file, start the completion record with a link to that plan.

The `ask` prompt must be:

> 修改和验证已完成，请选择下一步（必须明确选择其中一项）：

Present these Chinese options in this order. For options 2 and 3, include the concrete planned result path in the option description:

| Option | Meaning | Next action |
|---|---|---|
| 1. 提交 | 只提交本次完成的改动。 | Use `run` to inspect status, commit relevant changes, then report the commit hash. |
| 2. 记录结果并提交 | 将完成结果保存到 `<artifact root>/complete/YYYY-MM-DD-<topic>.md`，然后提交。 | Use `edit` to create/update the completion record, use `run` to commit relevant changes, then report the result path and commit hash. |
| 3. 记录结果 | 将完成结果保存到 `<artifact root>/complete/YYYY-MM-DD-<topic>.md`，但不提交。 | Use `edit` to create/update the completion record, then report the result path and state that changes remain uncommitted. |
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
| Treating a saved plan as a commitment to implement | Offer `修改已保存方案`; if selected, return to plan revision and reapproval without implementing |
| Starting implementation without a chosen mode | Only options 1, 2, and 3 authorize implementation; option 4, silence, generic approval, or “继续” do not |
| Saving before resolving decisions | Review human-required decisions after plan approval and resolve them before saving or committing |
| Saving a summary-only plan | Save the complete handoff plan with evidence anchors, traceability, implementation constraints, validation, and key decisions |
| Leaving confirmed decisions only in chat | Record every implementation-affecting confirmed decision in `Key Decisions and Changes` with source and impact |
| Letting an implementation agent re-decide confirmed choices | Require it to read the saved plan and honor traceability, invariants, explicit non-changes, and the deviation protocol |
| Accepting a silent implementation deviation | Compare the candidate against traceability rows and reject or return to plan revision when a material deviation lacks approval |
| Completion without evidence | Report checks and results |
| Treating isolated subagent work as done | Main agent must review, commit in the isolated worktree, bring the accepted commit into the main worktree, verify it there, and clean up the isolated worktree |
| Ending with uncommitted changes | After validation, use the post-validation completion gate to offer commit / record result and commit / record result / keep current state |
| Over-exploring simple tasks | Match search tool to task scope; run one `find` (Grep or MCP `search_code`) before dispatching `agent` (Explore); reserve `agent` for genuinely cross-module or uncertain-scope investigation |
