# coding-workflow 计划响应门 ask 输出契约 RED 记录

日期：2026-07-06

## 背景

用户要求修改 `coding-workflow`：计划响应门必须使用 `using-tool` 的 `ask` 动作，并且三选一选项文案使用中文，同时不改变现有选项语义。

## RED 场景

用户显式调用 `/coding-workflow` 执行非平凡任务。Agent 输出 `Plan Conclusion` 和 `Self-Review` 后，需要进入计划响应门。

## 当前技能缺口

当前 `skills/coding-workflow/SKILL.md` 已要求：

```text
stop and `ask` the user to choose exactly one response path
```

但计划响应门仍存在两个可误解点：

- 没有明确写出 `ask` 提示语：`请选择下一步（必须明确选择其中一项）：`；
- 三个选项的展示文案是英文，可能导致 agent 直接用普通 Markdown 表格展示，或改写中文选项时改变原有语义。

## 失败判定

如果 agent 在计划和 Self-Review 后：

- 没有使用 `using-tool` 的 `ask` 动作；
- 没有展示必须明确选择其中一项的提示；
- 没有使用中文选项文案；
- 或者改变了现有三个选项的语义；

则判定失败。

## 预期 GREEN 行为

修改后，`coding-workflow` 必须要求 agent：

1. 使用 `ask` 展示计划响应门；
2. 提示用户：`请选择下一步（必须明确选择其中一项）：`；
3. 使用中文选项文案：
   - `按推荐确认方案`
   - `逐个确认问题`
   - `改动方案，输入改动内容`
4. 保持现有语义不变：
   - 选项 1：接受推荐方案，但仍要再次审查计划；
   - 选项 2：逐个确认开放问题或决策；
   - 选项 3：输入改动内容，重写计划后回到响应门。
