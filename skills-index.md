# Skills Index

Total skills: 5

Invocation modes:

- `coding-workflow`, `idea-shaping`, `team-memory`, and `writing-skills` are user-only skills: they require explicit user invocation and include `disable-model-invocation: true` so the model cannot invoke them on its own.
- `using-tool` is model-invocable and mandatory before using any skill from this plugin: agents must load it first, then load the runtime mapping file for the current agent/runtime.

- [coding-workflow](skills/coding-workflow/SKILL.md) — Use only when the user explicitly invokes `/my-skills:coding-workflow`, invokes `/coding-workflow`, or explicitly instructs the agent to use `coding-workflow`.
- [idea-shaping](skills/idea-shaping/SKILL.md) — Use only when the user explicitly invokes `/my-skills:idea-shaping`, invokes `/idea-shaping`, or explicitly instructs the agent to use `idea-shaping`.
- [team-memory](skills/team-memory/SKILL.md) — Use only when the user explicitly invokes `/my-skills:team-memory`, invokes `/team-memory`, or explicitly instructs the agent to use `team-memory`.
- [using-tool](skills/using-tool/SKILL.md) — Use when using any skill from this plugin, before executing plugin skill instructions, or when adapting tool-use instructions between Claude Code, Codex, or another agent runtime.
- [writing-skills](skills/writing-skills/SKILL.md) — Use only when the user explicitly invokes `/my-skills:writing-skills`, invokes `/writing-skills`, or explicitly instructs the agent to use `writing-skills`.
