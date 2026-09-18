// Runs on herdr's worktree.created event. Copies the gitignored env files from
// the main checkout into the new worktree, installs dependencies only when the
// repo has made that near-instant, then reports through a herdr notification.
// Everywhere else the agent installs on first need, so a monorepo does not pay
// for a full install on every worktree.
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";

const event = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON).data;
const worktree = event.worktree.path;
const repoRoot = event.workspace.worktree.repo_root;

function run(command, args, cwd) {
  // On Windows pnpm is a .cmd shim, which Node only runs through a shell. Every
  // token here is a constant, and cwd goes through the option, so joining them
  // is safe. git is an .exe and needs no shell anywhere.
  const viaShell = process.platform === "win32" && command !== "git";
  const result = viaShell
    ? spawnSync([command, ...args].join(" "), { cwd, encoding: "utf8", shell: true })
    : spawnSync(command, args, { cwd, encoding: "utf8" });
  if (result.error) throw new Error(`${command}: ${result.error.message}`);
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed: ${result.stderr.trim() || result.stdout.trim()}`);
  }
  return result.stdout;
}

function copyEnvFiles() {
  // --directory collapses ignored folders like node_modules into one entry
  // instead of walking every file inside them, which is seconds on a web repo.
  // An env file inside an ignored folder is build output, not a secret to copy.
  const listed = run("git", ["-C", repoRoot, "ls-files", "--others", "--ignored", "--exclude-standard", "--directory", "-z", "--", ":(glob)**/.env*"]);
  const copied = [];
  for (const rel of listed.split("\0").filter(Boolean)) {
    if (rel.endsWith("/")) continue;
    const dest = join(worktree, rel);
    if (existsSync(dest)) continue;
    mkdirSync(dirname(dest), { recursive: true });
    copyFileSync(join(repoRoot, rel), dest);
    copied.push(rel);
  }
  return copied;
}

// pnpm's global virtual store (https://pnpm.io/git-worktrees) makes a worktree
// install mostly symlinks into one shared store, so it is cheap enough to run
// up front. The setting lives in pnpm-workspace.yaml; the older spelling is
// enableGlobalVirtualStore. Any other repo is left to the agent.
function usesGlobalVirtualStore() {
  const settings = join(worktree, "pnpm-workspace.yaml");
  if (!existsSync(settings)) return false;
  const yaml = readFileSync(settings, "utf8");
  return /^\s*virtualStoreType:\s*["']?global["']?\s*$/m.test(yaml)
    || /^\s*enableGlobalVirtualStore:\s*true\s*$/m.test(yaml);
}

function installDeps() {
  if (!usesGlobalVirtualStore()) return null;
  // --prefer-offline: the main checkout's store already holds the packages.
  run("pnpm", ["install", "--frozen-lockfile", "--prefer-offline"], worktree);
  return "pnpm install";
}

function notify(title, body, sound) {
  spawnSync(process.env.HERDR_BIN_PATH, ["notification", "show", title, "--body", body, "--sound", sound], { encoding: "utf8" });
}

try {
  const copied = copyEnvFiles();
  const install = installDeps();
  const parts = [];
  if (copied.length) parts.push(`copied ${copied.join(", ")}`);
  if (install) parts.push(install);
  notify(`Worktree ready: ${event.worktree.branch}`, parts.join("; ") || "no env files to copy", "done");
} catch (error) {
  notify(`Worktree bootstrap failed: ${event.worktree.branch}`, error.message, "request");
  console.error(error.message);
  process.exit(1);
}
