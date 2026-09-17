// Runs on herdr's worktree.created event. Copies the gitignored env files from
// the main checkout into the new worktree and installs dependencies from the
// lockfile it finds there, then reports through a herdr notification.
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";

const event = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON).data;
const worktree = event.worktree.path;
const repoRoot = event.workspace.worktree.repo_root;
const windows = process.platform === "win32";

function run(command, args, cwd) {
  // On Windows pnpm and flutter are .cmd shims, which Node only runs through a
  // shell. Every token here is a constant, and cwd goes through the option, so
  // joining them is safe. git is an .exe and needs no shell anywhere.
  const viaShell = windows && command !== "git";
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
  const listed = run("git", ["-C", repoRoot, "ls-files", "--others", "--ignored", "--exclude-standard", "-z", "--", ":(glob)**/.env*"]);
  const copied = [];
  for (const rel of listed.split("\0").filter(Boolean)) {
    if (rel.split("/").includes("node_modules")) continue;
    const dest = join(worktree, rel);
    if (existsSync(dest)) continue;
    mkdirSync(dirname(dest), { recursive: true });
    copyFileSync(join(repoRoot, rel), dest);
    copied.push(rel);
  }
  return copied;
}

function installDeps() {
  if (existsSync(join(worktree, "pnpm-lock.yaml"))) {
    run("pnpm", ["install", "--frozen-lockfile"], worktree);
    return "pnpm install";
  }
  if (existsSync(join(worktree, "pubspec.lock"))) {
    run("flutter", ["pub", "get"], worktree);
    return "flutter pub get";
  }
  return null;
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
  notify(`Worktree ready: ${event.worktree.branch}`, parts.join("; ") || "nothing to bootstrap", "done");
} catch (error) {
  notify(`Worktree bootstrap failed: ${event.worktree.branch}`, error.message, "request");
  console.error(error.message);
  process.exit(1);
}
