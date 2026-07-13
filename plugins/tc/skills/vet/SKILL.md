---
name: vet
description: Cross-check claims against current online sources (web search of primary/official docs) and weave verified, cited findings into the work — flagging what's missing as well as what's wrong. Two uses — (1) audit a prior response or a specific claim, (2) bake online double-checking into a forward task so the answer is research-backed instead of asserted from memory. Triggers on "vet", "vet this", "cross-check", "double check", "verify", "verify your response", "research online", "check as of today", "is this still true" — and use it even when those words are absent whenever a request hinges on checkable facts (versions, APIs, prices, dates, "latest", best practices). Distinct from /deep-research (heavy multi-source exploratory report), /code-review (bugs in a code diff), and /verify (exercising a code change locally).
argument-hint: "[response | <claim or topic to verify> | <task to research>]"
allowed-tools: WebSearch WebFetch
---

vet grounds work in **current online sources** instead of training-data memory — it verifies checkable claims, cites them, and surfaces what's uncertain or missing. Core rule: **research the claim, not the source** — confirm facts against authoritative pages, never from memory or a search snippet.

## 1. Pick the mode (don't stall asking "what to review")

- **Auditing a prior response or a claim** the user points at → claim audit.
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y") → do the task *research-backed*: search current sources for every checkable fact before asserting, and cite inline as you go.
- **Ambiguous** → default to verifying the most recent checkable claims in the conversation. Only ask if there is genuinely nothing to act on.

## 2. Anchor to the project

For dev questions inside a repo, check what's actually installed **before** searching: manifests and lockfiles (package.json, pnpm-lock.yaml, pubspec.yaml, …). The target is the best current approach **compatible with the project**, not merely the newest — prefer version-specific docs and the changelog between the installed and current version.

## 3. Verify (the part that makes it vet, not a vibe-check)

- **Web-search first.** Never assert a checkable fact — version, API signature, price, date, deprecation, "latest", best practice — from training data alone.
- **Go to the right source of truth.** Official docs/specs/changelogs and project GitHub (source, README, issues/discussions) for APIs, versions, and definitive facts; for real-world behavior (performance, reliability, compatibility) and recommendations, add credible independent benchmarks, testing, and user reports. SEO/AI-generated content only as a pointer to a primary source — never as the authority you cite. Confirm you're on the project's canonical domain (the one linked from the repo or package registry), not a mirror, clone, or lookalike.
- **Depth matches the claim.** A definitive fact (API signature, version number, price, date) needs one authoritative, version-matched source. Recommendations, disputed or ambiguous claims, and anything security-sensitive need **2+ independent sources**. If sources conflict, *surface the conflict* — don't silently pick one.
- **Snippets aren't sources.** Search finds the page; fetch it and confirm the claim in context before citing.
- **Best practices are recommendations, not facts.** Establish the current official recommendation, as of when, and what it superseded; give a clear pick when the evidence supports one, and present the tradeoffs when it doesn't.
- **Date what's time-sensitive.** Note "as of <today>" when recency materially matters; cite a page date only when the page actually shows one — never guess a date.
- **Classify** each claim: **Verified · Partial · Unverified.** Flag what's **missing**, not just what's wrong — omissions are the most common miss.
- **Fallback** when web is blocked: read the vendored source (node_modules, lockfiles, installed docs) directly and say so. If neither is possible, mark **Unverified** — don't assert.

## 4. Present the result (shape follows size)

- **Forward task** → the normal answer with citations woven in. No separate report.
- **Focused check (1–2 claims)** → verdict first in a sentence, correction and citation after. No scaffolding, no tally.
- **Explicit multi-claim audit** → lead with a one-line tally, then compact findings — one per claim, worst first, glyphs `✗ Wrong · ⚠ Partly · ✓ Holds`; switch to a table with a verdict column when there are many.
- **Unverified footer only when earned** — if something stayed Unverified/Partial, close with one line naming it and why. If everything checks out, say so plainly — a clean result is valid; don't manufacture doubt.

Cite as autolinked source names (`[Vendor docs](url)`, add the date when it's real and relevant), not bare URLs.

## 5. Boundaries

- vet **reports/answers — it doesn't apply changes.** After an audit, wait for approval before editing.
- Bigger than a cross-check? Open-ended exploratory research → **/deep-research**. Bugs in a code diff → **/code-review**. Confirming a code change works by running it → **/verify**.
