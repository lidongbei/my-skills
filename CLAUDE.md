# CLAUDE.md

This repository is one standard agent skills plugin.

## Project Shape

- The repository root is the plugin root.
- Canonical plugin metadata lives in `.claude-plugin/plugin.json`.
- Runtime skills live in `skills/<skill-name>/SKILL.md`.
- The current skills are `coding-workflow`, `team-memory`, `idea-shaping`, and `writing-skills`.
- `PROJECT_SPEC.md` is the source of truth for future skill additions.

## Rules for Agents

- 使用中文和我交流
- Treat `skills/` as the payload for this single plugin, not as a broad skills export.
- Do not recreate the old root `plugin.json` bundle manifest.
- Do not add nested plugin directories under `skills/`.
- Do not rewrite skill behavior during structural refactors.
- Preserve skill frontmatter fields unless the user explicitly approves a behavior change.
- Skill descriptions must require explicit invocation and must not use broad semantic task categories as auto-trigger descriptions.
- Keep `skills-index.md`, `README.md`, and validation rules in sync after skill changes.
- Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1` before claiming the plugin shape is valid.