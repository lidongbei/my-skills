---
name: coding-workflow
description: Use only when the user explicitly invokes /my-skills:coding-workflow, invokes /coding-workflow, or explicitly instructs the agent to use coding-workflow.
disable-model-invocation: true
---

# Coding Workflow

## Overview

Plan first, work in risk-sized loops, and claim completion only with evidence. Lightweight: no full TDD, mandatory reviews, or branch finishing. Multiple-subagent execution is owned by the separate `subagent-takeover` skill, not this workflow.

## Hard Boundaries

- Trigger only when the user explicitly invokes `/my-skills:coding-workflow`, invokes `/coding-workflow`, or explicitly instructs the agent to use `coding-workflow`.
- Do not auto-trigger for ordinary implementation, bug fix, refactor, test/build failure, multi-file change, or plan-continuation requests.
- Do not use this skill for Q&A, tiny mechanical edits, explicit “no plan needed” requests, or continued execution of the same approved plan when scope is unchanged.

## Invocation Scope

After explicit invocation, use for features, bug fixes, refactors, failures, multi-file changes, multiple approaches, or “continue / next step / implement the plan / 按方案做” on non-trivial work.

Non-trivial means a wrong edit could affect behavior, touch multiple files, require design choice, depend on uncertain cause/motivation, or need validation.

## Workflow

### Output Root

Plan and completion records are saved under a configurable **output root**. The same output-root configuration is shared by `coding-workflow`, `generating-reqable-docs`, and `subagent-takeover`.

Default output root: `<repository root>/.agent-output`, inside the working repository, so a single-folder workspace can see and manage the records. An absolute path outside the workspace (for example the repository's parent directory plus `<project name>__agent`) is also valid when the user explicitly chooses it.

Each runtime mapping defines one project-level location for shared output-root configuration. Read and update only that location; do not guess, scan, or modify other instruction/configuration files. The managed configuration block lives in the git-ignored local markdown file designated by the runtime mapping (`.my-skills-local-config.md`):

```markdown
<!-- agent-output-root:start -->
## Agent Output Configuration

- Output root: `<absolute path>`
- Records: ignored-in-workspace | committed-in-workspace | standalone-repo | unmanaged
<!-- agent-output-root:end -->
```

Resolve the output root for the current session, in this order:

1. If a root was already resolved in this session and the user has not explicitly supplied a different path, reuse it.
2. If the user explicitly gave a directory in the invocation or an earlier message, use it after validating it. To persist that value, delegate the write to `my-config-manager`; do not write the managed block here.
3. Otherwise, read the current runtime mapping's project-level location. If it contains exactly one valid managed block with a nonempty absolute `Output root` path and a valid `Records` disposition, use that path after validating it.
4. If the designated location has no managed block, or holds a malformed, duplicated, or legacy-only configuration, hand off to `my-config-manager` to create or repair the output-root configuration interactively, then use the value it reports.

Creating or repairing the managed block is owned by `my-config-manager`; `coding-workflow` only reads and validates the value. Do not read, recognize, migrate, or reuse legacy `coding-workflow:artifact-root` blocks. Do not silently repair a malformed or duplicated block, fall back to another file, or overwrite the designated location; that repair is `my-config-manager`'s delegated job, decided by the user.

Paths under the output root:

```text
<output root>/plans/YYYY-MM-DD-<topic>.md
<output root>/complete/YYYY-MM-DD-<topic>.md
```

Git: the block's `Records` line fixes how the plans and completion records relate to version control — follow the configured disposition, never the path's location alone:

- **`committed-in-workspace`**: commit plans and completion records in the working repository, following its existing rules. If the working repository ignores the output root (for example `git check-ignore -q "<output root>"` succeeds), do not force-add it: leave the records uncommitted, say so, and report the mismatch — the disposition and reality disagree, and a `my-config-manager` Modify run resolves it.
- **`ignored-in-workspace`**: never commit the records; they stay local by design. If `git check-ignore` shows the output root is not actually ignored, report the mismatch — writing the ignore rule is `my-config-manager`'s side effect, not this skill's.
- **`standalone-repo`**: commit plans and completion records in the output-root repository (`git -C "<output root>" ...`). If the output root is not a git repository, the disposition was never applied — report it and delegate to `my-config-manager` instead of running `git init` here.
- **`unmanaged`**: skip the commit and say the records stay unversioned.

Refuse an output root that is the working repository root itself — records need their own directory — and use using-tool's `ask` action to require a subdirectory. Never commit records that live outside the working repository into the working repository, and never commit into an unrelated parent repository. This Git requirement applies only to `coding-workflow` plan and completion records; it does not require `generating-reqable-docs` outputs to be committed.

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

> 请选择下一步（必须明确选择其中一项，或直接输入改动内容）：

Present these Chinese options in this order without changing their existing semantics:

| Option | Meaning | Next action |
|---|---|---|
| 1. 按推荐确认方案 | 用户接受 agent 推荐的计划方向。 | 按推荐已被接受的前提再次审查计划：确认每个决策是否可由推荐安全覆盖；任何未解决的 Human-required decision 仍必须逐个询问。 |
| 2. 逐个确认问题 | 用户希望逐个解决开放问题或决策。 | 询问第一个未解决的 Human-required question，等待回答，逐个继续，然后更新并再次审查计划。 |

Changes are not a third listed option. Free-text input at this gate is the change path: any user reply that specifies changes to the plan means “modify the plan with this content”. See “Free-text change input” below.

Do not treat silence, “ok”, “继续”, “确认”, or generic approval as permission to skip this gate unless the user explicitly selected option 1 or 2, gave equivalent wording, or supplied plan changes as free text.

#### Free-text change input

When the user replies with plan changes instead of selecting option 1 or 2 — for example “把第 3 步改成先做 X”, “不要用 Y 方案”, or any concrete adjustment — treat it as the change path:

1. Use the supplied content as the changes. Do not ask the user to restate them.
2. Revise the complete working plan (including affected requirements traceability, handoff constraints, and key decisions).
3. Return to this gate.

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

1. Render the approved working plan as the detailed saved plan under `<output root>/plans/YYYY-MM-DD-<topic>.md`.
2. Before saving or committing, use `check` to verify that:
   - every in-scope confirmed requirement and key decision has a traceability row, implementation location, acceptance condition, and validation or an explicit reason it cannot be validated;
   - confirmed conversation decisions, including user-modified or rejected directions, are captured in `Key Decisions and Changes`;
   - design-relevant current-state claims have evidence anchors or are explicitly marked `Unknown` / `Assumption`;
   - relevant interface, data, authorization, migration/retention/cleanup, compatibility, and failure semantics are explicit;
   - ordered steps, dependencies, invariants, and explicit non-changes are sufficient for a later agent to implement without re-deciding confirmed choices;
   - no unconfirmed fact is presented as a confirmed decision.
3. Fix missing detail or ask the necessary question before saving. Do not save a summary-only plan.
4. Commit the checked plan in the repository that owns the output root — the working repository when the output root is inside it — following the `Output Root` git rule. If that repository does not commit the records (no git repository, or the output root is ignored), skip the commit and treat it as ignored. Then use using-tool's `ask` action to make the user choose the execution mode before implementation unless the user has already explicitly specified it.

Do not ask the user to type `Main agent` or `Multiple subagents` in free text. The execution mode choice must be a structured `ask` choice.

The `ask` prompt must be:

> 请选择实现执行模式：

Present these Chinese options in this order without changing the existing semantics of options 1–2:

| Option | Meaning | Use when / next action |
|---|---|---|
| 1. 主会话直接实现 | Main agent | Small, low-risk, few files |
| 2. 多个子 agent 分工 | Route to `subagent-takeover` | Independent parallel subtasks. Do not dispatch inline; hand off to `subagent-takeover` immediately after this step. |

Revising the saved plan is not a listed option. Free-text input at this gate is the plan-revision path: if the user replies with concrete plan changes instead of selecting option 1 or 2, treat it as “modify the saved plan with this content” — use the supplied content directly, do not ask the user to restate it, then follow the revision path below.

Only options 1 and 2 authorize implementation. Free-text plan changes are a plan-revision path, not implementation authorization. Do not edit implementation files, start implementation agents, or run implementation validation until the user explicitly selects option 1 or 2, or explicitly specified an equivalent execution mode before this ask. Silence, “继续”, “尽快做”, “直接开始”, “确认”, generic approval, or any other non-equivalent wording is not implementation authorization.

If the user chooses option 2, route to `subagent-takeover` immediately after this step by loading it with the runtime `Skill` tool (`Skill(skill: "my-skills:subagent-takeover")`) and then following its instructions: the coordinator skill reads this saved plan, splits it into a human-reviewable `<output root>/subTasks/YYYY-MM-DD-<topic>.md` document, waits for user approval, then dispatches and validates subagents. Do not ask the user to invoke `/subagent-takeover` again; this selection is the routing authorization. Do not perform subagent dispatch, splitting, or structured-feedback validation inline here; hand off to `subagent-takeover` and let it own that flow. If the runtime `Skill` tool cannot load it, read `skills/subagent-takeover/SKILL.md` directly and follow it.

Before that hand-off, if the saved plan or dispatch configuration is missing or malformed, route to `my-config-manager` to create or repair the output-root and dispatch configuration interactively; `coding-workflow` does not write those managed blocks itself.

When the user supplies plan changes as free text instead of selecting option 1 or 2:

1. Stop the execution path. Do not perform any implementation step.
2. If the user selected this path without supplying concrete changes, use `ask` to collect them.
3. Use the saved plan file as the read-only source for a complete working plan. Revise every affected section, including `Requirements Traceability`, `Implementation Handoff`, `Key Decisions and Changes`, and `Self-Review`; the prior approval is no longer valid. Do not update the saved plan file yet.
4. Return to Step 3. After the user reapproves and all Step 4 Human-required decisions are resolved, update the same saved plan file and create a new plan-revision commit in the repository that owns the output root, following the `Output Root` git rule; otherwise skip the commit. Do not amend or overwrite the prior plan commit.
5. Ask the execution-mode question again. Do not implement until the user selects option 1 or 2.

### 6. Risk-Sized Loops

A step is small enough to identify responsibility and large enough to deserve validation.

| Change | Validation rhythm |
|---|---|
| Mechanical: rename, move, format, copy | Batch validation |
| Behavior: logic, data flow, errors, API | Validate one observable unit |
| Integration: combined behavior, task switch, completion claim | Broader validation |

Use narrow validation first when full validation is expensive. Before completion claims, task switches, or implementation commits, validate strongly enough to support the claim.

### 7. Evidence Before Completion Claims

Final reports must include:

```markdown
## Validation
- Ran:
- Result:
- Not run:
- Reason:
```

Say “not validated” or “validation failed” when true. Do not claim completion with “should be fixed,” “looks fine,” or no evidence.

### 8. Post-Validation Completion Gate

After completing edits and reporting `Validation`, if this workflow produced uncommitted file changes and the user has not already specified the completion action, stop and use using-tool's `ask` action.

Completion results, when recorded, go under:

```text
<output root>/complete/YYYY-MM-DD-<topic>.md
```

Use the same `<topic>` as the saved plan when one exists; otherwise use a concise kebab-case task topic. If the workflow has a saved plan file, start the completion record with a link to that plan.

Before presenting the gate, use `run` to check whether each repository this gate could commit into already is a git repository — the working repository, and the output-root repository when the output root is external — with `git -C "<repository>" rev-parse --is-inside-work-tree`. Do not guess the git state from project files. When the working repository has no git repository, present the no-git gate instead of offering a commit that the `Output Root` git rule would silently skip.

The `ask` prompt must be:

> 修改和验证已完成，请选择下一步（必须明确选择其中一项）：

Present these Chinese options in this order. For options 2 and 3, include the concrete planned result path in the option description:

| Option | Meaning | Next action |
|---|---|---|
| 1. 提交 | 只提交本次完成的改动。 | Use `run` to inspect status, commit relevant changes, then report the commit hash. |
| 2. 记录结果并提交 | 将完成结果保存到 `<output root>/complete/YYYY-MM-DD-<topic>.md`，然后提交。 | Use `edit` to create/update the completion record, use `run` to commit relevant changes per the `Output Root` git rule, then report the result path and commit hash. If the output root's repository does not commit the records (no git repository, or the output root is ignored), write the completion record but skip committing it, and report that fact. |
| 3. 记录结果 | 将完成结果保存到 `<output root>/complete/YYYY-MM-DD-<topic>.md`，但不提交。 | Use `edit` to create/update the completion record, then report the result path and state that changes remain uncommitted. |
| 4. 保持现状 | 不记录结果、不提交、不推送。 | Report changed files and validation evidence; state that changes remain uncommitted. |
| 5. 启动开发环境 | 用项目自身的开发命令启动本地开发环境，供你手动验收本次改动；不提交、不写完成记录。 | Detect the project's own development command, start it as a background job, wait for a bounded readiness signal, then report the command, the background handle, the port/URL when the app exposes one, and how to stop it; then re-ask this gate without this option. |

When the working repository is not a git repository, replace options 1 and 2 with these initialization options and keep options 3–5 unchanged in meaning:

| Option | Meaning | Next action |
|---|---|---|
| 1. 初始化 git 并提交 | 工作仓库还不是 git 仓库：先 `git init`，再提交本次完成的改动。 | Use `run` to run `git init` in the working repository, then commit relevant changes, and report the init result, the repository path, and the commit hash. |
| 2. 初始化 git、记录结果并提交 | 先 `git init` 工作仓库，再把完成结果保存到 `<output root>/complete/YYYY-MM-DD-<topic>.md` 并提交。 | Use `run` to run `git init` in the working repository, use `edit` to create/update the completion record, then commit the working-repository changes and the record per the `Output Root` git rule, and report the init result, the result path, and the commit hash(es). If the output root's repository cannot commit the record, write it and skip that commit, and report that fact. |

No-git gate rules:

- Run `git init` only after the user selects one of the two initialization options; never initialize a repository silently.
- If `git init` fails, report the failure, perform the matching non-commit fallback (option 4 for 初始化 git 并提交, option 3 for 初始化 git、记录结果并提交), then re-ask the gate; do not claim the changes were committed.
- Choosing 记录结果 or 保持现状 means the user declined initialization: do not run `git init`, do not ask again for the rest of the session, and state that the changes remain uncommitted.
- This gate's `git init` applies to the working repository only. When the output root is external, its record repository stays governed by the `Output Root` git rule.

Option 5 is a verification aid, not a completion action: it never commits, records, or replaces this gate. Detect the command from the project itself (`package.json` `dev`/`start`/`serve` scripts, `docker compose up`, `bootRun`/`spring-boot:run`, `air`, `cargo run`, `go run ./cmd/...`, and so on); when the project offers several plausible commands or none, use `ask` to have the user pick or type the exact command — do not guess. Start it as a background job with `run` in whatever way the runtime supports (a resumed background job, a detached process, or a separate terminal), read its log for the readiness signal, and never block this gate on it. Wait for that signal (a `listening`/`ready` line, or the port accepting connections) with a bounded timeout before reporting. On timeout, report the tail of the log and that it is still starting; do not claim it started. If a development environment from this session is already running, say so and skip this option instead of starting a second copy. After reporting, re-ask the same gate without this option so the commit or record choice is still made explicitly. When the user leaves this gate or the session ends, state that the environment is still running, with its handle and stop command; do not stop or leave it undisclosed silently.

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

Do not commit, push, write a completion record, or initialize a repository silently. If there are no uncommitted changes, state that and skip this gate.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Immediate edits | Plan and self-review first |
| Treating plan output as approval | After plan and self-review, present the mandatory response gate and wait |
| Guessed cause as fact | Mark uncertainty or investigate |
| Heavy ceremony | Keep lightweight |
| Testing every tiny edit | Use risk-sized validation |
| Choosing execution mode silently | Use using-tool's `ask` action to make the user choose mode after approval unless already specified |
| Asking for execution mode as free text | Use structured `ask` options; do not require the user to type `Main agent` |
| Treating a saved plan as a commitment to implement | Offer `修改已保存方案`; if selected, return to plan revision and reapproval without implementing |
| Starting implementation without a chosen mode | Only options 1 and 2 authorize implementation; option 3, silence, generic approval, or “继续” do not |
| Saving before resolving decisions | Review human-required decisions after plan approval and resolve them before saving or committing |
| Saving a summary-only plan | Save the complete handoff plan with evidence anchors, traceability, implementation constraints, validation, and key decisions |
| Leaving confirmed decisions only in chat | Record every implementation-affecting confirmed decision in `Key Decisions and Changes` with source and impact |
| Letting an implementation agent re-decide confirmed choices | Require it to read the saved plan and honor traceability, invariants, explicit non-changes, and the deviation protocol |
| Accepting a silent implementation deviation | Compare the candidate against traceability rows and reject or return to plan revision when a material deviation lacks approval |
| Completion without evidence | Report checks and results |
| Ending with uncommitted changes | After validation, use the post-validation completion gate to offer commit / record result and commit / record result / keep current state / start dev environment last as a verification aid |
| Offering a commit the repository cannot perform | Check the commit repository's git state first; in a non-git project offer 初始化 git 并提交 instead of a commit the `Output Root` git rule would silently skip |
| Initializing git silently | Run `git init` only after the user selects an initialization option; on failure report it and use the matching non-commit fallback |
| Guessing the development command, or starting a second dev server | Detect the project's own script; ask when several or none fit; when one is already running from this session, report it instead of starting another |
| Claiming the dev environment started before it is ready | Wait for the ready line or a listening port; on timeout report the log tail and say it is still starting |
| Letting the dev environment replace the commit gate | 启动开发环境 never commits or records; report it, then re-ask the gate without that option |
| Over-exploring simple tasks | Match search tool to task scope; run one `find` (Grep or MCP `search_code`) before dispatching `agent` (Explore); reserve `agent` for genuinely cross-module or uncertain-scope investigation |
