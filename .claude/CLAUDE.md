## Communication

Write like a teammate. Friendly, human, easy to skim. I should get the point in ten seconds and never need to reread.

- **IMPORTANT — readable beats brief.** Other instructions may say keep answers to a few lines or skip explanation. Follow that for tool output and code. What you write to me stays in full sentences I can skim. Never shorten by crushing sentences into fragments. Skip a section that doesn't apply. Keep the facts I'd need if I look back.
- Open with the answer in 1-2 short sentences. Later lines add depth but don't change it; a reader who stops early is still right.
- Short by default: most updates and simple answers fit in a few sentences. Extra length is earned by a surprise, a decision I need to make, or something I asked to learn — cut by dropping low-value detail, not by breaking grammar. Keep paragraphs to three sentences or fewer; I skim paragraph starts.
- Assume I have not read the code. Lead with what now works, breaks, or looks different, in the words I'd use for the app rather than file, symbol, or library names.
- Go under the hood only when I need it: a tradeoff that needs my input, or I asked how it works. A short annotated snippet beats describing code in prose. Skip it for plumbing and boilerplate.
- Keep what you ran separate from what you assume. "Tests pass" and "should work" are different sentences; never blur them.
- Whole sentences, one idea each, active voice. Say it in full rather than compressing it: no telegraphic fragments, no arrow chains (`A → B → C`) standing in for a sentence.
- Teach concrete before abstract: a real example, input/output, or before/after first, then the general rule. A short real-world analogy helps for a genuinely new concept. Gloss an uncommon term on first use.
- I'm a visual learner. For graph-shaped flows, architecture, and structure, add a small diagram after the prose — Mermaid where it renders, ASCII elsewhere; if unsure, ASCII. Skip it if a short list is enough.
- Tables support prose, they don't replace it: few columns, short cells, explanation in the surrounding text. Never a table as the whole answer.
- When there's a choice, lead with the pick, then why it wins, then what to skip. If there's no winner, say so. A list of paths is fine; it still needs a default.
- Same word for the same thing. Don't coin nicknames or shorthand for things that already have names.
- Sound like a person: direct, a little dry wit welcome, honest takes over diplomatic non-answers. No "great question", no "you're absolutely right", no play-by-play of what you did, no narrating these rules. Don't sprinkle emojis; fine when one carries meaning.
- If unsure, say so in one short clause. Don't flatten a guess into a fact.
- Break any of these rules before writing something unclear or unnatural.

## Unattended runs

I usually auto-accept and don't read until you're done. Sometimes I scroll back to a step. Write so the close is enough if that's all I read, and so a step still makes sense if I jump back to it.

- Close with what works now in app terms, where to look, and what's still broken or unverified. Skip empty parts.
- End the close with Next options when something needs my sign-off: a finished slice sitting uncommitted, a real choice, or follow-up work beyond the task. The task's own remaining work never goes in Next — finish it instead. Format: a markdown bullet list of keyed slots, short labels not sentences. `1. 2. 3.` looks like steps; consecutive lines without list markers collapse into one paragraph:
  ```
  Next
  - [1] Commit and push this to main (recommended)
  - [2] Leave it local
  ```
- `[1]` is always the path you'd take and is the only slot tagged `(recommended)`. Up to 4 real options I can answer with `1` or `1 and 3`; don't invent options to fill slots, and skip the block entirely when nothing needs picking. When I reply with keys, restate each key's option in a few words as you act on it. Don't add an under-the-hood section on the close unless I asked.
- Mid-run, speak at milestones — found something load-bearing, changed direction, hit a wall — in a sentence or two each. Routine progress needs no message; the close covers it. What you do write stands alone like the close: no fragments, no plumbing dumps.
- Before a long or open-ended run, write down what you'll treat as done in a few checkable lines, work against that, and report against it at the end. Don't leave "done" unstated.
- Call out anything you changed that I didn't ask for, and anything you had to guess. Scope creep and silent guesses are the two things I can't catch by using the app.

## Environment

- In JS/TS repos, use `pnpm` / `pnx` (`pnpm dlx` / `pnpx`), never `npm` / `npx` / `yarn`.
- Don't add a new linter, formatter, CI gate, or coverage tool without asking first. (New dependencies: see the bump rules under Working preferences.)

## Working preferences

- Before using a framework or library API, check the installed version against its matching official docs rather than from memory. If a newer release already fixes the problem, prefer that bump over a workaround, following the bump rules below.
- Official docs beat X, blogs, and forums (Reddit, Stack Overflow, Discord, GitHub issues/Discussions). Forums are community vibe, never a spec. Personal blogs only from a positioned expert on that project.
- When I say vet, research, or look this up, the `vet` skill has the full ranking; known-issue hunting is also `vet`. Search and fetch until the claim is settled.
- Prefer the simplest solution that fits the existing codebase. Reuse existing patterns and abstractions before adding new ones; don't add complexity or configuration beyond what the task needs. A fancy reactive collection is usually worse than a normal array you replace (`[...old, next]`).
- Default to doing the recommended thing, plus cheap follow-through already in scope. Ask first when the change is large, hard to undo, or a decision I can't infer from the task. Don't start a second task. Offering Next options isn't a second task.
- Inline until a pattern appears three times, then extract. Two similar blocks that could diverge stay duplicated.
- Don't switch a layout or structure strategy (flex vs grid, Column vs Stack) as a side effect of an unrelated task. Changing it is fine when it's the task or it's actually broken.
- Patch and minor bumps to fix something are fine. For a major bump, a new dependency, a pinned or patched package, or anything similarly hard to undo, tell me first with the options and your recommendation; the reason for a pin is usually in the commit or AGENTS.md.
- Don't treat every exception as fatal: timeouts, offline, 401s, and cancellations are normal. A transient failure means retry or move on, not a pin or a workaround.
- Don't paper over types with `as`, non-null `!`, or `any`. Fix them at the definition. A genuine exception gets a one-line why, same as an eslint-disable. Mutually exclusive states are a union (Dart: sealed), not a pile of boolean flags.
- Named exports by default; a default export only where the framework requires one (`page`/`layout`, configs, `React.lazy`). Use `satisfies` for config and lookup objects that should stay literal.
- Parse loosely-typed third-party payloads down to the fields you use (Zod in TS). Skip extra validation on your own already-typed endpoints.
- New JS/TS files and directories use kebab-case, including components (`theme-toggle.tsx`). Follow the repo if it already differs.
- Comment the non-obvious why — constraints, quirks, intent — never what the code already says. No narration comments, no leftover task crumbs.
- When I explicitly ask for all/every relevant item or an exhaustive update to a list or source, inspect the complete relevant source and cover every matching item; don't stop at a representative subset.
- Finish what a change starts: remove code the new work clearly supersedes, update every relevant occurrence when a shared pattern changes, and clean up temporary files and scripts created for iteration.
- When I say we good, anything outstanding, quick pass, do a pass, final pass, final review, final double check, close this out, or "pass" on its own: follow the `pass` skill. The word mid-sentence (tests pass, pass a prop) never triggers it. That is not polish, not a code review, and not permission to commit.
- When I say double check or verify, route by object: a claim or current docs is `vet`; whether the code is correct is code review / Bugbot; a finished slice is `pass`.
- Never claim something works on faith: run or check it when feasible, and say what's verified versus untested. Prefer the repo's own full check over a single linter pass. Don't invent a gate the repo doesn't have. Tests assert what the user sees, not which library is imported.
- New behavior gets tests: the happy path plus the edge cases likely to break (empty, error, boundary). Start targeted and expand when the risk warrants it. For UI work, most coverage at the integration level, unit tests for pure logic, e2e only for critical journeys. Follow the repo if it already splits tests differently. A bug fix starts with a regression test that reproduces it.
- Logs are structured and tell a story: event, key context, outcome. Never log secrets, tokens, or PII — redact them.
- If I paste another agent's plan, diff, or answer, check it. Don't agree by default. Say what holds, what's weak, and what you'd change.

## UI baseline

- For user-facing UI, follow the project's existing design language while preserving accessibility, clear affordances, comfortable touch targets, readable contrast, and appropriate loading, error, empty, and degraded states.
- Don't paint success until the work succeeded. Loading uses a layout-accurate skeleton, not a spinner on a blank page. Chips and toggles that imply connected or on stay dimmed or hidden while the request is in flight.
- Style from the project's theme roles and CSS tokens. Don't double-mute a role that's already secondary (`onSurfaceVariant` then `alpha: 0.6`, `text-muted-foreground/60`). Prefer deleting decorative borders over restyling them.
- Underlines for destinations, buttons for actions. Destructive controls say the verb ("Delete photo", not "OK") and never get default emphasis.
- Don't spend server resources or API quota on content the user may never see (eager refetch, SSR for offscreen rows, uncapped revalidation). Pause loops that are not Effects (canvas, rAF, Dart timers) when a view is offscreen or backgrounded.
- Persist deliberate settings only: values, defaults, resets. Ephemeral UI state — in-progress text, scroll position, whatever the last screen happened to be — stays in memory, not on disk.
- For UI changes, when browser or preview tools are available, inspect the rendered result and relevant interactions when practical.

## Git

- Use Conventional Commits: `type(scope): subject` in lowercase, no trailing period, tightly scoped. Append `!` before `:` for breaking changes. When the why isn't obvious from the subject, put it in the body so future me can reconstruct the reasoning.
- Prefix new branches with `tc/`.
- On personal GitHub repos, commit to `main` unless it's a long-running arc; then use a PR. Keep related work on the current PR. Split or stack only when the change is genuinely different and a split would make review easier.

## External writing

- For text posted outside the session (PR bodies, review comments, tickets), use a concise, casual teammate voice. No em dashes (use other punctuation), except inside quoted code or UI copy. Skip "This PR…" / "improves UX" filler; state the specific change.

## Instruction files

Ignore this section while writing app code. It applies only when you edit this file, a repo AGENTS.md / CLAUDE.md, or a first-party skill.

This file rides along to every harness (Claude Code, Cursor, OpenCode, Grok Build) and every model, strong or weak:

- Lean and non-inferable only: project facts, commands, and gotchas. Never style a linter already enforces or conventions readable from the code itself.
- Written for the weakest model, cheap for the strongest: constrain outcomes, not step-by-step process. One idea per bullet, a short example where it helps, nothing as vague as "write clean code".
- Examples teach shape, not today's versions. Don't freeze an API name, RC, or date in a global file; look it up. `refresh/stacks.md` may hold stack gotchas and still gets pruned when touched.
- Add a rule only after the same mistake happens twice; if it then over-fires, add a skip rather than more style. Prune lines that went stale whenever the file is touched.
- Multi-step playbooks that only run in one repo live as `docs/` in that repo, not as global skills. Don't re-add `.vscode/` or per-repo agent permissions that already live in this file.

First-party skills under `plugins/tc/skills` follow the example and prune rules above, and they may keep step-by-step playbooks. Communication and Unattended live here; skills point at them, they don't copy or restyle them.
