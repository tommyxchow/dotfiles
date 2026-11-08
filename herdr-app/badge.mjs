// Prints the sidebar values for the git checkout around a folder, as JSON:
// `branch`, `pr`, the state of the branch's pull request and its CI (or just the
// CI on the default branch, which has no pull request), and `added` and
// `removed`, the uncommitted lines. The Herdr desktop app's tc mods run it as
// `node badge.mjs <folder>`, so both show one badge.
import { spawnSync } from "node:child_process";
import { lstatSync, readFileSync } from "node:fs";
import { join } from "node:path";

const FAILED_CHECKS = new Set(["FAILURE", "ERROR", "TIMED_OUT", "STARTUP_FAILURE", "ACTION_REQUIRED"]);
// Commit statuses have only a state; check runs have a status and a conclusion.
const PENDING_STATES = new Set(["PENDING", "EXPECTED"]);
const MAX_UNTRACKED_BYTES = 1_000_000;

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

// The worst state across a set of checks: ✗ when any failed, ◌ while any is
// still running, ✓ when all passed, and null when there are none.
function ciMark(checks) {
  if (checks.length === 0) return null;
  if (checks.some((check) => FAILED_CHECKS.has(check.conclusion ?? check.state))) return "✗";
  const running = checks.some((check) => (check.status ? check.status !== "COMPLETED" : PENDING_STATES.has(check.state)));
  return running ? "◌" : "✓";
}

// Short on purpose: the sidebar clips long values. A PR number under 10000 keeps
// the longest badge, "#1234 approved ✗", at 16 characters.
function formatBadge(pr) {
  const state = prState(pr);
  // CI on a merged or closed PR is history, not something to act on.
  const mark = state === "merged" || state === "closed" ? null : ciMark(pr.statusCheckRollup ?? []);
  return mark ? `#${pr.number} ${state} ${mark}` : `#${pr.number} ${state}`;
}

// gh run list reports lowercase values and an empty conclusion while a run is
// going, so this maps them onto the check-run shape ciMark reads. Dependabot's
// update jobs run on the default branch's commit and fail on their own, so they
// don't count toward its CI.
function runsBadge(runs) {
  const checks = runs
    .filter((run) => !run.workflowName.startsWith("Dependabot"))
    .map((run) => ({ status: run.status.toUpperCase(), conclusion: (run.conclusion ?? "").toUpperCase() || null }));
  const mark = ciMark(checks);
  return mark ? `CI ${mark}` : null;
}

function defaultBranch(checkout) {
  // Fails when the clone never recorded origin's HEAD; main and master cover that.
  const result = spawnSync("git", ["-C", checkout, "rev-parse", "--abbrev-ref", "origin/HEAD"], { encoding: "utf8" });
  if (result.status !== 0) return null;
  return result.stdout.trim().replace(/^origin\//, "");
}

// The default branch has no pull request, so its badge is the CI of the checked-out
// commit. Nothing shows before that commit is pushed or in a repo without CI.
function defaultBranchBadge(checkout) {
  const sha = run("git", ["-C", checkout, "rev-parse", "HEAD"]);
  // 100 so Dependabot and scheduled runs on the same commit can't push the real
  // CI out of the list.
  const found = run("gh", ["run", "list", "--commit", sha, "--limit", "100", "--json", "status,conclusion,workflowName"], checkout);
  return runsBadge(JSON.parse(found));
}

// Returns the badge text, or null for a detached HEAD or a branch with no pull request.
function prBadge(checkout) {
  const branch = run("git", ["-C", checkout, "branch", "--show-current"]);
  if (!branch) return null;
  if (branch === "main" || branch === "master" || branch === defaultBranch(checkout)) return defaultBranchBadge(checkout);
  const fields = "number,state,isDraft,reviewDecision,statusCheckRollup";
  // gh reads the repository from its working directory, so run it in the checkout.
  const found = run("gh", ["pr", "list", "--head", branch, "--state", "all", "--limit", "1", "--json", fields], checkout);
  const [pr] = JSON.parse(found);
  return pr ? formatBadge(pr) : null;
}

// Git treats a file with a NUL byte in its first 8000 bytes as binary and gives
// it no line count, so this does too.
function lineCount(content) {
  if (content.length === 0 || content.subarray(0, 8000).includes(0)) return 0;
  let lines = 0;
  for (const byte of content) if (byte === 0x0a) lines++;
  return content.at(-1) === 0x0a ? lines : lines + 1;
}

// The spaces row shares about 16 columns with the branch and the PR badge, so
// 12345 shows as "12.3k".
function compact(count) {
  return count < 1000 ? String(count) : `${Math.round(count / 100) / 10}k`;
}

// Lines added and removed across all uncommitted work: staged and unstaged
// edits against the last commit, plus new files git doesn't track yet, which
// count as added the way a pull request shows them.
function diffCounts(checkout) {
  // A repo with no commits yet has no HEAD, so there only staged files count.
  const hasHead = spawnSync("git", ["-C", checkout, "rev-parse", "--verify", "--quiet", "HEAD"]).status === 0;
  const numstat = run("git", ["-C", checkout, "diff", "--numstat", hasHead ? "HEAD" : "--cached"]);
  let added = 0;
  let removed = 0;
  for (const line of numstat.split("\n").filter(Boolean)) {
    // A binary file reports "-" for both counts, which Number turns into NaN.
    const [plus, minus] = line.split("\t").map(Number);
    added += plus || 0;
    removed += minus || 0;
  }
  // Called directly because run() trims, which would cut a leading space off the
  // first name. The larger buffer fits a folder not ignored yet, like a fresh
  // node_modules, whose file list passes the 1 MB default.
  const untracked = spawnSync("git", ["-C", checkout, "ls-files", "--others", "--exclude-standard", "-z"], {
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });
  if (untracked.status !== 0) {
    throw new Error(`git ls-files failed: ${untracked.error?.message ?? untracked.stderr.trim()}`);
  }
  for (const file of untracked.stdout.split("\0").filter(Boolean)) {
    const path = join(checkout, file);
    // Undefined when a watcher or test run deleted the file after ls-files listed it.
    const stat = lstatSync(path, { throwIfNoEntry: false });
    // A nested repo shows up as a folder and a symlink has no lines of its own.
    // Anything big, like a dump or a video, is left out rather than read whole
    // on every refresh.
    if (stat?.isFile() && stat.size <= MAX_UNTRACKED_BYTES) added += lineCount(readFileSync(path));
  }
  return {
    added: added ? `+${compact(added)}` : null,
    removed: removed ? `-${compact(removed)}` : null,
  };
}

// A folder outside git prints all nulls. A failed PR lookup (gh missing, signed
// out, offline, or not a GitHub repo) still prints the counts, with the reason
// in `error` so the caller can log it.
function printJson(folder) {
  // The app's spaces mod watches .git and reruns this on a change, so its git
  // calls must not write there (an index refresh would wake the watch again).
  process.env.GIT_OPTIONAL_LOCKS = "0";
  const top = spawnSync("git", ["-C", folder, "rev-parse", "--show-toplevel"], { encoding: "utf8" });
  if (top.status !== 0) {
    console.log(JSON.stringify({ branch: null, pr: null, added: null, removed: null }));
    return;
  }
  const checkout = top.stdout.trim();
  const values = { branch: run("git", ["-C", checkout, "branch", "--show-current"]) || null, ...diffCounts(checkout), pr: null };
  try {
    values.pr = prBadge(checkout);
  } catch (error) {
    values.error = error.message;
  }
  console.log(JSON.stringify(values));
}

try {
  printJson(process.argv[2] ?? process.cwd());
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
