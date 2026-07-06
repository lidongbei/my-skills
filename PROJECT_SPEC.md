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

This plugin currently contains five skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`
- `using-tool`

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
- `description` for user-only skills must require explicit invocation and must not use broad semantic task categories as auto-trigger descriptions.
- `description` for model-invocable skills must start with `Use when`, stay trigger-focused, and avoid workflow summaries.
- Existing user-only skills use user-only mode with `disable-model-invocation: true`.
- `using-tool` is model-invocable by user decision, is mandatory before using any skill from this plugin, and must not include `disable-model-invocation: true`.
- User-only means the model must not invoke the skill on its own through the runtime `Skill` tool; a user slash-command invocation is still valid.
- If a user explicitly invokes a user-only skill and the runtime `Skill` tool rejects it because of `disable-model-invocation: true`, the agent should read `skills/<skill-name>/SKILL.md` directly and follow it instead of treating the user invocation as invalid.
- `writing-skills` uses agent-mode planning: do not use plan mode; ask targeted clarification questions and output the plan directly in chat.
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
- Any direct skill directory other than `coding-workflow`, `team-memory`, `idea-shaping`, `writing-skills`, or `using-tool` exists.
- A skill frontmatter `name` is missing or does not match its directory.
- A user-only skill frontmatter `description` is missing, blank, or does not require explicit invocation.
- A model-invocable skill frontmatter `description` is missing, blank, or does not start with `Use when`.
- A model-invocable skill includes `disable-model-invocation: true`.
- `using-tool` is missing a required runtime mapping file under `skills/using-tool/runtimes/`.
- `skills-index.md` omits a current skill or references a missing skill.

## Adding A Future Skill

1. Create `skills/<new-skill>/SKILL.md`.
2. Ask the user to choose `user-only` or `model-invocable` invocation mode.
3. Add frontmatter with matching `name`; for user-only skills use an explicit-invocation `description` and include `disable-model-invocation: true`; for model-invocable skills use a trigger-focused `Use when` description and omit `disable-model-invocation`.
4. Place skill-specific evals under `skills/<new-skill>/evals/` if needed.
5. Update `skills-index.md`.
6. Update `README.md` if the public skill list changes.
7. Update `scripts/validate.ps1` allowed skill names and invocation-mode lists if the new skill is approved.
8. Run validation.
