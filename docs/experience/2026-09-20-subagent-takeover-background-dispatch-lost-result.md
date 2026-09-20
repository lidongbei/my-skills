# subagent-takeover 后台派发后主 Agent 结束导致丢结果失败经验

日期：2026-09-20

## 背景

用户选择 `coding-workflow` 的「多个子 agent 分工」执行模式，路由到 `subagent-takeover`。协调者（主 Agent）按 Step 4 派发子 agent 后，本回合无事可做，回合结束，进程进入 idle；子 agent 完成后的通知链未能续接本次会话，导致：

- 拿不到子任务结果；
- 没有进入 Step 5 的校验和后续流程。

本次中断涉及 SUB-05 / SUB-07；恢复时通过直接 `find`/`read` 磁盘产物验证，反而发现了已损坏的产物。

## RED 场景

协调者派发多个子 agent，工具立即返回 agentId 句柄、不阻塞：

```text
派发 Agent（后台）→ 立即拿到 agentId 句柄 → 工具返回，不阻塞
        ↓
本轮没别的事 → 回合结束，进程 idle（但活着）
        ↓
子 agent 完成 → harness 注入 <task-notification> → 主 Agent 被重新调用
```

当进程在通知到达前退出时，链路在第二步之后断裂，子任务结果与后续流程一并丢失。

## 机制真相

本运行时**不存在**"阻塞等待"原语，只有"回合结束 + 事件唤醒"：

- 协调者不能"轮询"或"卡住等"，架构里没有这个动作；
- **进程存活 = 唤醒的前提**。进程一退出，通知链断裂；
- 因此"主 Agent 阻塞等待"在实现上不存在，只能靠通知驱动。

这个机制事实此前没有写进技能，是本次失败的根本前提。

## 当前技能缺口

本轮修复前的 `subagent-takeover` Step 4 只有一句：

```markdown
For each subtask, use `agent` to dispatch one subagent.
```

没有规定前台/后台，于是运行时默认走后台派发。缺口具体是三处：

| 缺口 | 后果 |
|---|---|
| 未规定派发必须阻塞 | 后台派发 → 回合结束 → 进程退出后断链 |
| 结构化反馈只存在于子 agent 的 final message | 消息随进程消亡，磁盘无副本 |
| `Subtask Status` 表只记 `pending`，不记 agentId / 派发时刻 | 断链后连"该找谁恢复"都丢失 |

其中第二条是致命点：`Subagent Feedback` 契约原本要求子 agent 在**最终消息**里返回结构化反馈，而最终消息正是通过那个可能永远不来的通知传递的。

## 根因分析

### 失败层级

Skill gap（技能缺口）-- Step 4 未约束派发语义，Step 5 把易失的消息当作唯一交付通道。

### 判断失误链

1. 技能未禁止"派发后结束回合"，协调者按运行时默认行为异步派发；
2. 回合结束即进入 idle，唤醒完全依赖事件注入；
3. 进程退出后通知链断裂，结果与后续流程同时丢失；
4. 恢复依赖内存中的 agentId 句柄，而该句柄没有任何持久化记录。

## 影响

- 整条多子 agent 流程无声中断，用户侧看到的是流程"消失"；
- 已落地的部分改动无人校验，可能留下半截编辑；
- 若在恢复时盲目重新派发，会重复应用已落地的改动。

## 最小修正建议（已实施）

三道互补防线，缺一不可：

**① Step 4——派发必须阻塞。** 结果在同一回合内消费；并行子任务放同一条消息里的多个 `agent` 调用（仍在同一回合内等待）。后台派发仅当同回合还有别的事可做，**不得作为回合的最后一个动作**。

**② Step 5——反馈落盘。** 子 agent 必须先把结构化反馈 `edit` 写入 `<output root>/subTasks/YYYY-MM-DD-<topic>/SUB-<nn>-feedback.md`，final message 只是副本；协调者以磁盘文件为权威记录校验。

**③ 新增 Step 7 Resume Protocol + 状态机。** `Subtask Status` 表增加 `State / Agent handle / Dispatched at`，状态机 `pending → dispatched → feedback-received → completed`，硬规则：回合结束时不得有行停在 `dispatched`。重入时先读文档恢复状态，再查反馈文件；完整则直接校验不重跑，缺失或截断才用 `SendMessage(agent handle)` 续跑或重新派发。

配套改动：

- Hard Boundaries 增加派发与反馈落盘两条红线；
- `Common Mistakes` 增加 4 行，`Red Flags - STOP` 增加 3 条；
- `using-tool/runtimes/claude-code.md` 的 `agent` 段同步阻塞默认与 `run_in_background` 使用边界。

## 可恢复项与不可恢复项

修复后仍要诚实区分能力边界：

| 情形 | 修复后结果 |
|---|---|
| 派发后回合结束、进程存活 | 阻塞派发已从源头避免 |
| 进程退出但反馈文件已落盘 | 重入后从磁盘恢复，可继续流程 |
| 进程被杀、产物写一半就崩 | 仍会损坏；技能层无法保证进程不死 |

技能指令能做到的极限，是把损害从"整条流程失踪"降级为"重入后可从磁盘续跑"。要绝对不丢，需要 harness 级的持久化后台任务，超出技能层的控制范围。

## GREEN 验证建议

重新走一遍多子 agent 分工流程，判定标准：

- 期望：协调者阻塞派发并在同一回合内消费结果；`Subtask Status` 每行按状态机推进，无行停在 `dispatched` 结束回合。
- 期望：每个子任务产出的 `SUB-<nn>-feedback.md` 在磁盘上存在且为完整块。
- 模拟中断：派发后强制结束会话，再重入本技能，期望走 Resume Protocol 从 `Subtask Status` + 反馈文件恢复，而不是重跑整个拆分或重复已落地改动。

判定失败：协调者以 `run_in_background: true` 派发后直接结束回合；或校验时只引用子 agent 的消息而不读反馈文件。

## 注意事项

不要把这个缺口修成"禁止并行"。

错误修法：

```text
子 agent 只能串行派发，禁止并行。
```

正确修法：

```text
同一条消息内并发派发（阻塞等待），禁止把后台派发作为回合最后一个动作。
```

同时不要把最终消息判定为"可丢弃"：消息仍应返回，只是不再作为唯一交付通道和权威记录。

## 状态

已按上述方案修改 `skills/subagent-takeover/SKILL.md` 与 `skills/using-tool/runtimes/claude-code.md`；`scripts/validate.ps1` 校验通过。GREEN 验证尚未执行，待用一次真实多子 agent 分工流程确认。
