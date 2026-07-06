# using-tool runtime 指令使用样例补全方案

日期：2026-07-01

## 背景

用户指出：`skills/using-tool/runtimes` 中的指令使用样例不全。

已检查文件：

- `skills/using-tool/SKILL.md`
- `skills/using-tool/runtimes/claude-code.md`
- `skills/using-tool/runtimes/codex.md`

## 诊断

Diagnosis: Workflow / reference coverage gap

Evidence:

- `using-tool` 的核心职责是把便携 tool-action alias 或源 runtime 工具指令，适配到当前 agent runtime。
- `skills/using-tool/SKILL.md` 明确 runtime files 应包含 instruction shapes and examples、重要参数/约束、fallback。
- 当前两个 runtime 文件已有 alias 映射和边界说明，但示例集中在少数 alias：
  - Claude Code 文件主要只有 `ask` 的完整结构化示例；
  - Codex 文件主要只有 `ask` 与 `read/find` 的具体示例；
  - `edit`、`run`、`todo`、`agent`、`check` 缺少足够的源指令到当前 runtime 操作的示例。
- 这会削弱 `using-tool` 的参考价值：后续 agent 可能理解“要适配语义”，但不知道具体如何从 portable instruction 或源 runtime 工具名落到当前 runtime 的操作形态。

## 决策

按用户选择，采用“最小补全”方案：

- 只修改 `skills/using-tool/runtimes/claude-code.md` 和 `skills/using-tool/runtimes/codex.md`。
- 不修改 `skills/using-tool/SKILL.md` 主体，不扩大触发、不改变 mandatory loading rule、不改变 model-invocable 决策。
- 不新增 runtime 文件、不改 plugin 结构。

## 最小修改范围

### Claude Code runtime

补充紧凑示例，覆盖每个 alias 的典型迁移形态：

- `ask`: portable choice instruction → `AskUserQuestion`；开放式澄清 → 普通聊天。
- `read/find`: known file/search instruction → `Read`/`Glob`/`Grep`，优先专用工具而不是 shell 读搜。
- `edit`: modify existing file → 先 `Read` 再 `Edit`；new/full replacement → `Write`。
- `run`: validation/test/build instruction → `Bash`，带清晰 description 和必要 timeout。
- `todo`: multi-step checklist → `TaskCreate`/`TaskUpdate`；简单一步不强行使用。
- `agent`: independent exploration/review → `Agent`；`Workflow` 仅在用户明确 opt-in 时使用。
- `check`: verify/review instruction → 命令输出、文件检查、diff/review evidence，不无证据宣称验证。

### Codex runtime

补充对应示例，强调不复制 Claude Code schema：

- `ask`: structured choice → 普通聊天编号选项。
- `read/find`: 优先 Codex 可见工具；无工具时 bounded shell，如 `sed -n`、`rg -n`。
- `edit`: 使用 Codex patch/edit 能力；不能只输出 patch 就声称已应用。
- `run`: shell execution，遵守 sandbox/approval。
- `todo`: 有 plan/update tool 则用；没有则 Markdown checklist。
- `agent`: 有 delegation 才委派；没有则主 agent 完成并说明限制。
- `check`: 命令结果、diff、文件检查或人工观察作为证据。
- source-runtime migration: Claude Code `AskUserQuestion` JSON → Codex 编号问题，而不是原样复制。

## 验证计划

修改完成后运行：

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

并检查：

- `using-tool` frontmatter 未改变；
- user-only/model-invocable 决策未改变；
- runtime 文件仍是 reference/mapping，不引入新 workflow；
- 未新增 root `plugin.json` 或 nested plugin；
- 示例不会误导 agent 把 alias 当真实工具名，或复制其他 runtime 的 JSON schema。

## 自审

- 范围是否足够小：是。只补两个 runtime reference 文件，不改主技能行为。
- 是否解决用户指出的问题：是。缺口集中在 runtime examples，而非主技能规则。
- 是否存在过度设计：否。不新增 eval、不新增 runtime、不改 adapter。
- 风险：样例如果写得过长会增加 token 成本；实现时应保持表格式或短块示例。
- 待确认：实现方式按用户已选的最小补全执行；具体措辞在实现阶段保持精简。
