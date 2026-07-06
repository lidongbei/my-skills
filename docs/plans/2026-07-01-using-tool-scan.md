# using-tool 扫描与清理记录

日期：2026-07-01

状态：已按用户逐项确认完成清理，并通过验证。

## 背景

用户请求创建新技能 `using-tool`，解决在不同 agent 工具/runtime 中使用本插件其他 skills 时，由于直接套用源工具的具体 tool 名称、参数格式或交互模型而导致的工具调用失败问题。

典型失败例：skill 中要求像 Claude Code 的 `AskUserQuestion` 那样向用户提问，但目标工具/runtime 没有同名工具或参数格式不同，agent 照抄 Claude Code 的参数结构后调用失败。

## 已确认设计决策

- 技能名称：`using-tool`
- 主要使用者：任意 agent
- 调用模式：`model-invocable`
  - `SKILL.md` frontmatter 不加入 `disable-model-invocation: true`
- 首批目标 runtime：Claude Code、Codex
- 其他 skills 写工具动作时使用反引号短动词代称，而不是具体工具名或参数格式
- 代称风格：短动词
- 初版代称集合：
  - `ask`：向用户提问、澄清、让用户选择
  - `read`：读取文件或资源
  - `find`：搜索文件、内容、符号、资料
  - `edit`：修改或创建文件
  - `run`：执行命令、脚本、测试、验证命令
  - `todo`：记录、更新、推进任务列表
  - `agent`：委派子代理或并行探索
  - `check`：验证结果、审查变更、确认行为符合预期
- 缺少目标能力时：先寻找目标工具/runtime 的最近等价能力；没有等价能力时，再降级到文本交互或明确说明限制
- 映射维护方式：

```text
skills/using-tool/
  SKILL.md
  runtimes/
    claude-code.md
    codex.md
```

`SKILL.md` 定义代称协议、加载规则、适配流程和失败处理；每个 runtime 子文件维护代称到真实工具/交互方式的映射。不同 agent 根据自身 runtime 自行加载对应映射文件。

## 扫描范围

扫描目标：现有 `skills/*/SKILL.md` 中是否存在 Claude Code 专用工具名或容易被跨 runtime 误用的工具调用说明。

重点搜索词：

```text
AskUserQuestion, TaskCreate, TaskUpdate, TaskList, TaskGet,
Read, Edit, Write, Glob, Grep, Bash, Agent, Skill,
EnterPlanMode, ExitPlanMode, WebFetch, Workflow, TodoWrite
```

另扫描 `adapters/**/*` 中已有跨工具/Codex 适配说明。

## 逐项确认与处理结果

### 1. `skills/idea-shaping/SKILL.md`

原命中位置：frontmatter `allowed-tools`

```yaml
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
```

用户决定：移除这个 frontmatter `allowed-tools`。

处理结果：已移除 `allowed-tools` 块，仅保留 user-only frontmatter 必要字段。

### 2. `skills/writing-skills/SKILL.md` plan mode 规则

原命中位置：Claude Code plan mode 禁用规则

```markdown
Do not use Claude Code plan mode (`EnterPlanMode` or `ExitPlanMode`) while using this skill.
```

用户决定：删除具体工具名但保留规则。

处理结果：已改为通用 plan mode 表述：

```markdown
Do not use plan mode while using this skill.
```

另同步清理同文件后续小节中的 `Claude Code plan mode` 表述，使其改为 `plan mode`。

### 3. `skills/writing-skills/SKILL.md` runtime `Skill` tool 说明

命中位置：user-only skill invocation 说明

```markdown
runtime `Skill` tool
```

用户决定：保留原样。

处理结果：未改动。原因是这里描述 runtime 的 skill 加载机制，不是普通工具动作指令，也不是应替换成 `ask` / `read` / `agent` 的动作代称。

### 4. `adapters/codex/AGENTS.md` Tool Mapping Notes

原命中位置：已有简短 Tool Mapping Notes

```markdown
Some skills mention Claude Code-specific tools or concepts. In Codex, adapt actions as follows:

- Read/search files: use shell commands such as `rg`, `cat`, and `ls`.
- Edit files: use Codex editing capabilities.
- Run commands: use shell command execution when available.
- Ask the user: ask directly in chat.
- Subagents: use Codex multi-agent support when available.

Use each skill's intent and workflow, not necessarily its exact Claude Code tool names.
```

用户决定：保持当前更新，即 adapter 不重复维护具体映射，只指向 `using-tool` 的 Codex runtime 映射文件。

处理结果：已改为指向：

```text
skills/using-tool/runtimes/codex.md
```

### 5. 继续清理所有可替换的 Claude Code 专用名称

用户决定：继续清理仓库中其他可替换的 Claude Code 专用工具名/runtime 名称。

处理结果：已清理以下非 runtime 映射语境中的表述：

- `PROJECT_SPEC.md`
  - `Claude Code user-only mode` → `user-only mode`
  - `EnterPlanMode` / `ExitPlanMode` → `plan mode`
- `CLAUDE.md`
  - `Claude Code user-only` → `user-only`
  - `Claude Code plan mode` → `plan mode`
- `README.md`
  - `Claude Code user-only skills` → `user-only skills`
  - `Existing user-only skills must remain Claude Code user-only` → `Existing user-only skills must remain user-only`
- `skills-index.md`
  - `Claude Code user-only skills` → `user-only skills`

## 已创建/更新的 using-tool 文件

已创建：

```text
skills/using-tool/SKILL.md
skills/using-tool/runtimes/claude-code.md
skills/using-tool/runtimes/codex.md
```

已同步更新：

```text
.claude-plugin/plugin.json
skills-index.md
README.md
PROJECT_SPEC.md
CLAUDE.md
adapters/codex/AGENTS.md
adapters/agents/AGENTS.md
adapters/claude-code/README.md
scripts/validate.ps1
scripts/install-claude-code.ps1
scripts/sync-from-claude.ps1
```

## 保留的专用名称及原因

以下命中保留是有意的：

- `skills/using-tool/SKILL.md` 中的 `AskUserQuestion`、`Claude Code`、`EnterPlanMode` 示例：这是本技能要识别和防止误迁移的源工具/反例，不应删除。
- `skills/using-tool/runtimes/claude-code.md` 中的 Claude Code 工具映射表：这是 Claude Code runtime 映射文件，必须保留真实工具名。
- `skills/using-tool/runtimes/codex.md` 中的 Claude Code 工具名翻译规则：这是 Codex 如何处理源工具名的映射说明，必须保留源名称以便识别。
- `adapters/claude-code/README.md` 中的 Claude Code adapter 名称和路径说明：这是 adapter 文档的目标 runtime 名称，不是误用的工具动作指令。
- `runtime Skill tool` 说明：用户已确认保留，表示 runtime skill 加载机制。

## 结论

当前策略不是无差别删除所有 runtime 名称，而是：

1. 普通 skill 正文里的可执行工具动作应使用 `ask`、`read`、`find`、`edit`、`run`、`todo`、`agent`、`check` 等短代称。
2. runtime 映射文件、adapter 名称、源工具反例、加载机制说明和精确边界说明可以保留真实名称。
3. 对已发现的非必要 Claude Code 专用表述，已按用户确认清理为通用表述。

## RED 场景草案

用于验证无 `using-tool` 时的失败方式：

### 场景 A：Codex 中误用 Claude Code `AskUserQuestion`

任务：agent 在 Codex 中执行某个 skill，需要向用户确认选择。

预期无技能失败：agent 直接构造 Claude Code `AskUserQuestion` 参数，如 `questions/options/header/multiSelect`，但 Codex 没有该工具或参数 schema 不匹配，导致调用失败或卡住。

`using-tool` 应阻止的行为：把 `ask` 代称直接当作 Claude Code `AskUserQuestion` 调用格式复制到 Codex。

### 场景 B：Claude Code 中把短代称当成 shell 命令

任务：skill 写“use `ask` to clarify”，agent 在 Claude Code 中执行。

预期无技能失败：agent 把 `ask` 当成字面命令或普通文本标签，而不是映射到 `AskUserQuestion` 或普通提问。

`using-tool` 应阻止的行为：不加载 runtime 映射、直接按字面解释代称。

### 场景 C：缺失等价能力时假装成功

任务：skill 要求维护 `todo`，目标 runtime 没有任务列表工具。

预期无技能失败：agent 假装已调用任务工具，或输出不存在的 tool call。

`using-tool` 应要求：先寻找最近等价能力；没有时降级为 Markdown todo 或明确说明限制，不能声称调用了不存在的工具。

## 验证

已运行仓库验证命令：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

结果：通过。

```text
Validation passed for one plugin with user-only skills: coding-workflow, idea-shaping, team-memory, writing-skills; model-invocable skills: using-tool.
```
