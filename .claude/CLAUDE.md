## Environment

- Use `pnpm` / `pnpx`, not `npm` / `npx` / `yarn`.
- Prefer LSP over Grep for semantic navigation: `findReferences` for signature changes, `hover` for inferred types, `goToDefinition` through re-exports.

## Behavior

- When asked to add items to a list (models, emotes, constants), read the source completely and add ALL relevant items, not just the first few.
- Before using a framework/library API, check the installed version (package.json, pubspec.yaml) and web-search version-specific docs — don't rely on training data.
- When web-searching, prefer official/primary sources (vendor docs, specs, changelogs, project GitHub incl. issues/discussions) over SEO/AI-generated/opinion blogs — use the latter only as a pointer to a primary source.
- Clean up temp files and scripts created for iteration at the end of the task.

## Code

- TypeScript: named exports only — no default exports except where Next.js requires them (page, layout, route).

## Workflow

- Run targeted tests for relevant files, not the full suite.
- Conventional commits: `type(scope): description` — lowercase, no period, tightly scoped. Append `!` before `:` for breaking changes.
- New branches: prefix with `tc/` (e.g., `tc/add-auth-flow`).

## GitHub operations

- Prefer the **github MCP** for writes and individual operations: creating PRs, submitting reviews, opening or updating issues, posting comments. Structured params handle multi-line bodies and special characters cleanly.
- Prefer **`gh`** with `--json field1,field2 --jq '...'` for reads and bulk filtering: listing PRs (`gh pr list`), listing issues (`gh issue list`), watching CI (`gh run watch`, `gh run view <id> --log`), searching (`gh search code|repos|issues`). Tight output, fast, composable with shell pipelines.
- Use `git` only for local repo operations (commit, branch, push, rebase). Never shell out to `git` for GitHub-specific actions like creating PRs.
