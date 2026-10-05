// Fills pane tokens the sidebar shows under each agent. Every agent gets
// `name`, its herdr name (the one `herdr agent rename` sets), since herdr has
// no built-in slot for it. An OpenCode agent also gets `ctx` (or `ctxhigh`),
// read off the bottom of its screen, because OpenCode 2 has no statusline
// hook to publish it the way Claude's statusline does. Herdr runs
// it with "all" on start, because tokens do not survive a server restart, and
// with "event" whenever an agent's status changes.
import { spawnSync } from "node:child_process";

const herdr = process.env.HERDR_BIN_PATH ?? "herdr";
// One fixed name: a pane accepts sequenced values from at most 32 sources in its lifetime.
const SOURCE = "tc-agent-tokens";
// The same soft ceiling the Claude statusline uses for its `ctxhigh` token,
// which applies only to a window of about 1M tokens or more. The footer shows
// tokens used and a rounded percentage, so the window is estimated from the two;
// the margin below 1M absorbs that rounding.
const CTX_HIGH_PCT = 50;
const CTX_HIGH_MIN_WINDOW = 900_000;
// OpenCode 2's footer: "~/Developer    21.8K (4%) · $0.06  ctrl+p commands".
const OPENCODE_CTX = /(\d[\d.,]*)([KM]?)\s+\((\d+)%\)/;
const UNIT = { "": 1, K: 1_000, M: 1_000_000 };

function run(args) {
  const result = spawnSync(herdr, args, { encoding: "utf8" });
  if (result.error) throw new Error(`${herdr}: ${result.error.message}`);
  if (result.status !== 0) {
    throw new Error(`${herdr} ${args.join(" ")} failed: ${result.stderr.trim() || result.stdout.trim()}`);
  }
  return result.stdout;
}

function listAgents() {
  return JSON.parse(run(["agent", "list"])).result.agents;
}

// Null values clear their token. A footer with no reading, like one before the
// first reply, one hidden by a dialog, or one reworded by an OpenCode update,
// clears the value rather than leaving an old one up.
function openCodeTokens(paneId) {
  const lines = run(["agent", "read", paneId, "--source", "visible", "--lines", "8"]).split("\n");
  // Only the footer, the last non-empty line, so a transcript line shaped like
  // "12 (40%)" can't stand in for a footer that has no reading yet.
  const footer = lines.findLast((line) => line.trim() !== "") ?? "";
  const [, amount, unit, pct] = footer.match(OPENCODE_CTX) ?? [];
  const used = pct !== undefined ? Number(amount.replaceAll(",", "")) * UNIT[unit] : 0;
  const window = pct > 0 ? (used * 100) / pct : 0;
  const high = pct !== undefined && Number(pct) >= CTX_HIGH_PCT && window >= CTX_HIGH_MIN_WINDOW;
  // The same units as the Claude statusline's token: 340k, or 1.2M from a million up.
  const label =
    used >= 999_500
      ? `ctx ${Math.floor(Math.round(Math.max(used, 1_000_000)) / 100_000) / 10}M`
      : `ctx ${Math.round(used / 1000)}k`;
  return {
    ctx: pct !== undefined && !high ? label : null,
    ctxhigh: high ? label : null,
  };
}

function tokensFor(agent) {
  const tokens = { name: agent?.name ?? null };
  if (agent?.agent === "opencode") Object.assign(tokens, openCodeTokens(agent.pane_id));
  return tokens;
}

// Two status changes in quick succession run as two processes that can finish
// in either order. Each report carries the time its read began, and herdr
// ignores a report older than the last one it took, so the newest read wins.
function report(paneId, tokens, seq) {
  const args = ["pane", "report-metadata", paneId, "--source", SOURCE, "--seq", String(seq)];
  for (const [name, value] of Object.entries(tokens)) {
    if (value === null) args.push("--clear-token", name);
    else args.push("--token", `${name}=${value}`);
  }
  run(args);
}

function main(mode) {
  const seq = Date.now();
  if (mode === "all") {
    for (const agent of listAgents()) {
      if (agent.name || agent.agent === "opencode") report(agent.pane_id, tokensFor(agent), seq);
    }
    return;
  }
  const data = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON ?? "{}").data ?? {};
  if (!data.pane_id) return;
  // An agent that quits reports unknown while herdr still lists it for a moment,
  // so it clears everything this script publishes. Claude's statusline refills
  // its own `ctx` within a minute if a Claude agent ever reports unknown.
  if (data.agent_status === "unknown") {
    report(data.pane_id, { name: null, ctx: null, ctxhigh: null }, seq);
    return;
  }
  report(data.pane_id, tokensFor(listAgents().find((a) => a.pane_id === data.pane_id)), seq);
}

try {
  main(process.argv[2]);
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
