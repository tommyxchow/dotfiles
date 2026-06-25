## Environment

- Use `pnpm` / `pnpm dlx`, not `npm` / `npx` / `yarn`.
- For semantic navigation, prefer precise code-aware lookups (language server / semantic search) over plain text grep when available — e.g. find references before a signature change, check inferred types, resolve definitions through re-exports.

## Behavior

- When asked to add items to a list (models, emotes, constants), read the source completely and add ALL relevant items, not just the first few.
- Before using a framework/library API, check the installed version (package.json, pubspec.yaml) and prefer version-specific docs when they exist — otherwise the changelog/release notes for that version or the vendored source. Don't rely on training data.
- When web-searching, prefer official/primary sources (vendor docs, specs, changelogs, project GitHub incl. issues/discussions) over SEO/AI-generated/opinion blogs — use the latter only as a pointer to a primary source.
- Clean up temp files and scripts created for iteration at the end of the task.

## Code

- TypeScript: prefer named exports — use a default export only where a framework/tool requires one (e.g. Next.js `page`/`layout` and other special files, config files, `React.lazy`/`dynamic` targets, Storybook `meta`).

## Workflow

- Run targeted tests for relevant files, not the full suite.
- Conventional commits: `type(scope): description` — lowercase, no period, tightly scoped. Append `!` before `:` for breaking changes.
- New branches: prefix with `tc/` (e.g., `tc/add-auth-flow`).

## GitHub operations

- For GitHub writes (creating PRs, submitting reviews, opening/updating issues, posting comments), prefer the **github MCP** when available — its structured params handle multi-line bodies and special characters cleanly — otherwise use `gh`.
- Prefer **`gh`** with `--json field1,field2 --jq '...'` for reads and bulk filtering: listing PRs (`gh pr list`), listing issues (`gh issue list`), watching CI (`gh run watch`, `gh run view <id> --log`), searching (`gh search code|repos|issues`). Tight output, fast, composable with shell pipelines.
- Use `git` only for local repo operations (commit, branch, push, rebase). Never shell out to `git` for GitHub-specific actions like creating PRs.
