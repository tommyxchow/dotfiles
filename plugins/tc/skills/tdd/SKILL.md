---
name: tdd
description: 'Builds new behavior and fixes bugs one failing test at a time. Use for tdd, test first, red green, or the build workflow when behavior can be asserted. State the cases, observe the relevant failure, then implement the smallest passing change. Skip for exploration with no settled behavior, config, docs, styling, and mechanical edits. Not an existing-code coverage sweep, cleanup (polish), or defect hunt (review).'
argument-hint: "[<behavior to build or bug to fix>] [cases: <the cases you want>]"
---

# TDD

Grow the feature and tests together. Watching a test fail for the right reason provides evidence that it detects the behavior it claims to check; independently chosen expectations still matter.

`$ARGUMENTS`: the behavior to build or the bug to fix, plus any cases the user already has in mind. Cases they name go in as given.

## 1. Does the loop fit?

Decide first and say which way in one sentence. Don't ask.

- **It fits** when the change has an observable result: a function or module with inputs and outputs, business rules, a parser or format, an API route, a bug with a reproduction. A bug fix always starts here, because the regression test is the proof the fix works.
- **It doesn't fit** when there is nothing to assert yet: exploration where the shape is still unknown, config, docs, copy, styling and visual layout, a change with no behavior change (a rename, a moved file), a throwaway script. Say so and build it normally, with the repo's usual tests after. Size is not the test: a one-line permission fix has behavior and fits.
- **It half fits** more often than either. Take the part with observable behavior through the loop and build the rest normally. A form's validation rules are testable; which shade of grey the error text is, is not.

## 2. Name the cases before the first test

Never write a test at a boundary you chose silently.

- **If the plan has an acceptance checklist**, that is the list: one or more cases per criterion, in the criterion's words. Add the edges it didn't mention, and say which ones you added.
- **If the user gave cases**, those are the list. Add the edges they didn't mention, and say which ones you added.
- **If neither, derive them**: the happy path, the edges most likely to break (empty, one, many, the boundary value, the error path), and for a bug, the exact failure reported.
- **Changing code that has no tests**: pin its current behavior first with a characterization test (assert what it does today, even the odd parts), then start the loop for the change. Otherwise you can't tell a deliberate change from an accident.
- **Say where you'll test them.** The function, the module's public surface, the route's response, what the component renders. Pick the outermost boundary that still fails for one clear reason, because a test bound to internals breaks on every refactor and proves nothing about behavior.
- **Then start.** State the list and the boundary in a few lines and go. Stop and ask only when the boundary is a real design decision, such as inventing a new module seam to make something testable.

If testing a case means reaching inside the thing under test, that is a design signal. Say it, and either restructure or move the boundary out.

## 3. The loop

Find the repo's own test command before the first run: the package manifest's scripts, the test config, CI, the Makefile. Never assume `npm test`. If the repo has no test setup at all, stop and say so rather than picking one: a test framework is a new dependency and that is the user's call, not a side effect of building a feature. Run the narrowest target that covers the case, a single file or a single test name, and save the full suite for the end.

One case at a time, all the way through, then the next:

1. **Write one failing test** for one case.
2. **Run it and read the failure.** It has to fail for the reason the case describes. A failure from a typo, a missing import, or a broken fixture is not red: fix it and run again. A test that passes before the code exists usually means the test asserts nothing, so fix the test. If instead the behavior already exists and no other test covers it, keep it and say so: it is acceptance evidence for that criterion, not a red-green step.
3. **Write the smallest code that passes.** No extra cases, no speculative branches, no handling for a case you haven't written a test for yet.
4. **Run it again and see green.**
5. **Next case.**

Never write the implementation first and backfill the tests around it. If the code for a case already exists and a test already covers it, the loop is over for that case; don't add a second test that recomputes what the code does.

## 4. What makes a test worth keeping

Follow the testing rules under global Working preferences for meaningful failures, independently checked expectations (including reviewed snapshots), dependencies, isolation, and retries. Four more on top of those:

- **Assert what the caller can see**: the return value, the rendered output, the response body, the row that got written. Not which internal functions were called, and not how many times.
- **Name the case, not the function.** "rejects an expired token", not "test login".
- **Mock a boundary, not the behavior under test.** An owned vendor wrapper or intercepted network request can isolate a test. Mocking an app module is not by itself a reason to restructure; check whether it hides the behavior this test should exercise before moving the boundary.
- **One reason to fail per test.** Two assertions about the same behavior are fine; two behaviors are two tests. Duplication between tests is fine, since a test should read top to bottom without chasing a helper.

## 5. Close

Say which cases are covered and which you deliberately left out, then run the repo's full check once. Name each test against its acceptance criterion when there is a checklist, since `pr` reads that as the criterion's evidence. Reshaping the code you just wrote is `polish`. Hunting defects in it is `review`. Neither runs here.

```
Built the retry backoff with cases for the initial delay, doubling, the cap, and non-retryable errors. Each test failed first for its own reason before the code went in. For jitter, controlled random inputs at the low and high ends verify the permitted delay range without depending on a seed or real time.
```
