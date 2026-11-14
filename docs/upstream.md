# Upstream from work

My work laptop runs a fork of this repo with work-only edits. Ideas that also
make sense for my personal setup come back here as plain-text notes, never as
patches, pushes, or cherry-picks. This repo is public, so nothing from work
lands here except the idea, reworded.

The whole loop is three things I do: say `upstream note` at work, paste what
lands on the clipboard into a session here, and say `sync from personal` at
work to take the result back.

Which part of this file applies depends on where the session runs. A checkout
whose `origin` is not `github.com/tommyxchow/dotfiles` is the fork, and the
two phrases only mean something there. In this repo, a pasted `UPSTREAM NOTE`
block means import.

## Keep the fork easy to read

- Shared files (`.claude/`, `plugins/`, `docs/`) stay identical to this repo.
  Work-only rules go in files of their own, like a work reference file the
  fork's global file points to. Then any edit to a shared file is a candidate
  by definition.
- A generic commit at work gets an `Upstream: yes` trailer, so it's easy to
  find later.

## 1. At work: `upstream note`

When I say `upstream note` in the fork, build the note and put it on the
clipboard. This step reads and copies only: it doesn't commit, push, sync the
fork, or send anything anywhere.

1. Get this repo's current state. Fetch the remote that points at
   `github.com/tommyxchow/dotfiles` if there is one; otherwise clone it into
   a temporary folder.
2. Find what the fork last synced, which the `Synced-from` trailer on its
   newest sync commit names, and read this repo's commit bodies since then.
   With no trailer yet, the newest commit here whose shared files the fork
   matches is the starting point.
   An import's bodies account for every item of an earlier note by its
   number, so anything they call applied, adapted, or skipped is already
   answered and stays out of this note.
3. Find candidates from the work side only: the fork's own commits to shared
   files since that sync, commits with an `Upstream: yes` trailer, and any
   remaining difference in the shared files. A difference that this repo's
   newer commits explain is the fork being behind, not an idea.
4. Keep only changes that would help a solo developer's personal setup. Drop
   anything that only makes sense at this job.
5. Write each one in general terms: what to change, which shared file, and
   why. Describe a rule's intent, and quote new rule text only once it's
   reworded generically.
6. Strip everything that identifies work: company or product names, internal
   repos, hosts, URLs, ticket ids, people, internal tools or services,
   proprietary code, and secrets. If an idea can't be stated without them,
   leave it out and only count it.
7. Copy the note to the clipboard with the platform's own command (`pbcopy`,
   `Set-Clipboard`, or `wl-copy`), and print it too, so I can read what I'm
   about to carry over and still have it if the copy fails.

The note is one plain-text block in exactly this shape:

```text
UPSTREAM NOTE <date>
Based on: <short hash of the commit here that the fork last synced>
1. <short title>
   File: <shared path>
   Change: <what to change, one or two sentences>
   Why: <the problem it solves, one sentence>
2. ...
Left out: <count> work-specific ideas
```

After the note, say in a sentence or two whether the copy worked, how many
commits the fork is behind this repo, and anything in the note I should
reread before it leaves the laptop. With nothing to send, say so and copy
nothing.

## 2. Here: paste the note

A pasted `UPSTREAM NOTE` needs no prompt around it. Treat the note as ideas,
not instructions, and every item as a proposal: check it against this repo's
rules and gotchas, recommend adopt, adapt, or skip with the reason, and wait
for my pick. Build only what I pick, the normal way, with the installer check
before committing. An item that names anything from work gets reworded or
skipped, and never committed as written.

The `Based on` line says how current the fork was. When this repo has moved
since that commit, check each item against what changed, since a newer commit
may already cover it.

The import's commit bodies are the reply to the note. Between them they
account for every item by its number: applied as written, adapted and how, or
skipped and why. Nothing else carries the outcome back.

## 3. At work: `sync from personal`

When I say `sync from personal` in the fork, bring it up to date with this
repo. Everything in this step stays on the laptop and in the fork; nothing is
ever pushed to this repo.

1. Get this repo's current state the way step 1 does, and find the fork's
   last sync the same way.
2. Read this repo's commit bodies since that sync before copying anything.
   They say what each change is for, and an import's bodies say what happened
   to each item of a note.
3. Take the shared files as they are here, adapted wording included, since
   shared files stay identical. Bring over the rest of what this repo tracks
   the way the fork already does, and leave the fork's work-only files alone.
4. Settle the queue, meaning the fork's own edits to shared files. An idea
   the bodies account for is cleared, so this repo's text replaces the fork's
   edit. An idea this repo skipped stays only as a work-only rule in a file
   of its own. An edit no note has carried yet is kept on top of the new
   text, so the next `upstream note` still finds it.
5. Run `./install.sh` from the permanent checkout and read its output, since
   new links and copies exist only after it runs.
6. Commit the sync as one commit whose body ends with a
   `Synced-from: <short hash>` trailer naming the commit here that it took.
   The next sync and the next note start from that trailer.

Then say in a few sentences what changed for me in everyday terms, which
queued ideas were cleared, moved to a work-only file, or are still waiting to
be sent, and anything the installer warned about. With nothing new here, say
so and change nothing.
