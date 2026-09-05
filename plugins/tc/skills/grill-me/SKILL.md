---
name: grill-me
description: A relentless interview that stress-tests a plan, design, or decision before any code gets written. Maps the open decisions as a tree, asks one round of them at a time with a recommended answer on each, and looks up its own facts rather than asking. Offer it when a plan leaves a real choice open; the user starts it. Ends with the plan restated as settled, never with code.
argument-hint: "[<plan, design, or decision to stress-test>]"
disable-model-invocation: true
---

# Grill me

Interview until the plan has no unexamined branches left. Finding the questions is your job. Answering them is the user's.

`$ARGUMENTS` is the subject. With none, take the plan or idea last discussed.

## The tree

Every decision branches into the decisions that hang off it. The **frontier** is every decision whose prerequisites are already settled: the ones you can ask now without guessing at an answer you haven't heard yet.

Ask the whole frontier in one round. A question whose answer depends on another question still open in this round belongs to the next round, not this one. Each round the user answers pushes the frontier outward and unblocks whatever was waiting behind it.

## A round

Number the questions and put your own recommended answer on each, so the user can agree in a word instead of writing an essay. Then stop and wait. The decisions are theirs: never answer your own round and carry on.

```
**Q1: <short title>**

<the question, with the options where there are any>

Recommend: <your answer, and the one-line why>

**Q2: <short title>**

<...>
```

## Find your own facts

A question that a file, a command, or the docs can answer is not a question for the user. Look it up. Version, API, and "latest" facts follow `vet`. Don't hold the round for it: only the questions downstream of that fact wait, so ask the rest now.

## How long

Size it to the plan. Two or three real decisions is one round, and one round can be the whole session. Don't invent rounds to look thorough, and don't ask about anything the plan already answers.

## Done

Done when the frontier is empty: every branch visited, nothing left silently assumed. Close by restating the plan as settled, in the user's own decisions, and stop there. No code until the user confirms it reads right.
