# my-skills

`my-skills` is a single Claude Code plugin that packages seven agent skills.

The plugin root is this repository. Its canonical plugin manifest is:

```text
.claude-plugin/plugin.json
```

Included skills:

- `coding-workflow`
- `configuring-plugin`
- `generating-reqable-docs`
- `idea-shaping`
- `subagent-takeover`
- `using-tool`
- `writing-skills`

## Use As A Claude Code Plugin

From the parent directory of this repository, start Claude Code with this plugin directory:

```powershell
claude --plugin-dir ./my-skills
```

From inside this repository, use:

```powershell
claude --plugin-dir .
```

You can also pass an absolute path:

```powershell
claude --plugin-dir D:\AI\my-skills
```

During development, reload changed plugins from inside Claude Code:

```text
/reload-plugins
```

List loaded plugins:

```text
/plugin list
```

## Use The Skills

Invocation modes:

- `coding-workflow`, `generating-reqable-docs`, `idea-shaping`, and `writing-skills` are user-only skills. Their frontmatter includes `disable-model-invocation: true`, so the model should not invoke them automatically.
- `configuring-plugin` is model-invocable so it can configure, upgrade, or repair this plugin's per-project configuration for the current workspace. It also handles configuration writes and repairs delegated from other skills.
- `subagent-takeover` is model-invocable so `coding-workflow` can route to it after the user selects the multiple-subagents execution mode. It still runs only on that route or on explicit user invocation, never from a generic task category.
- `using-tool` is model-invocable and mandatory before using any skill from this plugin. Agents must load it first, then load the runtime mapping file for the current agent/runtime before executing the target skill.

Examples:

```text
/my-skills:coding-workflow implement this feature
```

```text
/coding-workflow fix this bug
```

```text
/my-skills:writing-skills @docs/experience/example.md this is a failed skill-use experience
```

```text
/configuring-plugin set up this workspace's plugin configuration
```

If a runtime tool rejects a user-only skill because of `disable-model-invocation: true`, the user invocation is still valid. The agent should read the matching `skills/<skill-name>/SKILL.md` file and follow it directly.

## Skill Summary

| Skill | Mode | Use when... |
|---|---|---|
| `coding-workflow` | user-only | You explicitly want to plan, approve, implement, and validate non-trivial coding work with a lightweight workflow. |
| `configuring-plugin` | model-invocable | You want to configure, upgrade, or repair this plugin's per-project configuration for the current workspace, or another plugin skill needs a managed configuration block created or repaired. |
| `generating-reqable-docs` | user-only | You explicitly want to generate a Reqable Collection 3.0 JSON interface document from an API definition or reference collection. |
| `idea-shaping` | user-only | You explicitly want to shape a product, feature, project, startup, side-project, or internal-tool idea. |
| `subagent-takeover` | model-invocable (routed from `coding-workflow` or explicit invocation) | You selected the multiple-subagents execution mode in `coding-workflow`, or you explicitly want to split an approved plan into human-reviewed subtasks and execute them through a declared dispatch backend. |
| `writing-skills` | user-only | You explicitly want to create, diagnose, edit, or verify skills with a TDD-style process. |
| `using-tool` | model-invocable | Before using any skill from this plugin, to adapt portable tool-use instructions to the current runtime. |

## Install As A Claude Code Plugin

The preferred development path is loading the repository for the current session:

```powershell
claude --plugin-dir .
```

To persistently install the entire repository as one Claude Code plugin, validate first, then register the local marketplace and install the plugin with Claude Code's native commands:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
claude plugin marketplace add D:\AI\my-skills
claude plugin install my-skills@my-skills
```

Add `--scope project` (or `--scope local`) to either native command to limit the installation to a project or local configuration. This installs one `my-skills` plugin containing all seven skills; it does not copy separate skill directories into `~/.claude/skills`.

Inspect or remove the persistent installation with Claude Code's native commands:

```powershell
claude plugin list
claude plugin details my-skills
claude plugin uninstall my-skills@my-skills
```

## Skill Directory Installs

`scripts/install-agent-skills.ps1` is the repository's single install script. It installs skill directories into agent tool roots; it is not a plugin installer, and it does not register marketplaces or run `claude plugin install`.

## Use With Other Agent Runtimes

Other tools can use these skills if they support directories shaped like:

```text
<skill-name>/SKILL.md
```

Copy or symlink selected skill directories from:

```text
skills/<skill-name>
```

into the runtime's skill directory.

Common locations:

```text
~/.agents/skills/<skill-name>
~/.codex/skills/<skill-name>
```

Before using any skill from this plugin in another agent runtime, load `using-tool` first, then load the matching runtime file under `skills/using-tool/runtimes/`. The runtime file explains how portable tool-action aliases such as `ask`, `read`, `find`, `edit`, `run`, `todo`, `agent`, and `check` map to that runtime's actual tools or interaction patterns.

For runtime-specific notes, see:

- `adapters/claude-code/README.md`
- `adapters/agents/AGENTS.md`
- `adapters/codex/AGENTS.md`
- `adapters/trae/README.md`
- `adapters/codearts/README.md`

### Install Script: Pick The Tools, Pick The Skills

`scripts/install-agent-skills.ps1` is the repository's single install script, and it replaces the former per-tool installers. It targets any subset of tools, any subset of skill groups, and either a directory link (the installed skills follow this repository) or a copy (an independent snapshot).

Skill plan: the installer works with groups, and a group is always installed as a whole. Each group and each skill carries a one-line intro in the menu.

| Group key | Label | Skills |
|---|---|---|
| `core` (default) | Core workflow | `coding-workflow`, `subagent-takeover`, `configuring-plugin`, `using-tool` |
| `documents` | Documents | `generating-reqable-docs` |
| `ideas-memory` | Ideas | `idea-shaping` |

Skills that are not listed in the plan are ignored by this script, both for installation and for removal. An install with no group or skill selection uses the default group; an uninstall with no selection removes every group. Planned skills missing from `skills/` stop the run with a clear message instead of silently installing an incomplete group.

Local tool detection checks three things per tool: its user state directory (for example `~/.codex` or `$DSH_HOME`), its command on `PATH` (`codex`, `claude`, `dsh`), and whether the `-Target` project already contains the tool's folder (`.trae`, `.codeartsdoer`, `.dsh`, ...). Detected tools are pre-selected in the wizard; every tool stays selectable, so a tool can be prepared before it is installed.

```powershell
# Interactive: action (install / reinstall / uninstall), groups, tools, link or copy, confirm
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1

# Same wizard with the typed prompt instead of the arrow-key selector
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -PlainSelect

# Pick the action on the command line instead of at the first prompt
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh -Action uninstall
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh -Action reinstall

# Show the skill plan (groups, skills, intros) plus the tool roots, then exit
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -List

# Non-interactive: name the tools and groups on the command line
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh,agents -Groups core
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools trae,codearts -Groups documents,ideas-memory -Scope project -Target D:\work\my-app
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools custom -Path D:\shared\agent-skills -Groups all -LinkType copy

# Exact skills, bypassing the group rule
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh -Skills using-tool

# Remove the same selection again
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh,agents -Groups core -Uninstall

# Remove and install again even when the entries are already correct
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh,agents -Reinstall
```

Accepted group values are the key (`core`), the label (`Core workflow`, `Ideas`), an unambiguous prefix (`doc`), or `all`. `-Groups` and `-Skills` cannot be combined.

| Tool key | User root | Project root |
|---|---|---|
| `dsh` | `$DSH_HOME/skills` | `<project>/.dsh/skills` |
| `agents` | `~/.agents/skills` | `<project>/.agents/skills` |
| `codex` | `~/.codex/skills` | `<project>/.codex/skills` |
| `claude` | `~/.claude/skills` | `<project>/.claude/skills` |
| `trae` | — | `<project>/.trae/skills` |
| `codearts` | — | `<project>/.codeartsdoer/skills` |
| `custom` | `-Path <skills directory>` | `-Path <skills directory>` |

Behavior worth knowing:

- The wizard asks for the action first: `Install` (keeps entries that are already correct), `Reinstall` (removes the selected entries and adds them again), or `Uninstall`. `-Action install|reinstall|uninstall` sets it on the command line, and `-Reinstall` / `-Uninstall` remain as switches for the same two actions.
- The group step lists groups as selectable rows with each group's skills and their one-line intros printed underneath; the skill lines are informational, because a group is installed as a whole.
- An uninstall skips the link/copy prompt, because nothing is being created.
- The interactive wizard is keyboard-driven in a real console: `Up`/`Down` move, `Space` toggles, `A` selects all, `N` clears, `I` inverts, `Enter` confirms, `Esc` cancels. The single-choice steps (action, install mode) also accept `Left`/`Right` and the digit keys, and the last prompt is a single `Y`/`N` key.
- `Enter` with nothing selected does not confirm; the selector asks for at least one item so a selection can never be empty.
- When raw key input is impossible (redirected input or output, `< file`, CI, ISE), the wizard automatically falls back to the typed prompt (`numbers/names`, `a` for all, `0` to cancel) instead of blocking, because reading a key there would hang. `-PlainSelect` forces the typed prompt even in a console.
- `-LinkType auto` (default) tries an NTFS directory junction, then a symbolic link. `-LinkType copy` copies real files instead, and re-running refreshes the copies.
- `-Scope auto` (default) uses user roots for user-capable tools and project roots for Trae and CodeArts. `-Scope project` needs `-Target`.
- CodeArts ignores directory links, so that tool is always installed by copy, followed by `ProjectSkillStatus.txt` for the installed subset.
- The installer never touches version control: it does not read, write, or create `.gitignore` (or any other git file). Keeping installed folders out of a commit is the user's decision.
- An existing real directory is replaced only when it is a previous copy; anything else needs `-Force`. `-Uninstall` removes links, and removes a real directory only when it mirrors the repository or when `-Force` is given.
- `-Reinstall` deletes the selected entries and installs them again; without it a re-run is idempotent and reports `already in place`. `-Reinstall` and `-Uninstall` cannot be combined.
- Every install and uninstall is verified by hashing the installed files against the repository.

### Install Into A DSH (DeepSeek Harness) Environment

DSH discovers skills from `<project>/.dsh/skills`, `<project>/.agents/skills`, `$DSH_HOME/skills`, and `~/.agents/skills`. Install into those roots with the install script, which links every skill directory instead of copying files, so the installed skills follow this repository: edited `SKILL.md` files, new supporting files, and newly added skills apply without reinstalling.

Preview, then install for the current DSH user (available in every project):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh -WhatIf
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh
```

Install for one project instead (links into `<project>/.dsh/skills`; ignoring that folder is up to you, the installer does not touch `.gitignore`):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh -Scope project -Target D:\work\my-app
```

Add `-Tools agents` to cover the `.agents/skills` root as well, and remove the links with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools dsh,agents -Uninstall
```

`-LinkType auto` (the default) creates an NTFS directory junction, which needs no special privilege and may point across local volumes; it falls back to a symbolic link only when the junction fails. On Windows a symbolic link needs Developer Mode or an elevated shell. If linking is not possible at all, point the DSH profile at the repository skills directory directly with `customSkillDirs`:

```yaml
- id: skill-filesystem
  name: "@deepseek-ai/dsh-skill-filesystem"
  config:
    customSkillDirs:
      - D:\AI\my-skills\skills
```

DSH watches the skill root itself, so a newly linked skill is detected, but an edit made inside the repository through the link raises no watcher event. Skill content is read live through the link; restart the session if a skill catalog description looks stale.

### Subagent Dispatch Backends

Delegation is the least portable capability across runtimes, and the difference is largest when the model is served behind a local proxy. Runtimes differ in whether a native subagent exists, whether dispatch can block inside the turn, how many subagents may run at once, and whether one can be resumed by handle.

Every runtime file under `skills/using-tool/runtimes/` therefore declares a **Subagent Dispatch Capability** section: native tool, blocking form, parallel limit, resume-by-handle, default backend, and CLI fallback.

`subagent-takeover` resolves exactly one backend before splitting and records it in the subtask document:

| Backend | Execution |
|---|---|
| `native` | The runtime's own subagent tool, dispatched blocking inside the turn. |
| `cli` | The coordinator runs a headless agent process per subtask and waits for it. This is the portable path for local-proxy models, because the spawned process carries its own model configuration. |
| `sequential` | No delegation: the coordinator executes each subtask itself, with the on-disk subtask document as the context boundary. |
| `manual` | The coordinator writes dispatch-prompt files for the user to run elsewhere and validates the feedback files that come back. |

All four backends produce the same artifacts — the subtask document, the per-subtask feedback file, and the status table — so a runtime that cannot delegate degrades explicitly instead of silently changing the workflow's outcome.

Declare the backend (and a concurrency cap) in the project-level `.agents/my-skills-local-config.md`:

```markdown
<!-- agent-dispatch:start -->
## Agent Dispatch Configuration

- Backend: native | cli | sequential | manual
- CLI template: <command that runs one headless agent for one prompt file>
- Max parallel: <integer, default 1>
- Subagent model: inherit | <provider/model>
<!-- agent-dispatch:end -->
```

`Max parallel` defaults to `1`, which is the correct value when a local inference server serves one request at a time.

## Repository Layout

```text
my-skills/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   ├── coding-workflow/
│   │   └── SKILL.md
│   ├── configuring-plugin/
│   │   └── SKILL.md
│   ├── generating-reqable-docs/
│   │   └── SKILL.md
│   ├── idea-shaping/
│   │   └── SKILL.md
│   ├── subagent-takeover/
│   │   └── SKILL.md
│   ├── using-tool/
│   │   ├── SKILL.md
│   │   └── runtimes/
│   │       ├── claude-code.md
│   │       ├── codex.md
│   │       ├── trae.md
│   │       ├── codearts.md
│   │       └── dsh.md
│   └── writing-skills/
│       ├── SKILL.md
│       └── supporting files...
├── adapters/
├── scripts/
├── PROJECT_SPEC.md
└── skills-index.md
```

## Maintain This Plugin

`PROJECT_SPEC.md` is the source of truth for adding or changing skills.

Core rules:

- The repository root is the plugin root.
- Keep `.claude-plugin/plugin.json` as the canonical plugin manifest.
- Keep runtime skills under `skills/<skill-name>/SKILL.md`.
- Keep `skills-index.md`, this README, and validation rules in sync after skill changes.
- Existing user-only skills must remain user-only with `disable-model-invocation: true` unless the user explicitly approves a behavior change.
- When creating a future skill, ask whether it should be `user-only` or `model-invocable` before writing frontmatter.

Validate the plugin:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

## Sync Notes

This repository is the source project. Do not edit installed copies under `~/.claude/skills` independently; the directory install links those copies back to `skills/`, so edits made there already land in the repository. Prefer editing `skills/<skill-name>/` directly and then reinstalling or updating the plugin.
