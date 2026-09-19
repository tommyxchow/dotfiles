// Fills two sidebar values for each git workspace: `pr`, the state of the
// branch's pull request, and `dirty`, how many files are uncommitted. Herdr runs
// it with "all" on start and from the refresh action, and with "event" when an
// agent settles or a workspace gets focus. The values show through the `$pr`
// and `$dirty` slots in herdr's sidebar config.
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const herdr = process.env.HERDR_BIN_PATH ?? "herdr";
// One fixed name: a workspace accepts values from at most 32 sources in its lifetime.
const SOURCE = "tc-pr-badge";
// Absorbs bursts, like a focus and a settle landing together; each refresh is a
// GitHub call. Kept short because a skipped event is never retried, so a longer
// window would drop the settle that ends a quick turn and leave the badge stale.
const THROTTLE_MS = 10_000;
const SETTLED = new Set(["idle", "done"]);
const FAILED_CHECKS = new Set(["FAILURE", "ERROR", "TIMED_OUT", "STARTUP_FAILURE", "ACTION_REQUIRED"]);

function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: "utf8" });
  if (result.error) throw new Error(`${command}: ${result.error.message}`);
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed: ${result.stderr.trim() || result.stdout.trim()}`);
  }
  return result.stdout.trim();
}

function prState(pr) {
  if (pr.state === "MERGED") return "merged";
  if (pr.state === "CLOSED") return "closed";
  if (pr.isDraft) return "draft";
  if (pr.reviewDecision === "APPROVED") return "approved";
  if (pr.reviewDecision === "CHANGES_REQUESTED") return "changes";
  return "open";
}

// Short on purpose: the sidebar clips long values. A PR number under 10000 keeps
// the longest badge, "#1234 approved ✗", at 16 characters.
export function formatBadge(pr) {
  const checks = pr.statusCheckRollup ?? [];
  const failed = checks.some((check) => FAILED_CHECKS.has(check.conclusion ?? check.state));
  return `#${pr.number} ${prState(pr)}${failed ? " ✗" : ""}`;
}

function defaultBranch(checkout) {
  // Fails when the clone never recorded origin's HEAD; main and master cover that.
  const result = spawnSync("git", ["-C", checkout, "rev-parse", "--abbrev-ref", "origin/HEAD"], { encoding: "utf8" });
  if (result.status !== 0) return null;
  return result.stdout.trim().replace(/^origin\//, "");
}

// Returns the badge text, or null when the branch can have no pull request.
function prBadge(checkout) {
  const branch = run("git", ["-C", checkout, "branch", "--show-current"]);
  if (!branch || branch === "main" || branch === "master" || branch === defaultBranch(checkout)) return null;
  const fields = "number,state,isDraft,reviewDecision,statusCheckRollup";
  // gh reads the repository from its working directory, so run it in the checkout.
  const found = run("gh", ["pr", "list", "--head", branch, "--state", "all", "--limit", "1", "--json", fields], checkout);
  const [pr] = JSON.parse(found);
  return pr ? formatBadge(pr) : null;
}

function dirtyMarker(checkout) {
  const changed = run("git", ["-C", checkout, "status", "--porcelain"]).split("\n").filter(Boolean).length;
  return changed ? `±${changed}` : null;
}

function report(workspaceId, values) {
  const args = ["workspace", "report-metadata", workspaceId, "--source", SOURCE];
  for (const [name, value] of Object.entries(values)) {
    if (value === null) args.push("--clear-token", name);
    else args.push("--token", `${name}=${value}`);
  }
  run(herdr, args);
}

function refresh(workspaceId) {
  const workspace = JSON.parse(run(herdr, ["workspace", "get", workspaceId])).result.workspace;
  const checkout = workspace.worktree?.checkout_path;
  if (!checkout) return; // not a git checkout, so there is nothing to show
  const values = { dirty: dirtyMarker(checkout) };
  try {
    values.pr = prBadge(checkout);
  } catch (error) {
    // gh missing, signed out, offline, or not a GitHub repo: keep the last badge.
    console.error(`${workspace.label}: PR badge left as is. ${error.message}`);
  }
  report(workspaceId, values);
}

function stateFile() {
  const dir = process.env.HERDR_PLUGIN_STATE_DIR;
  if (!dir) return null;
  mkdirSync(dir, { recursive: true });
  return join(dir, "last-refresh.json");
}

function readLastRefresh(file) {
  if (!file || !existsSync(file)) return {};
  try {
    return JSON.parse(readFileSync(file, "utf8"));
  } catch (error) {
    console.error(`Ignoring unreadable ${file}: ${error.message}`);
    return {};
  }
}

// The workspace an event is about, or null when the event should be ignored.
function eventWorkspace() {
  const data = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON ?? "{}").data ?? {};
  if (process.env.HERDR_PLUGIN_EVENT === "pane.agent_status_changed" && !SETTLED.has(data.agent_status)) return null;
  return data.workspace_id ?? data.workspace?.workspace_id ?? process.env.HERDR_WORKSPACE_ID ?? null;
}

function main(mode) {
  if (mode === "all") {
    const { workspaces } = JSON.parse(run(herdr, ["workspace", "list"])).result;
    for (const workspace of workspaces) {
      // One broken checkout should not blank the badges of every other workspace.
      try {
        refresh(workspace.workspace_id);
      } catch (error) {
        console.error(`${workspace.label}: ${error.message}`);
        process.exitCode = 1;
      }
    }
    return;
  }
  const workspaceId = eventWorkspace();
  if (!workspaceId) return;
  const file = stateFile();
  const lastRefresh = readLastRefresh(file);
  if (Date.now() - (lastRefresh[workspaceId] ?? 0) < THROTTLE_MS) return;
  refresh(workspaceId);
  if (file) writeFileSync(file, JSON.stringify({ ...lastRefresh, [workspaceId]: Date.now() }));
}

// Guarded so formatBadge can be imported and checked without running anything.
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    main(process.argv[2]);
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
