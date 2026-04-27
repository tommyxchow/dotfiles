## Environment

- Use `pnpm` / `pnpx`, not `npm` / `npx` / `yarn`.
- After UI changes, use the chrome-devtools MCP to navigate to the affected page, screenshot it, and verify against intent — don't claim a UI feature is done without visual verification.
- Prefer LSP over Grep for semantic navigation: `findReferences` for signature changes, `hover` for inferred types, `goToDefinition` through re-exports.

## Behavior

- Stay scoped: only make changes directly requested or clearly necessary. Don't add docstrings/comments/types to code you didn't change. Don't add error handling for scenarios that can't happen — only validate at system boundaries (user input, external APIs). Don't design for hypothetical future requirements.
- When asked to add items to a list (models, emotes, constants), read the source completely and add ALL relevant items, not just the first few.
- Before using a framework/library API, check the installed version (package.json, pubspec.yaml) and web-search version-specific docs — don't rely on training data.
- When asked to "verify" or "vet", use web search to check current docs and flag anything suspicious — including what's missing, not just what's wrong.
- Before swapping a component's underlying library or layout strategy, ask first.
- Clean up temp files and scripts created for iteration at the end of the task.

## Delegation

- Parallelize tool calls when independent (within one message). Spawn subagents (Task tool) for fan-out across files/repos, independent workstreams, or research that would clutter context.
- Auto-invoke loaded skills and MCPs proactively when their description matches the task (e.g., `vet` before commits or to verify recent claims, `chrome-devtools` for UI verification, `understand` for unfamiliar repos) — don't reinvent workflows that exist. Opus 4.7 under-uses these by default.

## Code

- TypeScript: named exports only — no default exports except where Next.js requires them (page, layout, route).
- React state: useState → Jotai → Context, in that order.
- React: when UI visibility depends on an async query (modals, banners, gates), default to hidden and only show after loading completes — never let `defaultValue` flash UI while the query is in flight.

## Code Review

- Surface ALL findings labeled `critical` / `major` / `minor` — severity is for ranking, not filtering. Don't drop low-severity findings to "be conservative" or "avoid nits."

## Workflow

- Run targeted tests for relevant files, not the full suite.
- Conventional commits: `type(scope): description` — lowercase, no period, tightly scoped. Append `!` before `:` for breaking changes.
- New branches: prefix with GitHub username (e.g., `tommyxchow/add-auth-flow`). Run `gh api user --jq .login` to find it.

## Never

- Never install a new dependency without asking first.
- **IMPORTANT**: Never `git push` without first confirming `pwd` and the target remote, then waiting for approval — pushing to the wrong repo in a multi-repo workflow has caused incidents.
