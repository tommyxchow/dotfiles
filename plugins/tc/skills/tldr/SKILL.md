---
name: tldr
metadata:
  opencode/slash: "true"
description: 'TL;DR-first skimmable technical writing: lead with the answer, then reveal detail progressively. Use when the user says "tldr", "tl;dr", "tldr this", "give me a tldr", "summarize this", "catch me up", or asks for a skimmable summary. Bare invocation summarizes the last few messages; with an argument, summarizes a topic, file, URL, pasted text, the actual code changes (`changes`), a PR (`pr <number|url>`), or the whole session (`session` for the full arc). Do not use for explaining work you just finished (that is Communication / Session flow), a walkthrough, or "what changed" about a library or version (that is vet).'
argument-hint: "[<topic>|<file path>|<url>|<text>|changes|pr <number|url>|session]"
---

# TL;DR

Produce TL;DR-first, skimmable technical writing. Lead with the answer, then reveal detail progressively. A reader who stops after the TL;DR still has the right picture, and a reader who keeps going learns more detail, not a different answer.

Write in the voice the global Communication section describes. When a TL;DR is headed for posted output (a PR body, a commit, a ticket comment), it also follows the global External writing rules.

Don't end with a recap.

## What to summarize

Bare `/tldr` summarizes the last few messages: what was just asked, just done, and just decided. Don't summarize the whole session by default. Pull in earlier context only when it is needed to make sense of what was just said.

With an argument, summarize whatever it names. Route it by what kind of thing it is, not by a keyword:

- The **code changes** (`changes`, or any phrasing like "what changed", "the diff", "what we did to the code"): read `git status`, the diff against the merge base or the uncommitted diff, and recent commits. What the repo shows wins over what the chat claims.
- A **PR** (`pr <number|url>`, or a PR URL): read the title, body, and review comments with `gh pr view`, plus the diff with `gh pr diff`. A conversation *about* PRs, such as why one was or wasn't opened, is still a topic.
- The **whole session** (`session`): summarize everything since the session started, with the same structure as the default and a wider window. It is opt-in because it is expensive.
- A **file path** that exists on disk, a **URL**, or **pasted text**: read or fetch it and summarize that. Treat a short word that could be a file or a topic as a file first, and as a topic when no such file is found.
- Anything else is a **topic**: summarize what was discussed about it in the recent conversation.

This skill covers single-session and ad-hoc summaries. It doesn't cover week-scale rollups across many sessions.

## Output shape: pick by what you're summarizing

Drop any section that doesn't apply. Trivial inputs get a one-line direct answer with no template.

- **Recent exchange or session**: open with a TL;DR of where things stand in app terms, then the decisions made (each with its one-line why), open questions / next steps, and files touched if any. Build the narrative from your conversation memory, but take concrete artifacts (file paths, branch names, ticket IDs, tools invoked) from your tool-use history, not from recall. If the exchange included code edits the user wasn't watching, cross-check the story against `git status` / `git diff` before telling it, because what the chat says can stop matching the working tree. State the end state (works, broken, unverified) explicitly. A trivial exchange (a one-line acknowledgment, a fix-this-typo) gets a one-line answer and nothing more.
- **Recommendation / substantive answer**: give the pick first, then why it wins, then what to skip / tradeoffs. If you recommend A over B, say what B is good for and why A wins here.
- **Document, article, or pasted text**: give a one-to-three-sentence thesis, then the key points, then details only when the source has nuance worth preserving.
- **Changes or a PR**: say what it changes and why in 1-3 sentences, in app terms rather than file names. Then give the risk areas worst-first, what to review first, and anything broken or unverified. Mention tests only if they exist in the diff, and never invent coverage. Read the diff before summarizing, rather than summarizing a diff from its description.

## Worked example

User: `/tldr` after a few exchanges debugging an SSR hydration mismatch on `dark-mode`.

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
