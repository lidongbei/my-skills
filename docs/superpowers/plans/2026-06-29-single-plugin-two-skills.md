# Single Plugin Two Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `D:\AI\my-skills` into one standard plugin project containing exactly two skills: `team-memory` and `idea-shaping`.

**Architecture:** The repository root is the single plugin root. Plugin metadata lives in `.claude-plugin/plugin.json`; skill payloads live as direct children under `skills/<skill-name>/SKILL.md`; project rules live in root `PROJECT_SPEC.md`.

**Tech Stack:** Markdown skill files, JSON plugin metadata, PowerShell helper scripts, Windows paths with Bash-compatible validation commands.

## Global Constraints

- This repository is one plugin, not a multi-plugin collection and not a generic exported bundle.
- The only runtime skills in this refactor are `team-memory` and `idea-shaping`.
- The root plugin manifest is `.claude-plugin/plugin.json`.
- Every skill must live in `skills/<skill-name>/SKILL.md`.
- Skill names must be kebab-case and match their directory names.
- Skill frontmatter must include `name` and `description`; additional frontmatter keys are allowed.
- Do not rewrite the internal behavior or trigger semantics of either skill.
- Keep `skills/team-memory/evals/evals.json` with `team-memory`.
- Remove old 16-skill bundle semantics rather than preserving compatibility mode.
- This directory is not a git repository; do not run `git commit` unless the project is initialized as a git repo later.

---

## File Structure

- Create `.claude-plugin/plugin.json`: standard root plugin metadata.
- Create `PROJECT_SPEC.md`: durable rules for adding and maintaining skills.
- Create `skills/idea-shaping/SKILL.md`: moved copy of the existing nested `idea-shaping` skill.
- Keep `skills/team-memory/SKILL.md`: canonical `team-memory` skill.
- Keep `skills/team-memory/evals/evals.json`: `team-memory` evals.
- Remove `skills/plugins/`: obsolete nested plugin wrapper.
- Remove legacy direct skill directories except `team-memory` and `idea-shaping`.
- Remove `plugin.json`: legacy root bundle manifest.
- Rewrite `README.md`: single-plugin overview.
- Rewrite `AGENTS.md`: agent instructions for the new plugin shape.
- Rewrite `skills-index.md`: two-skill index.
- Rewrite `scripts/validate.ps1`: strict target-shape validation.
- Rewrite `scripts/install-claude-code.ps1`: installs only approved skills.
- Rewrite `scripts/sync-from-claude.ps1`: syncs only approved skills.
- Rewrite `adapters/claude-code/README.md`: Claude Code adapter for the two-skill plugin.
- Rewrite `adapters/codex/AGENTS.md`: Codex adapter for the two-skill plugin.
- Rewrite `adapters/agents/AGENTS.md`: shared agents adapter for the two-skill plugin.

---

### Task 1: Create Plugin Manifest And Project Spec

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `PROJECT_SPEC.md`

**Interfaces:**
- Consumes: Approved design in `docs/superpowers/specs/2026-06-29-single-plugin-two-skills-design.md`.
- Produces: Root plugin metadata and durable project rules consumed by validation, docs, and future skill additions.

- [ ] **Step 1: Create root plugin manifest directory**

Run:

```bash
mkdir -p 'D:/AI/my-skills/.claude-plugin'
```

Expected: command exits with code 0.

- [ ] **Step 2: Write `.claude-plugin/plugin.json`**

Write this exact JSON to `D:/AI/my-skills/.claude-plugin/plugin.json`:

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

- [ ] **Step 3: Verify manifest JSON parses**

Run:

```bash
powershell.exe -NoProfile -Command "Get-Content -Raw -Path 'D:\AI\my-skills\.claude-plugin\plugin.json' | ConvertFrom-Json | Out-Null; 'plugin manifest json ok'"
```

Expected: prints `plugin manifest json ok` and exits with code 0.

- [ ] **Step 4: Write root project spec**

Write this content to `D:/AI/my-skills/PROJECT_SPEC.md`:

```markdown
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

This plugin currently contains exactly two skills:

- `team-memory`
- `idea-shaping`

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
- `description` must describe trigger conditions, not implementation details.
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
- Any direct skill directory other than `team-memory` or `idea-shaping` exists.
- A skill frontmatter `name` is missing or does not match its directory.
- A skill frontmatter `description` is missing or blank.
- `skills-index.md` omits a current skill or references a missing skill.

## Adding A Future Skill

1. Create `skills/<new-skill>/SKILL.md`.
2. Add frontmatter with matching `name` and trigger-focused `description`.
3. Place skill-specific evals under `skills/<new-skill>/evals/` if needed.
4. Update `skills-index.md`.
5. Update `README.md` if the public skill list changes.
6. Update `scripts/validate.ps1` allowed skill names if the new skill is approved.
7. Run validation.
```

- [ ] **Step 5: Record no git commit**

Run:

```bash
git -C 'D:/AI/my-skills' rev-parse --is-inside-work-tree 2>/dev/null || printf 'not a git repo; skip commit\n'
```

Expected: prints `not a git repo; skip commit`.

---

### Task 2: Migrate Skills And Prune Legacy Bundle

**Files:**
- Create: `skills/idea-shaping/SKILL.md`
- Keep: `skills/team-memory/SKILL.md`
- Keep: `skills/team-memory/evals/evals.json`
- Delete: `skills/plugins/`
- Delete: `plugin.json`
- Delete: all direct `skills/*` directories except `skills/team-memory` and `skills/idea-shaping`

**Interfaces:**
- Consumes: `.claude-plugin/plugin.json` from Task 1.
- Produces: Exact two-skill layout consumed by scripts and docs in later tasks.

- [ ] **Step 1: Back up the current tree outside the project**

Run:

```bash
backup="D:/AI/my-skills-backup-before-single-plugin-refactor"
rm -rf "$backup"
cp -a 'D:/AI/my-skills' "$backup"
printf 'backup created at %s\n' "$backup"
```

Expected: prints `backup created at D:/AI/my-skills-backup-before-single-plugin-refactor`.

- [ ] **Step 2: Move `idea-shaping` skill to direct skill layout**

Run:

```bash
mkdir -p 'D:/AI/my-skills/skills/idea-shaping'
cp 'D:/AI/my-skills/skills/plugins/idea-shaping/skills/idea-shaping/SKILL.md' 'D:/AI/my-skills/skills/idea-shaping/SKILL.md'
```

Expected: command exits with code 0.

- [ ] **Step 3: Verify `idea-shaping` frontmatter was preserved**

Run:

```bash
powershell.exe -NoProfile -Command "$p='D:\AI\my-skills\skills\idea-shaping\SKILL.md'; $c=Get-Content -Raw -Path $p; if ($c -notmatch 'name:\s*idea-shaping') { throw 'missing idea-shaping name' }; if ($c -notmatch 'disable-model-invocation:\s*true') { throw 'missing disable-model-invocation' }; if ($c -notmatch 'allowed-tools:') { throw 'missing allowed-tools' }; 'idea-shaping frontmatter ok'"
```

Expected: prints `idea-shaping frontmatter ok`.

- [ ] **Step 4: Verify `team-memory` evals remain in place**

Run:

```bash
test -f 'D:/AI/my-skills/skills/team-memory/evals/evals.json' && printf 'team-memory evals present\n'
```

Expected: prints `team-memory evals present`.

- [ ] **Step 5: Remove legacy skill directories except the two approved skills**

Run:

```bash
for dir in 'D:/AI/my-skills/skills'/*; do
  name="$(basename "$dir")"
  if [ -d "$dir" ] && [ "$name" != 'team-memory' ] && [ "$name" != 'idea-shaping' ]; then
    rm -rf "$dir"
    printf 'removed legacy skill dir %s\n' "$name"
  fi
done
```

Expected: prints removals for legacy directories, including `plugins` if present.

- [ ] **Step 6: Remove legacy root bundle manifest**

Run:

```bash
rm -f 'D:/AI/my-skills/plugin.json'
test ! -e 'D:/AI/my-skills/plugin.json' && printf 'legacy plugin.json removed\n'
```

Expected: prints `legacy plugin.json removed`.

- [ ] **Step 7: Verify only approved skill directories remain**

Run:

```bash
powershell.exe -NoProfile -Command "Get-ChildItem -Path 'D:\AI\my-skills\skills' -Directory | Select-Object -ExpandProperty Name | Sort-Object"
```

Expected output exactly:

```text
idea-shaping
team-memory
```

---

### Task 3: Rewrite Documentation And Index

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `skills-index.md`
- Modify: `adapters/claude-code/README.md`
- Modify: `adapters/codex/AGENTS.md`
- Modify: `adapters/agents/AGENTS.md`

**Interfaces:**
- Consumes: Target layout from Task 2.
- Produces: Human and agent documentation that no longer references a 16-skill bundle.

- [ ] **Step 1: Rewrite `README.md`**

Write this content to `D:/AI/my-skills/README.md`:

```markdown
# my-skills

A single standard agent skills plugin containing two skills: `team-memory` and `idea-shaping`.

## Layout

```text
my-skills/
├── .claude-plugin/
│   └── plugin.json          # canonical plugin manifest
├── PROJECT_SPEC.md          # rules for maintaining this plugin
├── skills-index.md          # human-readable skill index
├── skills/
│   ├── idea-shaping/
│   │   └── SKILL.md
│   └── team-memory/
│       ├── SKILL.md
│       └── evals/
│           └── evals.json
├── adapters/                # runtime-specific install notes
└── scripts/                 # validation and sync helpers
```

## Included Skills

- `team-memory` — curates reusable memory into project/team memory or cross-project habits.
- `idea-shaping` — shapes product, feature, project, startup, side-project, or internal-tool ideas when explicitly invoked.

## Canonical Rules

Use `PROJECT_SPEC.md` as the source of truth for adding or changing skills.

Core rules:

- The repository root is the plugin root.
- `.claude-plugin/plugin.json` is the canonical plugin manifest.
- Skills live directly under `skills/<skill-name>/SKILL.md`.
- This plugin currently contains exactly `team-memory` and `idea-shaping`.

## Validation

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

## Claude Code Usage

Claude Code user-level skills live under:

```text
~/.claude/skills
```

Install this plugin's skills with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

Preview installation with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

## Codex And Shared Agent Usage

Tools that consume `SKILL.md` directories can copy or symlink selected directories from `skills/` into their runtime skill directories. See `adapters/` for runtime-specific notes.
```

- [ ] **Step 2: Rewrite `AGENTS.md`**

Write this content to `D:/AI/my-skills/AGENTS.md`:

```markdown
# AGENTS.md

This repository is one standard agent skills plugin.

## Project Shape

- The repository root is the plugin root.
- Canonical plugin metadata lives in `.claude-plugin/plugin.json`.
- Runtime skills live in `skills/<skill-name>/SKILL.md`.
- The only current skills are `team-memory` and `idea-shaping`.
- `PROJECT_SPEC.md` is the source of truth for future skill additions.

## Rules for Agents

- Treat `skills/` as the plugin payload, not as an exported 16-skill bundle.
- Do not recreate the old root `plugin.json` bundle manifest.
- Do not add a nested `skills/plugins` directory.
- Do not rewrite skill behavior during structural refactors.
- Preserve skill frontmatter fields unless the user explicitly approves a behavior change.
- Keep `skills-index.md`, `README.md`, and validation rules in sync after skill changes.
- Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1` before claiming the plugin shape is valid.
```

- [ ] **Step 3: Rewrite `skills-index.md`**

Write this content to `D:/AI/my-skills/skills-index.md`:

```markdown
# Skills Index

Total skills: 2

- [idea-shaping](skills/idea-shaping/SKILL.md) — Use only when the user explicitly invokes `/idea-shaping` to shape a product, feature, project, startup, side-project, or internal-tool idea before implementation.
- [team-memory](skills/team-memory/SKILL.md) — Use when the user invokes `/team-memory` or wants to curate reusable memory into the right long-term location.
```

- [ ] **Step 4: Rewrite Claude Code adapter docs**

Write this content to `D:/AI/my-skills/adapters/claude-code/README.md`:

```markdown
# Claude Code Adapter

Claude Code loads user-level skills from:

```text
~/.claude/skills
```

On this machine:

```text
C:\Users\Administrator\.claude\skills
```

## Install

Preview installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1 -WhatIf
```

Install the two approved skills:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-claude-code.ps1
```

The script installs only:

- `team-memory`
- `idea-shaping`

## Policy

`D:\AI\my-skills` is the source project for this single plugin. Avoid editing installed copies under `~/.claude/skills` independently unless you intentionally sync them back with `scripts/sync-from-claude.ps1`.
```

- [ ] **Step 5: Rewrite Codex adapter docs**

Write this content to `D:/AI/my-skills/adapters/codex/AGENTS.md`:

```markdown
# Codex Adapter

This repository is one plugin containing `SKILL.md`-based skills.

Codex user-level skills normally live at:

```text
~/.codex/skills
```

Codex can also read the shared cross-runtime skills path:

```text
~/.agents/skills
```

## Install

Copy or symlink selected skill directories from:

```text
D:\AI\my-skills\skills\<skill-name>
```

into one of:

```text
~/.codex/skills/<skill-name>
~/.agents/skills/<skill-name>
```

Current approved skills:

- `team-memory`
- `idea-shaping`

## Tool Mapping Notes

Some skills mention Claude Code-specific tools or concepts. In Codex, adapt actions as follows:

- Read/search files: use shell commands such as `rg`, `cat`, and `ls`.
- Edit files: use `apply_patch`.
- Track plans: use Codex plan/update mechanisms.
- Subagents: use Codex multi-agent support when available.

Use each skill's intent and workflow, not necessarily its exact Claude Code tool names.
```

- [ ] **Step 6: Rewrite shared agents adapter docs**

Write this content to `D:/AI/my-skills/adapters/agents/AGENTS.md`:

```markdown
# Shared Agents Adapter

Use this directory as guidance for agent tools that support portable `SKILL.md` skills.

Recommended shared location:

```text
~/.agents/skills
```

Install by copying or symlinking selected direct skill directories from:

```text
D:\AI\my-skills\skills\<skill-name>
```

into:

```text
~/.agents/skills/<skill-name>
```

Current approved skills:

- `team-memory`
- `idea-shaping`

Each skill directory must keep this shape:

```text
<skill-name>/SKILL.md
```

If a tool does not support automatic skill discovery, point it to `skills-index.md` or the relevant `skills/<skill-name>/SKILL.md` manually.
```

- [ ] **Step 7: Verify docs contain no 16-skill bundle references**

Run:

```bash
rg -n "16|agents-skills-bundle|portable skill bundle|exported from Claude Code|skills/plugins" 'D:/AI/my-skills/README.md' 'D:/AI/my-skills/AGENTS.md' 'D:/AI/my-skills/skills-index.md' 'D:/AI/my-skills/adapters'
```

Expected: no matches. If `rg` exits with code 1 because there are no matches, treat that as success.

---

### Task 4: Rewrite Validation Script

**Files:**
- Modify: `scripts/validate.ps1`

**Interfaces:**
- Consumes: `.claude-plugin/plugin.json`, `skills/idea-shaping/SKILL.md`, `skills/team-memory/SKILL.md`, `skills-index.md`.
- Produces: Strict validation gate used by install/sync scripts and final verification.

- [ ] **Step 1: Replace `scripts/validate.ps1`**

Write this content to `D:/AI/my-skills/scripts/validate.ps1`:

```powershell
param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Skills = Join-Path $Root 'skills'
$PluginManifest = Join-Path $Root '.claude-plugin\plugin.json'
$SkillsIndex = Join-Path $Root 'skills-index.md'
$AllowedSkills = @('idea-shaping', 'team-memory')
$errors = @()

function Add-ValidationError {
  param([string]$Message)
  $script:errors += $Message
}

function Get-FrontmatterValue {
  param(
    [string]$Content,
    [string]$Key
  )

  $pattern = "(?m)^$([regex]::Escape($Key)):\s*(.+?)\s*$"
  $match = [regex]::Match($Content, $pattern)
  if ($match.Success) {
    return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
  }
  return $null
}

if (!(Test-Path $PluginManifest)) {
  Add-ValidationError "Missing plugin manifest: $PluginManifest"
} else {
  try {
    Get-Content $PluginManifest -Raw | ConvertFrom-Json | Out-Null
  } catch {
    Add-ValidationError "Plugin manifest is not valid JSON: $($_.Exception.Message)"
  }
}

if (!(Test-Path $Skills)) {
  Add-ValidationError "Missing skills directory: $Skills"
} else {
  $legacyPlugins = Join-Path $Skills 'plugins'
  if (Test-Path $legacyPlugins) {
    Add-ValidationError "Legacy nested plugin directory is not allowed: $legacyPlugins"
  }

  $skillDirs = @(Get-ChildItem -Path $Skills -Directory | Sort-Object Name)
  $actualNames = @($skillDirs | ForEach-Object { $_.Name })

  foreach ($name in $actualNames) {
    if ($AllowedSkills -notcontains $name) {
      Add-ValidationError "Unexpected skill directory: $name"
    }
  }

  foreach ($name in $AllowedSkills) {
    if ($actualNames -notcontains $name) {
      Add-ValidationError "Missing required skill directory: $name"
    }
  }

  foreach ($skillDir in $skillDirs) {
    $skillFile = Join-Path $skillDir.FullName 'SKILL.md'
    if (!(Test-Path $skillFile)) {
      Add-ValidationError "Missing SKILL.md in $($skillDir.FullName)"
      continue
    }

    $content = Get-Content $skillFile -Raw
    if ($content -notmatch '^---\s*\r?\n') {
      Add-ValidationError "Missing YAML frontmatter start in $skillFile"
      continue
    }

    $frontmatterName = Get-FrontmatterValue -Content $content -Key 'name'
    $frontmatterDescription = Get-FrontmatterValue -Content $content -Key 'description'

    if ([string]::IsNullOrWhiteSpace($frontmatterName)) {
      Add-ValidationError "Missing frontmatter name in $skillFile"
    } elseif ($frontmatterName -ne $skillDir.Name) {
      Add-ValidationError "Frontmatter name mismatch in $skillFile; expected '$($skillDir.Name)', got '$frontmatterName'"
    }

    if ([string]::IsNullOrWhiteSpace($frontmatterDescription)) {
      Add-ValidationError "Missing frontmatter description in $skillFile"
    }
  }
}

if (!(Test-Path $SkillsIndex)) {
  Add-ValidationError "Missing skills index: $SkillsIndex"
} else {
  $indexContent = Get-Content $SkillsIndex -Raw
  foreach ($name in $AllowedSkills) {
    $expectedLink = "skills/$name/SKILL.md"
    if ($indexContent -notmatch [regex]::Escape($expectedLink)) {
      Add-ValidationError "skills-index.md missing link: $expectedLink"
    }
  }

  $unexpectedIndexLinks = [regex]::Matches($indexContent, 'skills/([^/]+)/SKILL\.md') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $AllowedSkills -notcontains $_ }
  foreach ($name in $unexpectedIndexLinks) {
    Add-ValidationError "skills-index.md references unexpected skill: $name"
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Host "Validation passed for one plugin with skills: $($AllowedSkills -join ', ')."
```

- [ ] **Step 2: Run validation and expect current target shape to pass**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:/AI/my-skills/scripts/validate.ps1'
```

Expected output:

```text
Validation passed for one plugin with skills: idea-shaping, team-memory.
```

- [ ] **Step 3: Verify validation rejects stale legacy manifest if recreated**

Run:

```bash
test ! -e 'D:/AI/my-skills/plugin.json' && printf 'legacy root plugin.json absent\n'
```

Expected: prints `legacy root plugin.json absent`.

---

### Task 5: Rewrite Install And Sync Scripts

**Files:**
- Modify: `scripts/install-claude-code.ps1`
- Modify: `scripts/sync-from-claude.ps1`

**Interfaces:**
- Consumes: strict validation script from Task 4.
- Produces: helper scripts that cannot install/sync arbitrary legacy skills by default.

- [ ] **Step 1: Replace `scripts/install-claude-code.ps1`**

Write this content to `D:/AI/my-skills/scripts/install-claude-code.ps1`:

```powershell
param(
  [switch]$WhatIf,
  [string]$Target = "$env:USERPROFILE\.claude\skills"
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'skills'
$Validate = Join-Path $PSScriptRoot 'validate.ps1'
$ApprovedSkills = @('idea-shaping', 'team-memory')

& $Validate

if (!(Test-Path $Source)) {
  throw "Plugin skills directory not found: $Source"
}

if (!(Test-Path $Target)) {
  if ($WhatIf) {
    Write-Host "Would create $Target"
  } else {
    New-Item -ItemType Directory -Path $Target | Out-Null
  }
}

foreach ($skillName in $ApprovedSkills) {
  $sourceSkill = Join-Path $Source $skillName
  $targetSkill = Join-Path $Target $skillName

  if (!(Test-Path $sourceSkill)) {
    throw "Approved skill is missing: $sourceSkill"
  }

  if ($WhatIf) {
    Write-Host "Would install $sourceSkill -> $targetSkill"
  } else {
    if (Test-Path $targetSkill) { Remove-Item -Recurse -Force $targetSkill }
    Copy-Item -Recurse -Force $sourceSkill $targetSkill
    Write-Host "Installed $skillName"
  }
}
```

- [ ] **Step 2: Preview Claude Code install**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:/AI/my-skills/scripts/install-claude-code.ps1' -WhatIf
```

Expected output includes:

```text
Validation passed for one plugin with skills: idea-shaping, team-memory.
Would install D:\AI\my-skills\skills\idea-shaping -> C:\Users\Administrator\.claude\skills\idea-shaping
Would install D:\AI\my-skills\skills\team-memory -> C:\Users\Administrator\.claude\skills\team-memory
```

- [ ] **Step 3: Replace `scripts/sync-from-claude.ps1`**

Write this content to `D:/AI/my-skills/scripts/sync-from-claude.ps1`:

```powershell
param(
  [switch]$WhatIf,
  [string[]]$Skill = @('idea-shaping', 'team-memory')
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $env:USERPROFILE '.claude\skills'
$Dest = Join-Path $Root 'skills'
$ApprovedSkills = @('idea-shaping', 'team-memory')
$Validate = Join-Path $PSScriptRoot 'validate.ps1'

foreach ($skillName in $Skill) {
  if ($ApprovedSkills -notcontains $skillName) {
    throw "Refusing to sync unapproved skill '$skillName'. Approved skills: $($ApprovedSkills -join ', ')"
  }
}

if (!(Test-Path $Source)) {
  throw "Source skills directory not found: $Source"
}

if (!(Test-Path $Dest)) {
  if ($WhatIf) {
    Write-Host "Would create $Dest"
  } else {
    New-Item -ItemType Directory -Path $Dest | Out-Null
  }
}

foreach ($skillName in $Skill) {
  $sourceSkill = Join-Path $Source $skillName
  $target = Join-Path $Dest $skillName

  if (!(Test-Path $sourceSkill)) {
    throw "Source skill directory not found: $sourceSkill"
  }

  if ($WhatIf) {
    Write-Host "Would sync $sourceSkill -> $target"
  } else {
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse -Force $sourceSkill $target
    Write-Host "Synced $skillName"
  }
}

if (!$WhatIf) {
  & $Validate
}
```

- [ ] **Step 4: Preview sync for installed skills**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:/AI/my-skills/scripts/sync-from-claude.ps1' -WhatIf
```

Expected: if both approved skills exist in `~/.claude/skills`, output includes `Would sync` lines for both. If `idea-shaping` is not installed globally yet, expected failure is:

```text
Source skill directory not found: C:\Users\Administrator\.claude\skills\idea-shaping
```

This failure is acceptable before installing `idea-shaping`; do not broaden sync to all global skills.

- [ ] **Step 5: Verify sync rejects unapproved skills**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:/AI/my-skills/scripts/sync-from-claude.ps1' -Skill brainstorming -WhatIf
```

Expected: fails with:

```text
Refusing to sync unapproved skill 'brainstorming'. Approved skills: idea-shaping, team-memory
```

---

### Task 6: Final Structural Verification

**Files:**
- Verify: `.claude-plugin/plugin.json`
- Verify: `PROJECT_SPEC.md`
- Verify: `README.md`
- Verify: `AGENTS.md`
- Verify: `skills-index.md`
- Verify: `skills/idea-shaping/SKILL.md`
- Verify: `skills/team-memory/SKILL.md`
- Verify: `skills/team-memory/evals/evals.json`
- Verify: `scripts/*.ps1`

**Interfaces:**
- Consumes: all previous tasks.
- Produces: evidence that the project matches the approved one-plugin two-skill design.

- [ ] **Step 1: Run strict validation**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:/AI/my-skills/scripts/validate.ps1'
```

Expected output:

```text
Validation passed for one plugin with skills: idea-shaping, team-memory.
```

- [ ] **Step 2: Verify direct skill directories**

Run:

```bash
powershell.exe -NoProfile -Command "Get-ChildItem -Path 'D:\AI\my-skills\skills' -Directory | Select-Object -ExpandProperty Name | Sort-Object"
```

Expected output exactly:

```text
idea-shaping
team-memory
```

- [ ] **Step 3: Verify no legacy paths remain**

Run:

```bash
test ! -e 'D:/AI/my-skills/plugin.json' && test ! -e 'D:/AI/my-skills/skills/plugins' && printf 'legacy paths absent\n'
```

Expected: prints `legacy paths absent`.

- [ ] **Step 4: Verify index lists exactly two skills**

Run:

```bash
powershell.exe -NoProfile -Command "$links=[regex]::Matches((Get-Content -Raw -Path 'D:\AI\my-skills\skills-index.md'), 'skills/([^/]+)/SKILL\.md') | ForEach-Object { $_.Groups[1].Value } | Sort-Object; $links; if (($links -join ',') -ne 'idea-shaping,team-memory') { throw 'skills-index.md does not list exactly idea-shaping and team-memory' }"
```

Expected output:

```text
idea-shaping
team-memory
```

- [ ] **Step 5: Preview install script**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:/AI/my-skills/scripts/install-claude-code.ps1' -WhatIf
```

Expected: validation passes and only `idea-shaping` and `team-memory` are listed for installation.

- [ ] **Step 6: Check git status handling**

Run:

```bash
git -C 'D:/AI/my-skills' rev-parse --is-inside-work-tree 2>/dev/null || printf 'not a git repo; no commit created\n'
```

Expected: prints `not a git repo; no commit created`.

- [ ] **Step 7: Report final evidence**

Final implementation report must include:

```text
Validation command: powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
Validation result: <exact pass/fail output>
Skill directories: idea-shaping, team-memory
Legacy paths: plugin.json absent, skills/plugins absent
Git: not a git repository; no commit created
```
