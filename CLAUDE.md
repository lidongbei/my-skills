# CLAUDE.md

This repository is one standard agent skills plugin.

## Project Shape

- The repository root is the plugin root.
- Canonical plugin metadata lives in `.claude-plugin/plugin.json`.
- Runtime skills live in `skills/<skill-name>/SKILL.md`.
- The current skills are `coding-workflow`, `team-memory`, `idea-shaping`, `writing-skills`, and `using-tool`.
- `PROJECT_SPEC.md` is the source of truth for future skill additions.

## Rules for Agents

- 使用中文和我交流
- Treat `skills/` as the payload for this single plugin, not as a broad skills export.
- Do not recreate the old root `plugin.json` bundle manifest.
- Do not add nested plugin directories under `skills/`.
- Do not rewrite skill behavior during structural refactors.
- Preserve skill frontmatter fields unless the user explicitly approves a behavior change.
- Existing user-only skills must remain user-only with `disable-model-invocation: true` unless the user explicitly approves a behavior change.
- `using-tool` is model-invocable by user decision, is mandatory before using any skill from this plugin, and must not include `disable-model-invocation: true`.
- If the user explicitly invokes a user-only skill and the runtime `Skill` tool rejects it because of `disable-model-invocation: true`, treat the user invocation as valid; read the corresponding `skills/<skill-name>/SKILL.md` directly and follow it instead of retrying the tool or saying the skill cannot be used.
- When using `writing-skills`, do not enter plan mode; clarify interactively and output the modification plan in agent mode.
- When creating a future skill, ask whether it should be `user-only` or `model-invocable`; do not choose a default unless the user already made it explicit.
- Skill descriptions for user-only skills must require explicit invocation and must not use broad semantic task categories as auto-trigger descriptions.
- Skill descriptions for model-invocable skills must start with `Use when`, stay trigger-focused, and avoid workflow summaries.
- Keep `skills-index.md`, `README.md`, and validation rules in sync after skill changes.
- Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1` before claiming the plugin shape is valid.