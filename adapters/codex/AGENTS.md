# Codex Adapter

This repository is one plugin containing `SKILL.md`-based skills.

Codex user-level skills normally live at:

```text
~/.codex/skills
```

Codex can also read the shared cross-runtime skills path:

```text
~/.agents/skills
```

## Install

Copy or symlink selected skill directories from:

```text
D:\AI\my-skills\skills\<skill-name>
```

into one of:

```text
~/.codex/skills/<skill-name>
~/.agents/skills/<skill-name>
```

Current approved skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`
- `using-tool`

## Tool Mapping Notes

Before using any skill from this plugin in Codex, load `using-tool`, then use:

```text
skills/using-tool/runtimes/codex.md
```

That runtime file maps portable tool-action instructions to Codex tools or interaction patterns, including usage examples, parameters where applicable, and fallbacks.

Use each skill's intent and workflow, not necessarily its exact Claude Code tool names or parameter formats.
