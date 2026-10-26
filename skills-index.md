# Skills Index

Total skills: 7

Invocation modes:

- `coding-workflow`, `generating-reqable-docs`, `idea-shaping`, and `writing-skills` are user-only skills: they require explicit user invocation and include `disable-model-invocation: true` so the model cannot invoke them on its own.
- `my-init-config` is model-invocable: it configures, upgrades, or repairs this plugin's per-project configuration for the current workspace, and other plugin skills delegate their configuration writes and repairs to it.
- `subagent-takeover` is model-invocable so `coding-workflow` can route to it after the user selects the multiple-subagents execution mode; it still runs only on that route or on explicit user invocation.
- `using-tool` is model-invocable and mandatory before using any skill from this plugin: agents must load it first, then load the runtime mapping file for the current agent/runtime.

- [coding-workflow](skills/coding-workflow/SKILL.md) — Use only when the user explicitly invokes `/my-skills:coding-workflow`, invokes `/coding-workflow`, or explicitly instructs the agent to use `coding-workflow`.
- [my-init-config](skills/my-init-config/SKILL.md) — Use when configuring this plugin's per-project configuration for the current workspace, including first-time setup in a new workspace, upgrading an existing workspace, repairing missing, malformed, duplicated, or legacy configuration blocks, or when another plugin skill needs a managed configuration block created or repaired.
- [generating-reqable-docs](skills/generating-reqable-docs/SKILL.md) — Use only when the user explicitly invokes `/my-skills:generating-reqable-docs`, invokes `/generating-reqable-docs`, or explicitly instructs the agent to generate a Reqable Collection interface document.
- [idea-shaping](skills/idea-shaping/SKILL.md) — Use only when the user explicitly invokes `/my-skills:idea-shaping`, invokes `/idea-shaping`, or explicitly instructs the agent to use `idea-shaping`.
- [subagent-takeover](skills/subagent-takeover/SKILL.md) — Use when coding-workflow selected the multiple-subagents execution mode and routed here, or when the user explicitly invokes /my-skills:subagent-takeover, invokes /subagent-takeover, or explicitly instructs the agent to use subagent-takeover to split an approved plan into reviewed subtasks.
- [using-tool](skills/using-tool/SKILL.md) — Use when using any skill from this plugin, before executing plugin skill instructions, or when adapting tool-use instructions between Claude Code, Codex, or another agent runtime.
- [writing-skills](skills/writing-skills/SKILL.md) — Use only when the user explicitly invokes `/my-skills:writing-skills`, invokes `/writing-skills`, or explicitly instructs the agent to use `writing-skills`.
