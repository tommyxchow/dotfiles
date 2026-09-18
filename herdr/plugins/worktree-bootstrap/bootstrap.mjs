// Runs on herdr's worktree.created event. Copies the gitignored env files from
// the main checkout into the new worktree, then reports through a herdr
// notification. It does not install dependencies: the agent installs on first
// need, so a monorepo does not pay for a full install on every worktree.
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";

const event = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON).data;
const worktree = event.worktree.path;
const repoRoot = event.workspace.worktree.repo_root;

function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: "utf8" });
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

function notify(title, body, sound) {
  spawnSync(process.env.HERDR_BIN_PATH, ["notification", "show", title, "--body", body, "--sound", sound], { encoding: "utf8" });
}

try {
  const copied = copyEnvFiles();
  const body = copied.length ? `copied ${copied.join(", ")}` : "no env files to copy";
  notify(`Worktree ready: ${event.worktree.branch}`, body, "done");
} catch (error) {
  notify(`Worktree bootstrap failed: ${event.worktree.branch}`, error.message, "request");
  console.error(error.message);
  process.exit(1);
}
