---
name: session-handoff-save
description: Use only when the user explicitly invokes /my-skills:session-handoff-save, invokes /session-handoff-save, or explicitly instructs the agent to use session-handoff-save.
disable-model-invocation: true
---

# Session Handoff Save

Create an explicit continuation handoff for a future session without turning the transcript into long-term memory.

## Hard Boundaries

- Trigger only when the user explicitly invokes `/my-skills:session-handoff-save`, invokes `/session-handoff-save`, or explicitly instructs the agent to use `session-handoff-save`.
- Do not auto-trigger from natural phrases such as “继续上次”, “保存上下文”, “暂存交接”, “新会话继续”, or “记录一下”. If the user has not invoked this skill, continue normally or suggest the slash command.
- This is temporary session handoff, not durable project memory. Do not use it to curate stable team knowledge; use `team-memory` when the user explicitly asks for durable memory.
- Do not save secrets, credentials, tokens, cookies, private keys, or sensitive personal data. Redact while preserving enough meaning to continue.
- Do not paste the full transcript. Save an executable continuation record.

## Required Location

Use the project-local handoff area:

```text
docs/handoffs/yyyy-MM-dd-<name>.md
docs/handoffs/HANDOFFS.md
```

Rules:

- If `docs/handoffs/` does not exist, create it.
- If `docs/handoffs/HANDOFFS.md` does not exist, create it.
- Use the current local date unless the user specifies another date.
- Use kebab-case for `<name>`; choose a task/topic name, not `handoff` alone.
- Before creating a file, use `find` or `read` on `docs/handoffs/HANDOFFS.md` and nearby `docs/handoffs/*.md` entries to avoid duplicate names.

## Workflow

1. Use `read`/`find` to inspect existing `docs/handoffs/HANDOFFS.md` and handoff files when present.
2. Use `ask` if the handoff name, status, scope, or whether to supersede older same-topic handoffs is unclear.
3. Choose a clear file name: `docs/handoffs/yyyy-MM-dd-<name>.md`.
4. Use `edit` to create or update the handoff file with the required template below.
5. Use `edit` to add or update one short index line in `docs/handoffs/HANDOFFS.md`.
6. Use `check` to verify the file exists, the index links to it, the required sections are present, and no obvious secret was saved.

## Conversation Excerpt Selection

`最近两轮对话摘录` must preserve meaningful continuation context, not the mechanics of invoking this skill.

When the latest user turn is only a handoff-save invocation, a retry of handoff-save, or a complaint about the save result:

- Do not make the slash command, tool transcript, or handoff-save mechanics the main conversation content.
- Prefer the most recent substantive user-assistant exchange that the future session must understand.
- Record the save invocation only in `来源记录` or as a short note when it explains why the handoff exists.
- If the user says “把这次回答做存档”, “保存上面/下面这段”, or otherwise points to a prior answer, archive the referenced visible assistant answer or a faithful continuation-ready summary of it.
- If a selected turn contains tool logs, summarize the user-visible result, decisions, and next actions; do not paste raw tool-call logs unless the logs themselves are the artifact being debugged.

Example:

- Bad excerpt focus: “用户调用 `/my-skills:session-handoff-save`，agent 写入了文件。”
- Good excerpt focus: “用户要求保留完整分配方案；assistant 输出了包含背景、规则、接口、算法、验证、风险和待确认点的完整方案，后续需从该方案继续。”

## Cleanup Strategy

Session handoffs are short-term working documents. Manage them as a rolling chain, not permanent memory.

- Do not delete handoff files automatically. Deletion is hard to reverse; use `ask` before deleting, bulk-moving, or overwriting an existing handoff.
- When saving a new handoff for the same task, prefer creating a new dated file and marking the previous same-task entry as `已被取代` in `docs/handoffs/HANDOFFS.md`.
- In the previous same-task handoff file, add a short supersession note when practical: `已被 <new-file> 取代，保留用于追溯。`
- Keep the index focused on actionable handoffs: active/current entries first, superseded/completed entries under a `已归档 / 已取代` heading.
- If the index grows noisy, propose a cleanup plan instead of silently deleting: keep latest active handoff per task, keep superseded entries only when they explain decisions, and remove obsolete temporary files only after user confirmation.
- If the work is completed, mark the handoff `已完成` in the index. If its content became durable project knowledge, ask whether to promote the stable parts with `team-memory` instead of keeping the temporary handoff as the source of truth.

## Required Handoff Template

Every handoff file must use this structure. Unknown content must be written as `未知，需复核`; do not omit the section.

```markdown
# <交接标题>

## 基本信息

- 日期：YYYY-MM-DD
- 名称：<kebab-case-name>
- 来源：当前会话
- 适用仓库：<repo name or path>
- 当前分支：<branch or 未知，需复核>
- 当前状态：进行中 / 阻塞 / 等待用户决策 / 已完成待验证

## 交接目标

<明确说明未来会话要继续完成什么任务。不能只写“继续之前的工作”。>

## 用户原始意图

- <用户真正要达成的目标、约束或偏好>

## 已确认决策

- <用户已经明确确认、纠正或拍板的内容>
- <包括路径、技能数量、调用模式、命名、范围等>

## 已完成事项

- <已经完成的动作，例如已读文件、已做诊断、已形成方案、已运行命令>

## 当前未完成事项

- <下一步必须继续做的具体动作；不要写“继续实现”>

## 关键上下文

- <新会话继续工作必须知道的信息>
- <包括重要路径、规则、前置技能、用户修正意见>

## 涉及文件

### 已读取

- `<path>` — <为什么重要>

### 计划修改

- `<path>` — <预计修改什么>

### 已修改

- `<path>` — <修改了什么；如果没有则写“无”>

## 验证要求

- <必须运行的验证命令或检查方式>
- <哪些结果尚未验证>

## 阻塞点 / 待用户确认

- <如果没有，写“无”>

## 下一步建议

1. <新会话接手后的第一步>
2. <第二步>
3. <第三步>

## 不要做

- <明确禁止新会话误做的事>

## 最近两轮对话摘录

至少保留最新两次有续接价值的用户输入及对应输出结果。如果最近轮次只是调用或重试本技能，按 `Conversation Excerpt Selection` 选择更有意义的实质交流轮次，并在来源记录中说明保存动作。如果会话不足两轮，记录已有轮次并写明“不足两轮”。如包含敏感信息，必须脱敏后保留可续接含义。

### 第 1 轮

**用户输入：**

```text
<倒数第二次用户输入原文或必要脱敏后的原文>
```

**输出结果：**

```text
<对应 assistant 的最终输出结果、方案、结论或执行结果；优先保存有续接价值的实质交流内容，不要只写“调用了 session-handoff-save”或工具执行日志>
```

### 第 2 轮

**用户输入：**

```text
<最近一次用户输入原文或必要脱敏后的原文>
```

**输出结果：**

```text
<对应 assistant 的最终输出结果、方案、结论或执行结果；如果该轮尚未完成，写“本轮正在交接保存时尚未完成”>
```

## 来源记录

- 日期：YYYY-MM-DD
- 保存者：当前 agent
- 保存原因：<为什么需要暂存交接>
```

## Index Format

Keep `docs/handoffs/HANDOFFS.md` short:

```markdown
# Session Handoff Index

- [<title>](yyyy-MM-dd-<name>.md) — 状态：<status>；适用：<task/topic keywords>；保存日期：YYYY-MM-DD。
```

Rules:

- One line per handoff.
- Update an existing line if replacing an existing handoff for the same task.
- Do not paste the handoff body into the index.
- Include enough keywords for `session-handoff-load` to present meaningful choices.

## Quality Bar

A valid handoff is an execution sheet:

- “交接目标” is concrete.
- “当前未完成事项” and “下一步建议” are actionable.
- “已确认决策” includes user corrections and approvals from the current session.
- “验证要求” names commands or inspection checks; if not run, it says `尚未验证`.
- “最近两轮对话摘录” preserves at least the latest two meaningful user-assistant exchanges needed for continuation; do not let handoff-save commands, retries, or raw tool logs replace the substantive exchange the user wanted preserved.
- Missing facts are marked `未知，需复核` instead of silently omitted.

## Output to User

After saving, report concisely:

- Handoff file path.
- Index path.
- Handoff status.
- Next recommended action for a new session.
- Any redactions, unknowns, or verification not yet performed.
