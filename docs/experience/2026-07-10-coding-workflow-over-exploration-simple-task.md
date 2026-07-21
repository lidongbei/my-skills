# coding-workflow 简单任务过度探索失败经验

日期：2026-07-10

## 背景

用户显式调用 `/my-skills:coding-workflow` 执行一项简单代码任务：为"分配批次记录支持按照方案Id查询"添加 `planId` 查询字段。该任务实际只需改 3 个文件（DTO 加字段 + mapper xml 加条件 + controller 日志补字段）。

`coding-workflow` 的 Plan First 阶段要求：

```markdown
Missing facts? Investigate, then ask if still unclear.
```

但未指导 investigate 时如何匹配探索工具规模到任务复杂度。

## 失败现象

agent 收到任务后，未先评估任务复杂度，直接派 Explore 子 agent 做"全面"代码探索：

```text
Agent "Explore 分配批次 records code" finished
subagent_tokens: 57652
tool_uses: 32
duration_ms: 242606
```

消耗 57,652 tokens、32 次工具调用、约 4 分钟。

实际正确做法只需一次轻量搜索即可定位目标文件：

| 方式 | 消耗（约） | 说明 |
|---|---|---|
| MCP search_code + get_code_snippet | ~3,250 tokens | 结构化返回，无需读完整文件 |
| Grep + Read | ~8,750 tokens | 逐个读完整文件理解结构 |
| Explore 子 agent | ~57,652 tokens | 隔离上下文但总消耗最大 |

代价：token 浪费约 18 倍（MCP vs Explore）。

用户后续指出：

> 为什么没使用 mcp 分析项目代码
> 这么简单的功能为什么会使用 Explore 子 agent

## 当前技能缺口

`coding-workflow` 的 Plan First 只说 "Investigate"，没有规定：

- investigate 前是否需要评估任务复杂度；
- 何时用轻量搜索（`find`：Grep / MCP `search_code`）；
- 何时才派 `agent`（Explore 子 agent）；
- 简单任务（加字段、改日志、找定义）是否应直接定位而非全面探索。

因此 agent 可能：

- 收到任意任务都派 Explore 子 agent 做"全面"探索；
- 忽视 git 历史等线索（本次最近提交全是该模块，位置已明确）；
- 对加字段级任务也消耗数万 token。

## 根因分析

### 失败层级

Workflow gap（工作流缺口）-- Plan First 阶段缺探索工具选择指导。

### 具体原因

`coding-workflow` 技能中当前表达：

```markdown
Missing facts? Investigate, then ask if still unclear.
```

`Investigate` 没有约束探索规模。agent 默认选择最"全面"的方式（Explore 子 agent），而非最匹配任务规模的方式。

### 判断失误链

1. 未评估任务复杂度 -- "加查询字段"明显是小范围；
2. 忽视 git 历史线索 -- 最近提交全是 review-assignment 模块；
3. 本末倒置 -- 把"理解结构"等同于"全量探索"。

## 影响

- 简单任务消耗数万 token，成本约 18 倍；
- 增加响应延迟（4 分钟 vs 秒级）；
- 后续同类任务可能重复过度探索。

## 最小修正建议

在 `coding-workflow` 的 Plan First 的 `Investigate` 句后补充探索工具匹配规则：

```markdown
Missing facts? Investigate, then ask if still unclear. Match exploration tool to task scope: one `find` (Grep or MCP `search_code`) before dispatching `agent` (Explore); reserve `agent` for genuinely cross-module or uncertain-scope investigation.
```

并在 Common Mistakes 表增加一行：

```markdown
| Over-exploring simple tasks | Match search tool to task scope; run one `find` before dispatching `agent` |
```

不新增章节，控制 skill 长度。

## 任务复杂度与工具匹配参考

| 任务复杂度 | 工具 |
|---|---|
| 加字段 / 改日志 / 找定义 | `find`（Grep / MCP `search_code`）+ `read` |
| 中等改动（多文件、需理解关系） | MCP `search_code` + `get_code_snippet` |
| 跨模块、不确定范围 | `agent`（Explore 子 agent） |

## GREEN 验证建议

修改技能后，用类似简单任务验证：

```text
/coding-workflow 为某查询接口加一个筛选字段
```

期望 agent 在 Plan First 阶段先 `find`（Grep / MCP `search_code`）定位目标文件，而非直接 `agent` 派发 Explore 子 agent。

判定失败：agent 未做任何 `find` 就直接 `agent` 探索，或对加字段级任务派发子 agent。

## 注意事项

不要把这个问题修成过宽的确认门或硬性禁令。

错误修法：

```text
禁止使用 Explore 子 agent。
```

正确修法：

```text
派 agent 前先做一次 find；agent 留给真正跨模块或范围不确定的场景。
```

## 状态

已记录失败经验，待修改 `coding-workflow` 技能本体（Plan First 的 investigate 句 + Common Mistakes 表）。
