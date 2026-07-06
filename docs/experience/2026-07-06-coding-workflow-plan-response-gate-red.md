# coding-workflow 计划响应门 RED 记录

日期：2026-07-06

## 背景

用户要求修改 `coding-workflow`：在输出 `Plan Conclusion` 和 `Self-Review` 后，必须进入选项门，并且根据选项再次审查计划。

选项顺序：

1. 按推荐确认方案
2. 逐个确认问题
3. 改动方案，输入改动内容

## RED 场景

用户显式调用 `/coding-workflow` 执行非平凡任务。Agent 输出计划与 Self-Review 后，用户回复：

```text
确认
```

## 当前技能缺口

当前 `skills/coding-workflow/SKILL.md` 在计划与 Self-Review 后直接写：

```text
After the user approves the plan direction, scan the plan for open questions that affect implementation choices.
```

这没有规定：

- 必须展示三选一响应门；
- 普通“确认”是否足以跳过响应门；
- “按推荐确认方案”后还要再次审查计划；
- “逐个确认问题”后要用答案更新并复审计划；
- “改动方案”后要重写计划并回到响应门。

## 失败判定

如果 agent 在输出计划和 Self-Review 后，没有要求用户选择：

1. 按推荐确认方案
2. 逐个确认问题
3. 改动方案，输入改动内容

而是把普通“确认 / ok / 继续”直接当成计划批准并进入保存、提交、执行模式选择或实现，则判定失败。

## 预期 GREEN 行为

修改后，agent 必须：

1. 输出计划和 Self-Review；
2. 暂停并展示三选一响应门；
3. 用户选择 1 时，按“推荐已被接受”的前提再次审查计划，确认推荐是否安全覆盖所有决策；无法安全覆盖的人类决策仍逐个问；
4. 用户选择 2 时，逐个确认问题，每次只问一个；全部解决后更新计划并复审；
5. 用户选择 3 时，要求用户输入改动内容，重写计划和 Self-Review，再回到响应门。
