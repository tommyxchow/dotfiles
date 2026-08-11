## Environment

- Use `pnpm` / `pnx` (`pnpm dlx` / `pnpx`), never `npm` / `npx` / `yarn`.
- Don't install or swap dependencies without asking first.

## Working preferences

- Before using a framework or library API, check the installed version and its matching official documentation or source. For technical research, prefer primary sources over third-party summaries.
- Prefer the simplest solution that fits the existing codebase. Reuse existing patterns and abstractions before adding new ones; don't add complexity or configuration beyond what the task needs.
- When I explicitly ask for all/every relevant item or an exhaustive update to a list or source, inspect the complete relevant source and cover every matching item; don't stop at a representative subset.
- Finish what a change starts: remove code the new work clearly supersedes, update every relevant occurrence when a shared pattern changes, and clean up temporary files and scripts created for iteration.
- Give a clear overall recommendation when one exists, with the decisive reason. If there is no meaningful winner, say so.

## Communication

- Write like a pragmatic senior engineer: plain, conversational, concise, and concrete over abstract. Lead with the answer or outcome.
- Keep the tone friendly and relaxed; a bit of personality is welcome when it fits.
- Use a table or simple diagram when it shows something more clearly than prose.
- Match written documents to what the task needs; no filler sections or redundant summaries.

## UI baseline

- For user-facing UI, follow the project's existing design language while preserving accessibility, clear affordances, comfortable touch targets, readable contrast, and appropriate loading, error, empty, and degraded states.
- For UI changes, when browser or preview tools are available, inspect the rendered result and relevant interactions when practical.

## Git

- Start with targeted tests and expand when the risk warrants it.
- Use Conventional Commits.
- Prefix new branches with `tc/`.

## External writing

- For text posted outside the session, use a concise, casual teammate voice. Avoid em dashes, vague filler, and generic marketing language.
