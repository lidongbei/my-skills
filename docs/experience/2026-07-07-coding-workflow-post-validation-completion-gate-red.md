# coding-workflow 完成验证后收尾 ask RED 记录

日期：2026-07-07

## 背景

用户要求修改 `coding-workflow`：完成代码修改并输出 `Validation` 后，如果工作区仍有未提交变更，不能直接结束，也不能静默提交；必须使用 `using-tool` 的 `ask` 让用户选择收尾动作。

## RED 场景

Agent 完成实现后输出：

```markdown
已完成。

变更内容：
- DeptController ...
- LocalDeptQueryService ...

Validation
- Ran: mvn -pl cnapbp-example -am -DskipTests compile
- Result: BUILD SUCCESS
- Not run: 单元测试
- Reason: 按项目规则，Java + Maven 重任务完成后做统一编译验证，跳过单元测试。
```

同时工作区仍有未提交变更：

```text
M cnapbp-example/src/main/java/.../DeptController.java
M cnapbp-example/src/main/java/.../DeptExtendedMapper.java
M cnapbp-example/src/main/resources/mapper/DeptExtendedMapper.xml
```

## 当前技能缺口

当前 `coding-workflow` 只要求最终报告包含 `Validation`，没有规定完成验证后如何处理未提交变更，也没有规定完成结果记录路径。

因此 agent 可能：

- 输出“已完成”后直接结束；
- 自行决定是否 commit；
- 随意把结果记录到计划、经验文件或其他位置；
- 没有让用户选择是否提交、记录结果、或保持现状。

## 失败判定

如果 agent 在修改和验证完成后发现未提交变更，却没有使用 `using-tool` 的 `ask` 提供以下四个选项，则判定失败：

1. 提交
2. 记录结果并提交
3. 记录结果
4. 保持现状

如果用户选择记录结果，但 agent 没有把结果保存到 `docs/complete/YYYY-MM-DD-<topic>.md`，或有计划文件却没有在完成记录开头链接计划，也判定失败。

## 预期 GREEN 行为

修改后，agent 在输出 `Validation` 后应使用 `ask`：

```text
修改和验证已完成，请选择下一步（必须明确选择其中一项）：
```

选项：

1. `提交`
2. `记录结果并提交（保存到 docs/complete/YYYY-MM-DD-<topic>.md）`
3. `记录结果（保存到 docs/complete/YYYY-MM-DD-<topic>.md）`
4. `保持现状`

选择 2 或 3 时，完成结果记录必须保存到 `docs/complete/YYYY-MM-DD-<topic>.md`；如果本轮有 `docs/plans/YYYY-MM-DD-<topic>.md` 计划文件，完成记录开头必须链接该计划。
