---
name: vet
description: Cross-checks a claim against current official docs and primary sources, then answers in a few sentences with the pages that settled it. Stops as soon as the best source answers; a fact the vendor never published is reported as not documented, not hunted. Runs in a subagent so page fetches stay out of the parent window. Use when the user says vet, research, search online, look this up, cross-check, is this still true, is anyone else hitting this, known issue, workaround, or the request hinges on versions, APIs, prices, dates, or "latest". After an audit, wait to edit. Not for local codebase search, code review, running tests, tldr, or pass ("final review", "final double check"). Bare "double check" / "verify" routes by object: a claim or current docs is this skill; whether the code is correct is the review skill.
argument-hint: "[<claim or topic to verify> | <task to research>]"
context: fork
agent: general-purpose
background: false
---

vet answers from **current online sources** instead of memory. It checks the claim, cites the page that settled it, and says what is uncertain or missing. It is a quick lookup, not a research project: most runs are one or two searches and a few fetches.

Bare `vet` and `vet/research` are the same. `$ARGUMENTS` is the claim, topic, or forward task.

## Isolate

Page fetches stay in a child window. The parent keeps only the section 4 answer.

- **Already a subagent** (forked or spawned for this vet): do the work here. Don't spawn. `$ARGUMENTS` plus your prompt is the claim; if both are empty, ask, don't guess. Then section 1.
- **Parent**: don't search or fetch here, before or after the child runs. Spawn one general-purpose subagent, wait for it (not background), and present its answer as yours. Not Explore. Pack the claim quoted (`$ARGUMENTS`, or the last checkable claims, named topic, or pasted plan), this file's path plus "you are the worker", and the repo cwd. A forward task also needs any decision from this chat it depends on. Don't spawn an empty worker.

## 1. Pick the mode (don't stall asking "what to review")

- **Bare `vet` / `research` / search / look this up / cross-check / is this still true** → check the last response or the named topic (section 3). Short answer (section 4).
- **"is anyone else hitting this" / known issue / workaround** → the known-issue path in section 3.
- **"double check" / "verify"** → route by object. A claim, version, API, "latest", or current docs → this skill. Whether the code is correct, the diff, or this function → the `review` skill. A finished slice ("final double check", "close this out") → `pass`. Don't search just because they said double check.
- **Pasted plan from another model** ("chatgpt said", "wdyt", "what do you think") → audit the claims in the paste. Same short answer unless several claims are wrong or uncertain.
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y") → do the task research-backed: check each checkable fact against a current source before asserting it, and cite inline as you go.
- **Ambiguous** → the last checkable claims if the last turn asserted a fact; the last code change if they mean correctness. Only ask if there is genuinely nothing to act on.

## 2. Anchor to the project

For a dev question inside a repo, read the installed version from the manifest or lockfile (package.json, pnpm-lock.yaml, pubspec.yaml, …) before searching, and prefer docs for that version, including docs bundled in `node_modules`, over the live site, which is usually *latest*. When the question is a bug or a missing feature, also check the changelog between the installed and current version: if it is already fixed, say so and recommend the bump instead of a workaround. The target is the best current approach compatible with the project, not merely the newest.

## 3. Verify

- **Don't assert from training data.** A checkable fact (version, API signature, price, date, deprecation, "latest", best practice) comes from a fetched page, never from memory or a search snippet. In a repo, section 2 first; then search.
- **Go straight to the best source.** Search once for the canonical page, fetch it, confirm the claim on the page. Don't average across weaker sources. Confirm you're on the project's canonical domain (the one the repo or package registry links to), not a mirror or lookalike. A discussions, answers, `community.`, or forum page on that brand is community opinion, not the spec; `learn.` and `docs.` hosts can still be the real docs.
  1. Specs, **version-matched** official docs (Next.js, React, TypeScript, Flutter), language and platform docs (MDN, dart.dev), source, README, changelog, GitHub **releases**. This settles APIs, versions, and facts.
  2. The vendor's own blog or account: announcements only. Confirm the fact in (1) before citing.
  3. Independent benchmarks, tests, and named reports for real-world behavior (perf, reliability, compatibility). GitHub Advisories, NVD, and OSV for vulnerabilities.
  4. A personal blog or talk only if the author is a maintainer, on the vendor team, or named in the official docs. Tutorial farms, SEO and AI posts, and random personal sites are pointers at most, never the cite.
  5. GitHub **issues** and Discussions, Reddit, Stack Overflow, Discord, HN, and other forums: community opinion and workarounds only. Never the cite for a fact. If a thread links to docs, a PR, or a release, fetch that instead.
- **One good source settles a fact.** Fetch a second only when the first page is ambiguous or partial, two sources disagree, the claim is a recommendation or security-sensitive, or the question is which version fixed something (then docs plus the changelog). Never fetch another page to look thorough, and never add a (5) source to a settled answer.
- **Not documented is an answer.** Two searches scoped to the vendor's domains and two fetches there are the whole budget for proving an absence. If the canonical docs still don't state it, the verdict is "not documented" and you stop. Say what you checked. Don't go hunting through forums or third-party sites for a fact the vendor never published.
- **Known issue / workaround.** Search that project's issues and Discussions, fetch the one thread that matches, and say whether it's open, closed, or a maintainer-confirmed workaround. Then one changelog or releases check for a fix in a version the project can take. Stop.
- **Snippets aren't sources.** Search finds the page; the page proves the claim. Fetch the smallest slice that settles it: a targeted prompt or section of a long spec, changelog, or explainer, not the whole document.
- **Best practices are recommendations, not facts.** State the current official recommendation, as of when, and what it superseded. Give a clear pick when the evidence supports one, and the tradeoffs when it doesn't. If sources conflict, surface the conflict; don't silently pick one.
- **Date what's time-sensitive.** Note "as of <today>" when recency matters; cite a page date only when the page shows one.
- **Flag what's missing**, not just what's wrong. Omissions are the most common miss.
- **Past a handful of fetches and still not settled?** That is open-ended research, not a vet. Give the verdict with what's still missing and stop. Don't start a second topic. Several claims in one run share that budget.
- **Fallback when web is blocked:** read the manifest, lockfile, and bundled docs directly and say so. Vet never reads binaries, runs scripts against an install, or reverse-engineers anything; that is a normal session's job. If neither web nor bundled docs work, say you couldn't check. Don't assert.

## 4. Present the result

One-line verdict, then only what was wrong, in the global Communication voice: full sentences, plain words. A clean result is a few sentences and the sources, not a row per fact and not a scoreboard. Cite like a careful teammate, not a paper: no footnotes, no bibliography, no "according to".

- **Verdict first:** `✅ Yes.` / `❌ No.` / `⚠️ Yes, except …` One emoji on that line so it pops when I scroll back; don't mark every claim. Then the one or two things that are wrong, still uncertain, or missing.
- **Cite the pages that settled it** as autolinked names (`[Next.js docs](url)`, date only when the page shows one). Quote a short phrase when the exact wording is the proof (an API name, a version). Don't blockquote a page. Don't list every page you opened.
- **Forward task** → the normal answer with citations woven in. No separate report.
- **Explicit audit of a long list or pasted plan** → same verdict line. List only the misses, worst first. Don't list claims that were fine. A table only if the misses are many and a table reads easier than prose.
- If everything was fine, say so plainly and stop. Don't manufacture doubt.

```
✅ Yes. The method is `includes`, not `contains` ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/includes)): "`includes(searchElement)`".

⚠️ Yes, except the name: `Map` uses `has`, not `contains` ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/has)).
```

## 5. Boundaries

- vet **reports or answers; it doesn't apply changes.** After an audit, wait for approval before editing. "Final review" / "final double check" / "close this out" is `pass`, which vets then patches.
- Open-ended exploratory research is a standalone deep-research round, not a vet. Confirming a code change works means running it locally; don't web-search a local correctness check.
