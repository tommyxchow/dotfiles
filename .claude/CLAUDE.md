IDE: VSCode. Use pnpm, not npm.

## Behavior

- When asked to add items to a list (models, emotes, constants, etc.), be thorough on the first pass — read the source completely and add ALL relevant items, not just the first few.
- In plan mode, interview thoroughly — ask about technical implementation, UI/UX, tradeoffs, and edge cases before coding. Don't begin implementation until all important details are resolved. For refactors: summary → trade-offs → next steps.
- Before designing or implementing with a framework, library, or external API, check the installed version (package.json, pubspec.yaml, etc.) and read docs for THAT version — design around what's actually available, not training-data memory or latest-version-only docs. If newer versions offer relevant improvements (new features, deprecations, perf wins), surface them as optional upgrades for the user — don't assume them. Lean on relevant skills (`/feature-dev`, `/understand`, `/frontend-design`) and delegate extensive doc research to subagents.
- When implementing new code, search the codebase for existing usages and follow established patterns.
- When new code supersedes existing functionality, find and remove everything it makes redundant.
- When asked to "verify", always use web search to check current documentation and sources before responding. Do not rely solely on training data.
- Default to searching for factual questions, technical details, framework/library APIs, and version-specific behavior. Only skip search if the answer is absolutely foundational and unchanging.
- When setting up new tooling or infrastructure, surface key config decisions upfront as choices — don't silently pick defaults.
- **IMPORTANT**: When adding code that uses a new import, add the import AND the usage in the same Edit/Write call. The PostToolUse hook (prettier + eslint --fix) runs on every file write and strips unused imports — staging the import in a separate edit means it gets removed before the usage lands.

## Code Opinions

- `UPPER_SNAKE_CASE` for constants
- When editing config files (JSON, YAML), append new keys at the end — not the top or middle
- Derive state where possible — avoid duplicating what can be computed
- Inline until a pattern repeats 3+ times, then extract
- For new components/hooks/APIs: include a usage example
- Remove redundant props, classes, and styles that match defaults

### TypeScript

- Named exports only — no default exports except where required by Next.js (page, layout, route, etc.)
- `satisfies` over `as` for type validation
- `??` over `||`; explicit null checks over loose truthiness
- Avoid enums — use `as const` objects or union types

### React

- State progression: useState → Jotai → Context as needed
- Avoid `useRef` unless DOM access or imperative work
- Extract related/grouped logic (state, effects, handlers) into dedicated custom hooks when it improves readability — keep components focused on rendering
- Use React `key` to force remount when a component stays in the same JSX position but needs state reset (e.g., tab switches)
- Before swapping a component's underlying library or layout strategy, ask first. If an approved swap breaks the UI, revert immediately rather than attempting fixes

## Quality Priorities

In order: **correctness → user experience → simplicity → security**.

Not priorities: WCAG compliance (easy wins only), public accessibility, SEO, progressive enhancement.

## Tool Preferences

- Prefer LSP over Grep for semantic navigation:
  - `findReferences` before changing a function/component signature (no false positives)
  - `hover` to resolve inferred/computed types (Jotai atoms, Zod schemas, AI SDK generics)
  - `goToDefinition` to navigate through re-exports and barrel files
  - `incomingCalls`/`outgoingCalls` to trace call chains across routes, hooks, components
- When debugging third-party libraries, **read the extension source in `node_modules` first** — don't speculate about behavior. Check for validation, protocol restrictions, and attribute filtering before writing code.
- Spawn subagents (Task tool) when fanning out across files/repos or for research that would clutter context — don't spawn one for work you can complete in a single response.

## UI Patterns

- Adapt external designs (Figma specs, reference implementations) to codebase conventions before implementing. External descriptions may contain AI-generated rough drafts — always cross-reference against actual codebase patterns.
- (React) When UI visibility depends on an async query (modals, banners, gates), default to hidden and only show after loading completes — never let `defaultValue` flash the UI while the query is in flight.
- For UI changes, after implementation use chrome-devtools MCP to navigate to the affected page, take a screenshot, and verify against the intent — don't claim a UI feature is done without visual verification.

## Code Review

- Surface ALL findings labeled `critical` / `major` / `minor` — severity is for ranking, not filtering. Don't drop low-severity findings to "be conservative"
- Prefer minimal, tightly scoped diffs — don't switch layout strategies (e.g., grid to flex) unless explicitly asked, as it often breaks dependent sizing
- Flag unnecessary complexity with a simpler alternative
- Flag security issues (XSS, CSRF, injection, auth gaps) with fixes

## Testing

- Suggest tests when changes touch logic, but **IMPORTANT: do not write tests unless asked**.
- Run targeted tests for relevant files, not the full suite.
- After finishing implementation that touches backend logic or adds new code paths, present a concrete list of test cases that should be added or updated. List each as a one-line description (happy path, sad path, edge cases). Surface this clearly, don't bury it.

## Commit Convention

Conventional commits: `type(scope): description` — lowercase, no period, tightly scoped. Append `!` before `:` for breaking changes. Examples: `feat: add swipe gesture`, `fix: landscape padding`.

## Branching

New branches: prefix with your GitHub username (e.g., `tommyxchow/add-auth-flow`). Run `gh api user --jq .login` to find it.

## Aliases

- **"vet"** means: review code for correctness/quality, verify claims against external sources (web search), and flag anything suspicious — including what's _missing_, not just what's wrong with what exists.

## Never

- Never use `npm`, `npx`, or `yarn` — always use `pnpm` / `pnpx`
- **IMPORTANT**: Never install a new dependency without asking first
- Never create project-level settings overrides — use global settings unless explicitly asked otherwise
- **IMPORTANT**: Never `git add` or `git commit` without first showing what will be staged, confirming the branch with `git branch --show-current`, and waiting for approval
- **IMPORTANT**: Never `git push` without first confirming `pwd` and the target remote — pushing to the wrong repo in a multi-repo workflow has caused incidents
