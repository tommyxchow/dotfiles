---
name: vet
description: Review recent code changes for correctness, quality, and completeness — then cross-check claims against current official documentation via web search. Use this skill after completing a feature, bug fix, config change, or any series of changes before committing. Also use when the user says "vet", "vet this", "cross-check", "review and verify", or wants a final quality pass on their work. This is distinct from /simplify (which focuses on code cleanup) and /review-pr (which reviews a PR) — /vet focuses on correctness verification with external source validation.
disable-model-invocation: true
---

# Vet

Review recent changes for correctness and quality, verify claims against external sources, and flag what's missing — not just what's wrong.

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
- **Completeness**: are there missing edge cases, error handling gaps, or unfinished implementations?
- **What's missing**: dead code left behind, imports not cleaned up, types not updated, related files that should have changed but didn't

### 3. Verify claims against external sources

This is what distinguishes /vet from a normal code review. For any of the following in the changed code, **web search to verify against current official documentation**:

- Framework/library API usage (correct function signatures, deprecated APIs, version-specific behavior)
- Third-party service integration (correct endpoints, auth patterns, rate limits)
- Configuration values (correct option names, valid values, default behavior)
- Security patterns (current best practices, known vulnerabilities in dependencies)
- Platform-specific behavior (browser APIs, Node.js APIs, OS-specific paths)

Do not rely on training data for these — search and verify. Prefer official docs (framework docs, MDN, vendor docs) over blog posts.

### 4. Report findings

Present findings in a structured format:

```
## Vet Report

### Critical
- [file:line] description of issue — with fix

### Major
- [file:line] description of issue — with fix or recommendation

### Minor
- [file:line] description of issue

### Verified
- [what was checked] — confirmed correct per [source]

### Missing
- [what should exist but doesn't]
```

If everything looks clean, say so — don't manufacture issues. A clean vet is a valid outcome.

Keep the report concise. Link to sources when citing external documentation.
