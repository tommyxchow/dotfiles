---
name: vet
description: Cross-check claims against current online sources (web search of primary/official docs) and weave verified, cited findings into the work — flagging what's missing as well as what's wrong. Two uses — (1) audit a prior response or a specific claim, (2) bake online double-checking into a forward task so the answer is research-backed instead of asserted from memory. Triggers on "vet", "vet this", "cross-check", "double check", "verify", "verify your response", "research online", "check as of today", "is this still true", "final pass" — and use it even when those words are absent whenever a request hinges on checkable facts (versions, APIs, prices, dates, "latest", best practices). Distinct from /deep-research (heavy multi-source exploratory report) and /code-review (bugs in a code diff).
argument-hint: "[response | <claim or topic to verify> | <task to research>]"
---

vet grounds work in **current online sources** instead of training-data memory — it verifies checkable claims, cites them, and surfaces what's uncertain or missing. Core rule: **research the claim, not the source** — confirm facts against independent, authoritative pages, never by trusting a single one.

## 1. Pick the mode (don't stall asking "what to review")

- **Auditing a prior response or a claim** the user points at → claim audit (§3).
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y, vet it") → do the task *research-backed*: web-search current sources for every checkable fact before asserting, and cite inline as you go.
- **Ambiguous** → default to verifying the most recent checkable claims in the conversation. Only ask if there is genuinely nothing to act on.

## 2. Verify (the part that makes it vet, not a vibe-check)

- **Web-search first.** Never assert a checkable fact — version, API signature, price, date, deprecation, "latest", best practice — from training data alone.
- **Go to the source of truth.** Follow the source hierarchy in the global `~/.claude/CLAUDE.md` (official docs/specs/changelogs, then project GitHub; SEO/AI-generated/opinion content only as a pointer to a primary source — never as the authority you cite).
- **Triangulate** anything non-trivial across **2+ independent sources**. If sources conflict, *surface the conflict* — don't silently pick one.
- **Date-stamp.** Prefer current pages, note "as of <today>", and watch for stale or superseded info.
- **Classify** each claim: **Verified · Partial · Unverified.** Flag what's **missing**, not just what's wrong — omissions are the most common miss.
- **Fallback** when web is blocked: read the vendored source (`node_modules`, lockfiles, installed docs) directly and say so. If neither is possible, mark **Unverified** — don't assert.

## 3. Report (match the shape to the mode)

**Forward research** — weave linked citations into the normal answer; don't emit a separate report. Close with a one-line coverage footer:

> ✓ Verified: <what + source> · ? Unverified: <what + why>

**Response / claim audit** — lead with a TL;DR tally, then one finding per claim. Verdict glyphs: `✗ Wrong · ⚠ Partly · ✓ Holds`.

Compact per-claim cards by default:

```
## Vet Report
**TL;DR** — N wrong · N partly · N hold

### ✗ Wrong: <claim label>
> <what was claimed>
**Reality** — <corrected version>, per [Source (date)](url)
**Missed** — <nuance/omission not surfaced originally>
```

When there are many claims, switch to a table with the same glyphs in a verdict column instead.

Both shapes: **autolinked source names with dates** (`[Vendor docs (Mar 2026)](url)`), not bare URLs; surface uncertainty rather than hiding it.

## 4. Boundaries

- vet **reports/answers — it doesn't apply changes.** After an audit, wait for approval before editing.
- A clean result is valid — if everything checks out, say so; don't manufacture doubt.
- Bigger than a cross-check? Open-ended exploratory research → hand off to **/deep-research**. Just bugs in a diff → **/code-review**.
