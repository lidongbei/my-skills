---
name: my-config-manager
description: Use when initializing, modifying, or validating this plugin's per-project configuration for the current workspace: first-time setup in a new workspace, repairing missing, malformed, duplicated, or legacy configuration blocks or locations, updating a value that is already configured (correcting a pinned toolchain version, migrating the output root together with its records, choosing how the output root's records are versioned — committed to the working repository, ignored in it, or kept in a standalone repository — re-choosing a configured item), auditing the current configuration read-only, or when another plugin skill needs a managed configuration block created, repaired, or corrected.
---

# My Config Manager

## Overview

This skill manages this plugin's per-project configuration for the current workspace through three capabilities:

- **Initialize** — first-time setup in a new workspace, and repair of a workspace whose configuration is missing, malformed, duplicated, or left at a legacy location.
- **Modify** — change a value that is already valid: a corrected toolchain pin, an output-root migration that moves the existing records together with the value, a change of how the records are versioned (committed to the working repository, ignored in it, or a standalone repository), a re-chosen configuration item.
- **Validate** — a read-only audit of the current configuration: classify every registry item, verify every value against this workspace and this machine, and report drift — including records stranded under a previous output root.

Core principle: **this skill owns every create and repair of the plugin's project-level configuration.** Other plugin skills resolve and read those values, but they do not create or repair them; when such a skill would write or repair a managed block, it hands off here. Never silently repair, overwrite, migrate, or guess a configuration value.

### Choosing the capability

- The user asks to check, audit, verify, or validate the configuration → **Validate**.
- The user asks to change a value that is already configured ("update the configuration", "correct the pinned JDK", "move the output root", "change the dispatch backend", "re-run the choices") → **Modify**.
- Anything else that triggers this skill — first-time setup; a missing, malformed, duplicated, or legacy configuration; a delegated create or repair → **Initialize**.

A run executes exactly one capability and never silently turns into another. When Initialize or Validate uncovers something the user may want changed (a stale pin, records under a previous root), the run reports the finding and names the capability that resolves it; it does not apply the change itself.

## Hard Boundaries

- Trigger when the user explicitly invokes this skill, when the user asks to configure, complete, upgrade, update, or audit this plugin's project configuration for the current workspace, or when another plugin skill delegates a create/repair of a managed configuration block.
- Do not trigger for ordinary work that merely reads a configured value; act only on configuration tasks (first-time setup, upgrade, repair, update, or audit).
- Configure only the plugin's designated project-level configuration location defined by the current runtime mapping. Do not configure or repair any other file.
- Never silently repair a malformed, duplicated, or legacy configuration. Use `ask` and require the user to decide.
- Run every `ask` of this configuration in Chinese: the question text, each option `label`, and each option `description` are written in Chinese. Keep this skill's document, the managed blocks, and the Output Contract report in English, and never translate a value that will be written into a block. When the runtime mapping requires a literal English marker on the recommended option (for example `(Recommended)`), keep that marker and write the rest of the label in Chinese.
- Never run `git init`, add or remove an ignore rule for an output root, or commit records anywhere except as the side effect of a `Records` disposition the user chose in this run (`standalone-repo` → `git init` the root; `ignored-in-workspace` → ignore exactly the output-root path). No other git action on an output root is this skill's to take.
- Detect project languages only from the documented marker files at the workspace root and its direct child directories; do not recurse the tree. Pin only tools for a language the project actually uses.
- Do not change other skills' behavior and do not invent configuration items outside the registry below.
- Do not commit, stage, or otherwise version-control the configuration location; the config-location ignore item exists to keep it out of version control.
- Do not write a value the user has not chosen. For a default, present it as the recommended `ask` option; never pick it silently.
- Do not claim an item is configured without a fresh `check` after writing.
- Never change a value that is already valid on your own initiative: a valid value is reported, not re-asked. Change it only in a Modify run the user asked for, and only for the items the user selected.
- A run that writes an `Output root` value while records exist under a different root runs the Records migration sub-flow before the write. Creating the destination directory is step zero of that sub-flow, never the migration itself; a run that ends with an empty new output root while a previous root still holds records ends `unresolved`, not `configured`.
- Never move, copy, or delete existing records under an output root without an explicit user choice, and never claim a migration succeeded without comparing the destination inventory against the source.
- Never force-add, or make a repository stop ignoring, a migrated output root; report that the records stay uncommitted instead.
- The Validate capability is read-only: it writes nothing, edits nothing, creates nothing, and deletes nothing — not even a missing output root — and it never asks the user to change a value; it classifies, verifies, and reports.

## Delegation From Other Skills

Other plugin skills resolve and read configuration (output root, dispatch; toolchain is registered ahead of its consumers) from the same designated location, but they do not create or repair it. When `coding-workflow`, `subagent-takeover`, or `generating-reqable-docs` reaches a point where it would have written or repaired a managed block, it hands off to this skill. This skill runs the interactive configuration below and returns control **with the Output Contract report**; the invoking skill then continues from the values and states that report names. A delegated run may skip nothing: it reports every registry item, including the config-location ignore item.

## Configuration Registry

The registered project-level configuration items for this plugin. Treat this table as the single source of truth for what "configured" means. When a skill later introduces a new project-level config item, register a row here.

| Config item | Managed block | Required fields | Consumed by | Necessity |
|---|---|---|---|---|
| Output root | `agent-output-root` | `Output root` = an absolute path; `Records` = the records disposition, one of `committed-in-workspace`, `ignored-in-workspace`, `standalone-repo`, `unmanaged` (see Records disposition) | `coding-workflow`, `subagent-takeover`, `generating-reqable-docs` | Required |
| Dispatch | `agent-dispatch` | `Backend`; `CLI template` when `Backend: cli`; `Max parallel` (default `1`); `Subagent model` | `subagent-takeover` | Optional (absent → runtime default) |
| Toolchain | `agent-toolchain` | At least one `<tool name>: <version or absolute path>` entry; every value resolves unambiguously to exactly one installed, runnable build on this machine | Registered for later consumers; no skill consumes it yet | Optional (absent → no pinned toolchain) |
| Config location ignore | none — a version control ignore rule, not a block | The configuration location file itself is excluded by the workspace's version control, so the local config is never committed | the whole registry: a per-developer file that gets committed stops being per-developer | Required |

Output-root default: the recommended value is `<repository root>/.agent-output`, inside the working repository, where `<repository root>` is the nearest ancestor directory of the workspace root that contains a version control root (`.git`), and, in a workspace without version control, the workspace root itself. A single-folder workspace (many tools open only the repository root) can then see, browse, and manage the plan and completion records; an absolute path outside the workspace stays valid and is still offered, but never as the recommended option. The default is presented through `ask` and is never written silently.

### Records disposition

The `Records` field of the `agent-output-root` block fixes how the output root's records relate to version control. It is a configured choice, never inferred from the path's location:

| Value | Meaning | Valid when |
|---|---|---|
| `ignored-in-workspace` | The root lives inside the working repository and an ignore rule excludes exactly the output-root path; the records stay local and are never committed. | Root inside a version-controlled workspace |
| `committed-in-workspace` | The root lives inside the working repository and the working repository commits the records. | Root inside a version-controlled workspace |
| `standalone-repo` | The root is its own git repository; records are committed there, never in the working repository. | Any root |
| `unmanaged` | No version-control handling; the records stay unversioned. | Any root |

Ask the disposition as its own question, right after the output-root value — the path and the disposition are two decisions. When the chosen root is inside a version-controlled workspace, `ignored-in-workspace` is the recommended option (records are per-project working state and should not enter the shared history by default), with `committed-in-workspace` and `standalone-repo` as alternatives. For a root outside the workspace, or a workspace without version control, offer `standalone-repo` and `unmanaged` and mark neither as recommended. Never offer a disposition the path cannot support — `committed-in-workspace` and `ignored-in-workspace` are meaningless outside a version-controlled workspace.

The disposition has side effects this skill owns, applied only because the user chose the disposition — the ask is the consent:

- `ignored-in-workspace` → add an ignore rule for exactly the output-root path, with the config-location ignore item's discipline: check for an equivalent rule first, append only the missing line, never rewrite the file.
- `standalone-repo` → run `git init "<output root>"` when the root is not already a git repository. A `standalone-repo` root inside the working repository appears there as an untracked nested repository; offer ignoring that path in the working repository as a separate follow-up option, never silently.
- `committed-in-workspace` and `unmanaged` → no side effects. When a `committed-in-workspace` root is nevertheless ignored in the working repository, report that the records will stay uncommitted; never remove an ignore rule on your own.

An old-shape block (no `Records` line) is `malformed` — it misses a required field; the repair asks only the disposition question and appends the one line, without re-asking the path.

The configuration location is per-developer, machine-specific state: it holds absolute paths and runtime-specific backend choices, and the runtime mappings state that the location is ignored. That ignore rule is an invariant to verify, not a fact to assume — a fresh workspace usually has no ignore entry for it, and the first `git add .` then commits a machine-specific file into the shared repository. The rule covers exactly the configuration location file: only that file carries machine-specific state, so ignore the file itself, never the whole workspace. A directory-wide rule does not cover the file and also hides sibling content that is meant to be shared.

Write managed blocks in exactly this shape:

```markdown
<!-- agent-output-root:start -->
## Agent Output Configuration

- Output root: `<absolute path>`
- Records: ignored-in-workspace | committed-in-workspace | standalone-repo | unmanaged
<!-- agent-output-root:end -->

<!-- agent-dispatch:start -->
## Agent Dispatch Configuration

- Backend: native | cli | sequential | manual
- CLI template: <command that runs one headless agent for one prompt file>
- Max parallel: <integer, default 1>
- Subagent model: inherit | <provider/model>
<!-- agent-dispatch:end -->

<!-- agent-toolchain:start -->
## Agent Toolchain Configuration

- JDK: <version or absolute path>
- Node: <version or absolute path>
<!-- agent-toolchain:end -->
```

The toolchain block is open-ended: keep one `<tool name>: <version or absolute path>` entry per tool the user pins, and keep only the tools the user actually chooses. The example names above are illustrative, not a fixed field list.

### Language-driven toolchain detection

The toolchain item follows the project's actual languages, not a fixed list of popular tools. Before asking anything, detect the languages and the tools those languages need.

Scan the workspace root and its direct child directories (depth 1 only, never the whole tree) for marker files:

| Language | Marker files | Tools to pin |
|---|---|---|
| Java/JVM | `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts` | `JDK` plus `Maven` (Maven markers) or `Gradle` (Gradle markers) |
| Node | `package.json` | `Node` |
| Python | `pyproject.toml`, `requirements.txt`, `Pipfile`, `setup.py`, `setup.cfg` | `Python` |
| Go | `go.mod` | `Go` |
| Rust | `Cargo.toml` | `Rust` |
| .NET | `global.json`, `*.sln`, `*.csproj` | `.NET` |

A project with several markers gets several languages; a marker container at depth 1 (a sub-project, a monorepo package) counts as the project's language too.

Prefer a version the repository itself declares over anything found on this machine:

| Tool | Repository-declared version sources |
|---|---|
| Node | `.nvmrc`, `.node-version`, `package.json` `engines.node` or `packageManager` |
| Python | `.python-version`, `requires-python` in `pyproject.toml` |
| Java | `pom.xml` `maven.compiler.release` / `<java.version>`, Gradle `sourceCompatibility` / `targetCompatibility` / Java toolchain block |
| Maven / Gradle | `gradle/wrapper/gradle-wrapper.properties` `distributionUrl`; a Maven version only when the repository pins one explicitly |
| Go | the `go` directive in `go.mod` |
| Rust | `rust-version` in `Cargo.toml` |
| .NET | `sdk.version` in `global.json` |
| any | `.tool-versions` (asdf/mise) when it names the tool |

When no marker is found, do not guess: fall back to the generic "which tools do you want pinned" multi-select (`JDK`, `Node`, `Python`, `Maven`, `Gradle`, `Go`, `Rust`, `.NET`, plus a free-text "other"). That fallback has no recommended option — with no marker there is no project language to derive one from — so do not mark a tool as recommended there.

Probe this machine for what is actually installed, not only what `PATH` resolves to: `java -version`, `node -v`, `mvn -v`, `gradle -v`, `go version`, `cargo --version` and `python --version` report one default entry, and a machine that pins toolchains usually has several builds. Enumerate the install roots and version managers as well, then report the union:

| Tool | Enumerate installed entries |
|---|---|
| JDK | `%USERPROFILE%\.sdk\cache\java`, `%USERPROFILE%\.jdks`, `%ProgramFiles%\Java`, `%ProgramFiles%\Eclipse Adoptium`, `%ProgramFiles%\Microsoft\jdk-*`, `%USERPROFILE%\.sdkman\candidates\java`, `/usr/lib/jvm`, `/Library/Java/JavaVirtualMachines` — builds usually sit one container level down (`v-21.0.12\java-21.0.12`); each build directory holds `bin/java` or a `release` file, and a container holding neither is empty, not installed |
| Node | `nvm ls` / `nvm list`, `fnm list`, `volta list node` when those managers exist; `%USERPROFILE%\.sdk\cache\node`, `%APPDATA%\nvm`, `%LOCALAPPDATA%\fnm`, `%USERPROFILE%\.volta`, `/usr/local/n/versions/node` |
| Python | `py -0p` (the launcher lists every registered install), `conda env list`; `%USERPROFILE%\.sdk\cache\python`, `%USERPROFILE%\.pyenv\versions`, `%LOCALAPPDATA%\Programs\Python`, `~/.asdf/installs/python` |
| Maven | `%USERPROFILE%\.sdk\cache\maven`, `%ProgramFiles%\apache-maven-*`, `%USERPROFILE%\.sdkman\candidates\maven`, `/opt/apache-maven-*` |
| Gradle | `%USERPROFILE%\.gradle\wrapper\dists`, `%USERPROFILE%\.sdkman\candidates\gradle`, `%ProgramFiles%\Gradle*` |
| Go | `%ProgramFiles%\Go`, `/usr/local/go`, `%USERPROFILE%\.sdkman\candidates\go` |
| Rust | `rustup toolchain list` (each line is an installed toolchain); `%USERPROFILE%\.rustup\toolchains` |
| .NET | `dotnet --list-sdks` already lists every SDK under `DOTNET_ROOT`, not only the default |

State which entry is the `PATH` default and list the rest with their paths. Never treat `java -version` or `node -v` as the inventory: on a machine with four JDKs it reports one of them.

An entry counts as an installed build only when its directory holds something runnable — the executable (`bin/java`, `bin/node`, `bin/mvn`) or a `release` file. Some roots nest one container level above the build (`...\v-21.0.12\java-21.0.12`, `...\v-24.16.0\node-24.16.0`): enumerate the build directory, and treat a container that holds no build as empty rather than as an installed version. When a directory name and the build disagree, run the build to get its version.

Ask one question per detected language. Offer, in order: the repository-declared version (the recommended option when it is installed here), the other installed entries from that inventory (each labelled with its path), skip this language, and a free-text value. When the declared version is not installed, say so in the option description and recommend an installed version instead of a pin that cannot resolve. Because several builds of one major can be installed, pin an absolute path (or the exact full version) whenever the bare version would not identify exactly one installed entry. A repository declaration names a target version, not an installed build: when `pom.xml` declares `21` and the inventory holds only `21.0.12`, write `21.0.12` (or its path), because a major-only value matches no build id in the inventory.

The configuration location is defined by the current runtime's `using-tool` mapping (Claude Code: the repository-root, git-ignored file `.my-skills-local-config.md`). Do not read `CLAUDE.md`, `AGENTS.md`, `.trae/`, or any other file for this configuration.

### Legacy block names

Never read, recognize, migrate, or reuse these blocks. Treat their presence as `legacy-only`, not as configuration, and resolve them only through the user decision in step 4.

| Legacy block | Superseded by |
|---|---|
| `coding-workflow:artifact-root` | `agent-output-root` |

When a skill later retires a managed block name, add it here.

### Legacy configuration locations

Earlier plugin versions kept the same configuration file at other places (for example `.agents/my-skills-local-config.md` under the repository root). A file found at such a legacy location is not the configuration:

- Read it only to harvest candidate prior values. An output-root path found there is the important one: it names a root under which existing records may live, and it feeds the Records migration sub-flow below.
- Never write to, extend, or "fix" the legacy file, and never copy its blocks into the canonical location without asking.
- Resolve it through `ask` (in Chinese): re-initialize fresh values at the canonical location (recommended), or adopt a harvested value the user confirms. Deleting or archiving the legacy file is offered as an option and never done silently.
- Report the legacy file's path and its final disposition in `Action taken`.

## Records Migration Sub-Flow

Run this sub-flow whenever a run is about to write an `Output root` value while records exist under a different root — a Modify `U4` run, or an Initialize run whose classification surfaced a previous root: a value harvested from the current file, a legacy location, a legacy block, or a malformed duplicate, or record directories found at the sibling `<parent>/<project name>__agent` path.

1. **Find the candidates.** Collect every previous-root candidate: each output-root value seen during classification (including values in legacy files and malformed duplicates) plus the sibling `<parent>/<project name>__agent` path. Discard candidates that do not exist or hold nothing. When no candidate remains, skip the rest of this sub-flow and record `no previous records` as the migration outcome.
2. **Inventory each remaining candidate**: `plans/`, `complete/`, `subTasks/`, `reqable/`, `docs/`, any other children, per-child file counts, and whether the candidate is itself a git repository (`git -C "<candidate>" rev-parse --show-toplevel`). Show the inventory before asking anything.
3. **Choose the target** (Modify runs only): ask for the target root first — recommend `<repository root>/.agent-output`, then offer the other candidates that make sense here (for example a directory inside the workspace, or an absolute path outside it), and a free-text value. In an Initialize run the user already chose the new value for the output-root item; use it. Never treat the recommendation as the answer, and do not move anything before the target is chosen.
4. **Choose what happens to the records**: use `ask` (in Chinese), describing the inventory — move the records to the new root (recommended when the candidate is this workspace's `<project name>__agent` sibling or its children are exactly the plugin's record directories; otherwise describe both roots and let the user decide), copy them and keep the old root, or leave the records in place. The new root's value and what happens to the records are two separate decisions; ask both. Never move or copy anything before the user chooses.
5. **Execute**: create the destination directory when it does not exist — this is step zero, not the migration — then move or copy with `run`, one top-level child at a time, never the parent directory itself. On a move, do not delete the old root or its now-empty parents in the same step; verify first and leave the empty directory for the user to remove.
6. **Verify**: re-list the destination, compare every migrated child's file count with the inventory, compare per-file checksums against the pre-move checksums on a move, and `read` one migrated file to confirm it is intact. A count or checksum mismatch is a failed migration: stop, report the difference, and do not write the new value.
7. **Write the value** only after a clean verification, or after the user chose to leave the records in place. If the old root was a git repository, do not delete it and do not run `git init` anywhere; state that the old repository still exists.
8. **Apply the Records disposition** chosen for the new root (see Records disposition and Initialize step 6): `ignored-in-workspace` → ensure the ignore rule for the new root's path; `standalone-repo` → `git init` the new root when it is not already a repository; `committed-in-workspace` and `unmanaged` → no side effect. When the disposition is `committed-in-workspace` but the working repository ignores the new root's path, report that the records will stay uncommitted — never remove an ignore rule on your own.
9. **Report the records migration outcome** per candidate in `Action taken`: moved or copied N files to the destination, or left in place by user choice — and state what the old root now holds: its remaining children, or that it is empty and left for the user to remove.

## Capability: Initialize

First-time setup and repair of missing, malformed, duplicated, or legacy configuration.

### 1. Resolve context

1. Load `using-tool` and the current runtime mapping; the mapping defines the configuration location.
2. `read` that location. If it does not exist, treat every block-backed registry item as `missing`.
3. Resolve the repository root: the workspace root is the directory the runtime opened as the workspace; the repository root is the nearest ancestor of the workspace root containing a version control root (`.git`), and in a workspace without version control it is the workspace root itself. The configuration location file lives at the repository root.
4. Check for legacy configuration locations (see Legacy configuration locations). When the canonical location is absent but a legacy file exists, the run is a location migration: harvest candidate prior values from the legacy file and plan the re-initialization at the canonical location.

### 2. Classify each registry item

For each block-backed item, assign exactly one state from the `read` result:

- `missing` — no managed block for the item.
- `valid` — exactly one block, all required fields present and valid. For the output-root item this includes a `Records` line whose value is one of the four dispositions and is compatible with the path's location (`committed-in-workspace` and `ignored-in-workspace` require a root inside a version-controlled workspace).
- `malformed` — duplicated blocks, truncated markers, a missing required field (an old-shape `agent-output-root` block without the `Records` line counts), or an invalid value.
- `legacy-only` — only a block whose name is listed as legacy exists (for example `coding-workflow:artifact-root`). Legacy blocks are not valid configuration and must never be migrated or reused.

For the toolchain item, apply the same four states to the block itself and additionally judge each entry: an entry whose value pins a version that is not installed, or an absolute path that does not exist, makes the block `malformed`. Report the offending entry; do not repair it silently.

Classify the config-location ignore item by asking whether the configuration location **file** is excluded, not a directory that contains it:

- `valid` — the configuration location file is already excluded by an ignore rule that applies to that exact path, or the workspace is not under a version control root (`.git`), so no ignore rule applies.
- `missing` — the workspace is under a version control root and the configuration location file is not excluded. An ignore rule for a directory does not cover this item: the rule must name the file.
- `malformed` — an ignore rule mentions the file path but a later rule re-includes it, so the file is not actually excluded.

### 3. Plan the interactive session

Use `todo` to list every registry item with its state. Report `valid` items too, so the user sees the full picture; do not skip an item because it looks healthy.

### 4. Ask per item

Ask before writing any value; do not re-ask a `valid` item in a first-time or repair run — report it instead. Only a Modify run the user asked for may change a valid value, and only for the items the user selected there (see Capability: Modify).

Write the question text, every option `label`, and every option `description` in Chinese. Example shape for the optional dispatch item:

- question: 「`agent-dispatch` 配置块缺失，是否持久化调度后端？」
- options: 「使用运行时默认（推荐）」— 不写入该块，由运行时默认后端决定 / 「持久化为 `native`」— 写入 `Backend: native` / 「本次跳过」— 不写入，保持缺失

Block names, field names, paths, versions, and any other value that gets written stay exactly as they are reported; only the human-facing wording is Chinese. A value harvested from a legacy location or a legacy block is presented as a candidate option the user may confirm — it is never adopted silently.

- `missing` required item: use `ask` to let the user choose the value once. Mark the consumed skill's documented default as the recommended option (output-root default: `<repository root>/.agent-output`, inside the working repository; present an absolute path outside the workspace only as an alternative option). For the output-root item the value question is followed by the separate disposition question (see Records disposition): recommend `ignored-in-workspace` when the chosen root is inside a version-controlled workspace; offer `standalone-repo` and `unmanaged` without a recommendation otherwise.
- `missing` optional item: use `ask` to let the user set it, skip it, or accept the runtime default; do not write a value silently.
- Toolchain item, `missing`: detect the project's languages first (see Language-driven toolchain detection), then ask per detected language. Each language question offers the repository-declared version (recommended when installed), another version installed on this machine, skip, and a free-text value. When a declared version is not installed here, state that in the option description and recommend an installed one instead of a pin that cannot resolve. Detect instead of listing every popular tool: for a Java-only project, ask only about `JDK` and `Maven`/`Gradle`; never offer a tool the project does not use, and never pin a tool the user did not choose. Fall back to the generic "which tools do you want pinned" multi-select (JDK, Node, Python, Maven, Gradle, Go, Rust, .NET, plus a free-text "other") only when no marker file was found, and do not mark any tool as recommended in that fallback: with no marker there is no project language to derive a recommendation from.
- `malformed` or `legacy-only`: do not repair or migrate silently. Use `ask` to present the exact conflict and the candidate resolutions (which block to keep, which to delete, or clear to `missing`) and let the user decide. Apply only what the user chose. When the only defect is a missing `Records` line, ask only the disposition question (see Records disposition) and append that one line — the existing path value is not re-asked.
- Config-location ignore item, `missing`: use `ask` to offer adding the ignore rule as the recommended option; do not add it silently. Recommend the rule for the configuration location file (`/.my-skills-local-config.md` under Claude Code) and mark it as the recommended option. If an existing rule ignores a directory instead of the file, present narrowing it to the file as an alternative option, and do not delete or rewrite the existing rule on your own. This is a workspace-level invariant, so it stays `missing` unless the user chooses it.
- Config-location ignore item, `malformed`: present the conflicting rule and let the user decide what to do with it.

### 5. Migrate records before writing the output root

When the run is about to write an `Output root` value and the Records migration sub-flow's candidate check found a non-empty previous root, run that sub-flow now, before the write step. The `Output root` line is written only inside that sub-flow, after its verification passes (or after the user chose to leave the records in place). Skipping this step and merely creating the destination directory is the failure this capability exists to prevent: a fresh empty root with the workspace's history stranded elsewhere.

### 6. Write

Use `edit` to write only the managed block(s) the user chose:

- Location absent → create the file at the repository root containing only the chosen block(s).
- Block absent → append it.
- Existing block to change → replace only from `<!-- <name>:start -->` through `<!-- <name>:end -->`.

Never touch a block the user did not ask to change, and preserve all content outside the managed blocks.

The toolchain block is open-ended, so editing it never means rewriting the whole block: add, change, or remove only the entry lines for the tools the user chose this run, and preserve every other entry line and the markers exactly.

When the output-root block was written or its `Records` line changed, apply the disposition's side effects now (see Records disposition): `ignored-in-workspace` → ensure the ignore rule for exactly the output-root path exists; `standalone-repo` → `git init "<output root>"` when it is not already a repository. The output-root directory must exist first — after the Records migration sub-flow when it ran.

For the config-location ignore item, use `edit` to add the ignore rule for the configuration location file **only when the user chose it**. Check for an equivalent existing rule first, and append only the missing line: never duplicate an ignore rule or rewrite the file. When the user chose to narrow an existing parent-directory rule instead, replace that one line with the file rule — do not touch any other line.

### 7. Check

`check` by re-`read`ing the location. Verify, per written item:

- the block appears exactly once with intact start/end markers;
- the output root is an absolute path, is an existing directory or a creatable path (an existing file or non-creatable path is invalid), and is not the workspace root itself (records need their own directory, so an in-repo value such as `<repository root>/.agent-output` is valid but the repository root is not); the `Records` line holds one of the four dispositions, is compatible with the path's location, and its side effects are in place — `ignored-in-workspace` → `git check-ignore` names the output-root path; `standalone-repo` → `git -C "<output root>" rev-parse --show-toplevel` resolves to the output root itself; `committed-in-workspace` → `git check-ignore` does not match the path;
- `Backend:` is one of `native | cli | sequential | manual`; `CLI template` is present when the backend is `cli`; `Max parallel` is an integer ≥ 1;
- each toolchain entry has a non-empty tool name and value, no tool name appears twice, every pinned version or absolute path resolves on this machine against the enumerated inventory (not only the `PATH` default) to exactly one installed, runnable build — a bare version matching two builds or a directory holding no build fails — and every detected language's companion build tool (`Maven` or `Gradle` for Java/JVM) is either pinned or explicitly declined by the user.

For the config-location ignore item, `check` by re-reading the ignore file and confirming a rule excludes the configuration location **file** (cite the matching rule line, or a `git check-ignore` result naming the file). Do not accept a directory rule as evidence. When the workspace is not under version control, cite that instead, naming the highest ancestor you checked for `.git`.

Do not claim an item is configured without this evidence.

### 8. Report

Output the configuration report below. Mark any item you could not resolve as `unresolved` and state what blocks it and what the user must do.

A `valid` output root whose value uses the sibling `<parent>/<project name>__agent` form stays `already-valid`; do not re-ask it automatically, but note in the report that `<repository root>/.agent-output` is the recommended form and can be migrated with the Modify capability (`U4`).

## Capability: Modify

A Modify run changes values that are already valid. It is a separate flow from Initialize: every value it touches already exists, and some of those values have side effects — a pinned version that other runs build with, a directory that already holds records.

Trigger a Modify run only when the user asks for it: "update the configuration", "correct the pinned JDK", "move the output root", "change how the records are versioned", "change the dispatch backend", "re-run the choices". Staleness detection is still your job — when a pinned version no longer matches the project or no longer resolves, say so in the report — but a stale value is corrected only after the user asks.

### U1. Read the current state first

Resolve the location and read every block (Initialize step 1). Build one row per block-backed item with its current value and show that table before asking anything. A Modify run never starts from memory.

### U2. Ask what to update

Use `ask` (multi-select) listing the items that can be updated, each labelled with its current value: `Output root` (current path), `Records disposition` (current value), `Toolchain` (current entries, or "absent"), `Dispatch` (current backend, or "absent"), and the config-location ignore item when it is not `valid`. Never change an item the user did not select; report the unselected items as unchanged. An item that is currently `missing` (an absent `Dispatch`, for example) is answered with the Initialize step-4 shape for that item — set it, skip it, or accept the runtime default — not with the change-a-valid-value shape.

### U3. Toolchain correction

Re-run language detection and compare each existing entry with what the project now needs and with what this machine now has. Classify and report every entry before asking:

| Entry state | Meaning | Offered choice |
|---|---|---|
| `current` | resolves and matches the repository-declared version, or the only installed build of that major when the repository declares none | keep (descoped unless the user selected it) |
| `stale` | resolves, but the repository now declares another version, or another installed build is the one the project asks for | the declared version (recommended), then keep as is |
| `unresolvable` | the pin no longer resolves to exactly one installed, runnable build: the build is gone, its directory holds no build, or a bare version matches several builds | correct it, or remove the entry; never leave it in place |
| `orphan` | its language no longer appears in the marker files | remove (recommended), or keep deliberately |
| `new-language` | a detected language has no entry | the declared or installed version, or skip |
| `missing-companion` | a detected language has its primary pin but not the build tool that drives it (Java detected, no `Maven`/`Gradle` entry) | pin the companion tool, or decline it |

Editing keeps the block open-ended (Initialize step 6): change only the entry lines the user decided on, and preserve every other entry and the markers. Write an absolute path instead of a bare version whenever the version would not identify exactly one installed build. If the corrected entry still fails the Initialize step-7 check, the run ends `unresolved` (U8) instead of writing a value that cannot resolve.

### U4. Output-root migration

Changing the output root changes where existing records live, so the value and the records move together. Run the Records migration sub-flow from its step 3 (choose the target): it covers the candidate search, the inventory, the move/copy/leave choice, the execution, the count-and-checksum verification, the write, and the report. A Modify run that writes the new value while leaving records under the old root without an explicit user choice ends `unresolved`, never `configured`.

### U5. Dispatch re-selection

Show the current values first, then ask field by field, offering "keep" as the per-field default: `Backend`, `CLI template` (meaningful only for `cli`), `Max parallel`, `Subagent model`. Moving `Backend` away from `cli` removes the `CLI template` line, and so does a `CLI template` the user clears. Preserve the block's other lines and its markers.

### U6. Re-verify the ignore item

Re-check the config-location ignore item instead of assuming the earlier answer still holds: a fresh clone, a `.gitignore` edit, or a `git add -f` can each change it. Reuse the Initialize step-7 evidence rule.

### U7. Records disposition change

The disposition governs side effects, so show the current state before asking: the configured value, and for `ignored-in-workspace` whether the ignore rule actually covers the output-root path (`git check-ignore`), for `standalone-repo` whether the root is a git repository (`git -C "<root>" rev-parse --show-toplevel`). Then ask the new disposition with the option set for the root's location (see Records disposition), with "keep the current disposition" as the default option. Apply only what the choice implies:

- to `ignored-in-workspace` → add the ignore rule for exactly the output-root path;
- to `standalone-repo` → `git init "<output root>"` when it is not already a repository;
- away from `ignored-in-workspace` → offer removing the ignore rule as a separate explicit option, never remove it silently;
- away from `standalone-repo` → leave the repository in place and say so; never deinitialize or delete it.

The output-root value itself and the records under it do not move in this flow — a path change is `U4`.

### U8. Check and report

Run the Initialize step-7 checks against every touched item, then the Output Contract report. `State before` is `valid` for a value that existed and changed; `Status` is `configured` when it changed and `already-valid` when the user chose to keep it. A Modify run that leaves an `unresolvable` entry or a failed migration ends `unresolved`, never `configured`.

## Capability: Validate

A read-only audit: answer "is this workspace's configuration healthy right now?" without changing anything.

- Trigger: the user asks to check, audit, verify, or validate this plugin's configuration, or a delegated pre-flight requests it.
- Read-only, always: never write, edit, create, or delete a file or directory — not even a missing output root. Never use `ask` to change a value; report the finding and name the capability (Initialize or Modify) that resolves it.

1. **Resolve context** exactly as Initialize step 1, including the legacy-location check.
2. **Classify** every registry item with the Initialize step-2 states.
3. **Verify values against reality** with the Initialize step-7 checks, read-only: block shape and markers; the output root is absolute, is not the workspace root, and exists or is creatable (a missing directory is a finding to report, not something to create); the `Records` disposition is present, valid, location-compatible, and its side effects hold — `ignored-in-workspace` → the ignore rule covers the output-root path, `standalone-repo` → the root is a git repository, `committed-in-workspace` → the path is not ignored — and a mismatch is `drift-detected`, with the report naming the Modify flow (`U7`) that resolves it; dispatch fields; every toolchain pin still resolves against the enumerated machine inventory to exactly one installed, runnable build; the ignore rule still covers the configuration location file (`git check-ignore` evidence).
4. **Records-drift check** — the audit's core. List the configured output root and every previous-root candidate (values harvested from legacy locations or blocks, malformed duplicates, and the sibling `<parent>/<project name>__agent` path), stating for each whether it exists and what it holds. Report `drift-detected` when the configured root is missing or empty while a candidate holds record directories (`plans/`, `complete/`, `subTasks/`, `reqable/`, `docs/`): a past run changed the value without migrating the records, and a Modify run (`U4`) resolves it.
5. **Staleness**: a pinned version that no longer resolves or no longer matches the repository is reported as `unresolvable` or `stale` (the Modify `U3` vocabulary) with a recommendation; it is never corrected here.
6. **Report** with the Output Contract. `State before` is the classified state; `Action taken` is `audited` with what was checked; `Value written` is always `none (read-only)`; per-item `Status` is `valid`, `missing`, `malformed`, `legacy-only`, `stale`, or `drift-detected`. A Validate run never reports `configured` and never claims the workspace is configured.

## Output Contract

Always end with this report, one row per registry item:

| Registry item | State before | Action taken | Value written | Validation evidence | Status |
|---|---|---|---|---|---|

- `Status` is `configured`, `already-valid`, `skipped-by-user`, or `unresolved`; a Validate run uses `valid`, `missing`, `malformed`, `legacy-only`, `stale`, or `drift-detected` instead.
- `Validation evidence` cites the fresh re-`read` result, not an assertion.
- When a run wrote or audited an output-root value, `Action taken` states the records migration outcome (`moved N files from <old root>`, `copied N files from <old root>`, `left in place by user choice`, or `no previous records`) and the configured `Records` disposition (`ignored-in-workspace`, `committed-in-workspace`, `standalone-repo`, or `unmanaged`).
- A run that wrote a new output-root value while records remained under a previous root without an explicit user choice reports `unresolved` and says exactly which files stayed where.
- If any item is `unresolved`, do not claim the workspace is configured.
- A delegated run returns control with this report; the invoking skill then consumes the reported values or states.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Silently picking a default output root. | Use `ask`; present the default only as the recommended option. |
| Defaulting the output root to a sibling of the repository (`<parent>/<project name>__agent`). | Recommend `<repository root>/.agent-output`; a sibling directory is invisible to single-folder workspaces. |
| Creating the new output-root directory and reporting `configured` while the old root still holds the records. | Creating the destination is step zero of the Records migration sub-flow, not the migration; run the full sub-flow and verify counts and checksums before writing the value. |
| Migrating the configuration file to a new location without asking where the old output root's records live. | Harvest every previous output-root value during classification and run the Records migration sub-flow for each non-empty candidate. |
| Treating one `ask` answer as covering both the new output-root value and the records. | They are two decisions — the value (which root) and what happens to the records (move, copy, or leave); ask both. The `Records` disposition (how the records are versioned) is a third question, asked right after the value. |
| Inferring the records' Git handling from the output root's location. | The `Records` field is a configured choice, never inferred; ask it with the option set for the root's location, recommending `ignored-in-workspace` inside a version-controlled workspace. |
| Writing or removing an output-root ignore rule without the matching disposition choice. | An output-root ignore rule changes only as the side effect of a chosen `Records` disposition — added for `ignored-in-workspace`, removed only as an explicit separate option when switching away. |
| Treating an old-shape `agent-output-root` block (no `Records` line) as valid. | Classify it `malformed` (missing required field); repair by asking only the disposition and appending that one line. |
| Creating a missing directory "to be helpful" during an audit. | Validate is read-only; report the missing directory as a finding. |
| Reading a legacy configuration location as if it were the live configuration. | Harvest candidate values only; resolve through `ask`; leave the legacy file untouched unless the user chooses otherwise. |
| Presenting every popular toolchain before detecting the project's languages. | Detect marker files first, then ask only about the tools the project's languages need. |
| Pinning a version for a language the project does not use, or skipping a declared version silently. | Ask per detected language; offer the repository-declared version first and state when it is not installed. |
| Asking in English, or translating a path/version into Chinese. | Write the question and option labels/descriptions in Chinese; leave every value that gets written untouched. |
| Quietly deleting one of two duplicate blocks. | Present the conflict via `ask`; the user decides. |
| Treating a legacy `artifact-root` block as usable configuration. | Mark it `legacy-only`; never migrate or reuse it. |
| Assuming the configuration location is git-ignored in a fresh workspace. | Verify the ignore rule and add it with the user's consent. |
| Duplicating an existing ignore rule, or rewriting the ignore file. | Append only the missing line; preserve everything else. |
| Ignoring a directory instead of the configuration file (for example a leftover `.agents/` rule). | Ignore the configuration location file itself; a directory rule does not cover the file and hides sibling content meant to be shared. |
| Treating a parent-directory ignore rule as satisfying the config-location ignore item. | Classify the file as `missing`; the rule must name the file. |
| Reporting "configured" without re-reading. | `check` by re-reading; cite the evidence. |
| Editing text outside the managed blocks. | Change only the block content the user chose. |
| Auto-running `git init` on an output root. | `git init` happens only as the side effect of a `standalone-repo` disposition the user chose; never improvise it. |
| Skipping the optional dispatch item. | Report it; let the user set or skip it. |
| Pinning a toolchain version this machine does not have. | Probe first and reject an uninstalled version or a non-existent path; classify the entry `malformed`. |
| Treating `java -version` / `node -v` as the list of installed versions. | Those report the `PATH` default only; enumerate install roots and version managers, then report the whole inventory. |
| Pinning toolchain tools the user did not choose. | Ask which tools to pin first, then one question per chosen tool. |
| Rewriting the open-ended toolchain block. | Edit only the entry lines for the chosen tools; preserve every other entry and the markers. |
