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

- `team-memory`
- `idea-shaping`

## Tool Mapping Notes

Some skills mention Claude Code-specific tools or concepts. In Codex, adapt actions as follows:

- Read/search files: use shell commands such as `rg`, `cat`, and `ls`.
- Edit files: use `apply_patch`.
- Track plans: use Codex plan/update mechanisms.
- Subagents: use Codex multi-agent support when available.

Use each skill's intent and workflow, not necessarily its exact Claude Code tool names.
