---
name: vet
description: Review recent code changes OR recent assistant responses for correctness, completeness, and freshness — cross-check claims against current official docs (web search) or vendored source, and flag what's missing as well as what's wrong. Use before any commit, PR, or "I think it's done" moment, OR after the assistant makes claims/recommendations you want verified — including phrases like "vet", "vet this", "cross-check", "double check", "verify", "verify your response", "review and verify", "review and audit", "research online", "check as of today", or "final pass". Distinct from /simplify (cleanup/refactor for elegance) and /review-pr (PR-level review).
argument-hint: "[staged | branch | <pr-number>]"
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git branch *)
---

## Workflow

### 1. Identify scope

Determine what to review:

- If `$ARGUMENTS` specifies files or a scope → use that
- If recent code changes exist → run `git diff --stat` and `git diff --cached --stat`, review the diff
- If invoked after recent assistant responses with no code changes → audit the conversation: extract claims, recommendations, and factual assertions made in the recent turns, then verify each against fresh sources
- If neither is obvious → ask the user what to review

### 2. Read and review

**Code review mode** — read every changed file in full. Review for:

- **Correctness**: logic errors, off-by-ones, race conditions, null/undefined gaps
- **Security**: XSS, injection, auth gaps, exposed secrets, OWASP top 10
- **Consistency**: does the new code follow patterns established elsewhere in the codebase?
- **Completeness**: missing edge cases, error handling gaps, unfinished implementations
- **What's missing**: dead code left behind, imports not cleaned up, types not updated, related files that should have changed but didn't
- **Approach**: is this the simplest implementation that achieves the goal? Could a stdlib/existing utility or cleaner pattern replace what's there? Is the architectural choice (data structure, abstraction, library) right?

When flagging signature changes, use LSP `findReferences` first to avoid false positives — text grep produces noise on common names.

For TypeScript projects (tsconfig.json present), run `pnpm typecheck` (or `pnpm tsc --noEmit` if no typecheck script) before reporting clean — catches cross-file type errors LSP may miss inline. Report failures under Critical.

**Conversation audit mode** — extract assertions from recent assistant turns. Review for:

- **Factual claims**: version numbers, API behaviors, library features, doc references — anything checkable against an external source
- **Recommendations**: does the proposed approach hold up against current best practices and the user's stated context?
- **Tool result interpretation**: did conclusions actually follow from tool outputs (web search, file reads, command results), or fill gaps with assumption?
- **Logical gaps**: were there steps in the reasoning that weren't validated? Was anything skipped or hand-waved?
- **Hedges and uncertainty**: what did the assistant say it was unsure about, and is the uncertainty warranted (or is it overconfident on something it should have hedged)?

List each assertion explicitly before verifying — don't audit invisibly. The user should see what's being checked.

### 3. Cross-reference project conventions

Actively check the diff against the project conventions already in your context. Convention drift is the most common review miss — flag every violation.

### 4. Verify claims against external sources

This is what distinguishes /vet from a normal code review. For any of the following in the changed code, verify against current official documentation:

- Framework/library API usage (correct function signatures, deprecated APIs, version-specific behavior)
- Third-party service integration (correct endpoints, auth patterns, rate limits)
- Configuration values (correct option names, valid values, default behavior)
- Security patterns (current best practices, known vulnerabilities in dependencies)
- Platform-specific behavior (browser APIs, Node.js APIs, OS-specific paths)

**Verification preference:**

1. **Web search** for official docs (framework docs, MDN, vendor docs). Don't rely on training data.
2. If web search is blocked or unavailable (e.g., in a restricted-network environment), **read the vendored source in `node_modules` directly** — check actual function signatures, validation rules, and side effects. Mention in the report that verification fell back to source.
3. If neither is possible, mark the claim as **Unverified** in the report rather than asserting correctness.

### 5. Report findings

Present findings in a structured, skim-friendly format. **Always lead with a one-line TL;DR. Skip empty sections entirely** (don't render headers for buckets with zero findings).

```
## Vet Report

**TL;DR**: N critical · N major · N minor · N verified  *(or "All clear." if nothing flagged)*

### Critical
- `file:line` [H] Issue description
  → Fix: concrete action

### Major
- `file:line` [H] Issue description
  → Fix: concrete action or recommendation

### Minor
- `file:line` [M] Brief description

### Convention drift
- `file:line` Violates [CLAUDE.md / AGENTS.md / rule]
  → Fix: concrete action

### Approach
- `file:line` Cleaner alternative — rationale

### Verified
- ✓ What was checked — per [source URL or node_modules path]

### Unverified
- ? What couldn't be checked — why (e.g., web search blocked, no vendored source)

### Missing
- What should exist but doesn't

### Next steps
1. Critical/security first
2. Quick wins
3. (optional) Approach suggestions

→ Address critical, all critical+major, or skip?
```

**Confidence notation**: `[H]` / `[M]` / `[L]` after the file:line. Severity is "how bad if true" (the section bucket); confidence is "how sure I am it's real" (the bracket). Both inform priority differently.

**Empty section rule**: if Critical/Major/Minor/Convention drift/Approach/Unverified/Missing has nothing, omit the heading and bullets entirely. Don't render `*(none)*` placeholders. Always render TL;DR; render Verified if anything was checked; render Next steps only if there's actionable work.

Vet reports — it does not fix. After presenting the report, **wait for explicit user approval** before applying any changes. The Next steps section is a nudge, not a license to act.

If everything looks clean, say so — don't manufacture issues. A clean vet is a valid outcome (skip Next steps in that case).

Keep the report concise. Link to sources when citing external documentation.
