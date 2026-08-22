# Refresh — stack adapters

Not a command. Refresh reads **one** section after it detects the stack. Don't repeat the generic audit/classify rules.

## Next.js (App Router)

- Installed `next` vs current **stable** ([blog](https://nextjs.org/blog), [releases](https://github.com/vercel/next.js/releases)). Same change: `react`, `react-dom`, `@types/react`, `@types/react-dom`, `@next/eslint-plugin-next` (or `eslint-config-next` if that's what the repo uses). A security patch on the current minor is Must even in `minimal`. Never `next@canary`.
- Read `node_modules/next/dist/docs/` (or the versioned upgrade guide) before migrating APIs.
- After a minor/major: named official codemods when the [guide](https://nextjs.org/docs/app/guides/upgrading/codemods) lists them. Prefer `pnpm update` of the Next set over `pnx @next/codemod upgrade latest` — a non-TTY agent accepts every default. Drop route exports `cacheComponents` makes illegal (`revalidate` / `dynamic` / `dynamicParams` / `fetchCache`).
- If `error.tsx` / `global-error.tsx` still use the old recovery prop, follow the current Next `error.js` docs. Don't copy a prop name from this file.
- Keep `reactCompiler` / `typedRoutes` / `cacheComponents` / `partialPrefetching` as the repo already set them. Don't turn those on as a "refresh" if they're off ([cacheComponents](https://nextjs.org/docs/app/api-reference/config/next-config-js/cacheComponents) is not a rename).
- Cloudflare: bump `@opennextjs/cloudflare` + `wrangler` together. Don't bump `compatibility_date` to "today" as a refresh ([CF dates](https://developers.cloudflare.com/workers/configuration/compatibility-dates/) keep old dates working). Don't strip `nodejs_compat` as cleanup.
- Don't move static assets onto `next/image` on Workers as a "refresh" ([Images pricing](https://developers.cloudflare.com/images/pricing/): unique transformations / month, not free).
- ESLint: honor AGENTS holds (composed flat config vs `eslint-config-next`). Don't re-ignore `src/components/ui/` unless the repo chose that.
- shadcn: pinned CLI in package.json. Never `pnpm dlx shadcn@latest`, `apply`, `add --all`, or `shadcn diff`. `ui:diff` first; `add <name> --diff` on overwrite; take only real registry supersedes. Bump `shadcn` then components. Style preset changes are Ask.
- Intentional forks stay until upstream matches. next-template: `use-mobile` is `useSyncExternalStore` (registry still setStates in an effect); `utils.ts` often overwrites from Prettier import order. `ui:update sidebar` will try to revert `use-mobile`.
- `@types/node` tracks the runtime major. jsdom majors may need a Node bump first. Honor AGENTS.

## Flutter

- `flutter pub outdated` columns ([dart pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated), [Flutter deps](https://docs.flutter.dev/packages-and-plugins/dependency-management)): Upgradable → `flutter pub upgrade` (Optimal / Minimal). Resolvable that needs a pubspec bump is a package major → Ask unless `full`. `full` → `flutter pub upgrade --major-versions` (rewrites constraints). Latest > Resolvable stays skipped (blocked by another dep).
- `flutter --version` vs `environment` in `pubspec.yaml`. A pin lagging the SDK is Must: it blocks `flutter pub upgrade`. Don't run `flutter upgrade` (SDK) in a repo visit — report machine SDK vs pin vs current stable.
- Don't add `dependency_overrides` unless they agreed (same as pnpm overrides). Don't swap git-pinned forks back to pub.dev. Other holds (e.g. secure storage) stay unless a GHSA forces Ask.
- Verify: `flutter analyze` + `flutter test`. Commit regenerated `.g.dart` when the repo's rule is to commit them.

## Expo / React Native

- SDK major is Ask unless mode is `full`. One SDK at a time ([Expo upgrade](https://docs.expo.dev/workflow/upgrading-expo-sdk-walkthrough)). Then `pnpm add expo@^N`, `pnpm exec expo install --fix`, `pnpm dlx expo-doctor` ([Expo tools](https://docs.expo.dev/develop/tools)). Audit: `pnpm exec expo install --check`. Never `npx`. If they use CNG / prebuild, delete generated `android` / `ios` after the SDK bump (they'll regenerate).
- Keep `pnpm`. Pins that exist to match Expo Go stay held.

## Other JS

Same classify/apply/verify. No `check` script → typecheck + test + the README build, and say the gate is weaker.
