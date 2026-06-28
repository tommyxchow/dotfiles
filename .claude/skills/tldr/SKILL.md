---
name: tldr
description: TL;DR-first skimmable technical writing: lead with the answer, then reveal detail progressively. Use when the user asks for a "tldr"/"tl;dr", a summary, "where are we", or "catch me up". Bare invocation summarizes the last few messages; with an argument, summarizes a topic, file, URL, pasted text, or the whole session.
when_to_use: Trigger when the user says "tldr", "tl;dr", "tldr this", "give me a tldr", "summarize this", "where are we", "catch me up", or asks for a skimmable summary. Bare = last few messages only; pass `session` for the full arc.
argument-hint: "[<topic>|<file path>|<url>|<text>|session]"
allowed-tools:
  - "Read"
  - "WebFetch"
---

# TL;DR

Produce TL;DR-first, skimmable technical writing. Lead with the answer, then progressively reveal detail. A reader who stops at the TL;DR walks away correct; a reader who continues learns more, not different.

The invocation argument is `$ARGUMENTS` (empty on bare `/tldr`).

## Argument routing

| `$ARGUMENTS` | Source to summarize |
|---|---|
| **empty** (default) | The last few messages: what was just asked, just done, just decided |
| `session` | The full session arc since it started (opt-in, expensive) |
| Path to a file (exists on disk) | Read the file, TL;DR its content |
| URL (`http://` or `https://`) | WebFetch it, TL;DR the page |
| Multi-line pasted text | TL;DR that text |
| Short phrase / topic name | TL;DR what was discussed about that topic in the recent conversation |

For ambiguous strings (e.g. a short word that could be a topic or a filename), try `Read` first; on a not-found error, treat it as a topic.

This skill is for single-session and ad-hoc summaries, not week-scale rollups across many sessions.

## Output shape: pick by what you're summarizing

The skeleton is flexible. **Drop any section that doesn't apply.**

### Shape A: Recent exchange or session summary (default and `session` modes)

```
TL;DR
<one or two sentences: what we've been doing and where we are right now>

Decisions made
- <decision>: <one-line why>
- ...

Open questions / next steps
- <next action or unresolved question>
- ...

Files touched  (only if any were created/edited)
- file_path: <what changed>
```

Anchor decisions and next steps in concrete artifacts (file paths, ticket IDs, branch names) when they exist.

### Shape B: Recommendation / answer to a substantive question

```
TL;DR
<the conclusion or recommendation>

Why
- Key reason
- Key impact
- Key tradeoff considered

Tradeoffs / Risks  (only when they exist and matter)
- Constraint
- Edge case
- Downside

Details
<deeper technical explanation, code references, examples, alternatives>
```

### Shape C: Document, article, or pasted text

```
TL;DR
<one to three sentences capturing the thesis>

Key points
- <point 1>
- <point 2>
- <point 3>

Details  (only when the source has nuance worth preserving)
<sections, quotes, or technical specifics>
```

## Rules

- **TL;DR carries the answer alone.** No surprises buried in Details.
- **Each lower section adds depth, not new conclusions.**
- **Bullets beat walls of text** for reasons, decisions, steps.
- **Short paragraphs** (2 to 4 sentences) when prose is needed.
- **Code references** use `file_path:line_number` so the user can click through.
- **Explicit tradeoffs.** If recommending A over B, say what B is good for and why A wins here.
- **No restating the question** before answering it.
- **No trailing recap** of what the user just read.
- **Cut filler.** No "It's worth noting that...", "As you may know...", "Here's the thing.", "I hope this helps.", or thought-leader hype.
- **For trivial inputs** (single-fact questions, yes/no answers, typo-scale fixes), give a one-line direct answer. Skip the template.

**Writing for posted output:** in-session TL;DRs can use em dashes freely. If a TL;DR is headed for posted output (PR body, commit, Teams/Jira comment), follow the global posted-output rules in `~/.claude/CLAUDE.md` (no em dashes, casual + lowercase voice).

## Default mode: the last few messages

When `$ARGUMENTS` is empty, summarize the most recent exchange or two using **Shape A**. Don't roll up the whole session by default. Pull earlier context only when it's needed to make sense of what was just said.

Build the narrative from your conversation memory. Pull concrete artifacts (file paths, branch names, ticket IDs, tools invoked) from your tool-use history, not from recall.

If the recent exchange is trivial (one-line acknowledgment, a fix-this-typo), give a one-line answer and stop. For the full session arc, the user passes `session` (same skeleton, wider window).

## Worked example

User: `/tldr` after a few exchanges debugging an SSR hydration mismatch on `tc/dark-mode`.

```
TL;DR
Hydration mismatch on `tc/dark-mode` traced to <html> class diverging
on first paint. Settled on suppressHydrationWarning over blocking
paint until theme resolves.

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

For substantive recommendations, use **Shape B** (Why / Tradeoffs / Details). For a file or article, use **Shape C** (Key points / Details).
