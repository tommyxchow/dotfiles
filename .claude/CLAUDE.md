## Environment

- Use `pnpm` / `pnx` (aliases: `pnpm dlx`, `pnpx`), never `npm` / `npx` / `yarn`. All three dlx forms honor `minimumReleaseAge` since pnpm 11, so same-day packages wait out the 24h window. Corepack shims only `pnpm`/`pnpx` — if `pnx` isn't on PATH, use `pnpm dlx`.
- For semantic navigation, prefer precise code-aware lookups (language server / semantic search) over plain text grep when available — e.g. find references before a signature change, check inferred types, resolve definitions through re-exports.

## Behavior

- When asked to enumerate or add items ("what are all the X"; adding to a list/source like models, emotes, constants), be exhaustive — list ALL relevant ones, not just the first few; read the full source completely when editing code.
- Before using a framework/library API, check the installed version (package.json, pubspec.yaml) and prefer version-specific docs when they exist — otherwise the changelog/release notes for that version or the vendored source. Don't rely on training data.
- When web-searching, prefer official/primary sources (vendor docs, specs, changelogs, project GitHub incl. issues/discussions) over SEO/AI-generated/opinion blogs — use the latter only as a pointer to a primary source.
- Clean up temp files and scripts created for iteration at the end of the task.
- Don't install or swap dependencies/libraries without asking first.
- When new code supersedes existing functionality, find and remove what it makes redundant — don't leave dead paths behind.
- When a shared pattern changes (a border style, a header treatment, a component swap), update every occurrence in one pass — don't half-migrate the codebase one spot at a time.

## Code

- TypeScript: prefer named exports — use a default export only where a framework/tool requires one (e.g. Next.js `page`/`layout` and other special files, config files, `React.lazy`/`dynamic` targets, Storybook `meta`).
- Reach for `satisfies` (or `as const satisfies` for literal-exact inference) when you want a value checked against a type without widening its inferred type — e.g. config/lookup objects. Not a blanket replacement for annotations.
- For large or loosely-typed third-party payloads, parse with Zod down to the fields you use before passing to the client. Skip it for your own already-typed endpoints.
- Token storage default: access token in memory, refresh token in an HttpOnly + Secure + SameSite cookie, not localStorage; re-mint on load and pair cookie auth with anti-CSRF. Relax only for genuinely non-sensitive tokens.
- Prefer types that flow from the source: infer and thread generics so call sites stay typed without restating. Avoid `as`/casting and non-null `!` to paper over a type — fix it at the definition. Casting is fine for genuinely unrepresentable cases (`as const`, narrowing `unknown` after a real check, test fixtures).
- No TS enums — use `as const` objects or union types. Prefer discriminated unions over boolean flags for state with mutually exclusive shapes.
- Avoid `any`; if it's genuinely unavoidable, leave a one-line comment saying why.
- Use `kebab-case` for all files and dirs, including component files.

## Design & UX

- Respect `prefers-reduced-motion` for non-essential motion — reduce or replace it, don't necessarily strip.
- Keep keyboard focus visible — never remove focus outlines without an equally clear replacement.
- Underlines for navigation/destinations, buttons for actions; alerts for must-address attention, bottom sheets for dismissible content.
- UI copy: natural, HIG-style language ("What's the reason?" over "Report"). Default to sentence case for sentence-like phrases, Title Case for short labels and product names.
- Data-fetching UI handles loading, error, AND empty states (empty is the one that gets forgotten); design for degraded states too — slow/unstable/offline connections and requests that can hang (give network calls timeouts).
- Prefer discoverable, visible affordances over actions hidden behind long-press, hover-only, or gesture-only interactions — a visible control (or a tap that reveals a sheet/tooltip) beats a hidden one.
- Nested rounded corners should be concentric: inner radius = outer radius − the padding between them (a card's child rounds less than the card). Don't reuse the parent's radius on a padded child — compute it (`calc()`, e.g. Tailwind `rounded-[calc(var(--radius)-4px)]`) or step down a size token.

## Workflow

- Run targeted tests for relevant files, not the full suite.
- Conventional commits: `type(scope): description` — lowercase, no period, tightly scoped. Append `!` before `:` for breaking changes.
- New branches: prefix with `tc/` (e.g., `tc/add-auth-flow`).

## GitHub operations

- For GitHub writes (creating PRs, submitting reviews, opening/updating issues, posting comments), prefer the **github MCP** when available — its structured params handle multi-line bodies and special characters cleanly — otherwise use `gh`.
- Prefer **`gh`** with `--json field1,field2 --jq '...'` for reads and bulk filtering: listing PRs (`gh pr list`), listing issues (`gh issue list`), watching CI (`gh run watch`, `gh run view <id> --log`), searching (`gh search code|repos|issues`). Tight output, fast, composable with shell pipelines.
- Use `git` only for local repo operations (commit, branch, push, rebase). Never shell out to `git` for GitHub-specific actions like creating PRs.

## Output & writing

These apply to **posted/external output**: PR titles and bodies, inline review comments, commit messages, code comments that ship, and anything posted to chat platforms, tickets, or external services. In-session chat and internal scratch notes are exempt.

- **No em dashes (`—`).** They're the most obvious AI writing tell. Use a normal hyphen (`-`), comma, period, colon, or parentheses instead. Hyphen is the default when you'd naturally dash while typing. Exception: em dashes inside quoted string literals or code blocks (UI copy, regex, rule definitions) are fine.
- **Casual, lowercase teammate voice.** PR bodies and review comments read like Slacking a colleague, not docs or marketing. Lowercase the first letter when natural; capitalize proper nouns, acronyms, and headers. Commit subjects stay conventional-commit style (see Workflow).
- **No vague filler.** Skip "This PR...", "This change...", "improves code quality", "enhances UX", "streamlines the workflow". State the specific change instead: "drops the redundant null check at `foo.ts:42`".
- **Lead with the answer.** Bottom line first; reach for structure (tables, numbered lists) only when the content is genuinely structured. (In Claude Code, the "Structured & Scannable" output style enforces this for in-session replies; this section covers posted artifacts too.)
