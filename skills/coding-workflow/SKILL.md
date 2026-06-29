---
name: coding-workflow
description: Use when implementing features, fixing bugs, refactoring, resolving test/build/type failures, changing multiple files, continuing an approved development plan, or handling any non-trivial coding task in the current repository.
---

# Coding Workflow

## Overview

Plan first, work in risk-sized loops, and claim completion only with evidence. Lightweight: no full TDD, mandatory reviews, branch finishing, or required subagents.

## When to Use

Use for features, bug fixes, refactors, failures, multi-file changes, multiple approaches, or “continue / next step / implement the plan / 按方案做” on non-trivial work.

Skip for Q&A, tiny mechanical edits, explicit “no plan needed” requests, or continued execution of the same approved plan when scope is unchanged.

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

### 3. Save, Commit, Choose Mode

After explicit approval: save the plan under `docs/plans/YYYY-MM-DD-<topic>.md`, commit the plan to git, then choose mode.

| Mode | Use when |
|---|---|
| Main agent | Small, low-risk, few files |
| Single subagent | Medium, multi-file, or clean main context |
| Multiple subagents | Independent parallel subtasks |

Subagents are optional.

### 4. Risk-Sized Loops

A step is small enough to identify responsibility and large enough to deserve validation.

| Change | Validation rhythm |
|---|---|
| Mechanical: rename, move, format, copy | Batch validation |
| Behavior: logic, data flow, errors, API | Validate one observable unit |
| Integration: combined behavior, task switch, completion claim | Broader validation |

Use narrow validation first when full validation is expensive. Before completion claims, task switches, or implementation commits, validate strongly enough to support the claim.

### 5. Evidence Before Completion Claims

Final reports must include:

```markdown
## Validation
- Ran:
- Result:
- Not run:
- Reason:
```

Say “not validated” or “validation failed” when true. Do not claim completion with “should be fixed,” “looks fine,” or no evidence.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Immediate edits | Plan and self-review first |
| Guessed cause as fact | Mark uncertainty or investigate |
| Heavy ceremony | Keep lightweight |
| Testing every tiny edit | Use risk-sized validation |
| Forcing subagents | Choose mode after approval |
| Saving drafts | Save only after approval |
| Completion without evidence | Report checks and results |
