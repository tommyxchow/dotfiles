---
name: vet
description: Cross-checks claims against current official docs and primary sources. Use when the user says vet, search online, look this up, cross-check, double check, verify, is this still true, or the request hinges on versions, APIs, prices, dates, or "latest". After an audit, wait to edit. Not for local codebase search, code review, running tests, tldr, or pass ("we good", "anything outstanding", "final review", "final double check").
argument-hint: "[response | <claim or topic to verify> | <task to research>]"
allowed-tools: WebSearch WebFetch
---

vet grounds work in **current online sources** instead of training-data memory — it verifies checkable claims, cites them, and surfaces what's uncertain or missing. Core rule: **research the claim, not the source** — confirm facts against authoritative pages, never from memory or a search snippet.

## 1. Pick the mode (don't stall asking "what to review")

- **Auditing a prior response or a claim** the user points at → claim audit.
- **Pasted plan from another model** ("chatgpt said", "wdyt", "what do you think") → claim audit of that paste.
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y") → do the task *research-backed*: search current sources for every checkable fact before asserting, and cite inline as you go.
- **Ambiguous** → default to verifying the most recent checkable claims in the conversation. Only ask if there is genuinely nothing to act on.

## 2. Anchor to the project

For dev questions inside a repo, check what's actually installed **before** searching: manifests and lockfiles (package.json, pnpm-lock.yaml, pubspec.yaml, …). The target is the best current approach **compatible with the project**, not merely the newest — prefer version-specific docs and the changelog between the installed and current version. If that changelog shows the bug is already fixed, say so and recommend the bump instead of a workaround.

## 3. Verify (the part that makes it vet, not a vibe-check)

- **Web-search first.** Never assert a checkable fact — version, API signature, price, date, deprecation, "latest", best practice — from training data alone.
- **Go to the right source of truth.** Official docs/specs/changelogs and project GitHub (source, README, releases, issues/discussions) for APIs, versions, and definitive facts; for real-world behavior (performance, reliability, compatibility, sentiment) and recommendations, add credible independent benchmarks, tests, user reports, and X posts when X search is available. X is for announcements and developer sentiment, not the authority for specs. SEO/AI-generated content only as a pointer to a primary source — never as the authority you cite. Confirm you're on the project's canonical domain (the one linked from the repo or package registry), not a mirror, clone, or lookalike.
- **Depth matches the claim.** A definitive fact (API signature, version number, price, date) needs one authoritative, version-matched source. Recommendations, disputed or ambiguous claims, and anything security-sensitive need **2+ independent sources**. If sources conflict, *surface the conflict* — don't silently pick one.
- **Snippets aren't sources.** Search finds the page; fetch it and confirm the claim in context before citing.
- **Best practices are recommendations, not facts.** Establish the current official recommendation, as of when, and what it superseded; give a clear pick when the evidence supports one, and present the tradeoffs when it doesn't.
- **Date what's time-sensitive.** Note "as of <today>" when recency materially matters; cite a page date only when the page actually shows one — never guess a date.
- **Classify** each claim: **Verified · Partial · Unverified.** Flag what's **missing**, not just what's wrong — omissions are the most common miss.
- **Fallback** when web is blocked: read the vendored source (node_modules, lockfiles, installed docs) directly and say so. If neither is possible, mark **Unverified** — don't assert.

## 4. Present the result (shape follows size)

- **Forward task** → the normal answer with citations woven in. No separate report.
- **Bare `vet <topic>` or a focused check (1–2 claims)** → verdict first in a sentence, then the few sources that matter, then conflicts or gaps. No scaffolding, no tally, not a literature review.
- **Explicit multi-claim audit** → lead with a one-line tally, then compact findings — one per claim, worst first, glyphs `✗ Wrong · ⚠ Partly · ✓ Holds`; switch to a table with a verdict column when there are many.
- **Unverified footer only when earned** — if something stayed Unverified/Partial, close with one line naming it and why. If everything checks out, say so plainly — a clean result is valid; don't manufacture doubt.

Cite as autolinked source names (`[Vendor docs](url)`, add the date when it's real and relevant), not bare URLs.

## 5. Boundaries

- vet **reports/answers — it doesn't apply changes.** After an audit, wait for approval before editing. End-of-slice "we good" / "anything outstanding" / "final review" / "final double check" is `pass`, which vets then patches.
- Bigger than a cross-check? Open-ended exploratory research → a standalone deep-research round. Bugs in a code diff → the harness's code reviewer (Bugbot in Cursor, `/review` in Claude Code). Confirming a code change works → run it locally.
