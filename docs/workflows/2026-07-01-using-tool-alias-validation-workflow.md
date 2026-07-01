# using-tool Alias 映射验证工作流

## 定位

这是 `using-tool` 技能的子模块验证工作流，不是一次性实施计划，也不记录某次运行结果。

它是跨工具、跨运行时可重复使用的验证工具，用来验证 `using-tool` 中定义的工具动作别名是否能在当前运行时落地。每次执行本工作流时，必须把行为结果写入独立 result 文件。

## 结果文件规则

每次执行本工作流，都创建或更新一个独立结果文件：

```text
docs/results/<日期>-<工具>-using-tool-alias-validation.md
```

示例：

```text
docs/results/2026-07-01-claude-code-using-tool-alias-validation.md
docs/results/2026-07-01-codex-using-tool-alias-validation.md
```

规则：

- `<日期>` 使用本次验证日期，格式 `YYYY-MM-DD`。
- `<工具>` 使用当前运行时或代理工具名的 kebab-case，例如 `claude-code`、`codex`。
- workflow 文件只保留步骤、模板和完成标准；不得记录某次运行的观察结果。
- result 文件记录实际工具调用、调用参数、工具反馈、偏差、结论。

## 前置条件

1. 加载 `using-tool`。
2. 加载当前运行时对应的 runtime mapping 文件。
3. 明确当前运行时名称，用于 result 文件名。
4. 准备记录 8 个 alias 的验证证据。

## 验证对象

| Alias | 动作意图 | 验证目的 |
|---|---|---|
| `ask` | Ask the user for a decision, missing fact, confirmation, or choice. | 验证用户决策、澄清、确认是否能在当前运行时执行 |
| `read` | Read a file, document, notebook, image, or runtime-accessible resource. | 验证已知资源读取是否可执行并能形成证据 |
| `find` | Search files, paths, symbols, text, docs, or web resources. | 验证路径发现、内容搜索或资料检索是否可执行 |
| `edit` | Create, modify, replace, or delete file content. | 验证文件创建或修改是否可控落地 |
| `run` | Execute a command, script, test, build, validation, or app launch. | 验证命令、脚本、测试或校验是否可执行 |
| `todo` | Track work items, progress, dependencies, or checklist state. | 验证多步骤工作是否可被跟踪 |
| `agent` | Delegate to a subagent, reviewer, explorer, or parallel worker. | 验证是否可委派独立检查或子任务 |
| `check` | Verify behavior, inspect results, review changes, or confirm evidence. | 验证结果是否有具体证据支撑 |

## 调用证据要求

每个 alias 的 result 记录必须包含实际调用证据，不能只写结论。

最小证据字段：

- `调用工具 / 能力`：当前运行时实际使用的工具、命令或降级方式。
- `调用参数`：实际传入参数。参数较长时可以摘要，但必须保留能复现实验的关键参数，例如路径、pattern、command、description、task subject、agent prompt 摘要。
- `工具反馈 / 输出`：工具返回的成功信息、错误信息、用户拒绝信息、命令输出、任务编号、子代理返回内容等。
- `agent 反馈`：如果 alias 使用了子代理，必须记录子代理返回的结论或关键摘录。
- `解释`：把事实证据和主观判断分开写；不要把“工具可达”直接写成“验证完全通过”。

## 工作流原则

1. 每次只验证一个 alias，避免证据混杂。
2. 每个 alias 必须记录到 result 文件：输入意图、实际工具、调用参数、工具反馈、执行动作、观察结果、偏差或限制、结论。
3. 验证动作应尽量小、可逆、可观察。
4. 对会修改项目的动作，优先写入 result 文件或专用临时验证文件，避免污染技能本体。
5. 不同运行时复用同一 workflow，但使用各自 runtime mapping 和 result 文件。
6. 最终结论必须区分：PASS、PARTIAL、FAIL、BLOCKED。

## 验证步骤

### 1. 验证 `ask`

- 选择当前运行时中最接近 `ask` 的能力。
- 发起一个与本验证直接相关的用户决策、澄清或确认。
- 记录用户是否能看见、选择、拒绝或要求澄清。
- 记录完整问题、选项、用户反馈或拒绝原因。
- 不要把问题设计成无关业务选择。

### 2. 验证 `read`

- 读取一个已知、稳定、与本验证相关的资源。
- 推荐读取当前运行时 mapping 文件。
- 记录读取路径、offset/limit、返回内容类型、是否带可引用证据。

### 3. 验证 `find`

- 执行路径发现或内容搜索。
- 推荐查找 `skills/*/SKILL.md`，或搜索 `ask|read|find|edit|run|todo|agent|check`。
- 记录搜索方式、pattern、path、匹配结果和限制。

### 4. 验证 `edit`

- 创建或更新 result 文件。
- 如果当前运行时要求编辑前读取目标文件，先读取。
- 记录写入路径、编辑方式、关键参数、工具反馈。
- 长内容可摘要，但必须说明完整内容保存在哪个文件中。

### 5. 验证 `run`

- 执行一个安全、可重复、与项目相关的命令。
- 对本仓库优先使用：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

- 记录命令、description、timeout、退出结果、关键输出。

### 6. 验证 `todo`

- 创建或更新一个小型验证任务。
- 如果当前运行时没有任务工具，用 Markdown checklist 作为降级方案，并在 result 中说明。
- 记录任务创建参数、任务编号、状态变化和工具反馈。

### 7. 验证 `agent`

- 委派一个只读检查任务给子代理、审阅者或等价机制。
- 如果当前运行时没有子代理能力，记录缺失能力并使用人工检查降级。
- 记录 agent 类型、prompt 摘要或全文、隔离模式、是否后台运行、子代理返回结论。

### 8. 验证 `check`

- 汇总前 7 项证据。
- 对每个 alias 标注 PASS / PARTIAL / FAIL / BLOCKED。
- 说明偏差、限制和是否需要修改 `using-tool` 或 runtime mapping。
- 记录使用了哪些证据源；如果通过人工检查完成，也要明确写出检查依据。

## Result 文件模板

```markdown
# <工具> using-tool Alias 映射验证结果

## 元信息

- 日期：YYYY-MM-DD
- 工具 / 运行时：<tool-name>
- 对应工作流：`docs/workflows/2026-07-01-using-tool-alias-validation-workflow.md`
- Runtime mapping：<path-or-source>
- 验证对象：`ask`、`read`、`find`、`edit`、`run`、`todo`、`agent`、`check`

## 总结

<本轮验证总体结论。>

## 结果矩阵

| Alias | 状态 | 实际工具 / 行为 | 证据摘要 |
|---|---|---|---|
| `ask` |  |  |  |
| `read` |  |  |  |
| `find` |  |  |  |
| `edit` |  |  |  |
| `run` |  |  |  |
| `todo` |  |  |  |
| `agent` |  |  |  |
| `check` |  |  |  |

## 逐项记录

### Alias: `ask`

- 意图：
- 映射工具 / 行为：
- 调用参数：
  ```json
  {}
  ```
- 工具反馈 / 输出：
  ```text
  
  ```
- 观察结果：
- 是否符合 runtime mapping：
- 偏差或限制：
- 结论：PASS / PARTIAL / FAIL / BLOCKED

<!-- 对 read/find/edit/run/todo/agent/check 重复同一结构 -->

## Agent 反馈记录

如果本次验证使用了子代理，在这里保留子代理返回的关键结论或完整摘录。

## 偏差和改进建议

- 

## 最终结论

- PASS：
- PARTIAL：
- FAIL：
- BLOCKED：
```

## 完成标准

本工作流的一次执行完成时必须满足：

- result 文件按 `<日期>-<工具>-using-tool-alias-validation.md` 命名。
- 8 个 alias 都有独立验证记录。
- 每个 alias 都有实际调用参数和工具反馈。
- 如果使用了子代理，result 文件包含 agent 反馈结论或关键摘录。
- 每个 alias 都有明确状态：PASS / PARTIAL / FAIL / BLOCKED。
- result 文件区分实际证据和主观判断。
- 对缺失能力使用明确降级说明，不把降级伪装成成功工具调用。
- 最终输出说明哪些映射可靠、哪些需要改进 `using-tool` 或 runtime 文件。
