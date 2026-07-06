# Shared Agents Adapter

Use this directory as guidance for agent tools that support portable `SKILL.md` skills.

Recommended shared location:

```text
~/.agents/skills
```

Install by copying or symlinking selected direct skill directories from:

```text
D:\AI\my-skills\skills\<skill-name>
```

into:

```text
~/.agents/skills/<skill-name>
```

Current approved skills:

- `coding-workflow`
- `team-memory`
- `idea-shaping`
- `writing-skills`
- `using-tool`

Each skill directory must keep this shape:

```text
<skill-name>/SKILL.md
```

If a tool does not support automatic skill discovery, point it to `skills-index.md` or the relevant `skills/<skill-name>/SKILL.md` manually.

Before using any skill from this plugin, load `using-tool`, then load the runtime mapping file that matches the current agent tool. The runtime file maps portable tool-action aliases such as `ask`, `read`, `find`, `edit`, `run`, `todo`, `agent`, and `check` to that runtime's actual tools or interaction patterns.
