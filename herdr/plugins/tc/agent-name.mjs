// Fills the `name` pane token with each agent's herdr name (the one `herdr
// agent rename` sets), which the sidebar shows through `$name`, since herdr has
// no built-in slot for it. Herdr runs it with "all" on start, because tokens do
// not survive a server restart, and with "event" whenever an agent's status
// changes. It reads only herdr's own records, so it works for every harness.
import { spawnSync } from "node:child_process";

const herdr = process.env.HERDR_BIN_PATH ?? "herdr";
// One fixed name: a pane accepts sequenced values from at most 32 sources in its lifetime.
const SOURCE = "tc-agent-name";

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

// Two status changes in quick succession run as two processes that can finish
// in either order. Each report carries the time its read began, and herdr
// ignores a report older than the last one it took, so the newest read wins.
function report(paneId, name, seq) {
  const value = name ? ["--token", `name=${name}`] : ["--clear-token", "name"];
  run(["pane", "report-metadata", paneId, "--source", SOURCE, ...value, "--seq", String(seq)]);
}

function main(mode) {
  const seq = Date.now();
  if (mode === "all") {
    for (const agent of listAgents()) {
      if (agent.name) report(agent.pane_id, agent.name, seq);
    }
    return;
  }
  const data = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON ?? "{}").data ?? {};
  if (!data.pane_id) return;
  // An agent that quits reports unknown while herdr still lists it for a moment.
  const agent = data.agent_status === "unknown" ? null : listAgents().find((a) => a.pane_id === data.pane_id);
  report(data.pane_id, agent?.name, seq);
}

try {
  main(process.argv[2]);
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
