# Refresh — stack adapters

This file is not a command. Refresh reads **one** section of it after it detects the stack. Don't repeat the generic audit and classify rules.

## Next.js (App Router)

- Compare the installed `next` against the current **stable** ([blog](https://nextjs.org/blog), [releases](https://github.com/vercel/next.js/releases)). Bump `react`, `react-dom`, `@types/react`, `@types/react-dom`, and `@next/eslint-plugin-next` (or `eslint-config-next` if that's what the repo uses) in the same change. A security patch on the current minor is Must even in `minimal`. Never use `next@canary`.
- Read `node_modules/next/dist/docs/` (or the versioned upgrade guide) before migrating APIs.
- After a minor or major bump, run the named official codemods when the [guide](https://nextjs.org/docs/app/guides/upgrading/codemods) lists them. Prefer `pnpm update` of the Next set over `pnx @next/codemod upgrade latest`, because a non-TTY agent accepts every default.
- Drop the route exports that `cacheComponents` makes illegal (`revalidate` / `dynamic` / `dynamicParams` / `fetchCache`).
- If `error.tsx` / `global-error.tsx` still use the old recovery prop, follow the current Next `error.js` docs. Don't copy a prop name from this file.
- Keep `reactCompiler` / `typedRoutes` / `cacheComponents` / `partialPrefetching` set the way the repo already has them. If they're off, don't turn them on as a "refresh" ([cacheComponents](https://nextjs.org/docs/app/api-reference/config/next-config-js/cacheComponents) is not a rename).
- On Cloudflare, bump `@opennextjs/cloudflare` and `wrangler` together. Don't bump `compatibility_date` to "today" as a refresh, since old dates keep working ([CF dates](https://developers.cloudflare.com/workers/configuration/compatibility-dates/)). Don't strip `nodejs_compat` as cleanup.
- Don't move static assets onto `next/image` on Workers as a "refresh", because it isn't free: [Images pricing](https://developers.cloudflare.com/images/pricing/) charges by unique transformations per month.
- For ESLint, honor the AGENTS holds on a composed flat config versus `eslint-config-next`. Don't re-ignore `src/components/ui/` unless the repo chose that.
- For shadcn, use the CLI pinned in package.json. Never run `pnpm dlx shadcn@latest`, `apply`, `add --all`, or `shadcn diff`. Run `ui:diff` first, use `add <name> --diff` when a component would be overwritten, and take only real registry supersedes. Bump `shadcn` first, then the components. Style preset changes are Ask.
- Intentional forks stay until upstream matches them. In next-template, `use-mobile` uses `useSyncExternalStore`, while the registry version still calls setState in an effect. `utils.ts` often shows up as an overwrite because of Prettier import order. `ui:update sidebar` will try to revert `use-mobile`.
- `@types/node` follows the runtime's major version. A jsdom major may need a Node bump first. Honor what AGENTS says.

## Flutter

- Read the `flutter pub outdated` columns this way ([dart pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated), [Flutter deps](https://docs.flutter.dev/packages-and-plugins/dependency-management)). Upgradable means `flutter pub upgrade` on Optimal. Minimal names the packages instead (`flutter pub upgrade <pkg> ...`), since a bare upgrade takes every dependency to the newest version its constraint allows and that includes feature minors Minimal never promised. A Resolvable version that needs a pubspec bump is a package major, so it is Ask unless the mode is `full`. In `full`, run `flutter pub upgrade --major-versions`, which rewrites constraints. When Latest is greater than Resolvable, it stays skipped, because another dependency blocks it.
- Compare `flutter --version` against `environment` in `pubspec.yaml`. A pin lagging the SDK is Must, because it blocks `flutter pub upgrade`. Don't run `flutter upgrade` (SDK) in a repo visit. Instead, report the machine SDK, the pin, and the current stable.
- Don't add `dependency_overrides` unless the user agreed, the same as with pnpm overrides. Don't swap git-pinned forks back to pub.dev. Other holds, such as secure storage, stay unless a GHSA forces an Ask.
- Verify with `flutter analyze` and `flutter test`. Commit regenerated `.g.dart` files when the repo's rule is to commit them.

## Expo / React Native

- An SDK major is Ask unless the mode is `full`. Upgrade one SDK at a time ([Expo upgrade](https://docs.expo.dev/workflow/upgrading-expo-sdk-walkthrough)). Then run `pnpm add expo@^N`, `pnpm exec expo install --fix`, and `pnpm dlx expo-doctor` ([Expo tools](https://docs.expo.dev/develop/tools)). To audit, run `pnpm exec expo install --check`. Never use `npx`. If the repo uses CNG / prebuild, delete the generated `android` / `ios` folders after the SDK bump; they will regenerate.
- Keep using `pnpm`. Pins that exist to match Expo Go stay held.

## Other JS

Use the same classify, apply, and verify steps. If there is no `check` script, verify with typecheck, test, and the README build, and say that the gate is weaker.
