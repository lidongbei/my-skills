# coding-workflow Decision Review ask 输出契约 RED 记录

日期：2026-07-07

## 背景

用户要求修改 `coding-workflow`：当用户在计划响应门选择“逐个确认问题”后，后续每个 Human-required decision 也必须使用 `using-tool` 的 `ask` 呈现选项。

## RED 场景

用户已经在计划响应门选择：

```text
逐个确认问题
```

Agent 随后输出普通 Markdown 决策块：

```markdown
Decision: 是否同步重构 /api/v1/dept/user-tree 对应的 DeptController#getUserDeptTree？

Impact:
- 如果同步重构，UserDeptQueryServiceImpl 也需要从本地 Service 获取组织树，避免仍依赖 RBAC SDK 的 deptService.getDeptTree()，改动范围更完整但风险更大。
- 如果不同步重构，本次只改你点名的 DeptController#getDeptTree，范围更小，但系统内会同时存在“组织树接口走本地表、用户组织树仍走 RBAC SDK”的行为差异。

Options:
1. 只重构 getDeptTree
2. 同步重构 getUserDeptTree

My lean:
推荐选 1. 只重构 getDeptTree，因为你当前明确点名的是 DeptController#getDeptTree，先聚焦降低风险。
```

## 当前技能缺口

当前 `Decision Review` 只要求：

```text
Present Human-required items one at a time. Wait for an answer before moving to the next.
```

但没有明确要求每个 Human-required item 必须通过 `using-tool` 的 `ask` 来呈现选项。

## 失败判定

如果 agent 对 Human-required decision 只输出 Markdown 问题块，而没有使用 `ask` 提供结构化选项并等待用户选择，则判定失败。

## 预期 GREEN 行为

修改后，agent 应把该决策转换为 `ask`：

- question：`是否同步重构 /api/v1/dept/user-tree 对应的 DeptController#getUserDeptTree？`
- options：
  1. `只重构 getDeptTree（推荐）`
  2. `同步重构 getUserDeptTree`
- descriptions：写入各选项影响和权衡。

每次只问一个 Human-required decision，等待回答后再继续下一个。
