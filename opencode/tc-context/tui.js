// In the Herdr desktop app, publish this OpenCode session's effort and context
// use as labels on its terminal, the same `effort`, `ctx`, and `ctxhigh` values
// .claude/statusline-command.sh writes for Claude Code. The tc-agents sidebar
// mod draws its context bar from them, and an OpenCode hq reads its own `ctx`
// with `hc get`.
import { execFile } from "node:child_process";

// The Claude statusline's soft ceiling: 50% on a window of 1M or more.
const CTX_HIGH_PCT = 50;
const CTX_HIGH_MIN_WINDOW = 1_000_000;

function run(command, args) {
  return new Promise((resolve) =>
    execFile(command, args, { windowsHide: true, timeout: 20_000 }, (error, stdout) =>
      resolve(error ? null : stdout)));
}

// The TUI process is the opencode binary itself, so this reaches the same
// server without depending on PATH.
async function server(...args) {
  const stdout = await run(process.execPath, ["api", ...args]);
  if (!stdout) return null;
  try {
    return JSON.parse(stdout).data;
  } catch {
    return null; // A reply cut off mid-write; the next turn publishes again.
  }
}

// The statusline's format: tokens in K, or M with one decimal from a million up.
function tok(n) {
  if (n >= 999_500) return `${Math.floor(Math.max(n, 1_000_000) / 100_000) / 10}M`;
  return `${Math.round(n / 1000)}K`;
}

const windows = new Map();
async function contextWindow(model) {
  const key = `${model.providerID}/${model.id}`;
  if (!windows.has(key)) {
    const models = await server("model.list");
    const found = models?.find((m) => m.providerID === model.providerID && m.id === model.id);
    if (!found?.limit?.context) return undefined;
    windows.set(key, found.limit.context);
  }
  return windows.get(key);
}

const CLEARED = ["effort=", "ctx=", "ctxhigh="];

// Null means the read failed, so the labels already there stay put.
async function labelsFor(sessionID) {
  // The newest two entries are a finished turn's idle record and its last
  // reply, whose token counts are the prompt's size. Anything more pulls in
  // whole tool outputs and can pass execFile's output limit.
  const messages = await server(
    "session.message.list", "--param", `sessionID=${sessionID}`, "--param", "order=desc", "--param", "limit=2");
  if (!messages) return null;
  const last = messages.find((m) => m.type === "assistant" && m.tokens);
  // No reply in a non-empty list means something newer is queued, so keep
  // the current labels; an empty session has nothing to show yet.
  if (!last) return messages.length ? null : CLEARED;
  const effort = `effort=${last.model?.variant ?? ""}`;
  const window = last.model ? await contextWindow(last.model) : undefined;
  // `input` excludes cached tokens here. This is the sum OpenCode's footer shows.
  const { input = 0, output = 0, reasoning = 0, cache = {} } = last.tokens;
  const used = input + output + reasoning + (cache.read ?? 0) + (cache.write ?? 0);
  if (!window || !used) return [effort, "ctx=", "ctxhigh="];
  const pct = Math.min(100, Math.floor((used * 100) / window));
  const label = `${pct}% ${tok(used)}/${tok(window)}`;
  if (pct >= CTX_HIGH_PCT && window >= CTX_HIGH_MIN_WINDOW) return [effort, `ctxhigh=${label}`, "ctx="];
  return [effort, `ctx=${label}`, "ctxhigh="];
}

// OpenCode 2's TUI calls `setup` and runs the function it returns on dispose.
function setup(api) {
  const terminal = process.env.HC_TERMINAL_ID;
  if (!terminal) return;

  const routeSession = () => {
    const route = api.ui.router.current();
    return route.type === "session" ? route.sessionID : undefined;
  };
  let chain = Promise.resolve();
  let disposed = false;
  function publish() {
    const sessionID = routeSession();
    chain = chain.then(async () => {
      const labels = sessionID ? await labelsFor(sessionID) : CLEARED;
      if (labels && !disposed) await run("hc", ["label", terminal, ...labels]);
    });
  }

  // A turn ending is when the context size settles.
  const settled = new Set(["session.execution.succeeded", "session.execution.interrupted", "session.execution.failed"]);
  const unsubscribe = api.data.listen(({ details: event }) => {
    if (settled.has(event.type) && event.data?.sessionID === routeSession()) publish();
  });
  // Opening another session in this TUI changes whose numbers belong here.
  // Publishing once up front also clears labels an earlier program in this
  // terminal left behind, when the TUI opens on its home screen.
  let shown = routeSession();
  publish();
  const poll = setInterval(() => {
    if (routeSession() === shown) return;
    shown = routeSession();
    publish();
  }, 1000);
  return () => {
    disposed = true;
    clearInterval(poll);
    unsubscribe();
    // Labels outlive the program, so clear them for whatever runs here next.
    // Queued behind any publish in flight, so its labels can't land after.
    chain = chain.then(() => run("hc", ["label", terminal, ...CLEARED]));
  };
}

export default { id: "tc.opencode.context-labels", setup };
