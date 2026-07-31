---
name: generating-reqable-docs
description: Use only when the user explicitly invokes /my-skills:generating-reqable-docs, invokes /generating-reqable-docs, or explicitly instructs the agent to generate a Reqable Collection interface document.
disable-model-invocation: true
---

# 生成 Reqable 接口文档

根据用户提供的接口清单、现有 Reqable Collection 或参考文件，生成可导入 Reqable 的 `.reqable_collection.json` 文件。输出目标是**结构兼容 Reqable Collection 3.0 的 JSON**，不是 Markdown 接口说明，也不是把参考文件中的病案稽查业务数据原样复制成新接口。

## 硬边界

- 只在用户明确调用本技能或明确要求使用本技能时执行；普通的 API 文档请求不自动触发本技能。
- 生成前用 `read` 读取用户指定的参考文件，并用 `check` 确认它是合法 JSON；参考文件只作为结构样例，不能把其中的账号、token、Cookie、计划 ID、任务 ID、批次号或真实环境地址默认为新接口数据。
- 缺少环境值时使用显式占位符，例如 `<<BASE_URL>>`、`<REQUIRED_PLAN_ID>`，并在完成报告中列出待替换项；不要为补齐字段凭空猜测业务值。
- 不调用真实接口、不生成响应示例、不推断参考文件没有提供的鉴权或业务规则。
- 输出路径或文件名未指定时，使用用户当前项目中明确约定的位置；没有约定时先用 `ask` 询问一次。覆盖已有文件前必须用 `read` 检查目标并取得明确许可。覆盖操作应先在内存中完成全部校验，再写入临时文件；写后重新读取并解析确认成功后，才原子替换目标文件。任一输入、序列化、校验或写入步骤失败，都不得截断或覆盖原文件，也不得宣称成功。

## 输入契约

先整理接口定义。每个 API 至少需要：名称、HTTP 方法和 URL；如用户提供，还要保留请求头、查询参数、请求体、鉴权、脚本、说明、设置和所属文件夹。若用户只给出参考 Collection，按其实际节点生成等结构副本，但必须为新节点生成新的 UUID，并清除或替换其中的账号、凭据、业务 ID、批次号和环境专属地址；不得把“等结构”理解为逐字复制整个文件。若用户给出新增或修改清单，只改变明确指定的节点。

缺少必需的名称、方法或 URL 时，用 `ask` 一次性列出缺项；不要用参考文件中的业务值猜测。可安全继续的缺省值使用 Reqable 结构默认值，并标注为默认值而不是接口事实。

## 生成规则

1. 根对象使用 Reqable Collection 3.0 结构：
   - `version: "3.0"`
   - `info: "Reqable Collection APIs"`
   - `type: "collection"`
   - 新的全局唯一 `id`
   - `items`、`properties`、`revision`（默认 `-1`）
2. 递归遍历 `items`，同时支持 `type: "folder"` 和 `type: "api"`；不要假定所有 API 都在固定文件夹中，也不要按文件夹名称写死逻辑。
3. 文件夹保留 `id`、`items` 和 `properties`；API 保留参考中存在的结构字段：
   `id`、`type`、`name`、`method`、`url`、`headers`、`showInternalHeaders`、`body`、`script`、`authorization`、`documentation`、`settings`。
4. 每个新节点生成合法且全局唯一的 UUID；不能复制参考节点 ID，也不能为了“看起来一样”复用同一个 ID。
5. 原样保留用户明确提供的 URL、方法、参数名、请求头和示例值。URL 基地址可以使用 `<<BASE_URL>>` 等占位符。
6. 区分普通 headers 与 Reqable 的 `internal: true` headers；不要删除或把内部头改成业务头。
7. 有请求体时使用 `body.mode: "json"`，把对象、数组或字符串序列化为 `body.text`；无请求体时使用 `body.mode: "none"`。不要因为方法是 POST 就强行添加 body，也不要把数组改成对象。
8. 仅在用户明确提供鉴权信息时填充鉴权；否则保留安全的 `authorization.mode: "inherit"` 或参考文件明确指定的模式。禁止写入真实凭据。
9. 保留 `script`、`documentation`、`settings` 等 Reqable 元数据；未知扩展字段在不改变语义的前提下原样保留，不要为“简化”删除它们。
10. 以 UTF-8 写出 JSON。JSON 的字符串转义必须由序列化工具完成，不能手工拼接导致 `body.text` 或中文失效。

## 最小结构模板

下面的模板展示结构，不是业务接口答案；实际输出必须根据用户输入替换名称、方法、URL 和 body，并为所有节点生成新 ID。

```json
{
  "version": "3.0",
  "info": "Reqable Collection APIs",
  "type": "collection",
  "id": "<NEW_COLLECTION_UUID>",
  "items": [
    {
      "type": "folder",
      "id": "<NEW_FOLDER_UUID>",
      "items": [
        {
          "id": "<NEW_API_UUID>",
          "type": "api",
          "name": "示例接口",
          "method": "POST",
          "url": { "base": "<<BASE_URL>>/api/v1/example" },
          "headers": [
            { "key": "Content-Type", "value": "application/json", "internal": true }
          ],
          "showInternalHeaders": false,
          "body": { "mode": "json", "text": "{\n  \"example\": \"value\"\n}" },
          "script": { "wordWrap": true, "isEnabled": false },
          "authorization": { "mode": "inherit" },
          "documentation": { "content": "", "updatedAt": null },
          "settings": {
            "protocol": 0,
            "proxy": { "type": "unset", "value": "" },
            "maxRedirect": 10,
            "autoSave": true,
            "autoCookie": true,
            "autoId": true,
            "sslVerify": true,
            "omitEqualSign": true,
            "urlAutocomplete": true
          }
        }
      ],
      "properties": {
        "name": "示例目录",
        "query": [],
        "headers": [],
        "script": { "wordWrap": true, "isEnabled": false },
        "authorization": { "mode": "inherit" },
        "documentation": { "content": "", "updatedAt": null }
      }
    }
  ],
  "properties": {
    "name": "示例集合",
    "query": [],
    "headers": [],
    "script": { "wordWrap": true, "isEnabled": false },
    "authorization": { "mode": "inherit" },
    "documentation": { "content": "", "updatedAt": null }
  },
  "revision": -1
}
```

## 生成后校验

使用 `check`，按顺序确认：

- 输出可被 JSON 解析，根 `version` 为 `3.0`、`type` 为 `collection`，且存在 `id`、`items`、`properties`。
- 递归节点只有已知的 `folder`/`api` 类型；文件夹和 API 的 ID 全局唯一且非空。
- 每个 API 有非空 `name`、合法 HTTP `method`、非空 `url.base`、数组类型 `headers` 和 `body`，并保留脚本、鉴权、说明及设置结构。
- `body.mode` 只能是 `json` 或 `none`；`json` 模式的 `body.text` 再次解析后必须合法，`none` 模式不得凭空添加业务 body。
- 未出现 token、密码、Cookie 或未获用户明确授权的环境专属值；所有占位符和未补字段都已列出。
- 若按参考文件完整复制结构，递归计数应为 4 个文件夹、23 个 API（除非用户明确要求增删）；不要只检查顶层节点。

校验失败时不要写入或宣称已生成文件；先修正数据并重新校验。最终报告使用以下格式：

```markdown
文件：<输出路径>
文件夹：<数量>
API：<数量>
待替换占位符：<列表或“无”>
校验：JSON、Reqable 结构、ID 唯一性、请求体均通过/未通过（说明原因）
```

## 常见错误

| 错误 | 修正 |
|---|---|
| 把结果写成 Markdown 或自定义 JSON | 输出完整 Reqable Collection 3.0 根结构 |
| 只遍历固定文件夹 | 递归处理每个 `items`，保留根级 API |
| 所有接口都生成 POST 对象 body | 按输入保留方法及 `json`/`none`，支持数组 body |
| 复制参考 UUID 或示例账号 | 生成新 UUID；账号和业务 ID 改为用户值或占位符 |
| 手工拼接 JSON 字符串 | 使用序列化后再解析校验 |
| 生成后直接声称成功 | 先完成结构、body、敏感信息和计数校验 |

## Red Flags - STOP

- “参考文件已经能用，所以直接复制 ID 和账号。”
- “为了省时间，所有接口统一 POST + JSON body。”
- “Reqable 能容忍，校验可以省略。”
- “用户没给地址，就替他们猜一个真实服务地址。”

遇到这些想法，停止并回到对应的生成规则与校验步骤。
