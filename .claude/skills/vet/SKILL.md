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

Actively check the diff against the project conventions already in your context. Convention drift is the most common review miss — flag every violation. _(Skip this step in conversation audit mode — convention drift doesn't apply to claims.)_

### 4. Verify claims against external sources

This is what distinguishes /vet from a normal code review or a vibe-check. **Applies to both modes** — anything checkable against an authoritative source should be checked, never asserted from training data alone.

**In code review mode**, common things worth verifying in the diff against current official documentation (not exhaustive — verify anything else in the diff that's checkable):

- Framework/library API usage (correct function signatures, deprecated APIs, version-specific behavior)
- Third-party service integration (correct endpoints, auth patterns, rate limits)
- Configuration values (correct option names, valid values, default behavior)
- Security patterns (current best practices, known vulnerabilities in dependencies)
- Platform-specific behavior (browser APIs, Node.js APIs, OS-specific paths)

**In conversation audit mode**, common assertions worth verifying (not exhaustive — verify any other checkable claim made):

- Version numbers, release dates, deprecation status
- Library/framework features claimed to exist or behave a certain way
- Doc references cited (does the linked page actually say what was claimed?)
- Benchmark numbers, performance claims, industry sentiment shifts
- Best-practice recommendations (does the current consensus actually agree?)

**Verification preference:**

1. **Web search** for official docs (framework docs, MDN, vendor docs). Don't rely on training data.
2. If web search is blocked or unavailable (e.g., in a restricted-network environment), **read the vendored source in `node_modules` directly** — check actual function signatures, validation rules, and side effects. Mention in the report that verification fell back to source.
3. If neither is possible, mark the claim as **Unverified** in the report rather than asserting correctness.

### 5. Report findings

Pick the report shape based on what was audited. **Code reviews and claim audits have different shapes — don't force one into the other.** Always lead with a one-line TL;DR.

#### Code review mode — severity buckets

Use when the audit was on changed code. Findings are independent and need triage decisions, so severity buckets earn their keep.

```
## Vet Report

**TL;DR** — N critical · N major · N minor · N verified  *(or "All clear." if nothing flagged)*

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

---

### Verified
- ✓ What was checked — per [source name](url) or `node_modules/path`

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

**Confidence notation** — `[H]` / `[M]` / `[L]` after the `file:line`. Severity is "how bad if true" (the section bucket); confidence is "how sure I am it's real" (the bracket). Both inform priority differently.

#### Conversation audit mode — verdict cards or table

Use when the audit was on assistant claims. **Drop severity buckets and `[H]/[M]/[L]` brackets** — every finding's "severity" is the same shape ("the claim was wrong / partly / right"), and confidence is carried by the source link itself, not a tag. **Drop `→ Fix:`** — for a claim, the corrected reality IS the fix.

Verdict glyphs: `✗ Wrong` · `⚠ Partly` · `✓ Holds`.

**For ≤3 claims, use cards.** Heading-as-verdict puts the answer in the largest, boldest text on screen — F-pattern reading land. The blockquote visually offsets the _original_ claim from the _corrected_ version, killing "wait which one is the real take?" ambiguity. One card per claim, separated by `---`.

```
## Vet Report

**TL;DR** — N wrong · N partly · N hold

---

### ✗ Wrong: <short label of claim>

> Original claim: <quote or paraphrase of what was said>

**Reality** — <2–3 sentence corrected version>

**Evidence**
- [Source name (date)](url) — specific finding or number
- [Source name (date)](url) — specific finding or number

**Missed** — <nuance or related point not surfaced originally>

---

### ⚠ Partly: <short label>

> Original claim: ...

**Reality** — ...
```

**For 4+ claims, use a table.** Sweep-the-verdict-column reading beats wall-of-cards once the list grows.

```
## Vet Report

**TL;DR** — N wrong · N partly · N hold

|     | Claim     | Reality                                     |
| --- | --------- | ------------------------------------------- |
| ✗   | <claim 1> | Opposite — <correction>, per [Source](url)  |
| ⚠   | <claim 2> | <partial correction>, per [Source](url)     |
| ✓   | <claim 3> | Holds — <one-line confirmation>             |

**Missed**
- <nuance not surfaced inline>
- <related claim that should have been made>
```

#### Common rules for both modes

- **Empty section rule** — omit any zero-finding section entirely. No `*(none)*` placeholders.
- **Always render TL;DR.** Render `Verified` if anything was checked. Render `Next steps` only if there's actionable work.
- **Autolinked source names**, not bare URLs — `[Scalekit (Mar 2026)](url)` beats `→ source: https://...`
- **Em-dash `—` for inline label/value separators** when bolding labels — `**Reality** — text` reads denser than `**Reality:** text`.
- **Inline `code spans`** for tool, file, function, and config names — renders as a monospace pill in the terminal.
- **Horizontal rules `---`** between claim cards (conversation-audit mode), and once between the action-bucket sections (Critical / Major / Minor / Convention drift / Approach) and the coverage-bucket sections (Verified / Unverified / Missing) in code-review mode. Skip the code-review divider when only one zone rendered content.

**/vet reports findings — it doesn't apply them.** After presenting the report, **wait for explicit user approval** before making any changes. The Next steps section is a nudge, not a license to act.

If everything looks clean, say so — don't manufacture issues. A clean vet is a valid outcome (skip Next steps in that case).

Keep the report concise. Link to sources when citing external documentation.
