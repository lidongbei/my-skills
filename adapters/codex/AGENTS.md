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
- `my-config-manager`
- `generating-reqable-docs`
- `idea-shaping`
- `subagent-takeover`
- `writing-skills`
- `using-tool`

## Tool Mapping Notes

Before using any skill from this plugin in Codex, load `using-tool`, then use:

```text
skills/using-tool/runtimes/codex.md
```

That runtime file maps portable tool-action instructions to Codex tools or interaction patterns, including usage examples, parameters where applicable, and fallbacks.

Use each skill's intent and workflow, not necessarily its exact Claude Code tool names or parameter formats.

## Output Root Configuration

`coding-workflow` and `generating-reqable-docs` share an output root. The recommended default is `<repository root>/.agent-output`, inside the working repository, so a single-folder workspace can see and manage the records. The value is stored per-developer in the git-ignored `.my-skills-local-config.md` as an `agent-output-root` managed block, read/written through the `using-tool` runtime mapping. The block also records how the records are versioned: the `Records` disposition is `ignored-in-workspace` by default, `committed-in-workspace`, `standalone-repo`, or `unmanaged`. It is never written into the shared `AGENTS.md`.
