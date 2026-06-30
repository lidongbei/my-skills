---
name: team-memory
description: Use only when the user explicitly invokes /my-skills:team-memory, invokes /team-memory, or explicitly instructs the agent to use team-memory.
disable-model-invocation: true
---

# Team Memory

Curate important memory into the right durable location without bloating always-loaded context.

## Hard Boundaries

- Trigger only when the user explicitly invokes `/my-skills:team-memory`, invokes `/team-memory`, or explicitly instructs the agent to use `team-memory`.
- Do not auto-trigger from memory-like phrases such as “项目级复用”, “沉淀到仓库 memory”, “同步到 docs/memory”, “记住这个使用习惯”, “多个项目复用”, or “统一到 HABIT.md”.
- Do not use this skill for temporary reminders, current-session todos, ordinary documentation edits, or implementation plans.

This skill has two tracks:

```text
Project/team knowledge
  -> docs/memory/MEMORY.md
  -> docs/memory/<year>/<month>/<date-seq>-<name>.md

Human cross-project habits
  -> ~/.claude/HABIT.md

CLAUDE.md
  -> optional lightweight pointers only
```

The core principle is progressive disclosure: keep always-loaded files small, keep indexes short, and put full details in targeted documents.

## Track Selection

Before writing, classify the memory.

### Track A: Project Knowledge

Use `docs/memory` when the memory is about the current repository:

- Architecture decisions.
- Performance or capacity analysis.
- Debugging lessons tied to project files.
- Non-obvious project entry points.
- Operational workflows for this repo.
- Team-shared project constraints or conventions.
- Historical analysis that future maintainers should find from git.

Output locations:

```text
docs/memory/MEMORY.md
docs/memory/<year>/<month>/<date-seq>-<name>.md
```

### Track B: Human Habits

Use `~/.claude/HABIT.md` when the memory is the user’s reusable working habit across multiple projects:

- Personal preferences for how Claude should work.
- Cross-project workflow rules.
- Naming, documentation, verification, or communication habits not tied to one repo.
- Reusable “how I like things done” instructions.
- Conventions the user wants to migrate between projects.

Examples:

- “我习惯所有长期可复用规约放 HABIT.md。”
- “以后分析类结果先出方案再问是否实施。”
- “跨项目都不要把全文塞进 CLAUDE.md，只放入口。”

Output location:

```text
~/.claude/HABIT.md
```

If `~/.claude/CLAUDE.md` does not already reference `HABIT.md`, suggest or add a lightweight pointer only when the user explicitly wants the habit to be automatically visible in future sessions.

Recommended pointer:

```markdown
[HABIT.md](HABIT.md)
```

Do not put all habits directly into `CLAUDE.md`.

### Mixed Content

If a request contains both project knowledge and human habit:

1. Split it into two entries.
2. Put project facts into `docs/memory`.
3. Put cross-project habit into `~/.claude/HABIT.md`.
4. Cross-reference lightly when useful.

If the classification is unclear, ask one focused question:

> 这是只对当前仓库有效的项目知识，还是你希望多个项目都复用的个人习惯？

## Invocation Scope

After explicit invocation, use this skill when the user asks to:

- Promote local Claude memory into team/shared project documentation.
- Persist an important project analysis, decision, workflow, pitfall, or convention.
- Create or update `docs/memory/MEMORY.md`.
- Add a lightweight project `CLAUDE.md` pointer to the repository memory index.
- Save a reusable personal habit or cross-project rule to `HABIT.md`.
- Avoid context bloat while preserving future discoverability.

Do not use this skill for:

- Temporary reminders or current-session todos.
- Ordinary README or developer guide edits without a memory/knowledge-cache intent.
- Full transcript/log dumping.
- Secrets, credentials, private tokens, or sensitive personal data.
- Anthropic API / Managed Agents memory-store implementation tasks.
- Implementation plans that belong under the project’s normal planning docs.

## Workflow

### 1. Identify the Source

Determine what should be curated:

- Existing local memory file.
- Current conversation content.
- A user-provided summary.
- A repository document that should be indexed for future recall.
- A cross-project personal habit the user wants to reuse.

If the source is ambiguous, ask one focused question before writing.

### 2. Classify the Memory

Choose exactly one primary track unless the content is clearly mixed.

Use `docs/memory` if the memory would be wrong or meaningless outside this repository.

Use `~/.claude/HABIT.md` if the memory should travel with the user across projects.

When in doubt, prefer not to write until the distinction is clear. The user has explicitly stated that human usage habits are portable rules and should be unified in `HABIT.md`.

### 3. Filter for Long-Term Value

Keep information that helps future maintainers, future Claude sessions, or the user’s cross-project workflow.

Keep:

- Stable project decisions.
- Architecture or performance analysis.
- Operational workflows.
- Debugging lessons and root causes.
- Non-obvious file entry points.
- Project-specific caveats and constraints.
- User habits that are genuinely cross-project.

Remove or avoid:

- Chatty process details.
- One-off context.
- Unverified guesses presented as facts.
- Redundant content already obvious from code.
- Secrets, credentials, local-only private details unless explicitly relevant.

If something may become stale, include a “失效条件” section.

## Track A Workflow: Project Knowledge

### A1. Choose the Repository Memory Path

Use this path pattern:

```text
docs/memory/<year>/<month>/<date-seq>-<name>.md
```

Examples:

```text
docs/memory/2026/06/26-01-checkjob-ten-million-analysis.md
docs/memory/2026/06/26-02-build-verification-policy.md
```

Rules:

- Use current local date unless the user specifies another date.
- Use two-digit month.
- Use two-digit sequence for files created on the same date.
- Use kebab-case for `<name>`.
- Pick a topic name, not a source name.

Before creating a new file, check existing `docs/memory/**` entries to avoid duplicates. If a matching topic already exists, update it instead of creating a duplicate.

### A2. Write the Project Memory Entry

Use this structure unless the project already has a different memory format:

```markdown
# <Title>

## 摘要

<1-3 sentences explaining the reusable project knowledge.>

## 适用场景

- <when future agents/maintainers should read this>
- <keywords or task types>

## 内容

<curated details, concise but sufficient.>

## 推荐入口

- `<file-or-doc-path>` — <why it matters>

## 使用方式

<how future sessions should apply this memory without blindly trusting stale facts.>

## 失效条件

<when to re-check or retire this memory.>

## 来源

- 日期：YYYY-MM-DD
- 来源：<local memory/current conversation/user-provided/project analysis>
```

Guidelines:

- Write for a future reader who did not see the conversation.
- Prefer links to full documents over duplicating large content.
- Mark uncertain claims as needing verification.
- Keep the entry focused on one topic.

### A3. Update the Repository Memory Index

Ensure `docs/memory/MEMORY.md` exists.

Keep it short. It is an index, not the memory body.

Recommended format:

```markdown
# Repository Memory Index

## 性能与容量

- [checkjob 千万级数据量瓶颈与优化方案](2026/06/26-01-checkjob-ten-million-analysis.md) — 适用：checkjob/jobs、PlanShardDispatchJob、RuleExecuteJob、StateInitJob、大数据量性能优化；关键词：千万级、深分页、MOD 分片、批量写入、结果表分区。
```

Rules:

- Add a one-line entry with link, summary, and trigger keywords.
- Group by topic when useful.
- Do not paste the full memory into the index.
- If updating an existing memory file, update its existing index line instead of duplicating it.

### A4. Add a Lightweight Project `CLAUDE.md` Pointer When Needed

If this is the first repository memory entry, or project `CLAUDE.md` does not already mention the repo memory index, add only a small pointer.

Recommended text:

```markdown
## 项目知识缓存

重要历史分析、项目级记忆和团队复用知识见 `docs/memory/MEMORY.md`，仅在任务相关时按需读取。
```

Rules:

- Do not paste memory contents into `CLAUDE.md`.
- Do not paste the whole index into `CLAUDE.md`.
- If a similar pointer already exists, leave it or lightly update it.
- Preserve existing project rules and style.

## Track B Workflow: Human Habits

### B1. Locate `HABIT.md`

Use the user-level habit file:

```text
~/.claude/HABIT.md
```

On Windows this is typically:

```text
C:\Users\Administrator\.claude\HABIT.md
```

If the file does not exist, create it.

### B2. Inspect Existing Habits Before Writing

Before adding or changing a habit, read the existing `HABIT.md` and count habit entries.

Count habit entries as second-level headings under `# HABIT`:

```markdown
## <Habit Title>
```

Rules:

- `HABIT.md` must not exceed 30 habit entries.
- Do not append blindly.
- If the new habit duplicates an existing habit, update or merge the existing section instead of adding a new one.
- If the new habit overlaps with an existing habit, prefer broadening the existing section while keeping it concise.
- If the new habit conflicts with an existing habit, stop and ask the user to choose which rule should win. Do not write the conflicting habit until the user decides.
- If adding the habit would make the file exceed 30 entries, stop and propose a cleanup/merge plan instead of writing. Ask the user which habits to merge, retire, or keep.
- If the file is already near the limit, around 25+ entries, mention that habit count is getting high and recommend consolidation when appropriate.

Conflict examples:

- Existing: “Always ask before editing files.” New: “Do not ask before editing files.” → ask the user.
- Existing: “Store cross-project habits in HABIT.md.” New: “Store all habits in project CLAUDE.md.” → ask the user.
- Existing: “Run full compile only at the end for heavy Java projects.” New: “Run compile after every small edit.” → ask the user.

Duplicate/merge examples:

- Existing: “Do not put long content in CLAUDE.md.” New: “CLAUDE.md only stores lightweight pointers.” → merge into the existing section.
- Existing: “Project knowledge goes to docs/memory.” New: “Team reusable memory should be stored in docs/memory.” → update the existing section.

### B3. Write Habit Entries Concisely

Use a compact, portable format:

```markdown
# HABIT

## <Habit Title>

<The cross-project habit or personal rule.>

**Why:** <why this habit exists>

**How to apply:** <how Claude should apply it across projects>
```

For additional habits, append a new section. Prefer updating an existing matching section over creating duplicates.

Good habit entries are:

- Cross-project.
- User-specific.
- Actionable.
- Short enough to stay useful when imported.

Bad habit entries are:

- Project facts.
- One-off decisions.
- Long analysis documents.
- Logs or transcripts.
- Repo-specific paths.

### B4. Keep `CLAUDE.md` Lightweight

If the user wants habits automatically available, ensure user-level `~/.claude/CLAUDE.md` references `HABIT.md` with a lightweight pointer.

Recommended pointer:

```markdown
[HABIT.md](HABIT.md)
```

Rules:

- Do not duplicate the full habit content in `CLAUDE.md`.
- Do not add project-specific memory to `HABIT.md`.
- Do not write habits into repository `CLAUDE.md` unless the habit is intentionally team-shared and project-specific.

## Verification

Before reporting completion, check the applicable track.

For project memory:

- The memory path follows `docs/memory/<year>/<month>/<date-seq>-<name>.md`.
- `docs/memory/MEMORY.md` links to the new/updated entry.
- Project `CLAUDE.md` has at most a lightweight pointer.
- No secrets or local-only private details were added.
- The memory entry explains when to use it and when to re-check it.

For human habits:

- The existing `~/.claude/HABIT.md` was read before editing, unless it did not exist.
- The habit count remains at or below 30 entries.
- Duplicate or overlapping habits were merged instead of appended.
- Conflicting habits were not written; the user was asked to resolve the conflict first.
- If the file was already crowded or adding would exceed 30 entries, a cleanup/merge plan was proposed instead of blindly adding.
- The habit was written to `~/.claude/HABIT.md`.
- The entry is cross-project and not tied to one repository.
- Similar existing habit sections were updated instead of duplicated.
- User-level `~/.claude/CLAUDE.md` only references `HABIT.md` if needed.
- No secrets or sensitive personal details were added.

For Java/Maven or heavy projects, do not run a full compile just for documentation-only memory curation unless the user asks.

## Output to User

After completing, report:

- Which track was used: project memory, human habit, or both.
- The created or updated memory/habit document path.
- For human habits, whether the entry was added, merged, or blocked pending conflict/cleanup.
- The current habit count when `HABIT.md` was touched.
- The index path if project memory was updated.
- Whether any `CLAUDE.md` pointer was added or left unchanged.
- One sentence describing when the memory or habit should be used.

Keep the final response concise.
