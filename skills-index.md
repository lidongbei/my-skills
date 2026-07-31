# Skills Index

Total skills: 8

Invocation modes:

- `coding-workflow`, `generating-reqable-docs`, `idea-shaping`, `session-handoff-load`, `session-handoff-save`, `team-memory`, and `writing-skills` are user-only skills: they require explicit user invocation and include `disable-model-invocation: true` so the model cannot invoke them on its own.
- `using-tool` is model-invocable and mandatory before using any skill from this plugin: agents must load it first, then load the runtime mapping file for the current agent/runtime.

- [coding-workflow](skills/coding-workflow/SKILL.md) — Use only when the user explicitly invokes `/my-skills:coding-workflow`, invokes `/coding-workflow`, or explicitly instructs the agent to use `coding-workflow`.
- [generating-reqable-docs](skills/generating-reqable-docs/SKILL.md) — Use only when the user explicitly invokes `/my-skills:generating-reqable-docs`, invokes `/generating-reqable-docs`, or explicitly instructs the agent to generate a Reqable Collection interface document.
- [idea-shaping](skills/idea-shaping/SKILL.md) — Use only when the user explicitly invokes `/my-skills:idea-shaping`, invokes `/idea-shaping`, or explicitly instructs the agent to use `idea-shaping`.
- [session-handoff-load](skills/session-handoff-load/SKILL.md) — Use only when the user explicitly invokes /my-skills:session-handoff-load, invokes /session-handoff-load, or explicitly instructs the agent to use session-handoff-load.
- [session-handoff-save](skills/session-handoff-save/SKILL.md) — Use only when the user explicitly invokes /my-skills:session-handoff-save, invokes /session-handoff-save, or explicitly instructs the agent to use session-handoff-save.
- [team-memory](skills/team-memory/SKILL.md) — Use only when the user explicitly invokes `/my-skills:team-memory`, invokes `/team-memory`, or explicitly instructs the agent to use `team-memory`.
- [using-tool](skills/using-tool/SKILL.md) — Use when using any skill from this plugin, before executing plugin skill instructions, or when adapting tool-use instructions between Claude Code, Codex, or another agent runtime.
- [writing-skills](skills/writing-skills/SKILL.md) — Use only when the user explicitly invokes `/my-skills:writing-skills`, invokes `/writing-skills`, or explicitly instructs the agent to use `writing-skills`.
