# coding-workflow 轻量技能方案结论文档

## 1. 方案结论

创建一个轻量个人编码工作流技能，暂名：

```text
coding-workflow
```

它不是完整迁移 `D:\AI\superpowers\skills`，而是蒸馏其中适合长期使用的编码流程原则。

核心目标：

> 所有非平凡编码任务，必须先形成方案结论并自审，经用户人工确认后，保存方案、提交 git，再选择实现模式并开始修改。

技能核心只保留 3 条：

1. **方案先行，明确根因 / 动机 / 现状限制后实施**
2. **按风险小步闭环**
3. **完成前必须有证据**

子 Agent 不作为强制原则，而作为方案确认后的实现模式之一。

## 2. 问题 / 需求

当前问题：

- `superpowers` 的编码技能体系很完整，但过重。
- 如果完整迁移，会带来：
  - 技能数量多；
  - 流程繁琐；
  - TDD / code review / branch finishing / subagent 流程过于仪式化；
  - 不适合用户想要的轻量个人工作习惯。
- 真正需要的是：
  - 非平凡任务先讨论方案；
  - 方案要形成结论文档；
  - 方案先自审，再由用户人工审核；
  - 确认后保存方案并提交 git；
  - 再选择实现模式；
  - 实现过程不要过度测试，但也不能无证据完成。

## 3. 根因 / 动机 / 现状限制

### 根因

之前的迁移方向偏向“完整迁移 superpowers 技能体系”，导致流程过重，不符合用户预期。

### 动机

用户想要的是一个能约束 Claude 编码行为的轻量技能：

- 避免 Claude 直接动手；
- 避免需求、根因、目标不清时盲改；
- 避免过度流程化；
- 避免每几行代码都测试造成时间浪费；
- 避免完成时只有口头判断，没有验证证据。

### 现状限制

- 个人技能应尽量短、清晰、可触发。
- 不应该一次拆成很多编码技能。
- 不应该把 `superpowers` 的重流程原样照搬。
- 所有非平凡任务都必须走方案流程。
- 新功能类任务不能强行只写“根因”，应写更通用的 **根因 / 动机 / 现状限制**。

## 4. 目标

创建一个轻量 `coding-workflow` 技能，用于所有非平凡编码任务。

它应该让未来 Claude 明确遵守：

1. 非平凡任务不能直接改代码；
2. 先明确问题、根因 / 动机 / 现状限制、目标、边界、验证方式；
3. 形成方案结论文档；
4. Claude 先自审；
5. 用户人工审核确认；
6. 确认后保存方案并提交 git；
7. 再选择实现模式；
8. 实现时按风险小步闭环；
9. 完成前必须报告验证证据。

## 5. 不做什么

本次不做：

- 不完整迁移 `superpowers` 技能；
- 不创建多个编码技能；
- 不强制完整 TDD；
- 不强制每个任务都用子 Agent；
- 不强制每个小改动都跑测试；
- 不迁移完整 code review 流程；
- 不迁移完整 branch finishing 流程；
- 不做复杂 eval / 压力测试体系；
- 不把技能写成很长的规则手册。

## 6. 技能触发条件

建议 frontmatter：

```yaml
---
name: coding-workflow
description: Use when implementing features, fixing bugs, refactoring, resolving test/build/type failures, changing multiple files, or doing any non-trivial coding task that needs a plan, root cause or motivation clarity, validation evidence, and an implementation mode decision before editing.
---
```

触发场景：

- 实现功能；
- 修 bug；
- 重构；
- 修测试失败；
- 修构建失败；
- 修类型错误；
- 修改多个文件；
- 有多种实现方式；
- 创建或修改技能；
- 蒸馏外部方法到个人工作流；
- 用户提出“继续任务”“下一步实现”“按方案做”等非平凡开发请求。

不触发场景：

- 只解释概念；
- 只回答问题；
- 只做极小机械改动；
- 用户明确要求“不需要方案，直接改”；
- 已有确认方案且正在执行同一方案。

## 7. 技能主体建议

### 7.1 核心原则一：方案先行，明确根因 / 动机 / 现状限制后实施

所有非平凡任务，在改代码或写技能前，必须先形成方案结论。

方案结论必须写清：

```markdown
## 方案结论

- 问题 / 需求：
- 根因 / 动机 / 现状限制：
- 目标：
- 不做：
- 实现方案：
- 验证方式：
- 风险 / 待确认：
```

判断方式：

- bug / 失败类任务：重点写根因；
- 新功能 / 改进类任务：重点写动机和现状限制；
- 流程 / 技能类任务：重点写当前摩擦和要蒸馏的原则；
- 如果不明确，必须先调查或反问。

禁止行为：

- 需求不清就写代码；
- 根因未明就修 bug；
- 新功能动机不清就设计实现；
- 方案未确认就保存或提交；
- 把猜测包装成确定结论。

### 7.2 核心原则二：方案先自审，再交给用户审核

方案结论形成后，Claude 必须先自审。

自审内容：

```markdown
## 自审

- 根因 / 动机 / 现状限制是否明确：
- 方案是否过度设计：
- 是否遗漏用户要求：
- 是否存在多个需要用户选择的实现路径：
- 验证方式是否足够：
- 是否还有必须反问的问题：
```

自审后再交给用户确认。

如果自审发现问题：

- 能继续调查的，先调查；
- 需要用户判断的，明确反问；
- 不能直接进入实现。

### 7.3 核心原则三：确认后保存、提交、选择实现模式

所有非平凡任务都必须：

1. 先在聊天中确认方案；
2. 用户确认后保存方案文档；
3. 提交到 git；
4. 再选择实现模式。

建议方案保存路径：

```text
docs/plans/YYYY-MM-DD-coding-workflow.md
```

本次保存为：

```text
docs/plans/2026-06-29-coding-workflow-skill.md
```

提交信息建议：

```text
docs: add coding workflow skill plan
```

实现模式：

| 模式 | 使用场景 | 说明 |
|---|---|---|
| 主 Agent 直接实现 | 小型、低风险、文件少 | 主 Agent 修改并验证 |
| 单子 Agent 实现 | 中等复杂、多文件、需要保持主会话清晰 | 子 Agent 开发，主 Agent 审查 |
| 多子 Agent 并行 | 多个独立子任务 | 每个子 Agent 处理一个独立任务 |

默认策略：

- 简单任务：主 Agent；
- 复杂任务：单子 Agent；
- 多个独立任务：多子 Agent。

### 7.4 核心原则四：按风险小步闭环

“小步”不是每几行代码就测试。

正式定义：

> 每一步改动应当小到能清楚判断责任边界，大到值得跑一次验证。

分类：

| 类型 | 例子 | 验证节奏 |
|---|---|---|
| 机械改动 | 重命名、移动文件、格式、文案 | 可累计验证 |
| 行为改动 | 逻辑、数据流、错误处理、接口行为 | 完成一个可观察行为后跑窄验证 |
| 集成改动 | 多个行为组合、准备提交、切换任务、声明完成 | 跑宽验证 |

规则：

- 不为每几行代码跑全量测试；
- 行为改动完成一个可观察单位后验证；
- 验证成本高时，先跑最窄有效验证；
- 完成、提交、切换任务前必须跑足够支撑声明的验证；
- 最后用宽验证兜底。

### 7.5 核心原则五：完成前必须有证据

完成报告必须包含：

```markdown
## 验证

- 已运行：
- 结果：
- 未运行：
- 原因：
```

允许表达：

- “已通过相关窄验证，未跑全量验证。”
- “未验证，不能确认完成。”
- “验证失败，当前未完成。”

禁止表达：

- “应该好了”；
- “看起来没问题”；
- “理论上可以”；
- “我认为完成了”；
- 未运行验证却声称完成。

## 8. 建议创建文件

如果方案确认，下一阶段保存方案后，再实现技能文件：

```text
skills/coding-workflow/SKILL.md
```

暂不需要 supporting files。

技能应保持短小，建议不超过 200-300 行，最好更短。

## 9. 预期最终 SKILL.md 结构

```markdown
---
name: coding-workflow
description: Use when implementing features, fixing bugs, refactoring, resolving test/build/type failures, changing multiple files, or doing any non-trivial coding task that needs a plan, root cause or motivation clarity, validation evidence, and an implementation mode decision before editing.
---

# Coding Workflow

## Overview

## When to Use

## Core Workflow

### 1. Plan First

### 2. Self-Review Before Human Review

### 3. Save and Commit Approved Plans

### 4. Risk-Sized Implementation Loops

### 5. Evidence Before Completion Claims

## Implementation Modes

## Templates

## Common Mistakes
```

## 10. 自审

### 根因 / 动机 / 现状限制是否明确

明确。

核心根因是：完整迁移 `superpowers` 过重，不符合用户想要的轻量个人工作流。

### 方案是否过度设计

方案文档可以较完整，但最终 `SKILL.md` 应压缩，只保留规则、模板和常见错误。

### 是否遗漏用户要求

已覆盖：

- 不完整迁移；
- 只蒸馏；
- 流程不能繁重；
- 所有非平凡任务都必须；
- 方案结论文档；
- 先自审；
- 再人工审核；
- 确认后保存；
- 提交 git；
- 再选实现模式；
- 根因改为“根因 / 动机 / 现状限制”；
- 小步闭环按风险定义；
- 子 Agent 不是强制核心原则，只是实现模式。

### 是否存在多个需要用户选择的实现路径

后续实现阶段可选择：

- 主 Agent 直接实现；
- 单子 Agent 实现；
- 多子 Agent 并行。

### 验证方式是否足够

本次是技能创建方案，验证方式建议轻量化：

1. 检查 `SKILL.md` frontmatter 是否有效；
2. 检查技能描述是否 trigger-only；
3. 人工审查技能是否短小；
4. 用 2-3 个模拟请求检查是否会要求先出方案，而不是直接改。

不建议为这个轻量技能做完整压力测试矩阵，否则又会变重。

### 是否还有必须反问的问题

无。用户已确认通过并要求保存文件。
