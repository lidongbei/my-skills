---
name: session-handoff-load
description: Use only when the user explicitly invokes /my-skills:session-handoff-load, invokes /session-handoff-load, or explicitly instructs the agent to use session-handoff-load.
disable-model-invocation: true
---

# Session Handoff Load

Load a temporary session handoff from the project-local index so a new session can continue deliberately.

## Hard Boundaries

- Trigger only when the user explicitly invokes `/my-skills:session-handoff-load`, invokes `/session-handoff-load`, or explicitly instructs the agent to use `session-handoff-load`.
- Do not auto-trigger from natural phrases such as “继续上次”, “恢复上下文”, “加载交接”, or “从上次继续”. If the user has not invoked this skill, continue normally or suggest the slash command.
- Do not guess the latest handoff file. The user must choose from the index unless there is exactly one indexed entry and the user explicitly asked to load it.
- Do not treat a handoff as guaranteed current. Old paths, branches, plans, and validation results may be stale.
- Do not expose or expand redacted sensitive information.

## Required Source

Use the project-local handoff index:

```text
docs/handoffs/HANDOFFS.md
```

Handoff files should be linked from the index and usually follow:

```text
docs/handoffs/yyyy-MM-dd-<name>.md
```

If the index is missing or empty, report that no indexed handoff is available and ask the user to provide a file path or run `/session-handoff-save` in the source session.

## Workflow

1. Use `read` to inspect `docs/handoffs/HANDOFFS.md`.
2. Extract indexed handoff entries: title, path, status, keywords, and date when available.
3. Group entries into active candidates and archived candidates before asking the user to choose.
4. Use `ask` to let the user choose among active candidates when multiple active candidates exist; include the archive entry point only as described below.
5. Use a second-level `ask` only when the user chooses the archive entry point, explicitly asks for archived/superseded handoffs, or there are no active candidates.
6. Use `read` to load the selected handoff file.
7. Check that the required handoff sections are present.
8. Output a recovery summary before continuing work.

## Candidate Grouping

Before asking the user to choose, group indexed entries into active candidates and archived candidates.

Archived candidates include entries whose index line, heading, status, or handoff body indicates:

- 已归档
- 已被取代
- superseded
- archived
- replaced
- obsolete

When active candidates exist, the first-level `ask` must show active candidates plus at most one archive entry point, such as `查看已归档 / 已取代交接`.

Do not list every archived/superseded handoff beside active handoffs in the first-level choice.

If the user selects the archive entry point, use a second-level `ask` to choose among archived candidates.

If an archived candidate names a replacement file, mark it clearly and prefer loading the replacement unless the user explicitly chooses the archived file for traceability.

## Ask Requirement

When more than one active handoff is indexed, use `ask` with concise first-level options. Each active handoff option should include:

- title;
- date;
- status;
- keywords or task topic;
- linked file path.

If archived candidates also exist, include one additional first-level option only: `查看已归档 / 已取代交接`. Do not show individual archived candidates in the first-level options.

When the user selects the archive entry point, use a second-level `ask` with archived candidates. Each archived option should include:

- title;
- date;
- archived/superseded status;
- linked file path;
- replacement file or “取代者：未知，需复核” when relevant.

If the index has one active entry, you may ask for confirmation in plain chat unless the user explicitly said to load that exact entry. Do not add an archive entry point in this case unless the user explicitly asked to inspect archived handoffs.

If no active candidates exist but archived candidates do exist, state that no active handoff is available, then use `ask` to choose among archived candidates or ask whether to stop.

Do not silently choose the newest file.

## Required Recovery Summary

After loading, report these fields in Chinese:

```markdown
## 已加载交接

- 文件：`docs/handoffs/yyyy-MM-dd-<name>.md`
- 状态：<handoff status>

## 恢复的目标

<交接目标>

## 已确认决策

- <decisions from handoff>

## 当前未完成事项

- <unfinished actions>

## 阻塞点 / 待确认

- <blockers or “无”>

## 最近两轮对话摘录

- 第 1 轮：<user input summary + visible output summary>
- 第 2 轮：<user input summary + visible output summary>

## 需要复核 / 验证

- <commands, files, branch status, stale assumptions, or “尚未验证”>

## 建议下一步

1. <first action>
2. <second action>
3. <third action>
```

Rules:

- Do not just say “已加载上下文”.
- If required sections are missing, list missing sections and ask whether to proceed with partial context or inspect another handoff.
- Treat “最近两轮对话摘录” as important continuity evidence, especially when user intent or last confirmation is ambiguous.
- Preserve the distinction between loaded facts and facts re-verified in the current session.

## Cleanup Awareness

Handoffs are short-term continuation records.

- Active/current entries belong in the first-level choice list; archived, superseded, completed, or replaced entries belong behind the archive entry point.
- Do not mix archived/superseded entries directly beside active entries in the first-level `ask`.
- If the selected archived handoff says it was superseded, offer to load the newer linked handoff instead unless the user explicitly wants the archived file for traceability.
- If the loaded work is now complete, ask whether to mark the index entry completed or superseded; do not delete without explicit confirmation.
- If several old same-task handoffs exist, suggest a cleanup plan after the current recovery summary, not before loading the selected context.

## Missing or Broken Index

If `docs/handoffs/HANDOFFS.md` is absent, empty, or contains broken links:

1. State the concrete problem.
2. Do not invent entries.
3. Offer the user choices:
   - provide a handoff file path;
   - let the agent inspect `docs/handoffs/*.md` and then ask before loading;
   - stop and create a new handoff with `/session-handoff-save` from the source session if available.

## Quality Bar

Successful loading means:

- The selected file came from the index or an explicit user path.
- The user chose among multiple active indexed options with `ask`.
- Archived/superseded entries were not mixed directly with active entries in the first-level choice; they were offered through a single archive entry point and second-level choice when needed.
- The recovery summary includes goals, decisions, unfinished work, blockers, recent two-turn excerpt, validation needs, and recommended next steps.
- Stale or unverified claims are marked for re-check rather than silently trusted.

## Output to User

Keep the final output actionable. After the recovery summary, either ask for the next decision if blocked or proceed with the first safe next step if the user requested continuation and no blocker remains.
