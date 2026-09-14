---
name: tldr
description: 'TL;DR-first skimmable technical writing: lead with the answer, then reveal detail progressively. Use when the user says "tldr", "tl;dr", "tldr this", "give me a tldr", "summarize this", "where are we", "catch me up", or asks for a skimmable summary. Bare invocation summarizes the last few messages; with an argument, summarizes a topic, file, URL, pasted text, the actual code changes (`changes`), a PR (`pr <number|url>`), or the whole session (`session` for the full arc). Do not use for explaining work you just finished (that is Communication / Session flow), a walkthrough, or "what changed" about a library or version (that is vet).'
argument-hint: "[<topic>|<file path>|<url>|<text>|changes|pr <number|url>|session]"
---

# TL;DR

Produce TL;DR-first, skimmable technical writing. Lead with the answer, then progressively reveal detail. A reader who stops at the TL;DR walks away correct; a reader who continues learns more, not different.

Voice matches global Communication. Don't recap at the end. A TL;DR headed for posted output (a PR body, a commit, a ticket comment) follows the global External writing rules.

## What to summarize

Bare `/tldr` summarizes the last few messages: what was just asked, just done, just decided. Don't roll up the whole session by default; pull earlier context only when it is needed to make sense of what was just said.

With an argument, summarize whatever it names, routed by what it is rather than by a keyword:

- The **code changes** (`changes`, or any phrasing like "what changed", "the diff", "what we did to the code"): `git status`, the diff against the merge base or the uncommitted diff, and recent commits. Ground truth over chat claims.
- A **PR** (`pr <number|url>`, or a PR URL): `gh pr view` for title, body, and review comments, plus `gh pr diff`. Talk *about* PRs, such as why one was or wasn't opened, stays a topic.
- The **whole session** (`session`): the full arc since it started, same skeleton as the default with a wider window. Opt-in because it is expensive.
- A **file path** that exists on disk, a **URL**, or **pasted text**: read or fetch it and summarize that. A short word that could be a file or a topic is a file first; on not-found it is a topic.
- Anything else is a **topic**: what was discussed about it in the recent conversation.

This skill is for single-session and ad-hoc summaries, not week-scale rollups across many sessions.

## Output shape: pick by what you're summarizing

Drop any section that doesn't apply; trivial inputs get a one-line direct answer, no template.

- **Recent exchange or session**: TL;DR of where things stand in app terms, then decisions made (with the one-line why), open questions / next steps, and files touched if any. Build the narrative from your conversation memory, but pull concrete artifacts (file paths, branch names, ticket IDs, tools invoked) from your tool-use history, not from recall. If the exchange included code edits the user wasn't watching, cross-check the story against `git status` / `git diff` before telling it; chat claims can drift from the tree. State the end state (works, broken, unverified) explicitly. A trivial exchange (a one-line acknowledgment, a fix-this-typo) gets a one-line answer and nothing more.
- **Recommendation / substantive answer**: the pick first, then why it wins, then what to skip / tradeoffs. If recommending A over B, say what B is good for and why A wins here.
- **Document, article, or pasted text**: a one-to-three-sentence thesis, then key points, then details only when the source has nuance worth preserving.
- **Changes or a PR**: what it changes and why in 1-3 sentences, in app terms rather than file names, then risk areas worst-first, what to review first, and anything broken or unverified. Mention tests only if they exist in the diff; never invent coverage. Read the diff before summarizing; don't summarize a diff from its description.

## Worked example

User: `/tldr` after a few exchanges debugging an SSR hydration mismatch on `tc/dark-mode`.

```
TL;DR
Dark mode no longer flashes light on first paint. The html class
differed between server and client; suppressHydrationWarning was
cheaper than blocking paint.

Decisions made
- suppressHydrationWarning on <html>: simplest fix; the DOM truly
  does differ between server and client by design.
- Rejected blocking paint via inline <head> script: 30ms FCP cost
  doesn't justify the cleaner DOM.

Open questions / next steps
- Verify lighthouse score didn't regress.
- Designer review on dark-mode token mappings still pending.

Files touched
- src/app/layout.tsx
```
