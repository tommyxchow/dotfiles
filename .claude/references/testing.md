# Writing tests

Read this before writing or changing a test, as the global instructions say. The global file keeps the three core rules: new behavior gets tests, a bug fix starts with one, and a failing test is fixed in the code, never loosened.

- Before a behavior-preserving refactor of untested logic, add a characterization test that pins what the code does today. A deliberate behavior change is not one of these; don't pin the behavior you are replacing.
- Don't add test scaffolding for formatting, a mechanical rename, or a similarly low-impact edit with no behavior change.
- Test at the lowest level that can catch the failure: pure logic as a unit test, wiring as an integration test, and end-to-end only on critical journeys.
- Tests assert what the user sees. A UI test finds elements the way a user does, by role and visible label, with a test id as the last resort.
- **Tests match the final behavior.** The tests in a change describe how the code works when the change is done. When the behavior changes along the way, update or delete the test for the earlier version rather than leaving both.
- Don't add a test that only records a step you passed through, including a check that the old value is absent (`not`, `not.toContain`, `not in` the value you removed). A negative test stays when the absence is something a user can observe today, like no email sent without consent or a viewer getting a 403. It goes only when its sole reason is a state the code passed through, like asserting a removed config key is gone.
- **Size tests to the behavior**: roughly one focused test per stated behavior, in the repo's test style. Look for a test that already covers the case before adding one.
- Don't write a test to move a coverage number. Coverage finds untested code; it doesn't grade tests.
- Neighboring tests set the style and the scale. Where they are weak, write to the rules below rather than copying the weakness.
- Don't commit scratch checks, one-off scripts, or a focused or skipped test.
- A test must catch a relevant incorrect behavior. Deleting the implementation is one useful way to check that, not a universal rule, since a test that forbids an unwanted side effect may still pass.
- Check expected results independently of the implementation. Hand-written values and reviewed, focused snapshots both count; recomputing the same logic or accepting output you haven't read does not.
- Test the outcome, not the wording or the wiring. Assert a literal string, a constant, or a config value only when that exact value is the behavior, like an error message a user reads or a field another system parses.
- A test that only proves a framework or library works, or that a mock was called, tests nothing of ours.
- A test that has to change when the code is refactored without a behavior change is testing the implementation. Assert the outcome instead, or drop the test.
- A test reads top to bottom as one story (set up, act, assert) and is named for the behavior. Prefer plain duplication over a shared helper, and use no loops or conditionals.
- When a test fails, its message says what was expected and what happened, so the cause is obvious without a debugger.
- Use real dependencies where practical. At a slow, nondeterministic, or out-of-process boundary, prefer a fake (a small working stand-in) over a stub or mock.
- For vendor SDKs, prefer a wrapper you own when one fits; intercepting network requests is also valid.
- Keep tests fast and deterministic: fake the clock, and never wait with a sleep.
- Each test sets up its own state and passes alone and in any order.
- Keep auto-waiting and retrying assertions. Whole-test retries don't prove flakiness is fixed: fix the cause, and keep the repo's retry configuration unless changing it is part of the task.
- When any other test is wrong, say so and show why before changing it.
