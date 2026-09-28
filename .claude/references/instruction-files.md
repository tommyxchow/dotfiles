# Editing instruction files and skills

Read this before editing the global instruction file (`.claude/CLAUDE.md` in the dotfiles repo), a repo AGENTS.md / CLAUDE.md, or a first-party skill, as the global instructions say.

The global file goes to every harness (Claude Code, Cursor, OpenCode 2, Grok Build) and every model, strong or weak:

- Include only what a model can't infer: project facts, commands, and gotchas. Leave out style a linter already enforces and conventions that can be read from the code itself.
- Write for the weakest model while keeping it cheap for the strongest: constrain outcomes, not step-by-step process. Use one idea per bullet and a short example where it helps, and nothing as vague as "write clean code".
- Write it in the voice you want back. Models tend to copy the register and formatting of their instructions, so a rule about plain language is written in plain language. Where a skill describes a report, spell the shape out in full sentences with a short example, never as fragments to fill in.
- Match the voice Anthropic uses in the sample system-prompt text of its own prompting guides: full sentences in plain words, the reason next to the rule, what to do before what to avoid, the concrete behavior named rather than described in general, and a calm tone without capitals or stacked nevers.
- Examples teach shape, not today's versions. Don't freeze an API name, release candidate, or date in a global file; look it up. `refresh/references/stacks.md` may hold stack gotchas, and it still gets pruned when touched.
- A pattern earns a rule; a single observation doesn't. Add a rule after the same mistake happens twice, or when I state a preference. If the rule then fires too often, add a skip rather than more style.
- Prune lines that went stale whenever the file is touched. Size costs adherence too (Anthropic targets under 200 lines per file), but cut a live rule only when it is duplicated or can move to a file an always-loaded line tells the agent to read at an observable moment, never just to hit a number.
- A rule removed from an always-loaded file is named in the commit body, with where it lives now or why it is dropped. A slim that can't say that for a line keeps the line.
- Multi-step playbooks that only run in one repo live as `docs/` in that repo, not as global skills.
- Repo-specific numbers, like a slow first compile or the usual CI time, belong in that repo's AGENTS.md.
- A rule only fires from a file that is always loaded, or from a file an always-loaded line tells the agent to read at an observable moment, like these reference files. Anything else in a `docs/` playbook or a skill body is a note until an agent goes looking for it, so a gate that has to hold every session belongs in the global file.
- Skills take their arguments as plain words, never `--flags`. Scope keywords like `branch`, `all`, or `pr <number>` are right; a `--fix` switch is not.

Skills follow the example and prune rules above, and they may keep step-by-step playbooks. Their routing lives in each skill's description, not in the global file. Communication and Session flow live in the global file, and of any two instruction files, the more specific one cites the broader one instead of restating or restyling it.
