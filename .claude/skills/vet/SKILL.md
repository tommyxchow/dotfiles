---
name: vet
description: Review recent code changes for correctness, quality, and completeness — cross-check claims against current official documentation (web search) or vendored source in node_modules, and flag what's missing as well as what's wrong. Use before any commit, PR, or "I think it's done" moment — including phrases like "vet", "vet this", "cross-check", "review and verify", or "final pass" — since convention drift and unverified API claims are easy to miss without a structured pass. Distinct from /simplify (cleanup) and /review-pr (PR-level review).
disable-model-invocation: true
argument-hint: "[staged | branch | <pr-number>]"
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git branch *)
---

## Workflow

### 1. Identify scope

Determine what to review. If `$ARGUMENTS` specifies files or a scope, use that. Otherwise:

- Run `git diff --stat` to see unstaged changes
- Run `git diff --cached --stat` to see staged changes
- If no changes, ask the user what to review

### 2. Read and review all changed files

Read every changed file in full. Review for:

- **Correctness**: logic errors, off-by-ones, race conditions, null/undefined gaps
- **Security**: XSS, injection, auth gaps, exposed secrets, OWASP top 10
- **Consistency**: does the new code follow patterns established elsewhere in the codebase?
- **Completeness**: missing edge cases, error handling gaps, unfinished implementations
- **What's missing**: dead code left behind, imports not cleaned up, types not updated, related files that should have changed but didn't
- **Approach**: is this the simplest implementation that achieves the goal? Could a stdlib/existing utility or cleaner pattern replace what's there? Is the architectural choice (data structure, abstraction, library) right?

When flagging signature changes, use LSP `findReferences` first to avoid false positives — text grep produces noise on common names.

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

Present findings in a structured format:

```
## Vet Report

### Critical
- [file:line] description of issue — with fix

### Major
- [file:line] description of issue — with fix or recommendation

### Minor
- [file:line] description of issue

### Convention drift
- [file:line] violates [CLAUDE.md / AGENTS.md / rule] — fix

### Approach
- [file:line] suggests a cleaner pattern, simpler abstraction, or better architectural choice — with rationale

### Verified
- [what was checked] — confirmed correct per [source URL or node_modules path]

### Unverified
- [what couldn't be checked] — why (e.g., web search blocked, no vendored source)

### Missing
- [what should exist but doesn't]

### Next steps
- Suggested priority order (critical/security first, then quick wins, then larger refactors, then optional approach suggestions)
- End with: "Want me to address [specific items], all critical/major, or skip?"
```

Vet reports — it does not fix. After presenting the report, **wait for explicit user approval** before applying any changes. The Next steps section is a nudge, not a license to act.

If everything looks clean, say so — don't manufacture issues. A clean vet is a valid outcome (skip Next steps in that case).

Keep the report concise. Link to sources when citing external documentation.
