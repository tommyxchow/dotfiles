# Long work: handoffs and mechanical loops

Read this before handing work to another session or model, including when the global fresh-session split says to stop, and before a mechanical edit across many files, as the global instructions say.

## Handing work to another session or model

- When work does move to another model or session, the plan carries everything the builder needs: approved scope, decisions, constraints, code entry points, checks, and current progress. The builder owns the implementation details.
- The plan also carries its stop conditions: the code no longer matches the plan, the debugging budget in the global instructions runs out, or the fix needs a file the plan put out of scope. On any of those, the builder stops and reports instead of improvising.
- The fresh-session split still applies during `ship it`. The plan then records that `ship it` is in progress, so the next session resumes the loop.

## Mechanical jobs

- **A big mechanical job is a script first, then a loop.** When the same edit applies across many files and the edit is regular, write it as a script or codemod, because a script can't drift.
- When the edit can't be expressed as a script, prove the pattern on two or three files, then run it as one isolated invocation per file with only the tools that edit needs. One session working through forty files drifts partway down the list.
