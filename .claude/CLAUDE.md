IDE: VSCode. Use pnpm, not npm.

# Author Preferences

## Behavior

- When asked to add items to a list (models, emotes, constants, etc.), be thorough on the first pass. Read the source data completely and add ALL relevant items, not just the first few.
- In plan mode, interview thoroughly — ask about technical implementation, UI/UX, tradeoffs, and edge cases before coding. Don't begin implementation until all important details are resolved. For refactors: summary → trade-offs → next steps.
- When implementing new code, search the codebase for existing usages and follow established patterns.
- When new code supersedes existing functionality, find and remove everything it makes redundant.
- When asked to "verify", always use web search to check current documentation and sources before responding. Do not rely solely on training data.
- Default to searching for factual questions, technical details, framework/library APIs, and version-specific behavior. Only skip search if the answer is absolutely foundational and unchanging.
- Favor parallel tool calls and subagents when tasks are independent.

## Code Opinions

- `UPPER_SNAKE_CASE` for constants
- Derive state where possible — avoid duplicating what can be computed
- Inline until a pattern repeats 3+ times, then extract
- For new components/hooks/APIs: include a usage example

### TypeScript

- Named exports only — no default exports except where required by Next.js (page, layout, route, etc.)
- `satisfies` over `as` for type validation
- `??` over `||`; explicit null checks over loose truthiness
- Avoid enums — use `as const` objects or union types

### React

- State progression: useState → Context → Zustand as needed
- Avoid `useRef` unless DOM access or imperative work
- Extract related/grouped logic (state, effects, handlers) into dedicated custom hooks when it improves readability — keep components focused on rendering

## Quality Priorities

In order: **correctness → user experience → simplicity → security**.

Not priorities: WCAG compliance (easy wins only), public accessibility, SEO, progressive enhancement.

## Tool Preferences

- Prefer LSP over Grep for semantic navigation:
  - `findReferences` before changing a function/component signature (no false positives)
  - `hover` to resolve inferred/computed types (Zustand stores, Zod schemas, AI SDK generics)
  - `goToDefinition` to navigate through re-exports and barrel files
  - `incomingCalls`/`outgoingCalls` to trace call chains across routes, hooks, components
- When debugging third-party libraries, **read the extension source in `node_modules` first** — don't speculate about behavior. Check for validation, protocol restrictions, and attribute filtering before writing code.

## UI Patterns

- Adapt external designs (Figma specs, reference implementations) to codebase conventions before implementing. External descriptions may contain AI-generated rough drafts — always cross-reference against actual codebase patterns.
- (React) When UI visibility depends on an async query (modals, banners, gates), default to hidden and only show after loading completes — never let `defaultValue` flash the UI while the query is in flight.

## Infrastructure Checklist

When creating new infrastructure (routes, API handlers, providers), use exploration findings as a **checklist** — systematically verify each convention is followed before writing code.

## Code Review

- Label severity: `critical` / `major` / `minor`
- Prefer minimal, tightly scoped diffs — don't switch layout strategies (e.g., grid to flex) unless explicitly asked, as it often breaks dependent sizing
- Flag unnecessary complexity with a simpler alternative
- Flag security issues (XSS, CSRF, injection, auth gaps) with fixes

## Testing

- Suggest tests when changes touch logic, but don't write tests unless asked.
- Run targeted tests for relevant files, not the full suite.
- After finishing implementation that touches backend logic or adds new code paths, present a concrete list of test cases that should be added or updated. List each as a one-line description (happy path, sad path, edge cases). Surface this clearly, don't bury it.

## Commit Convention

Use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/): `type(optional scope): description` (lowercase, no period). Types: `feat`, `fix`, `chore`, `refactor`, `style`, `docs`, `test`, `perf`, `ci`, `build`. Append `!` before `:` for breaking changes (e.g., `feat!: remove legacy api`). Keep commits tightly scoped. Examples: `feat: add swipe gesture support`, `fix: landscape bottom padding`.

## Branching

New branches: prefix with your GitHub username (e.g., `tommyxchow/add-auth-flow`). Run `gh api user --jq .login` to find it.

## Aliases

- **"vet"** means: review code for correctness/quality, verify claims against external sources (web search), and flag anything suspicious — including what's _missing_, not just what's wrong with what exists.

## Never

- Never use `npm`, `npx`, or `yarn` — always use `pnpm` / `pnpx`
- Never install a new dependency without asking first
