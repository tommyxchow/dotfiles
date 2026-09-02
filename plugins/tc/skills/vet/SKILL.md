---
name: vet
description: Cross-checks claims against current official docs and primary sources. Search and fetch until settled (cite floor 1–2, hard cap 8 searches / 16 fetches). Runs in a subagent so page fetches stay out of the parent window. Use when the user says vet, research, search online, look this up, cross-check, is this still true, is anyone else hitting this, known issue, workaround, or the request hinges on versions, APIs, prices, dates, or "latest". After an audit, wait to edit. Not for local codebase search, code review, running tests, tldr, or pass ("final review", "final double check"). Bare "double check" / "verify" routes by object: a claim or current docs is this skill; whether the code is correct is the review skill.
argument-hint: "[<claim or topic to verify> | <task to research>]"
context: fork
agent: general-purpose
background: false
---

vet grounds work in **current online sources** instead of training-data memory — it verifies checkable claims, cites them, and surfaces what's uncertain or missing. Core rule: **research the claim, not the source** — confirm facts against authoritative pages, never from memory or a search snippet.

Bare `vet` and `vet/research` are the same. `$ARGUMENTS` is the claim, topic, or forward task.

## Isolate

Page fetches stay in a child window. The parent keeps only the section 4 answer.

- **Already a subagent** (forked or spawned for this vet): do the work here. Don't spawn. `$ARGUMENTS` plus your prompt is the claim; if both are empty, ask — don't guess. Then section 1.
- **Parent**: don't search or fetch here. Spawn one general-purpose subagent, wait (not background), present its answer as yours. Not Explore. Pack the claim quoted (`$ARGUMENTS` or last checkable claims / named topic / pasted plan), this file's path + "you are the worker", and repo cwd. A forward task also needs any decision from this chat it depends on. Don't spawn an empty worker.

## 1. Pick the mode (don't stall asking "what to review")

- **Bare `vet` / `research` / search / look this up / cross-check / is this still true** → look up the last response or the named topic. Thorough (section 3). Short answer (section 4), not a short search.
- **"is anyone else hitting this" / known issue / workaround** → section 3 known-bug path (that project's issues/Discussions, then changelog/releases). Thorough, short answer.
- **"double check" / "verify"** → route by object. A claim, version, API, "latest", or current docs → this skill. Whether the code is correct, the diff, or this function → the `review` skill. A finished slice ("final double check", "close this out") → `pass`. Don't search just because they said double check.
- **Pasted plan from another model** ("chatgpt said", "wdyt", "what do you think") → claim audit of that paste. Same short answer unless several claims are actually wrong or uncertain.
- **"vet" attached to a forward task** ("build X and vet it", "what's the best Y") → do the task *research-backed*: search current sources for every checkable fact before asserting, and cite inline as you go.
- **Ambiguous** → last checkable claims if the last turn asserted a fact; last code change if they mean correctness. Only ask if there is genuinely nothing to act on.

## 2. Anchor to the project

For dev questions inside a repo, check what's actually installed **before** searching: manifests and lockfiles (package.json, pnpm-lock.yaml, pubspec.yaml, …). Prefer **version-matched** docs for that install — including bundled docs in `node_modules` when the package ships them — over the live unprefixed site (that's often *latest*, not *yours*). Then the changelog between the installed and current version. If that changelog shows the bug is already fixed, say so and recommend the bump instead of a workaround. The target is the best current approach **compatible with the project**, not merely the newest.

## 3. Verify (the part that makes it vet, not a vibe-check)

- **Don't assert from training data.** Never take a checkable fact — version, API signature, price, date, deprecation, "latest", best practice — from memory. In a repo, section 2 first; then search. Outside a repo, search first.
- **Go to the right source of truth.** Use the best-ranked source below; don't average across weaker ones. Confirm you're on the project's canonical domain (the one linked from the repo or package registry), not a mirror, clone, or lookalike. A discussions, answers, `community.`, or forum page on that same brand is community opinion, not the spec, while `learn.` and `docs.` hosts can still be the real docs. Judge the page, not the hostname alone.
  1. Specs, **version-matched** official docs (Next.js, React, TypeScript, Flutter), language/platform docs (MDN, dart.dev), source, README, changelog, GitHub **releases**. This is the answer for APIs, versions, and facts.
  2. Vendor blog and the vendor's own X/account: **announcements only**. Confirm the fact in (1) before citing. Not the API spec. Someone else's X is (5).
  3. Independent benchmarks, tests, and named reports for real-world behavior (perf, reliability, compatibility). GitHub Advisories / NVD / OSV for vulns.
  4. A personal blog or talk only if the author is a positioned expert on that project (maintainer, vendor team, named in the official docs). Tutorial farms, SEO/AI posts, and random personal sites are pointers at most — never what you cite.
  5. GitHub **issues** and Discussions, Reddit, Stack Overflow, Discord, HN, and other forums: community vibe/workaround only. Never the cite for a fact (API, version, "the official way"). If a thread links to docs, a PR, or a release, fetch that.
- **Known bug / "is anyone else hitting this" / workaround** → search that project's issues and Discussions (then other (5) if needed). Say whether it's open, closed, or a maintainer-confirmed workaround. Then check (1) changelog/releases for a fix in a version you can take. Don't treat a random comment as the spec.
- **Keep looking until the claim is settled.** The cite floor is not a search cap. A thin, version-mismatched, or partial page means another fetch, not a verdict. `vet` and `vet/research` are the same.
- **Don't call it settled from one product-docs page.** Anything dated — this version, "latest", deprecation, best practice — needs docs **and** the changelog or releases (or bundled version-matched docs) in agreement. A language-spec fact (MDN `includes`, TypeScript Handbook) can stop on one fetched spec page. A first page that merely *looks* complete is not corroboration.
- **Hard cap: 8 searches and 16 fetches** per run. That cap is a ceiling, not a target. Stop earlier if settled. If you hit the cap first, give the verdict with what's still missing, then stop. Failed or off-domain fetches count. Don't start a second topic. A multi-claim last answer shares this budget; spend it on the claims, not padding.
- **Extra sources come from the top of the ranking.** When one page isn't enough, fetch more of (1), then (2) and (3) if the claim is an announcement, about real-world behavior, or disputed. Don't add (5) to look thorough. The exception is a known-issue or workaround question, where (5) is where you search and (1) confirms whether it's fixed.
- **Cite floor:** a language-spec fact still needs at least one fetched, version-matched, canonical page. Recommendations, disputes, security, and anything dated need at least two independent sources from (1)–(3). Fetch more whenever those don't settle it. If sources conflict, *surface the conflict* — don't silently pick one.
- **Snippets aren't sources.** Search finds the page; confirm the claim on the page before citing. Fetch the smallest slice that settles it. A long spec, explainer, changelog, or blog: targeted extract (find / start-line / a prompt for the relevant section), not the whole document.
- **Best practices are recommendations, not facts.** Establish the current official recommendation, as of when, and what it superseded; give a clear pick when the evidence supports one, and present the tradeoffs when it doesn't.
- **Date what's time-sensitive.** Note "as of <today>" when recency materially matters; cite a page date only when the page actually shows one — never guess a date.
- **Know the status** of each claim so the answer is honest. Don't print a tally or a row per fact that was fine. Flag what's **missing**, not just what's wrong — omissions are the most common miss.
- **Fallback** when web is blocked: read the vendored source (node_modules, lockfiles, installed docs) directly and say so. If neither is possible, say you couldn't check — don't assert.

## 4. Present the result

One-line verdict, then only what was wrong, in the global Communication voice: full sentences, plain words. A clean result is a few sentences and the sources, not a row per fact and not a scoreboard. Cite like a careful teammate, not a paper: no footnotes, no bibliography, no "according to."

- **Verdict first:** `✅ Yes.` / `❌ No.` / `⚠️ Yes, except …` One emoji on that line so it pops when I scroll back; don't mark every claim. Then the one or two things that are wrong, still uncertain, or missing.
- **Cite the pages that settled it** as autolinked names (`[Next.js docs](url)`, date only when the page shows one). Quote a short phrase when the exact wording is the proof (an API name, a version). Don't blockquote a page. Don't dump every page you opened.
- **Forward task** → the normal answer with citations woven in. No separate report.
- **Explicit audit of a long list or pasted plan** → same verdict line. List only the misses, worst first. Don't list claims that were fine. A table only if the misses themselves are many and a table is easier than prose.
- If everything was fine, say so plainly and stop. Don't manufacture doubt.

```
✅ Yes. The method is `includes`, not `contains` ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/includes)): "`includes(searchElement)`".

⚠️ Yes, except the name: `Map` uses `has`, not `contains` ([MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map/has)).
```

## 5. Boundaries

- vet **reports/answers — it doesn't apply changes.** After an audit, wait for approval before editing. End-of-slice "final review" / "final double check" / "close this out" is `pass`, which vets then patches.
- Bigger than a cross-check? Open-ended exploratory research gets a standalone deep-research round. Confirming a code change works means running it locally; don't web-search a local correctness check.
