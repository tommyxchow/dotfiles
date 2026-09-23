---
name: grill-me
metadata:
  opencode/slash: "true"
description: A relentless interview that stress-tests a plan, design, or decision before any code gets written. Maps the open decisions as a tree, asks one round of them at a time through the harness's question tool with a recommended answer on each, and looks up its own facts rather than asking. Run it when a plan leaves a real choice open, when the user says grill me, or when a described idea is too thin to build from. Ends with the plan restated as settled plus a numbered acceptance checklist, never with code.
argument-hint: "[<plan, design, or decision to stress-test>]"
---

# Grill me

Keep interviewing until no branch of the plan is left unexamined. Finding the questions is your job. Answering them is the user's.

`$ARGUMENTS` is the subject. When there is none, take the plan or idea discussed most recently. A casual idea or a GitHub issue counts as a plan. A thin one just has a bigger frontier.

## The tree

Each decision leads to the further decisions that depend on it. The **frontier** is every decision whose prerequisites are already settled, meaning the ones you can ask now without guessing at an answer you haven't heard yet.

Ask the whole frontier in one round. A question whose answer depends on another question still open in this round belongs to the next round, not this one. Each round the user answers moves the frontier forward and makes askable the decisions that were waiting on those answers.

## What earns a question

A question is worth asking when its answer changes what gets built. Drop everything else: anything the plan already settles, anything with one sensible answer that you can take yourself and mention as you go, and anything you could look up. Three questions that uncover a branch nobody had thought about are better than eight that repeat the plan back to the user. More questions are fine when every one of them is real, but don't pad the round.

A ticket usually says nothing about some things that a PM notices on the first click: the empty, loading, and error states of new UI, what happens on a retry or a double submit, and who else is affected by a shared change. Ask about those when the plan doesn't answer them.

## A round

Follow the global Session flow rules for question tools and the text fallback. Give each question a short title. Answers that change the remaining frontier come before the next round. The decisions are the user's, so never answer your own round and carry on.

Either way, the message that carries the round also names the decisions you took yourself and why, in a short paragraph. That lets the user veto any of them in the same reply as their answers.

## Find your own facts

When a file, a command, or the docs can answer a question, it is not a question for the user, so look it up. For version, API, and "latest" facts, follow `vet`. Don't hold up the round while you look. Only the questions that depend on that fact wait, so ask the rest now.

## How long

Size the interview to the plan. Two or three real decisions make one round, and one round can be the whole session. Don't invent rounds to look thorough, and don't ask about anything the plan already answers.

## Done

The interview is done when the frontier is empty, meaning every branch has been visited and nothing is left silently assumed. Close by restating the plan as settled, in terms of the user's own decisions, and end it with a numbered acceptance checklist. The checklist holds the ticket's criteria plus the edges the interview surfaced, the test or check each one maps to, and what is explicitly out of scope. That checklist guides implementation and verification, and it supplies the evidence if the work goes to a PR; planning does not decide that. Stop there, and don't write any code until the user confirms the plan reads right.
