---
name: refresh
metadata:
  opencode/slash: "true"
description: Catches a repo up occasionally. It bumps packages to the latest versions this stack can actually take, applies migrations, flags must-upgrades and security advisories, and vets AGENTS.md against current vendor docs. Use when the user types /refresh or says "refresh this repo", "refresh the packages", "upgrade everything", "any packages we can upgrade", "catch this repo up", "outdated packages", "security audit", "dependabot", or asks to migrate to the latest stack. It is distinct from the dotfiles machine playbook (docs/resync.md), polish (shape of working code), vet (claim checking), and pass (commits a finished slice).
argument-hint: "[optimal | full | minimal | audit | packages | docs] [custom instructions]"
---

# Refresh

This skill catches a repo up. It moves packages to the latest versions this stack can actually take, applies the migrations those versions need, and calls out prominently any must-upgrades, vulnerabilities, deprecations, and packages that are severely behind.

`$ARGUMENTS` holds an optional **mode** as its first token, followed by **custom instructions**. When it is empty, the mode is `optimal`. If the first token is not one of the modes below, treat the whole argument as custom instructions on `optimal`. A security-audit, Dependabot, or outdated request with no upgrade language means `audit`, which only reports.

Honor the holds in `AGENTS.md`, meaning the versions the repo deliberately keeps back. `audit` reports and changes nothing. The modes that do change code close the way any other slice does, through `pass`.

## Collision: machine vs repo

If this workspace **is the dotfiles/chow config repo**, which you can tell by an `install.sh` at the root plus `docs/resync.md`, **stop**. There, `audit` / `plan` is the setup audit: follow `docs/audit.md` and change nothing. Any other mode, including a bare `/refresh`, follows `docs/resync.md`, which covers the pull, the installer, plugins, and the leftover sweep rather than packages. Elsewhere, "resync" or "sync" means pull the latest changes, not this skill.

## Modes

| First token | Meaning |
|---|---|
| *(none)* / `optimal` | Take the latest on the current major, plus the required migrations. Holds stay. Majors are listed, not applied. **This is the default, with no picker.** |
| `full` | Optimal plus every major that is not a documented hold. Breaking a hold still means asking first. |
| `minimal` | Patches, the lockfile, and security or compatibility fixes that unblock the gate or fix a GHSA. It takes no feature minors, no framework story, and no shadcn style. `pnpm update <pkg>` follows the manifest range and can take a minor, so name the patch (`pnpm update foo@1.2.1`) and check that the lockfile stayed on the same minor. |
| `audit` / `plan` | Report only, with no edits. |
| `packages` | Dependencies, the lockfile, and verification. Skip docs and UI unless a bump requires them. |
| `docs` | Check AGENTS.md, README, and CI comments against vendor docs. Still mention holds that have a GHSA against them. |

For example: `/refresh full don't touch wrangler`, `/refresh minimal skip shadcn`, or `/refresh don't touch wrangler`, which is optimal plus a constraint.

### When to ask

Follow the global Session flow rules for question tools and the text fallback, including a clearly marked recommendation. **Don't ask** on a clean Optimal run with no majors and no must-upgrades.

Ask once in these cases:

1. No mode was given **and** a real major, or a must-upgrade that needs a major, is available. Offer to stay on Optimal, to include that major, or to do Minimal only.
2. **full** would break an `AGENTS.md` hold. Give the options and a recommendation, and don't silently undo the pin.
3. A **high/critical** GHSA can only be fixed by breaking a hold or adding an override. Show the [advisory](https://github.com/advisories) and wait.

A mode or custom instruction passed in the arguments is the answer, so don't prompt on top of it.

## Hard rules

- Use **pnpm / pnx** for JS. Never use `npm` / `npx` / `yarn` / `npm audit`. For Flutter, use `flutter` / `dart`.
- Don't add a dependency, linter, formatter, CI gate, or scanner (Snyk, Socket, osv-scanner, Dependabot config) unless the user asks.
- Never run a blanket `pnpm update --latest`. Instead, target the Apply packages with `pnpm update <pkg…>` ([pnpm update](https://pnpm.io/cli/update)), which keeps the range operator and writes the resolved version. Exclude holds (`\!typescript`). For an approved major, use `pnpm update foo@2`.
- `catalog:` dependencies change in `pnpm-workspace.yaml`.
- Honor **`minimumReleaseAge`**, and check the installed default. Don't add an exclude out of curiosity. **Security:** `pnpm audit --fix=update` may add a targeted exclude for the patched version ([pnpm audit](https://pnpm.io/cli/audit)). Leave that exclude in place and mention it.
- Don't stash or reset a dirty tree. Show `git status`, then work on top of it, or stop if the uncommitted changes are unrelated.
- **Vet** the Must items and the framework line against the vendor changelog or [GHSA](https://github.com/advisories), starting from the installed version. Don't assert "latest" or "safe" from memory.
- For the rest of Apply, the batched `outdated` and `audit` output plus registry metadata settles a routine patch or minor. Open a changelog or migration guide only for a major, an advisory, a deprecation, or a package whose API the repo calls directly. The outdated table alone does not settle anything. Don't read changelogs for Skip rows.
- Group packages that share an upstream release, and reuse anything already vetted this session.
- Don't load the full `vet` skill unless a claim is disputed. If a bump looks broken or a Must is disputed, search that package's issues, then confirm in its changelog or releases. Don't cite an issue thread as the spec.
- Don't take a canary, RC, or any dist-tag other than `latest` unless the user asked for it.
- Don't rewrite AGENTS or README to use a CLI that the pinned version doesn't ship. Match `packageManager` / the SDK pin.
- Don't add `allowBuilds` entries, which allow a new postinstall, unless the user agreed ([pnpm supply chain](https://pnpm.io/supply-chain-security)).
- Verify with the local check (see stacks.md for this stack), and let CI run the whole suite and any extra jobs in the default CI workflow. A bump changes no source file, so the affected tests are the ones that exercise the bumped package. Don't invent a gate the repo doesn't have. If the gate is already red, say so before bumping.
- Don't add `audit.ignore` / `ignored_advisories` entries unless the user has read the GHSA. Don't use `pnpm audit --ignore-unfixable`.
- Don't break a hold to quiet the audit. Being outdated is not the same as being vulnerable.

## Flow

Work in this order: recon, audit, classify, apply (unless the mode is `audit` or `plan`), verify, and report.

After detecting the stack, read only that stack's section of [stacks.md](stacks.md). If no section matches, stop and say so.

### 1. Recon

Read the pins in `AGENTS.md` / `CLAUDE.md` / `pubspec.yaml`. Note the package manager, the verify script, the Node version and `packageManager`, and any explicit holds.

### 2. Audit

Batch the independent CLI calls: `git status`, outdated, audit, and Dependabot if `gh` works. How deep you go depends on the mode. `minimal` and `packages` skip `ui:diff` and docs unless a bump requires them. `docs` skips outdated and `ui:diff`, but still flags a hold that has a GHSA.

Run each of these when its tool exists:

- **Outdated:** Run `pnpm outdated`, adding `-r` in a workspace with packages and `--include-github-actions` when the installed pnpm supports it. Compare Wanted against Latest. Don't pass `--compatible` as the only view, because the majors vanish from it. `outdated` and `install` can disagree on `minimumReleaseAge`, and install is the gate. Confirm this against the installed pnpm's changelog or releases. Don't add an exclude except for a GHSA. For Flutter, run `flutter pub outdated`. Take the framework's current stable from the vendor's blog or GitHub releases, not from memory.
- **Security:** Run `pnpm audit --audit-level high`, and glance at the lower severities so moderate ones aren't invisible. Check production dependencies first, then note whether the rest is dev-only. For Flutter, `flutter pub get` prints GHSAs ([Dart advisories](https://dart.dev/tools/pub/security-advisories)). Run `gh api repos/<owner>/<repo>/dependabot/alerts?state=open` when `gh` works. Treat the alerts as a signal and the GHSA as the source.
- **Deprecated:** Find deprecations in `pnpm outdated --format json` (`isDeprecated`) and the audit output, not with `pnpm view` on the tree. Also look for committed config keys the vendor now flags, such as Next route exports, Action inputs, and in-repo editor settings. A documented replacement on the same major is Must. Don't migrate `~` user settings; that belongs to the machine playbook.
- **Stale:** A direct dependency is stale when it is two or more minors behind on the same major, or a whole major behind and not a hold. A framework is stale when it is several stables behind current. A toolchain pin lagging the SDK is stale too, and it blocks every other upgrade.
- **Tooling:** Compare `packageManager` against `pnpm -v`. A new package-manager major is Ask; check the vendor rather than asserting RC or stable from this file. Compare `.nvmrc` / `engines.node` against the `@types/node` major. For Actions tags, moving `vN` to `vN+1` with the same `with:` is Apply on Optimal. Don't run `pnpm update --include-github-actions` unless the repo already pins commit SHAs, because that command rewrites tags to hashes. Run shadcn `ui:diff` (never `shadcn diff`) only if that CLI is in the repo and the mode includes UI. Check AGENTS.md against current vendor docs unless the mode is `packages` / `minimal`.

### 3. Classify

**Must** items get alerted first, and applied in Optimal or Minimal when the fix stays on the current major. They are: a high/critical GHSA with a fix, a resolved version that is deprecated, a committed config key the vendor replaced on this line, a vendor security fix or patch on the current framework line, and a pin so stale it blocks the rest of the tree.

**Apply** depends on the mode. In Optimal it is the latest on the current major plus Must. In Minimal it is Must plus patches only. In Full it is Optimal plus the majors that aren't holds.

**Ask** covers a new major (unless the mode is `full`), breaking a hold, a new dependency, a shadcn style preset, and a `pnpm audit --fix` override, since that writes workspace overrides. A hold that is itself Must stays Ask.

**Skip** covers unused starter dependencies the user kept, intentional registry forks, secrets in committed config, and moderate or low transitive dependencies with no fix or no production path. Count those transitives rather than padding Apply with them. Name unfixable GHSAs instead of hiding them.

### 4. Apply

Apply the Must items first, then the rest. The official order is to update first and then handle the GHSAs that are left ([pnpm audit](https://pnpm.io/cli/audit)):

1. Update the toolchain pin, staying on the same major.
2. Update the framework, React, react-dom, `@types/react*`, and first-party plugins as one unit, with `pnpm update`, not `--latest`.
3. Update the remaining Apply packages with `pnpm update`, excluding holds.
4. Run the named official migration codemods when the guide lists them. Don't run a catch-all `upgrade latest`, because a non-TTY agent accepts every default: React majors, Turbopack, and all recommended codemods.
5. Run `pnpm audit --fix=update` for GHSAs that are still open. Don't use bare `--fix`, which writes `overrides`, unless the user agreed.
6. For generated UI, inspect what an overwrite would change and take only the real supersedes.
7. Update AGENTS.md / README: add new gotchas, prune stale ones, and record new holds.

Finish what a bump starts by removing the APIs, config keys, and docs it superseded. Don't leave old and new paths side by side, shims, or eslint-disables behind. Don't delete unused starter dependencies or hunt for dead files; that is Skip / `polish` work.

### 5. Verify

The gate and any extra CI jobs must be green. If the gate was already red before the bump, say so and don't blame the bump. A new failure means you fix or revert **that** bump. Re-run the stack's security audit, but not a second outdated check. Any remaining high or critical advisories stay in the report.

### 6. Report

Write it in the global Communication voice: full sentences, answer first. If a bump changes what the app does, that is the first sentence. Then give the Must items, then what landed, then the holds and majors you skipped and why, then moderate-and-below advisories as a single count unless one is reachable from production code. Don't recap the steps.

```
Everything on the current major is now up to date, and the local check and CI both pass. One Must: the image library had a high-severity advisory, fixed by its patch release. Next stayed on its current minor and the React packages moved together. I skipped the ESLint major because AGENTS.md holds it. Four moderate advisories remain, all dev-only.
```
