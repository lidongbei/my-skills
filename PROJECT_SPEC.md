# Project Spec

## Project Shape

This repository is one standard agent skills plugin. It is not a generic exported skills bundle and it is not a multi-plugin collection.

The plugin root is the repository root. Plugin metadata lives at:

```text
.claude-plugin/plugin.json
```

Runtime skills live at:

```text
skills/<skill-name>/SKILL.md
```

## Current Skills

This plugin currently contains exactly four skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`

Do not add, rename, or remove skills without updating `skills-index.md`, relevant README content, and validation rules.

## Skill Rules

Each skill must use this layout:

```text
skills/<skill-name>/SKILL.md
```

Each `SKILL.md` must start with YAML frontmatter containing at least:

```yaml
---
name: <skill-name>
description: <when to use this skill>
---
```

Rules:

- `<skill-name>` must be kebab-case.
- Frontmatter `name` must match the skill directory name.
- `description` must require explicit invocation and must not use broad semantic task categories as auto-trigger descriptions.
- Current built-in skills use Claude Code user-only mode with `disable-model-invocation: true`.
- `writing-skills` uses agent-mode planning: do not use `EnterPlanMode` or `ExitPlanMode`; ask targeted clarification questions and output the plan directly in chat.
- When creating a future skill, ask the user to choose `user-only` or `model-invocable`; add `disable-model-invocation: true` only when the user chooses `user-only`.
- Additional frontmatter keys are allowed when required by a runtime.
- Skill-specific evals or fixtures stay inside that skill directory.
- Do not rewrite a skill's behavior during structural refactors.

## Plugin Metadata Rules

`.claude-plugin/plugin.json` is the canonical plugin manifest. Keep it valid JSON and describe the whole plugin, not individual skills.

Do not recreate the old root `plugin.json` bundle manifest unless a specific external tool requirement is documented first.

## Validation Rules

Run validation after every structural change:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

Validation must fail if:

- `.claude-plugin/plugin.json` is missing or invalid JSON.
- `skills/` is missing.
- A direct child of `skills/` lacks `SKILL.md`.
- `skills/plugins` exists.
- Any direct skill directory other than `coding-workflow`, `team-memory`, `idea-shaping`, or `writing-skills` exists.
- A skill frontmatter `name` is missing or does not match its directory.
- A skill frontmatter `description` is missing, blank, or does not require explicit invocation.
- `skills-index.md` omits a current skill or references a missing skill.

## Adding A Future Skill

1. Create `skills/<new-skill>/SKILL.md`.
2. Ask the user to choose `user-only` or `model-invocable` invocation mode.
3. Add frontmatter with matching `name` and explicit-invocation `description`; include `disable-model-invocation: true` only when the user chooses `user-only`.
4. Place skill-specific evals under `skills/<new-skill>/evals/` if needed.
5. Update `skills-index.md`.
6. Update `README.md` if the public skill list changes.
7. Update `scripts/validate.ps1` allowed skill names if the new skill is approved.
8. Run validation.
