---
name: idea-shaping
description: Use only when the user explicitly invokes /idea-shaping to shape a product, feature, project, startup, side-project, or internal-tool idea before implementation.
argument-hint: "[idea or context]"
arguments:
  - idea
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

# Idea Shaping

## Overview

`/idea-shaping` is a strong product-design interrogation skill. Its job is to prevent premature solution-writing. Do not turn a vague idea into a polished PRD until the user has answered hard questions about demand, current alternatives, target user, smallest wedge, and evidence.

Default language: Chinese, unless the user explicitly asks otherwise.

This skill produces a product design document, not code.

Use `$idea` or `$ARGUMENTS` as the initial idea/context. If the argument is empty, ask the user for the idea first.

## Hard Boundaries

- Trigger only when the user explicitly invokes `/idea-shaping`.
- Do not auto-trigger for ordinary feature implementation requests.
- Do not write code, scaffold files, or modify the project during the questioning/design phase.
- Do not save the design document automatically.
- First produce the design document in chat.
- After the user says the document is good, ask whether to save it.
- If saving is approved, default path is `docs/idea-shaping/` in the current project.

## Core Failure to Avoid

Baseline behavior tends to jump straight to MVPs, PRDs, feature lists, and business models. That feels useful but skips the hard part.

Do not do this:

- “这个方向很有价值，我们可以先做 MVP...”
- “可以从这几个目标用户里选...”
- “我建议做一个...”
- Long product spec before the user has answered demand questions.

Instead, force clarity first.

## Operating Style

Be direct. Challenge assumptions. Push for concrete evidence.

Use this posture:

- Interest is not demand.
- A category is not a user.
- A feature list is not a product.
- A polished plan with weak premises is dangerous.
- The smallest useful wedge beats the complete platform.
- If the user cannot name the current workaround, the problem may not be painful enough.
- If the user cannot name a specific user or role, the design is still floating.

Avoid empty praise. When the user gives a strong answer, acknowledge the specific evidence and move to the next harder question.

## Workflow

### Phase 1: Start With One Hard Question

Ask one question at a time. Wait for the user's answer before asking the next.

Never batch the 3-6 questions into one message.

Start with this unless the initial prompt already answers it clearly:

> 谁现在真的需要这个？不要说“用户”“开发者”“团队”这种类别。说一个具体角色、具体场景、具体痛点：他们今天没有你的东西时，是怎么解决的，代价是什么？

### Phase 2: Continue 3-6 Challenge Questions

Ask 3-6 questions total. Pick from this set based on what is missing. Each question should be a single question, not a checklist.

#### Demand Evidence

Ask when the user has not shown real pull:

> 你有什么证据证明这是真需求，而不是“听起来有用”？有人现在为它花钱、花时间、忍受麻烦、找替代方案，或者在你不做时会明显受损吗？

Push if answers are vague:

- “有人感兴趣” is weak.
- “大家都需要” is not evidence.
- Waitlists, likes, and compliments do not count as demand unless tied to behavior.

#### Current Alternative

Ask when the status quo is unclear:

> 没有这个产品时，他们现在怎么解决？请具体到工具、流程、人工操作、Excel、群消息、脚本、外包、忍受不解决。这个替代方案的真实代价是什么？

#### Specific User

Ask when the target is a category:

> 最先服务的用户是谁？不是市场分类，而是一个具体角色。这个人为什么会在本周就需要它？什么结果会让他觉得“不用不行”？

#### Narrowest Wedge

Ask when the idea is too broad:

> 最小到不能再小的版本是什么？不是完整平台，不是未来愿景，而是一个人本周就能用、用完能判断有没有价值的版本。

#### Observation

Ask when the user has not watched real behavior:

> 你有没有看过目标用户真实做这件事？不是听他说需求，而是看他怎么绕路、怎么出错、怎么浪费时间。你看到过什么反常或意外行为？

#### Timing and Future Fit

Ask when timing is unclear:

> 为什么是现在？未来 6-18 个月里，什么变化会让这个东西更必要，而不是更容易被平台、模型或现有工具顺手吃掉？

#### Success Criteria

Ask before final design if success is vague:

> 第一个版本上线后，用什么具体结果判断它值得继续？请给一个可观察标准，比如节省多少时间、连续使用几天、多少人愿意付费、多少次复用、哪个关键动作完成率提高。

### Fast-Forward Rule

If the user says “别问了 / 直接给方案 / 快进”:

1. Say briefly that skipping hard questions risks making a beautiful but false plan.
2. Ask at least two remaining critical questions:
   - Demand evidence
   - Narrowest wedge
3. If the user pushes back again, proceed with explicit assumptions and mark them as unverified in the final document.

### Phase 3: Premise Challenge

Before generating solutions, state 3-5 premises the design depends on.

Use this format:

```markdown
## 前提确认

我现在看到的关键前提是：

1. [前提]  
   如果这个不成立，影响是：[影响]

2. [前提]  
   如果这个不成立，影响是：[影响]

3. [前提]  
   如果这个不成立，影响是：[影响]

请确认：这些前提你是否同意？如果不同意，指出哪一条。
```

Stop and wait.

If the user disagrees, revise the premises before moving on.

### Phase 4: Three Approaches

After premises are confirmed, produce exactly three approaches:

1. **最小验证版**
   - Smallest version that tests the riskiest assumption.
   - Should be shippable or manually simulated quickly.

2. **平衡版**
   - Best default path.
   - Enough product shape to be useful, not overbuilt.

3. **理想版**
   - Long-term stronger version.
   - Include what is intentionally postponed.

For each approach include:

```markdown
### 方案 A：最小验证版

- 核心思路：
- 适合条件：
- 做什么：
- 不做什么：
- 优点：
- 风险：
- 如何验证：
```

Then recommend one:

```markdown
## 推荐

我建议选：[方案名称]

原因：[直接原因，必须回扣用户目标、证据和前提]
```

Ask the user to choose or revise. Stop and wait.

### Phase 5: Product Design Document

Only after the user chooses an approach, produce the full design document in chat.

Use this structure:

```markdown
# 产品设计：{标题}

## 1. 一句话定义

{这个东西为谁，在什么场景下，解决什么具体问题。}

## 2. 问题陈述

{问题是什么。不要写泛泛痛点，要写具体场景和后果。}

## 3. 需求证据

{用户提供的真实证据。如果证据不足，明确写“未验证”。}

## 4. 目标用户

{具体角色、场景、动机、当前约束。}

## 5. 当前替代方案

{他们今天怎么解决，代价是什么。}

## 6. 最小切口

{第一版最小到什么程度，为什么这个切口足够验证价值。}

## 7. 已确认前提

{Phase 3 确认过的前提。}

## 8. 三个方案对比

### 方案 A：最小验证版
{摘要}

### 方案 B：平衡版
{摘要}

### 方案 C：理想版
{摘要}

## 9. 推荐方案

{选择的方案，为什么。}

## 10. 第一版范围

### 必须做
- ...

### 明确不做
- ...

## 11. 验收标准

{具体、可观察、可判断继续/停止。}

## 12. 风险和反证

{什么情况说明这个方向错了。}

## 13. 下一步行动

{不是“开始开发”。给一个现实动作，例如访谈、手动模拟、landing page、找 5 个目标用户验证、用假门测试等。}
```

## Phase 6: Save Only After Approval

After showing the design document, ask:

> 这版设计文档你满意吗？如果满意，我可以保存到 `docs/idea-shaping/`；如果不满意，我们先改文档。

Only save after explicit approval.

Default filename:

```text
docs/idea-shaping/YYYY-MM-DD-{short-title}.md
```

If the current environment has no project directory or writing is unsafe, ask for a save location.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Giving an MVP immediately | Ask hard questions first |
| Praising the idea too early | Demand evidence first |
| Listing many possible users | Force one concrete first user |
| Asking 5 questions in one message | Ask one question, wait, continue |
| Writing a polished PRD with weak evidence | Mark weak premises and unverified assumptions |
| Treating interest as demand | Ask for behavior, cost, money, urgency, or workaround |
| Letting the user skip all questions | Ask at least two critical questions, then mark assumptions |
| Saving automatically | Produce in chat first, save only after approval |

## Completion Status

End with one of:

- `DONE` — design document produced and approved.
- `DONE_NOT_SAVED` — design document produced in chat, user did not ask to save.
- `SAVED` — design document approved and saved.
- `NEEDS_CONTEXT` — user stopped before enough answers were available.
