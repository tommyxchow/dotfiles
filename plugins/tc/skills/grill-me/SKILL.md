---
name: grill-me
description: A relentless interview that stress-tests a plan, design, or decision before any code gets written. Maps the open decisions as a tree, asks one round of them at a time through the harness's question tool with a recommended answer on each, and looks up its own facts rather than asking. Run it when a plan leaves a real choice open, when the user says grill me, or when a described idea is too thin to build from. Ends with the plan restated as settled plus a numbered acceptance checklist, never with code.
argument-hint: "[<plan, design, or decision to stress-test>]"
---

# Grill me

Interview until the plan has no unexamined branches left. Finding the questions is your job. Answering them is the user's.

`$ARGUMENTS` is the subject. With none, take the plan or idea last discussed. A casual idea or a GitHub issue counts as a plan; a thin one just has a bigger frontier.

## The tree

Every decision branches into the decisions that hang off it. The **frontier** is every decision whose prerequisites are already settled: the ones you can ask now without guessing at an answer you haven't heard yet.

Ask the whole frontier in one round. A question whose answer depends on another question still open in this round belongs to the next round, not this one. Each round the user answers pushes the frontier outward and unblocks whatever was waiting behind it.

## What earns a question

A question earns its place when the answer changes what gets built. Drop everything else: anything the plan already settles, anything with one sensible answer you can take yourself and just name as you go, and anything you could look up. Three questions that expose a branch nobody had thought about beat eight that survey the plan back at the user. More questions are fine when they are all real; padding is not.

Things a ticket usually leaves silent and a PM finds on the first click: the empty, loading, and error states of new UI, what happens on a retry or a double submit, who else is affected by a shared change. Ask about those when the plan doesn't answer them.

## A round

Follow the global Session flow rules for question tools and the text fallback. Give each question a short title. Answers that change the remaining frontier come before the next round. The decisions are theirs: never answer your own round and carry on.

Either way, the message that carries the round also names the decisions you took yourself and why, in a short paragraph, so the user can veto any of them in the same breath.

## Find your own facts

A question that a file, a command, or the docs can answer is not a question for the user. Look it up. Version, API, and "latest" facts follow `vet`. Don't hold the round for it: only the questions downstream of that fact wait, so ask the rest now.

## How long

Size it to the plan. Two or three real decisions is one round, and one round can be the whole session. Don't invent rounds to look thorough, and don't ask about anything the plan already answers.

## Done

Done when the frontier is empty: every branch visited, nothing left silently assumed. Close by restating the plan as settled, in the user's own decisions, and end it with a numbered acceptance checklist: the ticket's criteria plus the edges the interview surfaced, the test or check each one maps to, and what is explicitly out of scope. That checklist guides implementation and verification, and supplies the evidence if the work goes to a PR; planning does not decide that. Stop there. No code until the user confirms it reads right.
