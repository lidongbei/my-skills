# AGENTS.md

This repository is one standard agent skills plugin.

## Project Shape

- The repository root is the plugin root.
- Canonical plugin metadata lives in `.claude-plugin/plugin.json`.
- Runtime skills live in `skills/<skill-name>/SKILL.md`.
- The only current skills are `team-memory` and `idea-shaping`.
- `PROJECT_SPEC.md` is the source of truth for future skill additions.

## Rules for Agents

- Treat `skills/` as the payload for this single plugin, not as a broad skills export.
- Do not recreate the old root `plugin.json` bundle manifest.
- Do not add nested plugin directories under `skills/`.
- Do not rewrite skill behavior during structural refactors.
- Preserve skill frontmatter fields unless the user explicitly approves a behavior change.
- Keep `skills-index.md`, `README.md`, and validation rules in sync after skill changes.
- Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1` before claiming the plugin shape is valid.
