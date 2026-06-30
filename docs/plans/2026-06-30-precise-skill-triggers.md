# Plan: make skills require precise instruction triggers

## Context

User request: “把技能都改成需要精确指令触发” — make all skills trigger only from precise user instructions, not broad semantic task descriptions.

Current diagnosis:
- `skills/coding-workflow/SKILL.md` auto-triggers broadly for ordinary coding work such as features, bug fixes, refactors, failures, multi-file changes, and plan continuation.
- `skills/team-memory/SKILL.md` mixes explicit `/team-memory` invocation with broad memory-curation intent phrases and embeds workflow/storage policy in frontmatter.
- `skills/writing-skills/SKILL.md` auto-triggers broadly for skill creation/edit/review/verification tasks.
- `skills/idea-shaping/SKILL.md` is already close to the target pattern because it says to use only on explicit `/idea-shaping` invocation.
- Repository metadata is inconsistent: `.claude-plugin/plugin.json` and `skills-index.md` list four skills including `coding-workflow`, while `README.md`, `AGENTS.md`, `PROJECT_SPEC.md`, adapter docs, and scripts still describe/allow only three. `scripts/validate.ps1` currently rejects `coding-workflow`.

Intended outcome: all skills have trigger-only descriptions that require explicit invocation, the skill bodies reinforce that boundary, indexes/docs/scripts agree on the approved four-skill set, and validation catches future broad trigger descriptions.

## Recommended approach

Use one consistent trigger rule:

> A skill may load only when the user explicitly invokes the skill command or explicitly instructs the agent to use that skill by name.

For this plugin, descriptions should mention the precise namespaced slash command and, where useful for non-plugin runtimes, the unnamespaced command/name. Example pattern:

```yaml
description: Use only when the user explicitly invokes /my-skills:<skill-name> or explicitly instructs the agent to use <skill-name>.
```

Do not keep broad task categories as frontmatter triggers. If a broad list is still useful, move/reword it as “after explicit invocation, this skill is appropriate for...”.

## Files to modify

### 1. Skill frontmatter and hard boundaries

Modify:
- `skills/coding-workflow/SKILL.md`
- `skills/idea-shaping/SKILL.md`
- `skills/team-memory/SKILL.md`
- `skills/writing-skills/SKILL.md`

Planned changes:
- Replace broad frontmatter descriptions with `Use only when...` precise invocation descriptions.
- Add or update top-level hard boundaries so each skill says it must not auto-trigger from ordinary domain requests.
- Preserve each skill’s workflow after explicit invocation.

Representative per-skill treatment:
- `coding-workflow`: remove broad auto-trigger language from frontmatter and `When to Use`; add “do not auto-trigger for ordinary implementation, bug fix, refactor, test/build failure, multi-file change, or plan-continuation requests.” Keep the plan/self-review/save/validation workflow unchanged.
- `idea-shaping`: mostly keep as-is, but normalize command wording to the shared convention if needed. Keep “do not auto-trigger for ordinary feature implementation requests.”
- `team-memory`: shorten frontmatter to explicit invocation only; move Chinese phrases like “项目级复用”, “沉淀到仓库 memory”, “同步到 docs/memory”, “记住这个使用习惯”, “多个项目复用”, “统一到 HABIT.md” out of trigger status and explicitly state they should not auto-trigger the skill by themselves. Keep storage rules unchanged.
- `writing-skills`: shorten frontmatter to explicit invocation only; state that skill-file mentions, SKILL.md edits, eval edits, trigger discussions, or ordinary skill-related tasks do not auto-trigger this skill unless the user explicitly requests it. Keep diagnosis and RED/GREEN/REFACTOR workflow unchanged.

### 2. Skill index

Modify:
- `skills-index.md`

Update all four entries to mirror the new precise frontmatter descriptions. Keep `Total skills: 4`.

### 3. Repository/docs consistency for four skills

Modify stale three-skill references:
- `README.md`
- `AGENTS.md`
- `PROJECT_SPEC.md`
- `adapters/claude-code/README.md`
- `adapters/agents/AGENTS.md`
- `adapters/codex/AGENTS.md`

Planned changes:
- Replace “three skills” with “four skills” where applicable.
- Add `coding-workflow` to approved/current skill lists and tree examples.
- Add the repository rule that skill descriptions must require explicit invocation and must not use broad semantic task categories as auto-trigger descriptions.

No planned change to `.claude-plugin/plugin.json` unless inspection during implementation shows wording drift; it already names all four skills.

### 4. Scripts and validation

Modify:
- `scripts/validate.ps1`
- `scripts/install-claude-code.ps1`
- `scripts/sync-from-claude.ps1`

Planned changes:
- Add `coding-workflow` to all approved/allowed skill arrays.
- Update any success/install messages that assume three skills.
- Enhance `validate.ps1` to statically enforce the trigger convention. At minimum, each frontmatter `description` must:
  - start with `Use only when`;
  - contain the skill’s exact command/name, such as `/my-skills:team-memory` or `team-memory`;
  - mention explicit invocation/instruction;
  - avoid known broad trigger phrases from the current descriptions.

### 5. Evals / scenario fixtures

Modify if the existing JSON shape makes this straightforward:
- `skills/writing-skills/evals/evals.json`
- `skills/team-memory/evals/evals.json`

Add or adjust scenarios to document the new boundary:
- Negative examples that should not trigger by themselves: “Fix this bug”, “Review this SKILL.md”, “把这个结论沉淀到仓库 memory”, “Create a skill for X”, “Implement the approved plan”.
- Positive examples that should trigger: `/my-skills:coding-workflow ...`, `use coding-workflow ...`, `/my-skills:team-memory ...`, `use team-memory ...`, `/my-skills:writing-skills ...`, `use writing-skills ...`, `/my-skills:idea-shaping ...`.

## Implementation sequence after approval

1. Per existing project workflow, save this approved plan under `docs/plans/YYYY-MM-DD-precise-skill-triggers.md` and commit the plan before implementation.
2. Update the four `SKILL.md` files with minimal trigger-boundary changes.
3. Update `skills-index.md` to mirror descriptions.
4. Resolve four-skill drift in docs and scripts.
5. Add validation checks in `scripts/validate.ps1`.
6. Update eval fixtures if practical.
7. Run validation and inspect the diff.
8. Commit implementation after successful validation.

## Validation

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

Expected:
- Passes.
- Reports all four approved skills.
- Fails if any frontmatter description does not require explicit invocation.

Run preview install:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Expected:
- Shows all four skills would be installed.
- Does not mutate installed skills.

Optional preview sync:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-from-claude.ps1 -WhatIf
```

Expected:
- Accepts all four approved skills.
- Does not reject `coding-workflow`.

Manual checks:
- Inspect every `SKILL.md` frontmatter and `skills-index.md` entry for `Use only when...` explicit invocation wording.
- Confirm broad semantic phrases remain only as post-invocation scope guidance, not trigger descriptions.
- Review `git diff` to ensure workflows were preserved and only trigger/metadata/validation scope changed.

## Risks / open questions

- “Slash command only” would be stricter than allowing “use <skill-name>”. I recommend allowing both because both are precise instructions, and it supports runtimes where skills may not appear under a plugin namespace.
- Static validation can prevent broad frontmatter descriptions, but it cannot fully prove runtime skill-selection behavior; eval/manual scenarios remain useful.
- Updating `coding-workflow` as the fourth approved skill is recommended because it already exists and is listed by plugin/index metadata. Removing it would be a separate product decision, not required for this request.
