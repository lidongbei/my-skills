# coding-workflow 完成门选项顺序与未初始化 git 提示 RED 记录

日期：2026-10-28

## 背景

用户对 `coding-workflow` 步骤 8（完成验证后的收尾门）提出两点修改：

1. 「启动开发环境」是完成门新增的验收辅助项，但被放在了第 1 位，用户要求它排在最后。
2. 项目还不是 git 仓库时，完成门的「提交」「记录结果并提交」仍按原样出现，选中后只是被 `Output Root` 的 git 规则静默跳过，用户要求改为提示初始化 git，而不是给出一个无法执行的提交选项。

## RED 场景

项目目录没有 `.git`。Agent 完成修改并输出 `Validation` 后，按技能弹出完成门：

```text
修改和验证已完成，请选择下一步（必须明确选择其中一项）：
1. 启动开发环境
2. 提交
3. 记录结果并提交（保存到 .agent-output/complete/YYYY-MM-DD-<topic>.md）
4. 记录结果（保存到 .agent-output/complete/YYYY-MM-DD-<topic>.md）
5. 保持现状
```

用户选择「提交」后，Agent 执行 `git status` 失败，才想起项目不是 git 仓库；技能对这种情况只写了「跳过提交并说明」，没有初始化选项，也没有在弹门前检测仓库状态。结果是选项承诺了做不到的动作，用户还得重新选一次。

## 当前技能缺口

| 缺口 | 后果 |
|---|---|
| 验收辅助项排在第 1 位 | 用户先看到的是「启动开发环境」，容易误把它当成收尾动作，提交/记录选择被推到后面 |
| 弹门前没有检测提交目标仓库的 git 状态 | 非 git 项目仍看到「提交」选项，选中后才静默跳过 |
| 非 git 情况没有初始化选项 | 用户想提交时无路可走，只能手动 `git init` 后重新触发 |
| 非 git 时的规则只写「跳过提交」 | 无法区分「用户不想初始化」与「技能没有提示初始化」 |

## 预期 GREEN 行为

弹完成门前先用 `run` 执行 `git -C "<repository>" rev-parse --is-inside-work-tree`，据此选择门禁集合。

工作仓库是 git 仓库时，按以下顺序给出选项（验收辅助项在最后）：

```text
1. 提交
2. 记录结果并提交（保存到 <output root>/complete/YYYY-MM-DD-<topic>.md）
3. 记录结果（保存到 <output root>/complete/YYYY-MM-DD-<topic>.md）
4. 保持现状
5. 启动开发环境
```

工作仓库不是 git 仓库时，用初始化选项替换前两项，其余选项含义不变：

```text
1. 初始化 git 并提交
2. 初始化 git、记录结果并提交（保存到 <output root>/complete/YYYY-MM-DD-<topic>.md）
3. 记录结果（保存到 <output root>/complete/YYYY-MM-DD-<topic>.md）
4. 保持现状
5. 启动开发环境
```

行为约束：

- 只有用户选中初始化选项后才执行 `git init`，不得静默初始化；
- `git init` 失败时报告失败并按对应非提交选项回退，不得声称已提交；
- 用户选择「记录结果」或「保持现状」视为拒绝初始化：不执行 `git init`，本会话不再追问，并说明改动仍未提交；
- 该门禁的 `git init` 只针对工作仓库；输出根在外部时，其记录仓库仍由 `Output Root` git 规则决定；
- 保存计划（步骤 5）的提交不在本次提示范围内，仍按现有规则静默跳过。

## 最小修正（已实施）

- `skills/coding-workflow/SKILL.md` 步骤 8：新增弹门前的 git 状态检测段；选项表重排为提交 / 记录结果并提交 / 记录结果 / 保持现状 / 启动开发环境；新增非 git 初始化选项表与 4 条规则；验收辅助段落由「Option 1」改为「Option 5」。
- `Common Mistakes`：更新「Ending with uncommitted changes」的选项顺序；新增「Offering a commit the repository cannot perform」「Initializing git silently」两行；「Letting the dev environment replace the commit gate」改为引用「启动开发环境」。

## 状态

已修改 `skills/coding-workflow/SKILL.md` 并通过 `scripts/validate.ps1`；GREEN 验证尚未执行，待用一次非 git 项目 + 一次 git 项目的完整收尾流程确认。
