# subagent-takeover 跨客户端 / 本地代理模型效果不一致经验

日期：2026-09-30

## 背景

`subagent-takeover` 在 `coding-workflow` 选择「多个子 agent 分工」后被路由，负责拆分已批准方案、派发子任务、校验结构化反馈。实际使用中，同一份技能在不同 agent 客户端（Codex / Claude Code / DSH / Trae / CodeArts）和不同模型（多为本地代理后的模型）下效果差异很大，有的能跑通，有的直接无法执行。

用户的原始描述：

> 子会话在不同 agent 客户端和自定义模型下会发生不同的效果，有什么方案处理吗，模型多为本地代理后的，直接用 agent 的子代理不能实现。

## 缺口

技能此前把「派发子 agent」写成了一种运行时语义，等价于假设每个客户端都具备 Claude Code 形状的原生子 agent：

| 位置 | 写死的假设 | 其他运行时的现实 |
|---|---|---|
| Step 4 阻塞形式 | 只写了「in Claude Code, `run_in_background: false`」 | 其他运行时读到这句等于没读到 |
| Step 4 并行派发 | 「并行子任务放同一条消息里多个 `agent` 调用」 | CodeArts 明确「一次响应只能一个 `task` 调用」；本地推理服务通常单并发 |
| Step 4 提示词 | 要求子 agent 一次完成读取、搜索、编辑、校验 | 小模型/单并发工具调用下不成立 |
| Step 5 反馈契约 | 要求子 agent「生成」一大段结构化 markdown | 本地代理后的模型在生成结构上失败率高 |
| Step 7 Resume | 依赖 agent handle 续跑（`SendMessage`） | Codex 无 handle 续跑；无原生子 agent 时连 handle 都不存在 |
| 能力表 | `using-tool` 只覆盖 4 个运行时 | DSH 无映射文件；各 runtime 文件也没有「子 agent 能力」一节 |

根因一句话：**把不可移植的能力（delegation）和可移植的契约（产物 + 校验）混在一起写了**。

## 修正方案（已实施）

核心是**显式声明派发后端**，外部契约保持不变。

### 1. `using-tool` 新增能力层

- 新建 `skills/using-tool/runtimes/dsh.md`，补齐 DSH 映射（`ask_user_question` / `subagent` / `run_in_background: false` / `dsh headless` 等）。
- 每个 runtime 文件新增 **Subagent Dispatch Capability** 小节，固定六项：原生工具、阻塞形式、并行上限、能否按 handle 续跑、默认后端、CLI 兜底。数值事实：
  - Claude Code：原生 `Agent`，可同消息并行，`SendMessage` 可续跑。
  - Codex：原生 delegation 不保证；无 handle 续跑；默认 `cli`，无 headless 入口则 `sequential`。
  - DSH：原生 `subagent`，阻塞需显式 `run_in_background: false`，`send_message` 可续跑，`dsh headless` 可作 CLI 后端。
  - Trae：原生 `Task`，并发未文档化，按 1 处理。
  - CodeArts：原生 `task`，**一次响应只能一个**，`task_id` 可续跑。
- `using-tool/SKILL.md` 新增 `Subagent Dispatch Capability` 一节，定义四种后端与解析顺序 `native → cli → sequential → manual`，并写明本地代理的三条约束。

### 2. `subagent-takeover` 后端化

- 新增 `Dispatch Backend` 一节：`.agents/my-skills-local-config.md` 中的 `<!-- agent-dispatch -->` 块声明 `Backend` / `CLI template` / `Max parallel` / `Subagent model`；解析顺序为「声明 → runtime 默认 → 兜底顺序」，禁止静默降级。
- Step 0 增加后端解析，并在评审门（Step 3）向用户明示执行机制与并发上限。
- Step 4 改为按后端执行；并发受 `Max parallel` 约束（默认 1）；只有 `Max parallel > 1` 且 runtime 允许时才同消息并发。
- Step 2 新增**骨架化反馈**：预创建 `SUB-<nn>-feedback.md`，所有值写 `未填`，执行方只做原地替换。把「生成结构」降级为「填空」。
- Step 5 增加**机检头块**（`status` / `files` / `validation-ran` / `validation-result`），先命令校验再读正文；并新增**命令级证据**红线，`sequential` 下自撰反馈不算独立验证。
- 状态机新增 `awaiting-user`：`manual` 后端是唯一允许「回合结束时停在非完成态」的合法情形，原「不得停在 `dispatched`」红线保持不变。
- Step 7 恢复时**必须使用子任务文档记录的同一后端**，不允许恢复途中升级后端。

## 可恢复项与不可恢复项

| 情形 | 处理结果 |
|---|---|
| 运行时无原生子 agent | 显式降级到 `cli` / `sequential`，产物与状态表不变 |
| 本地代理模型未接到子会话 | 声明 `Subagent model`；无法钉住模型时走 `cli`，由进程携带自己的模型配置 |
| 本地推理服务单并发 | `Max parallel` 默认 1；并发派发需显式声明 |
| 弱模型写不出结构化反馈 | 骨架 + `未填` 原地替换 + 头块机检 |
| 弱模型当协调者，审阅盖章 | 强制命令级证据（退出码 / 文件内容 / grep / 测试结果） |
| 需要真正的并行加速 | 依赖服务端并发能力，技能层只能声明不能创造 |

技能层做不到的事：让一个不提供子 agent 的客户端长出子 agent；让单并发的本地服务真正并行。技能层能做的是把「不同客户端效果不同」从**静默走样**变成**显式声明 + 有降级路径 + 产物一致可校验**。

## GREEN 验证建议

1. 在 Claude Code（`native`）、Codex（`cli` 或 `sequential`）、DSH（`native`）各跑一遍多子 agent 分工流程。
2. 判定通过：子任务文档 `Summary` 记录了解析出的后端与 `Max parallel`；每条 `Subtask Status` 行有 `Backend` 列；反馈文件在派发前已存在骨架；校验时先读头块。
3. 判定通过：把 `.agents/my-skills-local-config.md` 的 `Max parallel` 设为 1 时，协调者不并发派发；设为 2 且 runtime 允许时才同消息多调用。
4. 判定失败：runtime 没有原生子 agent 却宣称用了子 agent；`manual` 后端以 `dispatched` 状态结束回合；恢复时更换后端。

GREEN 验证尚未执行。

## 注意事项

- 不要把「后端化」修成「禁止并行」。并行仍然可用，只是受声明约束。
- 不要把最终消息判定为可丢弃：消息仍应返回，只是不再作为唯一交付通道。
- `CLI template` 是用户/项目声明的自由文本，不要在技能里为运行时臆造 headless 命令；未声明且无原生子 agent 时走 `sequential`。

## 状态

已修改 `skills/using-tool/SKILL.md`、`skills/using-tool/runtimes/{claude-code,codex,trae,codearts}.md`、新增 `skills/using-tool/runtimes/dsh.md`、`skills/subagent-takeover/SKILL.md`、`scripts/validate.ps1`、`README.md`；`scripts/validate.ps1` 校验通过。GREEN 验证待执行。
