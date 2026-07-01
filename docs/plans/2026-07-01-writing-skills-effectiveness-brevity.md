# writing-skills 有效性优先于精简的修正方案

日期：2026-07-01

## 背景

在补全 `using-tool/runtimes` 指令使用样例时，用户指出最初的表格式样例“不像 `ask` 那样明确”。这暴露出 `writing-skills` 的现有约束存在误导风险：agent 可能把“最小修改”“token efficiency”“concise”执行成压缩关键指导内容，而不是保持最小行为范围。

## 失败证据

相关约束来源：

- `skills/writing-skills/SKILL.md` 中要求：不要默认把 skill 变长，优先最小修改。
- `skills/writing-skills/SKILL.md` 中有 Token Efficiency 章节，强调 token 成本和简洁。
- 方案文档 `docs/plans/2026-07-01-using-tool-runtime-examples.md` 受上述约束影响，写入“样例如果写得过长会增加 token 成本；实现时应保持表格式或短块示例”。

实际结果：

- 初版 runtime 补全偏向表格式映射，虽然短，但不够像 `ask` 的 Typical shape 一样可照着迁移。
- 用户指出明确性不足后，改成 Typical shape / 示例代码块才更符合 runtime mapping 文件的职责。

## 诊断

Diagnosis: Workflow / guidance priority conflict

根因：

- `writing-skills` 正确强调最小有效修改，但没有明确说明“最小”是行为范围最小，不是文字最少。
- Token efficiency 章节缺少反误用规则：不能为了省 token 删除让 skill 生效的关键形态、样例、schema、输出契约或决策规则。
- Match the Form to the Failure 表没有覆盖“缺少可执行细节/样例”的失败类型，导致 agent 可能用抽象表格替代具体形态。

## 决策

修改 `skills/writing-skills/SKILL.md`，保持最小范围：

1. 在 Hard Boundaries 附近补充“Effectiveness beats brevity”规则。
2. 在 Match the Form to the Failure 表中新增“Missing executable detail or examples”行。
3. 在 Token Efficiency 章节补充反误用规则：通过删重复、叙事、显而易见背景来省 token，而不是删关键示例/shape。

不修改其他 skill 行为，不新增新 skill，不改 frontmatter。

## 预期修改

### 1. Hard Boundaries 增加优先级规则

建议文本：

```markdown
- **Effectiveness beats brevity.** "Smallest change" means the smallest behavior scope, not the fewest words. If the observed failure is caused by missing concrete examples, unclear output shape, or insufficient executable detail, add the explicit shape/example needed to make agents succeed; reduce tokens by removing redundancy, not by compressing the critical guidance.
```

### 2. Match the Form to the Failure 增加失败类型

建议表格行：

```markdown
| Missing executable detail or examples | Concrete shape/example: show the minimal realistic command, schema, patch, output contract, or fallback wording agents can copy-adapt | Abstract mapping table alone when the failure is caused by agents not knowing the concrete form |
```

### 3. Token Efficiency 增加反误用规则

建议文本：

```markdown
Token efficiency must not remove the content that makes the skill work. Keep examples, schemas, output contracts, and decision rules when they are the mechanism that prevents the observed failure. Save tokens by deleting repeated explanation, narrative, or obvious background.
```

## 验证计划

修改完成后运行：

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate.ps1
```

并检查：

- `writing-skills` frontmatter 不变；
- 新规则不削弱最小修改原则，只澄清其优先级；
- 新规则不会鼓励默认写长文，而是要求关键指导必须足够明确；
- `using-tool` 这类 reference/runtime mapping 场景能自然导向 Typical shape，而不是抽象表格。

## 自审

- 是否解决真实失败：是。直接对应本次“表格太抽象、不如 ask 明确”的问题。
- 是否过度扩张：否。只改 `writing-skills` 的指导优先级和失败类型分类。
- 是否改变 skill 触发：否。不改 frontmatter，不扩大触发。
- 风险：措辞若过强可能被误解成“越详细越好”。因此文本必须保留“smallest behavior scope”和“delete redundancy”的限制。
