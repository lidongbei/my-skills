# Single Plugin With Two Skills Design

## Summary

Refactor `D:\AI\my-skills` from a portable 16-skill bundle into one standard plugin project. The plugin contains exactly two skills: `team-memory` and `idea-shaping`.

## Approved Direction

- The repository root is the single plugin root.
- The plugin uses standard Claude plugin layout: `.claude-plugin/plugin.json` plus `skills/<skill-name>/SKILL.md`.
- The only runtime skills in this project are `team-memory` and `idea-shaping`.
- The project convention document lives at the repository root.
- Old bundle semantics are removed rather than preserved as a compatibility mode.

## Current State

The project currently mixes two layouts:

- A legacy portable skills bundle at `skills/<skill-name>/SKILL.md`, with `plugin.json` listing 16 skills.
- A nested standard plugin example at `skills/plugins/idea-shaping`, containing `.claude-plugin/plugin.json` and `skills/idea-shaping/SKILL.md`.

This creates three problems:

1. The root `plugin.json` describes a bundle, not one standard plugin.
2. `idea-shaping` is hidden under a nested plugin path and is not part of the root skill index.
3. Validation and installation scripts assume all direct children of `skills/` are standalone skills, which conflicts with `skills/plugins`.

## Target Architecture

```text
my-skills/
├── .claude-plugin/
│   └── plugin.json
├── AGENTS.md
├── PROJECT_SPEC.md
├── README.md
├── skills-index.md
├── skills/
│   ├── idea-shaping/
│   │   └── SKILL.md
│   └── team-memory/
│       ├── SKILL.md
│       └── evals/
│           └── evals.json
├── scripts/
│   ├── install-claude-code.ps1
│   ├── sync-from-claude.ps1
│   └── validate.ps1
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-06-29-single-plugin-two-skills-design.md
```

### Plugin Manifest

Create `.claude-plugin/plugin.json` at the repository root. It describes the single plugin, not each skill. It should use minimal standard plugin metadata:

```json
{
  "name": "my-skills",
  "description": "Personal agent skills plugin containing team-memory and idea-shaping skills.",
  "version": "0.1.0",
  "author": {
    "name": "Administrator"
  }
}
```

The legacy root `plugin.json` should no longer represent the canonical plugin. It should be removed unless implementation discovers a runtime requirement for retaining it. If retained, it must be clearly documented as non-standard generated metadata and must list only the two current skills.

### Skills

`skills/team-memory/SKILL.md` remains the canonical `team-memory` skill. Its `evals/evals.json` remains with the skill because it is skill-specific validation data.

`skills/plugins/idea-shaping/skills/idea-shaping/SKILL.md` moves to `skills/idea-shaping/SKILL.md`. The nested `skills/plugins/idea-shaping/.claude-plugin/plugin.json` is removed because the root is now the plugin.

After migration, `skills/` must contain exactly these direct child directories:

- `idea-shaping`
- `team-memory`

### Documentation

Update `README.md` to describe this as a single plugin project, not an exported 16-skill bundle. It should explain:

- The root plugin manifest lives at `.claude-plugin/plugin.json`.
- Skills live at `skills/<skill-name>/SKILL.md`.
- The only included skills are `team-memory` and `idea-shaping`.
- `PROJECT_SPEC.md` is the source of truth for adding future skills.

Update `AGENTS.md` so agents treat the repository root as one plugin and `skills/` as the skill payload for that plugin.

Update `skills-index.md` so it lists exactly two skills with correct paths and trigger descriptions.

Create `PROJECT_SPEC.md` at the root. It must define the durable project rules for future changes:

- This repository is one plugin, not a multi-plugin collection and not a generic exported bundle.
- Plugin metadata belongs in `.claude-plugin/plugin.json`.
- Every skill lives in `skills/<skill-name>/SKILL.md`.
- Skill frontmatter must include `name` and `description`.
- `description` must state when to trigger the skill.
- Skill names must be kebab-case and match their directory names.
- Skill-specific tests/evals stay inside the skill directory.
- After adding, renaming, or removing a skill, update `skills-index.md`, `README.md` if needed, and run validation.

### Scripts

Update `scripts/validate.ps1` so it validates the target shape:

- `.claude-plugin/plugin.json` exists and parses as JSON.
- `skills/` exists.
- Each direct child of `skills/` contains `SKILL.md`.
- No nested `skills/plugins` compatibility directory exists.
- Only `team-memory` and `idea-shaping` are present for this refactor.
- Each `SKILL.md` has YAML frontmatter with `name` and `description`.
- The frontmatter `name` matches the directory name.
- `skills-index.md` references the same skill set.

Update installation/sync scripts to stop assuming a 16-skill exported bundle. They should operate on the direct `skills/*` directories in the root plugin. If they keep their original adapter purpose, they must copy or sync only `team-memory` and `idea-shaping`.

### Data Flow

For human or agent discovery:

1. Read `.claude-plugin/plugin.json` to identify the plugin.
2. Read `skills-index.md` to see included skills.
3. Load the relevant `skills/<skill-name>/SKILL.md`.
4. Follow `PROJECT_SPEC.md` when adding or changing skills.

For validation:

1. Parse the root plugin manifest.
2. Enumerate direct children of `skills/`.
3. Check each skill file and frontmatter.
4. Compare discovered skills against `skills-index.md`.
5. Fail if legacy nested plugin paths remain.

## Error Handling

Validation failures should be explicit and actionable. Examples:

- Missing `.claude-plugin/plugin.json` reports the exact missing path.
- Invalid JSON reports the manifest path.
- Missing `SKILL.md` reports the skill directory.
- Mismatched frontmatter name reports the expected and actual name.
- Unexpected skill directories report their names.
- Stale `skills-index.md` reports missing or extra entries.

## Testing And Verification

The implementation should verify the refactor with:

- `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1`
- A file-tree check showing only `skills/team-memory` and `skills/idea-shaping` under `skills/`.
- A content check that `skills-index.md` lists exactly two skills.

If the project is not a git repository, skip commit steps and report that no commit was created.

## Out Of Scope

- Rewriting the internal behavior of either skill.
- Adding new skills beyond `team-memory` and `idea-shaping`.
- Publishing the plugin externally.
- Creating package-manager metadata such as `package.json` unless a tool requirement is discovered during implementation.

## Acceptance Criteria

- The repository root is a valid standard plugin root with `.claude-plugin/plugin.json`.
- The project contains exactly two skills: `team-memory` and `idea-shaping`.
- `idea-shaping` is no longer nested under `skills/plugins`.
- Legacy 16-skill bundle metadata is removed or rewritten so it cannot be mistaken for the canonical format.
- `PROJECT_SPEC.md` documents the project rules for future skill additions.
- Validation succeeds with the updated script.
