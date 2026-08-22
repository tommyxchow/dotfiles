---
name: refresh
description: Occasional repo catch-up — bump to the latest versions this stack can honestly take, apply migrations, flag must-upgrades and security advisories, and vet AGENTS.md against current vendor docs. Use when the user says "refresh", "reaudit", "resync" (this product repo), "upgrade everything", "any packages we can upgrade", "catch this repo up", "outdated packages", "gonna do another release", "security audit", "dependabot", or asks to migrate to the latest stack. Distinct from the dotfiles machine playbook (docs/resync.md), polish (shape of working code), vet (claim checking), and pass (end-of-slice closer).
argument-hint: "[optimal | full | minimal | audit | packages | docs] [custom instructions]"
---

# Refresh

Repo catch-up: latest versions this stack can honestly take, plus migrations, plus a loud call-out for must-upgrades, vulns, deprecations, and things that are severely behind.

`$ARGUMENTS`: optional **mode** (first token) then **custom instructions**. Empty = `optimal`. If the first token is not a mode below, the whole argument is custom instructions on `optimal`. Security-audit / Dependabot / outdated with no upgrade language → `audit` (report only).

Honor `AGENTS.md` holds. Don't commit unless asked.

## Collision: machine vs repo

If this workspace **is the dotfiles/chow config repo** (root `install.sh` plus `docs/resync.md`): **stop**. Follow `docs/resync.md`, including `/refresh` and "resync" here. That playbook is pull, installer, plugins, leftover sweep — not packages. In any other repo, "resync" means this skill.

## Modes

| First token | Meaning |
|---|---|
| *(none)* / `optimal` | Current-major latest + required migrations. Holds stay. Majors listed, not applied. **Default. No picker.** |
| `full` | Optimal plus every major that is not a documented hold. Breaking a hold still needs a question. |
| `minimal` | Patches, lockfile, security/compat that unblocks the gate or fixes a GHSA. No feature minors, no framework story, no shadcn style. |
| `audit` / `plan` | Report only. No edits. |
| `packages` | Deps + lockfile + verify. Skip docs/UI unless a bump requires it. |
| `docs` | AGENTS.md / README / CI comments vs vendor docs. Still mention holds that sit on a GHSA. |

Examples: `/refresh full don't touch wrangler` · `/refresh minimal skip shadcn` · `/refresh don't touch wrangler` (optimal + constraint).

### When to ask

Harness question tool if it exists; otherwise one short labeled question. **Don't ask** on a clean Optimal run with no majors and no must-upgrades.

Ask once when:

1. No mode given **and** a real major (or a must-upgrade that needs a major) is sitting there: stay Optimal / include that major / Minimal only.
2. **full** would break an `AGENTS.md` hold. Options + recommendation. Don't silently undo the pin.
3. A **high/critical** GHSA is only fixable by a hold-break or an override. Show the [advisory](https://github.com/advisories) and wait.

A passed mode or custom instruction is the answer. Don't also prompt.

## Hard rules

- **pnpm / pnx** for JS. Never `npm` / `npx` / `yarn` / `npm audit`. Flutter: `flutter` / `dart`.
- Don't add a dependency, linter, formatter, CI gate, or scanner (Snyk, Socket, osv-scanner, Dependabot config) unless they ask.
- Never blanket `pnpm update --latest`. Target Apply packages with `pnpm update <pkg…>` ([pnpm update](https://pnpm.io/cli/update)): keeps the range operator, writes the resolved version. Exclude holds (`\!typescript`). An approved major: `pnpm update foo@2`. `catalog:` deps change in `pnpm-workspace.yaml`.
- Honor **`minimumReleaseAge`** (pnpm 11 default 24h). No exclude for curiosity. **Security:** `pnpm audit --fix=update` may add a targeted exclude for the patched version ([pnpm audit](https://pnpm.io/cli/audit)). Leave it, mention it.
- Don't stash/reset a dirty tree. Show `git status`; work on top or stop if the dirt is unrelated.
- **Vet** Must, the framework line, and each Apply package (installed first, then vendor changelog / [GHSA](https://github.com/advisories) / registry). Don't changelog Skip rows or load the vet skill unless a claim is disputed. Don't assert "latest" or "safe" from memory. No canary / RC / dist-tag except `latest` unless they asked (Next canary, pnpm 12 RC).
- Don't rewrite AGENTS/README to a CLI the pin doesn't ship (`pnx` needs pnpm 11). Match `packageManager` / the SDK pin.
- Don't add `allowBuilds` entries (new postinstall) unless they agreed ([pnpm supply chain](https://pnpm.io/supply-chain-security)).
- Verify with the repo's own full check (see stacks.md for this stack) plus extra jobs in the default CI workflow. Don't invent a gate the repo doesn't have. If the gate is already red, say so before bumping.
- Don't add `audit.ignore` / `ignored_advisories` without them reading the GHSA. Don't use `pnpm audit --ignore-unfixable`. Don't break a hold to quiet audit. Outdated ≠ vulnerable.

## Flow

recon → audit → classify → apply (unless `audit`/`plan`) → verify → report.

After detecting the stack, read only that section of [stacks.md](stacks.md). If none match, stop and say so.

### 1. Recon

`AGENTS.md` / `CLAUDE.md` / `pubspec.yaml` pins. Package manager, verify script, Node/`packageManager`, explicit holds.

### 2. Audit

Batch independent CLI (`git status`, outdated, audit, Dependabot if `gh` works). Depth follows mode: `minimal` / `packages` skip `ui:diff` and docs unless a bump requires it; `docs` skips outdated / `ui:diff` (still flag a hold on a GHSA).

When the tool exists:

- **Outdated:** `pnpm outdated` (`-r` in a workspace with packages; `--include-github-actions` on pnpm ≥11.16). Use Wanted vs Latest — don't pass `--compatible` as the only view or majors vanish. `outdated` can list a version still inside `minimumReleaseAge`; install honors the gate ([pnpm#11698](https://github.com/pnpm/pnpm/issues/11698)). Don't exclude except GHSA. `flutter pub outdated`. Framework stable from the vendor (blog / GitHub releases), not memory.
- **Security:** `pnpm audit --audit-level high`; glance lower severities so moderate isn't invisible. Prod first, then note if the rest is dev-only. Flutter: `flutter pub get` prints GHSAs ([Dart advisories](https://dart.dev/tools/pub/security-advisories)). `gh api repos/<owner>/<repo>/dependabot/alerts?state=open` when `gh` works — alerts are a signal, the GHSA is the source.
- **Deprecated:** from `pnpm outdated --format json` (`isDeprecated`) and audit output, not `pnpm view` on the tree. Committed config keys the vendor now flags (Next route exports, Action inputs, in-repo editor settings). Same-major documented replacement is Must. Don't migrate `~` user settings; that's the machine playbook.
- **Stale:** direct dep two+ minors behind on the same major, or a whole major behind that isn't a hold. Framework several stables behind current. Toolchain pin lagging the SDK (blocks every other upgrade).
- **Tooling:** `packageManager` vs `pnpm -v`. pnpm 12 is an RC ([what's different](https://pnpm.io/blog/whats-different-in-pnpm-12)) — toolchain major is Ask. `.nvmrc` / `engines.node` vs `@types/node` major, Actions tags (`vN` → `vN+1` with the same `with:` is Apply on Optimal). Don't run `pnpm update --include-github-actions` unless the repo already pins commit SHAs — that command rewrites tags to hashes. shadcn `ui:diff` (never `shadcn diff`) only if that CLI is in the repo and the mode includes UI. AGENTS.md vs current vendor docs unless mode is `packages` / `minimal`.

### 3. Classify

**Must** (alert first; apply in Optimal/Minimal if the fix stays on the current major): high/critical GHSA with a fix; resolved version deprecated; committed config key the vendor replaced on this line; vendor security/patch on the current framework line; pin so stale it blocks the rest of the tree.

**Apply:** Optimal = current-major latest + Must. Minimal = Must + patches only. Full = Optimal + non-hold majors.

**Ask:** new major (unless `full`); breaking a hold; new dep; shadcn style preset; `pnpm audit --fix` override (writes workspace overrides). A hold that is itself Must stays Ask.

**Skip:** unused starter deps they kept; intentional registry forks; secrets in committed config; moderate/low transitives with no fix or no production path (count them, don't pad Apply). Name unfixable GHSAs; don't hide them.

### 4. Apply

Must first, then the rest. Official order is update, then leftover GHSAs ([pnpm audit](https://pnpm.io/cli/audit)):

1. Toolchain pin (same major)
2. Framework + React + react-dom + `@types/react*` + first-party plugins as one unit (`pnpm update`, not `--latest`)
3. Remaining Apply packages (`pnpm update`, hold exclusions)
4. Named official migration codemods when the guide lists them — not a kitchen-sink `upgrade latest` (non-TTY agents accept every default: React majors, Turbopack, all recommended codemods)
5. `pnpm audit --fix=update` for GHSAs still open. Not bare `--fix` (writes `overrides`) unless they agreed.
6. Generated UI: inspect overwrite, take real supersedes only
7. AGENTS.md / README: new gotchas, prune stale, record new holds

Finish what a bump starts: remove APIs, config keys, and docs it superseded. Don't leave old+new dual paths, shims, or eslint-disables. Don't delete unused starter deps or hunt dead files — that's Skip / `polish`.

### 5. Verify

Gate (and extra CI jobs) green. Already red before the bump → say so, don't blame the bump. New failure → fix or revert **that** bump. Re-run the stack's security audit (not a second outdated). Remaining high/critical stay in the report.

### 6. Report

**Must** first, then what landed, then skipped holds/majors, then moderate-and-below as a count unless one is reachable. If a bump changes what the app does, say that in the first sentence. No recap.

## Distinct from

| Skill / playbook | This skill |
|---|---|
| Dotfiles `docs/resync.md` | Machine: pull, installer, plugins |
| `polish` | Shape of code you already wrote |
| `vet` | Check a claim; refresh uses it for versions and advisories |
| `pass` | End-of-slice closer; does not bump packages |
| `improve` | Advisor plans, does not bump |
