---
name: vet
description: Cross-checks claims against current official docs and primary sources. Use when the user says vet, search online, look this up, cross-check, double check, verify, is this still true, or the request hinges on versions, APIs, prices, dates, or "latest". After an audit, wait to edit. Not for local codebase search, code review, running tests, tldr, or pass ("we good", "anything outstanding", "final review", "final double check").
argument-hint: "[response | <claim or topic to verify> | <task to research>]"
allowed-tools: WebSearch WebFetch
---

vet grounds work in **current online sources** instead of training-data memory — it verifies checkable claims, cites them, and surfaces what's uncertain or missing. Core rule: **research the claim, not the source** — confirm facts against authoritative pages, never from memory or a search snippet.

## 1. Pick the mode (don't stall asking "what to review")

- **Bare `vet` / search / look this up / double check / cross-check** → look up the last response or the named topic. Short search answer (section 4).
- **Pasted plan from another model** ("chatgpt said", "wdyt", "what do you think") → claim audit of that paste. Same short answer unless several claims are actually wrong or uncertain.
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y") → do the task *research-backed*: search current sources for every checkable fact before asserting, and cite inline as you go.
- **Ambiguous** → last checkable claims, same short answer. Only ask if there is genuinely nothing to act on.

## 2. Anchor to the project

For dev questions inside a repo, check what's actually installed **before** searching: manifests and lockfiles (package.json, pnpm-lock.yaml, pubspec.yaml, …). The target is the best current approach **compatible with the project**, not merely the newest — prefer version-specific docs and the changelog between the installed and current version. If that changelog shows the bug is already fixed, say so and recommend the bump instead of a workaround.

## 3. Verify (the part that makes it vet, not a vibe-check)

- **Web-search first.** Never assert a checkable fact — version, API signature, price, date, deprecation, "latest", best practice — from training data alone.
- **Go to the right source of truth.** Rank, don't average. Confirm you're on the project's canonical domain (the one linked from the repo or package registry), not a mirror, clone, or lookalike.
  1. Official docs, specs, changelogs, the vendor's own blog, and the project's GitHub (source, README, releases, issues). Language/platform docs (MDN, dart.dev) when the claim is the language. This is the answer for APIs, versions, and facts. A `community.` / discussions / forum subdomain on that same site is vibe, not the spec.
  2. Independent benchmarks, tests, and named reports for real-world behavior (perf, reliability, compatibility). GitHub Advisories / NVD / OSV for vulns.
  3. X for announcements and developer sentiment, not specs. You can see who said it; still not the authority.
  4. A personal blog or talk only if the author is a positioned expert on that project (maintainer, vendor team, named in the official docs). Tutorial farms, SEO/AI posts, and random personal sites are pointers at most — never what you cite.
  5. Reddit, Stack Overflow, Discord, HN, and other forums: community vibe/workaround only. Never the cite for a fact. If a thread links to docs, fetch the docs.
- **Depth matches the claim.** A definitive fact (API signature, version number, price, date) needs one authoritative, version-matched source. Recommendations, disputed or ambiguous claims, and anything security-sensitive need **2+ independent sources**. If sources conflict, *surface the conflict* — don't silently pick one.
- **Snippets aren't sources.** Search finds the page; fetch it and confirm the claim in context before citing.
- **Best practices are recommendations, not facts.** Establish the current official recommendation, as of when, and what it superseded; give a clear pick when the evidence supports one, and present the tradeoffs when it doesn't.
- **Date what's time-sensitive.** Note "as of <today>" when recency materially matters; cite a page date only when the page actually shows one — never guess a date.
- **Know the status** of each claim so the answer is honest. Don't print a tally or a row per fact that was fine. Flag what's **missing**, not just what's wrong — omissions are the most common miss.
- **Fallback** when web is blocked: read the vendored source (node_modules, lockfiles, installed docs) directly and say so. If neither is possible, say you couldn't check — don't assert.

## 4. Present the result

One-line verdict, then only what was wrong. A clean result is a few sentences and the sources — not a row per fact, not ✓/✗/⚠. Cite like a careful teammate, not a paper: no footnotes, no bibliography, no "according to."

- **Verdict first:** `Yes.` / `No.` / `Yes, except …` Then the one or two things that are wrong, still uncertain, or missing.
- **Cite the page** as an autolinked name (`[Next.js docs](url)`, date only when the page shows one). Quote a short phrase when the exact wording is the proof (an API name, a version). Don't blockquote a page.
- **Forward task** → the normal answer with citations woven in. No separate report.
- **Explicit audit of a long list or pasted plan** → same verdict line. List only the misses, worst first. Don't list claims that were fine. A table only if the misses themselves are many and a table is easier than prose.
- If everything was fine, say so plainly and stop. Don't manufacture doubt.

```
Yes. The recovery prop is `retry`, not `reset` ([Next.js docs](https://nextjs.org/docs)).

No. The signature is still `reset()` ([error.js](https://nextjs.org/docs)): "`reset: () => void`".
```

## 5. Boundaries

- vet **reports/answers — it doesn't apply changes.** After an audit, wait for approval before editing. End-of-slice "we good" / "anything outstanding" / "final review" / "final double check" is `pass`, which vets then patches.
- Bigger than a cross-check? Open-ended exploratory research → a standalone deep-research round. Bugs in a code diff → the harness's code reviewer (Bugbot in Cursor, `/review` in Claude Code). Confirming a code change works → run it locally.
