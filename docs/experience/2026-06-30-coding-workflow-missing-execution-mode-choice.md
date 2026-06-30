# coding-workflow 未让用户选择执行方式失败经验

日期：2026-06-30

## 背景

用户显式调用 `/my-skills:coding-workflow` 执行一项非平凡代码任务：围绕 `StateInitBloomJobParam` 与 StateInit Bloom 自动扩容设计进行计划、确认、实现、测试和文档更新。

`coding-workflow` 技能要求：

1. 先输出计划与 Self-Review；
2. 用户确认后保存计划到 `docs/plans/YYYY-MM-DD-<topic>.md`；
3. 提交计划；
4. 然后选择执行模式：Main agent / Single subagent / Multiple subagents；
5. 再进入风险分块实现与验证。

## 失败现象

在用户确认计划后，agent 执行了：

- 保存计划；
- 提交计划；
- 直接由主 agent 继续实现；
- 完成代码、测试调整、文档更新、Maven 验证和提交。

但 agent **没有停下来让用户选择执行方式**。

用户后续指出：

> 检查技能在实现时没有让我选择执行方式

## 期望行为

在计划提交后、开始实现前，agent 应该明确询问用户选择执行方式，至少包括：

| 执行方式 | 适用场景 |
|---|---|
| Main agent | 小规模、低风险、少文件变更 |
| Single subagent | 中等复杂度、多文件、希望保持主上下文干净 |
| Multiple subagents | 可拆分为独立并行子任务 |

如果用户已经明确指定执行方式，可以直接按指定方式执行；否则应等待用户选择。

## 实际行为

agent 将技能里的 “then choose mode” 理解为：

> agent 自己根据风险选择执行方式。

因此 agent 默认选择 Main agent 继续执行，没有询问用户。

## 根因分析

### 失败层级

Workflow ambiguity / expectation mismatch（工作流措辞歧义 / 期望不匹配）

### 具体原因

`coding-workflow` 技能中当前表达类似：

```markdown
After explicit approval: save the plan under `docs/plans/YYYY-MM-DD-<topic>.md`, commit the plan to git, then choose mode.
```

这里的 `choose mode` 没有明确主语。

agent 可能理解为：

```text
agent 选择执行模式
```

但用户期望是：

```text
让用户选择执行模式
```

因此技能文本需要消除主语歧义。

## 影响

- 用户失去对实现执行方式的控制；
- 非平凡任务可能被 agent 直接主线程实现，错过使用 subagent 或多 subagent 的机会；
- 与用户对 `coding-workflow` 的流程预期不一致；
- 后续同类任务可能重复发生。

## 最小修正建议

将 `coding-workflow` 技能 Step 3 中的表达从：

```markdown
After explicit approval: save the plan under `docs/plans/YYYY-MM-DD-<topic>.md`, commit the plan to git, then choose mode.
```

修改为：

```markdown
After explicit approval: save the plan under `docs/plans/YYYY-MM-DD-<topic>.md`, commit the plan to git, then ask the user to choose the execution mode before implementation unless the user has already explicitly specified it.
```

并在执行模式表格前增加：

```markdown
Present these modes to the user and wait for their choice:
```

## 推荐规则

后续 `coding-workflow` 应明确：

```text
计划确认后，保存并提交计划；
如果用户未提前指定执行方式，必须暂停并让用户选择 Main agent / Single subagent / Multiple subagents；
获得选择后再开始实现。
```

## 压力场景 / RED 记录

### RED 场景

用户确认计划后说：

```text
确认
```

agent 可能认为：

```text
用户已批准计划，可以直接实现。
```

然后跳过执行模式选择。

### 失败判定

如果 agent 在保存并提交计划后没有询问：

```text
请选择执行方式：Main agent / Single subagent / Multiple subagents
```

而是直接开始编辑代码，则判定失败。

## GREEN 验证建议

修改技能后，用类似任务验证：

```text
/coding-workflow 为某个 Java Job 做多文件重构，计划确认后继续
```

期望 agent 在计划提交后输出执行模式选择问题，并等待用户回答，而不是直接编辑代码。

## 注意事项

不要把这个问题修成过宽的确认门。

错误修法：

```text
每一步都问用户是否继续。
```

正确修法：

```text
只在计划提交后、实现前，针对执行模式选择进行一次明确停顿。
```

## 状态

已记录失败经验，尚未修改 `coding-workflow` 技能本体。
