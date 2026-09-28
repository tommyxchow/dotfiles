---
name: tdd
metadata:
  opencode/slash: "true"
description: 'Builds new behavior and fixes bugs one failing test at a time. Use for tdd, test first, red green, or the build workflow when behavior can be asserted. Skip for exploration with no settled behavior, config, docs, styling, and mechanical edits. It is not for an existing-code coverage sweep, cleanup (polish), or a defect hunt (review).'
argument-hint: "[<behavior to build or bug to fix>] [cases: <the cases you want>]"
---

# TDD

Build the feature and its tests together. Watching a test fail for the right reason is evidence that it detects the behavior it claims to check. Independently chosen expectations still matter, though.

`$ARGUMENTS` holds the behavior to build or the bug to fix, plus any cases the user already has in mind.

## 1. Does the loop fit?

Decide this first, then say in a sentence whether you'll write the tests first, and for which part when only some of it fits. Don't ask.

- **It fits** when the change has an observable result: a function or module with inputs and outputs, business rules, a parser or format, an API route, a bug with a reproduction. A bug fix starts here whenever its behavior can be asserted, because the test for the corrected behavior is the proof that the fix works.
- **It doesn't fit** when there is nothing to assert yet: exploration where the shape is still unknown, config, docs, copy, styling and visual layout, a change with no behavior change (a rename, a moved file), a throwaway script. Say so, build it normally, and add the repo's usual tests afterward. The size of the change doesn't decide fit. A one-line permission fix has behavior, so it fits; whether a small unplanned change is worth the loop is the global sizing rule's call, and its test for the corrected behavior is written either way.
- **It half fits** more often than either. Take the part with observable behavior through the loop and build the rest normally. For example, a form's validation rules are testable, but which shade of grey the error text is, is not.

## 2. Name the cases before the first test

- **If the plan has an acceptance checklist or the user gave cases**, that is the list, used as given. Write one or more cases per checklist criterion, in the criterion's words. Either way, add the edges they didn't mention and say which ones you added.
- **If neither, derive them**: the happy path, the sad paths a user can hit, the edges most likely to break (empty, one, many, the boundary value), with realistic data, and for a bug, the exact failure reported.
- **If you're changing code that has no tests**, pin its current behavior first with a characterization test, which asserts what the code does today, even the odd parts. Then start the loop for the change. Without that test, you can't tell a deliberate change from an accident.
- **Say where you'll test them.** That might be the function, the module's public surface, the route's response, or what the component renders. Pick the outermost boundary that still fails for one clear reason, because a test bound to internals breaks on every refactor and proves nothing about behavior.
- **Then start.** Say in a sentence or two which cases you'll cover and where the tests will check the behavior, then go. Stop and ask only when the boundary is a real design decision, such as inventing a new module seam to make something testable.

If testing a case means reaching inside the thing under test, treat that as a signal about the design. Say so, and either restructure the code or move the boundary out.

## 3. The loop

Find the repo's own test command before the first run by checking the package manifest's scripts, the test config, CI, and the Makefile. Don't assume `npm test`. If the repo has no test setup at all, don't pick one, because a test framework is a new dependency, which is the user's call. Send a notification asking that question, keep building with the checks the repo does have, and mark the untested criteria unverified in the ledger. Run the narrowest target that covers the case, a single file or a single test name, and save the local check for the end.

Take one case all the way through before starting the next:

1. **Write one failing test** for one case.
2. **Run it and read the failure.** It has to fail for the reason the case describes. A failure from a typo, a missing import, or a broken fixture doesn't count as red, so fix it and run again. A test that passes before the code exists usually means the test asserts nothing, so fix the test. If instead the behavior already exists and no other test covers it, keep the test and say so. It is acceptance evidence for that criterion, not a red-green step.
3. **Write the smallest general code that passes.** It has to work for every valid input the case describes, not only the test's, so don't special-case the test's inputs beyond what the case itself describes, and never return its expected value. The test checks the behavior; it doesn't define it. Don't add extra cases, speculative branches, or handling for a case you haven't written a test for yet.
4. **Run it again and see green.**
5. **Move to the next case.**

Don't write the implementation first and then backfill the tests around it. If the code for a case already exists and a test already covers it, the loop is over for that case. Don't add a second test that recomputes what the code does. When a later decision replaces a case you already tested, fix or delete that test under the final-behavior rule in `~/.claude/references/testing.md`.

## 4. What makes a test worth keeping

Follow the testing rules in `~/.claude/references/testing.md` and the three under global Working preferences. Three more rules apply on top of those:

- **Assert what the caller can see**: the return value, the rendered output, the response body, the row that got written.
- **Mock a boundary, not the behavior under test.** Mocking an app module is not by itself a reason to restructure. Check whether the mock hides the behavior this test should exercise before you move the boundary.
- **Give each test one reason to fail.** Two assertions about the same behavior are fine. Two behaviors belong in two tests.

## 5. Close

Say which cases are covered and which you deliberately left out, then run the local check once. Quote each test's first failure line, since a red step nobody saw proves nothing. When there is a checklist, name each test against its acceptance criterion, since `pr` reads that as the criterion's evidence. Reshaping the code you just wrote is `polish` and hunting defects in it is `review`; neither runs here.

```
Built the retry backoff with cases for the initial delay, doubling, the cap, and non-retryable errors. Each test failed first for its own reason before the code went in, for example `expected 200, received 100` on the doubling case. For jitter, controlled random inputs at the low and high ends verify the permitted delay range without depending on a seed or real time.
```
