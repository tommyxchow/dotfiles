---
name: vet
metadata:
  opencode/slash: "true"
description: 'Cross-checks a claim against current official docs and primary sources, then answers in a few sentences with the pages that settled it. Stops as soon as the best source answers; a fact the vendor never published is reported as not documented, not hunted. Keeps page fetches out of this window. Use when the user says vet, research, search online, look this up, cross-check, is this still true, is anyone else hitting this, known issue, workaround, or the request hinges on versions, APIs, prices, dates, or "latest". After an audit, wait to edit. Not for local codebase search, code review, running tests, tldr, pass ("final double check"), or pr ("final review", "is this ready"). Bare "double check" / "verify" routes by object: a claim or current docs is this skill; whether the code is correct is the review skill. `quick` is up to three claims, local docs or one page each, no fan-out, and never the full vet.'
argument-hint: "[quick] [<claim or topic to verify> | <task to research>]"
context: fork
agent: general-purpose
background: false
---

vet checks claims against **version-matched local documentation or current primary sources**, cites what settled them, and names what remains uncertain. It is a bounded lookup, not a research project.

Bare `vet` and `vet/research` are the same. `$ARGUMENTS` is an optional `quick` first, then the claim, topic, or forward task.

## Isolate

Page fetches stay in child windows, and the coordinator keeps only the section 4 answer.

- **Leaf** (your prompt says you are a leaf, or you were given a single claim): do the work in this window and don't spawn workers. `$ARGUMENTS` plus your prompt is the claim. If both are empty, ask rather than guess. Then go to section 1.
- **Coordinator** (the parent chat, or a forked skill that received the full topic): don't search or fetch in this window. On `quick`, spawn no leaves, and take its claims through section 3 in this window, in the same turn. Otherwise, split the work by independent claim, or by vendor when several claims share one canonical page, and spawn those leaves in the same turn. One claim stays with one worker, spawned on the cheaper same-family model where the harness lets you choose, since a leaf only fetches and reports. Wait for every leaf rather than backgrounding them, then reconcile their results into one section-4 answer.
- Give each leaf its quoted claim, this file's path plus "you are a leaf", and the repo cwd. A forward task also needs any decision from this chat that it depends on. Don't spawn an empty worker.
- Don't use a read-only or search-only agent type for a leaf.
- Don't spawn a separate leaf for each source of the same fact, because one good source still settles it.
- Spawn at most four leaves. Leftover claims go with the leaf that shares their page, or otherwise with the last leaf.
- Spawn only one level deep: leaves never split their work again.
- **No way to spawn a worker here**: do the work in this window and don't mention it. Still run independent searches and fetches in the same turn. The isolation saves context, but the answer is what matters.

For example, one claim ("does `Map` use `has`?") is one leaf. A pasted plan with independent facts (HGIG vs DTM, Fine Tune Dark Areas with HGIG, whether a C3 needs ColorControl) gets one leaf per fact, all spawned in the same turn. Claims that live on one page go to the same leaf.

## 1. Pick the mode (don't stall asking "what to review")

- **Bare `vet` / `research` / search / look this up / cross-check / is this still true**: check the last response or the named topic using section 3, and give the short answer from section 4.
- **"is anyone else hitting this" / known issue / workaround**: follow the known-issue path in section 3.
- **"double check" / "verify"**: route by what is being checked. A claim, version, API, "latest", or current docs belongs to this skill. Code correctness goes to `review`. A finished slice ("final double check", "close this out") goes to `pass`. PR readiness ("final review", "is this ready") goes to `pr check`, which reports without flipping the draft.
- **Pasted plan from another model** ("chatgpt said", "wdyt", "what do you think"): audit the claims in the paste. Give the same short answer unless several claims are wrong or uncertain.
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y"): do the task with research behind it. Check each checkable fact against a current source before asserting it, and cite inline as you go.
- **Ambiguous**: check the last checkable claims if the last turn asserted a fact, or the last code change if the user means correctness. Ask only if there is genuinely nothing to act on.
- **`quick` / "quick vet" / "quick check"**: check the claims that would change what we do next, up to three, with the named one first. Spawn no leaves. For each claim, try section 2's local sources first, and stop there if they settle it. Otherwise, run one search and fetch the canonical page, plus one more page only when that page is partial or ambiguous. If the claim is still unsettled after that, say so and stop. A quick vet never rules "not documented", since proving an absence takes the full budget. Open the verdict line with "Quick vet" so nothing counts it as the full check.

## 2. Anchor to the project

For a dev question inside a repo, read the installed version from the manifest or lockfile (package.json, pnpm-lock.yaml, pubspec.yaml, …) before searching. Prefer docs for that version, including docs bundled in `node_modules`, over the live site, which usually describes *latest*. When the question is about a bug or a missing feature, also check the changelog between the installed and current version. If it is already fixed, say so and recommend the bump instead of a workaround. The target is the best current approach compatible with the project, not merely the newest.

**Local sources come first for how the installed thing behaves.** Flags, subcommands, config keys, and API signatures are settled by `<tool> --help`, `man`, `pnpm help <cmd>`, or the `README` / `CHANGELOG` shipped with the installed package or SDK. That output is version-matched by definition and costs no fetch, so cite it as "installed vX help output" and stop. The web is still the source for what the local copy can't know: "latest", what changed since the installed version, advisories, deprecations, prices, and best-practice recommendations. This doesn't mean you should grep the whole install, since the no-binaries rule in section 3 still holds.

## 3. Verify

- **Don't assert from training data.** A checkable fact (version, API signature, price, date, deprecation, "latest", best practice) comes from a fetched page, never from memory or a search snippet. A fact already verified this session, or a pattern the repo already uses, is settled. Re-check only what is new, changed, or disputed. In a repo, work through section 2 first, then search.
- **Go straight to the best source.** Search once for the canonical page, fetch it, and confirm the claim on the page. Don't average across weaker sources. Confirm you're on the project's canonical domain (the one the repo or package registry links to), not a mirror or lookalike. A discussions, answers, `community.`, or forum page on that brand is community opinion, not the spec, though `learn.` and `docs.` hosts can still be the real docs.
  1. Specs, **version-matched** official docs (Next.js, React, TypeScript, Flutter), language and platform docs (MDN, dart.dev), source, README, changelog, and GitHub **releases**. These settle APIs, versions, and facts.
  2. The vendor's own blog or account, for announcements only. Confirm the fact in (1) before citing it.
  3. Independent benchmarks, tests, and named reports, for real-world behavior (perf, reliability, compatibility). GitHub Advisories, NVD, and OSV, for vulnerabilities.
  4. A personal blog or talk, only if the author is a maintainer, on the vendor team, or named in the official docs. Tutorial farms, SEO and AI posts, and random personal sites can point you to a source at most, and are never the cite.
  5. GitHub **issues** and Discussions, Reddit, Stack Overflow, Discord, HN, and other forums, for community opinion and workarounds only. Never cite them for a fact. If a thread links to docs, a PR, or a release, fetch that instead.
- **One good source settles a fact.** Fetch a second only when the first page is ambiguous or partial, two sources disagree, the claim is a recommendation or security-sensitive, or the question is which version fixed something (then fetch the docs plus the changelog). Don't fetch another page just to look thorough, and don't add a (5) source to a settled answer.
- **Not documented is an answer.** Two searches scoped to the vendor's domains and two fetches there are the whole budget for proving an absence. If the canonical docs still don't state it, the verdict is "not documented" and you stop. Say what you checked. Don't search forums or third-party sites for a fact the vendor never published.
- **Known issue / workaround.** Search that project's issues and Discussions, fetch the one thread that matches, and say whether it's open, closed, or a maintainer-confirmed workaround. Then do one changelog or releases check for a fix in a version the project can take, and stop.
- **Snippets aren't sources.** Search finds the page, and the page proves the claim. Fetch the smallest slice that settles it: a targeted prompt or section of a long spec, changelog, or explainer, not the whole document.
- **Best practices are recommendations, not facts.** State the current official recommendation, as of when, and what it superseded. Give a clear pick when the evidence supports one, and the tradeoffs when it doesn't. If sources conflict, surface the conflict rather than silently picking one.
- **Date what's time-sensitive.** Note "as of <today>" when recency matters. Cite a page date only when the page shows one.
- **Flag what's missing**, not just what's wrong, because omissions are the most common miss.
- **Past a handful of fetches and still not settled?** That is open-ended research, not a vet. Give the verdict with what's still missing and stop. Don't start a second topic. Each leaf has its own budget, and the coordinator doesn't add fetches after the leaves return.
- **Fallback when web is blocked:** read the manifest, lockfile, and bundled docs directly, and say so. Vet never reads binaries, runs scripts against an install, or reverse-engineers anything, because that is a normal session's job. If neither the web nor the bundled docs work, say you couldn't check rather than asserting anything.
- **An empty fetch is a miss, not something to work around.** Don't curl the page, open a browser, go through a third-party proxy, or scrape a dump with a script. Try at most one other verified official source for the same project, including its official GitHub repository. If that also fails to settle the claim, stop and say you couldn't verify it.

## 4. Present the result

Start with a one-line verdict, then give only what was wrong, in the global Communication voice of full sentences and plain words. A clean result is a few sentences and the sources, not a row per fact and not a tally of every claim. Cite the way a careful teammate would rather than the way a paper does, so leave out footnotes, a bibliography, and "according to".

- **Verdict first:** `✅ Yes.` / `❌ No.` / `⚠️ Yes, except …` Put one emoji on that line so it stands out when I scroll back, and don't mark every claim. Then give the one or two things that are wrong, still uncertain, or missing.
- **Cite the pages that settled it** as autolinked names (`[Next.js docs](url)`, with a date only when the page shows one). Quote a short phrase when the exact wording is the proof (an API name, a version). Don't blockquote a page, and don't list every page you opened.
- **Forward task**: give the normal answer with citations inline, not a separate report.
- **Explicit audit of a long list or pasted plan**: use the same verdict line, then list only the misses, worst first. Don't list claims that were fine. Use a table only if the misses are many and a table reads more easily than prose.
- If everything was fine, say so plainly and stop. Don't add doubt that isn't there.

```
✅ Yes. The method is `includes`, not `contains` ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/includes)): "`includes(searchElement)`".

⚠️ Yes, except the name: `Map` uses `has`, not `contains` ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/has)).
```

## 5. Boundaries

- vet **reports or answers; it doesn't apply changes.** After an audit, wait for approval before editing. "Final double check" / "close this out" goes to `pass`, which vets and then patches. On a branch with a PR, "final review" goes to `pr`.
- Open-ended exploratory research is a standalone deep-research round, not a vet.
- Confirming a code change works means running it locally, so don't web-search a local correctness check.
