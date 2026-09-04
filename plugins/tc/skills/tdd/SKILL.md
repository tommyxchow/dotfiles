---
name: tdd
description: Test-driven loop for new behavior and bug fixes. Names the cases, writes one failing test, watches it fail for the right reason, then adds the smallest code that passes. Use when the user says tdd, test first, write the test first, red green, or asks for a test-driven approach, and for a bug fix that needs a reproducing regression test before any fix. Works from cases the user supplies or cases derived from the task and stated before the first test. Skips itself when the loop does not fit: exploratory work whose shape is unknown, config, docs, styling, or a change with no observable behavior. Not a coverage sweep over existing code, not reshaping working code (that's polish), and not defect hunting in a finished change (that's review).
argument-hint: "[<behavior to build or bug to fix>] [cases: <the cases you want>]"
---

# TDD

Grow the feature and its tests together, one failing test at a time. The loop is the point. A test you watched fail for the right reason is evidence that it can detect the thing it claims to detect, while a test written after the code usually just restates what the code already does.

`$ARGUMENTS`: the behavior to build or the bug to fix, plus any cases the user already has in mind. Cases they name go in as given.

## 1. Does the loop fit?

Decide first and say which way in one sentence. Don't ask.

- **It fits** when the change has an observable result: a function or module with inputs and outputs, business rules, a parser or format, an API route, a bug with a reproduction. A bug fix always starts here, because the regression test is the proof the fix works.
- **It doesn't fit** when there is nothing to assert yet: exploration where the shape is still unknown, config, docs, copy, styling and visual layout, a one-line change, a throwaway script. Say so and build it normally, with the repo's usual tests after.
- **It half fits** more often than either. Take the part with observable behavior through the loop and build the rest normally. A form's validation rules are testable; which shade of grey the error text is, is not.

## 2. Name the cases before the first test

Never write a test at a boundary you chose silently.

- **If the user gave cases**, those are the list. Add the edges they didn't mention, and say which ones you added.
- **If not, derive them**: the happy path, the edges most likely to break (empty, one, many, the boundary value, the error path), and for a bug, the exact failure reported.
- **Say where you'll test them.** The function, the module's public surface, the route's response, what the component renders. Pick the outermost boundary that still fails for one clear reason, because a test bound to internals breaks on every refactor and proves nothing about behavior.
- **Then start.** State the list and the boundary in a few lines and go. Stop and ask only when the boundary is a real design decision, such as inventing a new module seam to make something testable.

If testing a case means reaching inside the thing under test, that is a design signal. Say it, and either restructure or move the boundary out.

## 3. The loop

Find the repo's own test command before the first run: the package manifest's scripts, the test config, CI, the Makefile. Never assume `npm test`. If the repo has no test setup at all, stop and say so rather than picking one: a test framework is a new dependency and that is the user's call, not a side effect of building a feature. Run the narrowest target that covers the case, a single file or a single test name, and save the full suite for the end.

One case at a time, all the way through, then the next:

1. **Write one failing test** for one case.
2. **Run it and read the failure.** It has to fail for the reason the case describes. A failure from a typo, a missing import, or a broken fixture is not red: fix it and run again. A test that passes before the code exists is asserting nothing, so fix the test.
3. **Write the smallest code that passes.** No extra cases, no speculative branches, no handling for a case you haven't written a test for yet.
4. **Run it again and see green.**
5. **Next case.**

Never write the implementation first and backfill the tests around it. If the code for a case already exists, the loop is over for that case; don't add a test that recomputes what the code does.

## 4. What makes a test worth keeping

- **Assert what the caller can see**: the return value, the rendered output, the response body, the row that got written. Not which internal functions were called, and not how many times.
- **Write the expected value literally.** A test that computes the answer the same way the code does passes when the code is wrong.
- **Name the case, not the function.** "rejects an expired token", not "test login".
- **Mock only at system boundaries**: network, clock, randomness, filesystem, payment provider. Never mock your own modules; if that seems necessary, the boundary is in the wrong place.
- **One reason to fail per test.** Two assertions about the same behavior are fine; two behaviors are two tests.
- **Duplication in tests is fine.** A test should be readable top to bottom without chasing a helper.

## 5. Close

Say which cases are covered and which you deliberately left out, then run the repo's full check once. Reshaping the code you just wrote is `polish`. Hunting defects in it is `review`. Neither runs here.

```
Built the retry backoff with four cases: first retry waits the base delay, each retry doubles it, the delay is capped at the ceiling, and a non-retryable status throws instead of waiting. Each test failed first for its own reason before the code went in.

I left the jitter untested. It's random by design, and pinning it would only assert the seed.
```

## Distinct from

| Skill    | This skill                                                              |
| -------- | ----------------------------------------------------------------------- |
| `polish` | Shape of working code. TDD writes it, polish reshapes it afterwards.     |
| `review` | Finds defects in a finished change. TDD prevents a class of them upfront. |
| `pass`   | The end-of-slice closer. TDD is how the code inside the slice got built. |
| `vet`    | Checks claims against docs. TDD checks behavior against tests.           |
