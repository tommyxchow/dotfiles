// Agents in grouped or priority views; parents take their most urgent sub-agent's place.
//
// Modified by tc from Herdr's shipped `agents` mod (version in mod.json), under
// the Apache License 2.0 (herdr-app/LICENSE in the dotfiles repo). Changes:
// every row is two lines of fixed height, the name with its status, then one
// line that never comes and goes; that line's left end says what the agent
// reports it's doing while it works or waits on you, and otherwise where it
// runs (its tab and space, or a paneless hq worker's branch and uncommitted
// lines, since it has no space row of its own); its right end keeps the
// worker's PR badge, the agent's context as a fill bar and percent, and the
// time label, which drops first in a narrow sidebar; a row leading with the
// agent's own title; a sub-agent with its own row not repeated under its
// parent; a row without a space header leading with the agent's own name; and
// hover tooltips in plain words for the context, the time label, the badge,
// and the line counts.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, terminals, focused, spaces, run, theme, shared, setShared, setAgentOrder, openOverlay, closeOverlay, props, window, layout, exec, appHome } from "herdr";

// The context the dotfiles status line publishes, like "12% 126K/1M", at the end
// of the line under a row's name as a small fill bar and the percent, with the
// token counts in its tooltip; orange once it's `ctxhigh` past the soft ceiling.
const CTX_BAR_PX = 18;
function ctxLabel(t, k) {
  const l = k?.labels ?? {};
  const ctx = l.ctxhigh || l.ctx;
  if (!ctx) return null;
  const color = l.ctxhigh ? t.ansi3 : t.dim;
  const [, pct, used, size] = ctx.match(/^(\d+)% (\S+)\/(\S+)$/) ?? [];
  if (!pct) return div().flex_none().text_size(11).text_color(color).child(ctx);
  const fill = Math.round((CTX_BAR_PX * Math.min(Number(pct), 100)) / 100);
  return h_flex().id(`ctx-${k.address}`).flex_none().gap(4).items_center().text_size(11).text_color(color)
    .tooltip(`Context ${pct}% full, ${used} of ${size} tokens`)
    .child(div().w(CTX_BAR_PX).h(4).rounded(2).bg(t.input).child(div().w(fill).h_full().rounded(2).bg(color)))
    .child(`${pct}%`);
}

const activity = (k) => (typeof k?.report === "string" ? k.report : k?.report?.msg) || null;

// Folders of live paneless workers on this computer: the only rows that show
// git, since an agent with a pane has its space's row for that. Another
// machine's would need `on`.
const gitFolders = () => [...new Set(terminals()
  .filter((k) => k.state === "live" && k.cwd && k.parent && !k.address.includes("/"))
  .map((k) => k.cwd))];

const GIT_EVERY_MS = 90_000;

// The dotfiles badge script, linked into this folder by the dotfiles installer,
// so this mod and the spaces mod compute the same badge.
const badgeScript = () => `${appHome()}/mods/tc-agents/badge.mjs`;

// A badge's colors: red for a failed check or requested
// changes, orange while checks run, green once approved.
export function badgeColor(t, text) {
  if (/✗|changes/.test(text)) return t.ansi1;
  if (text.includes("◌")) return t.ansi3;
  if (text.includes("approved")) return t.ansi2;
  // Merged and closed are history, so they fade; an open PR or a CI result reads
  // a step brighter.
  if (/merged|closed/.test(text)) return t.dim;
  return t.muted;
}

// The badge in words for its tooltip: "#12 approved ✓" reads "Pull request #12:
// approved, CI passed", and "CI ✗" reads "Default branch: CI failed".
function badgeTip(text) {
  const ci = { "✓": "CI passed", "✗": "CI failed", "◌": "CI running" }[text.match(/[✓✗◌]/u)?.[0]];
  if (text.startsWith("CI")) return `Default branch: ${ci ?? "no CI"}`;
  const [, number, state] = text.match(/^#(\d+) (\w+)/) ?? [];
  if (!number) return text;
  const words = state === "changes" ? "changes requested" : state;
  return `Pull request #${number}: ${[words, ci].filter(Boolean).join(", ")}`;
}

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const sidebarWidth = () => find(layout(), "sidebar")?.size?.px ?? Infinity;
const narrow = () => sidebarWidth() < 160;
// Below this width a row drops its time label, so the line under the name keeps room.
const TIME_MIN_PX = 190;

// To the rail (on macOS wide enough for the traffic lights), or back to the width it had.
function toggleSidebar() {
  const width = find(layout(), "sidebar")?.size?.px;
  if (!narrow()) setShared("sidebar.width", width);
  // Mods edited before the rail went by width still read the flag.
  setShared("sidebar.collapsed", !narrow());
  run("layout.resize", { id: "sidebar", px: narrow() ? (shared("sidebar.width") ?? 268) : window()?.platform === "macos" ? 76 : 44 });
}

const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();

// The terminal's title when it names the work, like Claude Code's own session
// title; null when it only repeats the program, a path, or user@host.
function ownTitle(raw, program) {
  const live = clean(raw);
  // clean() would strip a path's leading ~ or /: test the title with only its status glyph gone.
  const path = /^[~/]|^[A-Za-z]:\\/.test((raw ?? "").replace(/^[^\p{L}\p{N}~/]+/u, ""));
  const telling = live && live !== program?.name && !path && !live.includes("@") && live.toLowerCase() !== program?.key;
  return telling ? live : null;
}
const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
// A sub-agent without a pane isn't in agents(): its raw word, error counting as
// blocked. It's never done: it reports to its parent, and the parent's done is the news.
const kidStatus = (k, listed) => {
  const s = listed.get(k.address) ?? k.status;
  return s === "error" ? "blocked" : s === "done" ? "idle" : s;
};
const SORTS = [
  { id: "priority", label: "Priority", icon: "clock" },
  { id: "grouped", label: "Grouped by space", icon: "layers" },
];
const sortOf = () => SORTS.find((s) => s.id === shared("agents.sort")) ?? SORTS[0];
const SECTION = { 4: "Needs you", 3: "Done", 2: "Working", 1: "Idle" };
const SECTION_STATUS = { 4: "blocked", 3: "done", 2: "working" };

function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

function durationWords(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "under a minute";
  if (m < 60) return `${m} min`;
  const h = Math.floor(m / 60);
  if (h < 24) return h === 1 ? "1 hour" : `${h} hours`;
  const d = Math.floor(h / 24);
  return d === 1 ? "1 day" : `${d} days`;
}

// The time label's tooltip, like "Working for 3 min" or "Finished 2 hours ago".
function timeTip(status, ms) {
  const span = durationWords(ms);
  if (status === "done") return `Finished ${span} ago`;
  const state = { working: "Working", blocked: "Waiting on you", idle: "Idle" }[status] ?? "Like this";
  return `${state} for ${span}`;
}

// The agent's icon from the app's program table: a one-color glyph or a picture.
function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

export default class Agents extends View {
  init(_props, cx) {
    if (props()?.sortMenu) return;
    this.folded = new Set();
    // Each agent's last state and when it changed (ms), kept across restarts.
    this.changed = JSON.parse(localStorage.getItem("changed") ?? "{}");
    this.pendingPins = JSON.parse(localStorage.getItem("pins") ?? "[]");
    if (!this.pendingPins.length) localStorage.removeItem("pins");
    this.migratingPins = new Set();
    this.git = {};
    cx.timer.every(30000, (cx) => cx.notify());
    cx.timer.every(GIT_EVERY_MS, (cx) => this.refreshGit(cx));
    this.refreshGit(cx);
  }

  // Each worker folder's branch, badge, and uncommitted lines.
  // A folder outside git, or a branch with no PR, simply shows less.
  refreshGit(cx) {
    // Asked again mid-run (a worker settled): run once more after, rather than drop it.
    if (this.refreshing) {
      this.again = true;
      return;
    }
    this.refreshing = true;
    this.again = false;
    const folders = gitFolders();
    // Pending until its lookup lands, so renders meanwhile don't see it as new and ask again.
    for (const cwd of folders) this.git[cwd] ??= {};
    cx.spawn(async (cx) => {
      // finally: one bad folder must not leave refreshing stuck and stop every later refresh.
      try {
        // In parallel, so one folder whose gh call hangs (offline) doesn't hold up the rest.
        await Promise.all(folders.map(async (cwd) => {
          this.git[cwd] = await this.lookup(cwd);
        }));
      } finally {
        this.refreshing = false;
        if (this.again) this.refreshGit(cx);
        cx.notify();
      }
    });
  }

  // { branch, pr, added, removed } from the badge script, or {} when it can't
  // run. Its `error` (gh signed out, offline) still leaves the counts.
  async lookup(cwd) {
    const r = await exec("node", [badgeScript(), cwd]).catch((err) => this.warn("node badge.mjs", err));
    if (!r) return {};
    if (r.code !== 0) {
      this.warn(`badge.mjs in ${cwd}`, r.stderr.trim());
      return {};
    }
    try {
      const values = JSON.parse(r.stdout);
      if (values.error) this.warn(`PR badge in ${cwd}`, values.error);
      return values;
    } catch (err) {
      this.warn(`badge.mjs output in ${cwd}`, err);
      return {};
    }
  }

  // Each distinct problem is logged once, not on every 90 s refresh.
  warn(what, err) {
    const line = `tc-agents: ${what}: ${err}`;
    this.warned ??= new Set();
    if (!this.warned.has(line)) console.log(line);
    this.warned.add(line);
    return null;
  }

  // The one line under a name. Its left end says what the agent is doing while
  // it works or waits on you, and otherwise where it runs: a worker's branch
  // and uncommitted lines, or a row's tab and space. Its right end keeps the
  // worker's PR badge, the context and the age. Every row has exactly this
  // line, even when it has nothing to say, so a row never changes height and nothing below it moves when an
  // agent starts or stops. `rail` draws tree lines in front of a sub-agent's.
  extras(t, k, status, indent, rail = [], tail = {}) {
    const g = (k?.parent && this.git[k.cwd]) || {};
    const id = k?.address ?? "none";
    const counts = [g.added && div().flex_none().text_color(t.ansi2).child(g.added), g.removed && div().flex_none().text_color(t.ansi1).child(g.removed)].filter(Boolean);
    const changed = [g.added && `${g.added.slice(1)} added`, g.removed && `${g.removed.slice(1)} removed`].filter(Boolean).join(", ");
    const where = [];
    if (g.branch) where.push(div().min_w(0).truncate().child(g.branch));
    if (counts.length) where.push(h_flex().id(`lines-${id}`).flex_none().gap(4).tooltip(`Not committed yet: ${changed} lines`).children(counts));
    // A sub-agent with a row of its own has both a branch and a tab.
    if (tail.where) where.push(div().min_w(0).truncate().child(tail.where));
    const doing = status === "working" || status === "blocked" ? activity(k) : null;
    const left = doing
      ? [div().min_w(0).truncate().text_color(status === "blocked" ? t.blocked : t.muted).child(doing)]
      : where.flatMap((b, i) => (i ? [div().flex_none().child("·"), b] : [b]));
    // The badge gives way before the sentence does: it truncates, and the left end keeps a floor.
    const badge = g.pr ? div().id(`badge-${id}`).min_w(0).truncate().text_color(badgeColor(t, g.pr)).tooltip(badgeTip(g.pr)).child(g.pr) : null;
    const right = [badge, ctxLabel(t, k), tail.when].filter(Boolean);
    return [h_flex().h(16).items_center().text_size(11).text_color(t.dim)
      .children(rail.map((l) => div().w(9).mr(4).h_full().flex_none().when(l === "│" || l === "├", (el) => el.border_l(1.5).border_color(t.input))))
      .child(div().w(indent).flex_none())
      .child(h_flex().flex_1().min_w(0).gap(8).items_center()
        .child(h_flex().flex_1().min_w(60).gap(5).items_center().children(left))
        .children(right))];
  }

  // Stamps agents whose state changed. Done and idle count as one: looking at a
  // finished agent turns done into idle, and looking isn't the agent doing anything.
  track(list, now) {
    let dirty = false;
    for (const a of list) {
      const s = a.status === "done" ? "idle" : a.status;
      if (this.changed[a.address]?.s === s) continue;
      this.changed[a.address] = { s, at: now };
      dirty = true;
    }
    if (!dirty) return;
    // Gone and old: the list alone is empty right after a start.
    const listed = new Set(list.map((a) => a.address));
    for (const [k, c] of Object.entries(this.changed)) if (!listed.has(k) && now - c.at > 30 * 86400000) delete this.changed[k];
    localStorage.setItem("changed", JSON.stringify(this.changed));
  }

  // Keep offline pins until their terminal returns, and keep each pending until
  // core echoes the label so a failed write doesn't erase the old pin.
  migratePins(all) {
    const listed = new Map(all.filter((t) => t.state === "live").map((t) => [t.address, t]));
    const pending = this.pendingPins.filter((address) => {
      const terminal = listed.get(address);
      if (!terminal) return true;
      if (terminal.labels?.["herdr.pinned"]) return false;
      if (!this.migratingPins.has(address)) {
        this.migratingPins.add(address);
        run("terminal.pin", { terminal: address, pinned: true });
      }
      return true;
    });
    if (pending.length === this.pendingPins.length) return;
    this.pendingPins = pending;
    if (pending.length) localStorage.setItem("pins", JSON.stringify(pending));
    else localStorage.removeItem("pins");
  }

  since(a) {
    return this.changed[a.address]?.at ?? 0;
  }

  rank(a) {
    return RANK[a.status] ?? 0;
  }

  sortMenu(t) {
    const on = sortOf().id;
    return v_flex()
      .w_full()
      .p(5)
      .bg(t.popover)
      .text_size(12.8)
      .child(div().px(8).pt(4).pb(6).text_size(11).text_color(t.dim).child("Sort agents"))
      .children(SORTS.map((s) => h_flex()
        .id(`sort-${s.id}`)
        .h(31)
        .px(8)
        .gap(9)
        .rounded(7)
        .items_center()
        .text_color(t.foreground)
        .hover((el) => el.bg(t.hover))
        .on_click(() => {
          setShared("agents.sort", s.id);
          closeOverlay(props().overlay);
        })
        .child(svg(`mods/workspace-chrome/${s.icon}.svg`).size(14).flex_none().text_color(t.muted))
        .child(div().flex_1().child(s.label))
        .when(s.id === on, (el) => el.child(svg("mods/workspace-chrome/check.svg").size(14).flex_none().text_color(t.foreground)))));
  }

  peek(addr) {
    run("terminal.peek", { terminal: addr });
  }

  // Live sub-agents of `addr`, depth first, each with the tree lines in front of it.
  // One with a pane already has its own row, so it isn't repeated under its parent.
  tree(all, addr, lead = []) {
    const kids = all.filter((k) => k.parent === addr && k.state === "live" && !this.listed?.has(k.address));
    return kids.flatMap((k, i) => {
      const last = i === kids.length - 1;
      return [
        { t: k, lines: [...lead, last ? "└" : "├"] },
        ...this.tree(all, k.address, [...lead, last ? "" : "│"]),
      ];
    });
  }

  subRow(t, s, shown, compact) {
    const k = s.t;
    const st = kidStatus(k, this.listed);
    const pic = icon(k.program, 14, t.foreground);
    const on = k.address === shown;
    const extra = this.extras(t, k, st, pic ? 22 : 0, s.lines);
    return v_flex()
      .id(`sub-${k.address}`)
      .pl(39)
      .pr(8)
      // The name row is tight, so the gaps above, between and below even out.
      .pt(2)
      .pb(5)
      .rounded(8)
      .flex_none()
      .when(on, (el) => el.bg(t.raised))
      .hover((s) => s.bg(t.hover))
      .on_click(() => this.peek(k.address))
      .child(h_flex()
        .h(22)
        .gap(0)
        .items_center()
        .text_size(12.5)
        .children(s.lines.map(l => div().self_start().mt(-4).w(9).h(17).mr(4).flex_none()
          .when(Boolean(l), el => el.border_l(1.5).border_color(t.input))
          .when(l === "└" || l === "├", el => el.border_b(1.5).rounded_bl(6))))
        .when(Boolean(pic), el => el.child(div().mr(8).child(pic)))
        .child(div().flex_1().truncate().text_color(on ? t.foreground : t.muted).child(k.name || k.template || k.program?.name || k.address))
        .child(this.status(t, { status: st }, compact)))
      .children(extra);
  }

  // compact: a ! for blocked where a header already says "Needs you".
  status(t, a, compact = false) {
    const color = t[a.status] ?? t.dim;
    if (a.status === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).mx(1).flex_none().text_color(t.working).spin(900);
    if (a.status === "blocked" && compact) return div().size(14).flex_none().rounded(4).bg(t.blocked + "26").text_size(10.5).font_bold().text_color(t.blocked).flex().items_center().justify_center().child("!");
    if (a.status === "blocked") return div().flex_none().px(6).h(18).rounded(5).bg(t.blocked + "26").text_size(10.5).font_semibold().text_color(t.blocked).flex().items_center().child("Needs you");
    // Idle: a ring; done: a dot.
    if (a.status === "idle") return div().size(7).mx(3).flex_none().rounded(4).border(1.5).border_color(t.idle ?? t.dim);
    return div().size(7).mx(3).flex_none().rounded(4).bg(a.status === "done" ? color : t.dim + "00");
  }

  render(cx) {
    const t = theme();
    if (props()?.sortMenu) return this.sortMenu(t);
    const collapsed = narrow();
    const sort = sortOf();
    let list = agents();
    this.listed = new Map(list.map((a) => [a.address, a.status]));
    const all = terminals();
    this.migratePins(all);
    this.byAddr = new Map(all.map((k) => [k.address, k]));
    // A worker that just started, or just finished a turn (a commit, a pushed
    // PR), shouldn't wait for the next timer.
    const settled = all.some((k) => k.parent && this.kidWas?.[k.address] === "working" && k.status !== "working");
    this.kidWas = Object.fromEntries(all.filter((k) => k.parent).map((k) => [k.address, k.status]));
    if (settled || gitFolders().some((cwd) => !(cwd in this.git))) this.refreshGit(cx);
    const shown = focused()?.agent;
    const now = Date.now();
    this.track(list, now);
    const byPriority = sort.id === "priority";
    const urgency = new Map(list.map((a) => [a.address, Math.max(this.rank(a), ...this.tree(all, a.address).map((s) => RANK[kidStatus(s.t, this.listed)] ?? 0))]));
    const rankOf = (a) => urgency.get(a.address);
    if (byPriority) list = [...list].sort((x, y) => rankOf(y) - rankOf(x) || this.since(y) - this.since(x) || y.seq - x.seq);
    const pinned = list.filter((a) => a.pinned);
    const rest = list.filter((a) => !a.pinned);
    list = [...pinned, ...rest];
    setAgentOrder(list.map((a) => a.address));

    const withKids = (a, i) => {
      const subs = collapsed ? [] : this.tree(all, a.address);
      const r = row(a, i, subs);
      if (this.folded.has(a.address)) return [r];
      return [r, ...subs.map((s) => this.subRow(t, s, shown, byPriority))];
    };

    // The fold chevron; folded, the count too, colored by the most urgent one.
    const fold = (a, subs) => {
      const sts = subs.map((s) => kidStatus(s.t, this.listed));
      const top = sts.reduce((m, s) => ((RANK[s] ?? 0) > (RANK[m] ?? 0) ? s : m), null);
      const open = !this.folded.has(a.address);
      return div()
        .id(`fold-${a.address}`)
        .h(18)
        .px(3)
        .gap(3)
        .flex()
        .items_center()
        .rounded(4)
        .text_size(11)
        .text_color(open ? t.dim : (t[top] ?? t.dim))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_click((_e, cx) => {
          cx.stop_propagation();
          open ? this.folded.add(a.address) : this.folded.delete(a.address);
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/chevron-${open ? "down" : "right"}.svg`).size(11).flex_none())
        .when(!open, (el) => el.child(String(subs.length)));
    };

    // A row leads with the agent's own title, or the tab someone named when the
    // harness sets none, and puts that named tab on the line below a title. A tab carrying
    // only the program's name ("Claude Code") counts as unnamed, and an
    // automatic tab number shows only when two rows would otherwise read the same.
    const tabs = spaces().flatMap(s => s.tabs);
    // An unnamed tab's name is its position label, like "2"; a tab someone named
    // after the program gets its position instead, so two of them still differ.
    const tabNumber = (a) => {
      const own = spaces().find(s => s.tabs.some(tab => tab.id === a.tab))?.tabs ?? [];
      const at = own.findIndex(tab => tab.id === a.tab);
      if (at === -1) return null;
      return own[at].named ? String(at + 1) : own[at].name;
    };
    const namedTab = (a) => {
      const tab = tabs.find(tab => tab.id === a.tab);
      return tab?.named && tab.name !== a.program?.name ? tab.name : null;
    };
    const detail = new Map(list.map(a => [a.address, ownTitle(a.title, a.program) ?? namedTab(a)]));
    const seen = {};
    for (const a of list) { const k = `${a.space_name}\u0000${detail.get(a.address) ?? ""}`; seen[k] = (seen[k] ?? 0) + 1; }
    for (const a of list) {
      if (detail.get(a.address) == null && seen[`${a.space_name}\u0000`] > 1) detail.set(a.address, tabNumber(a));
    }

    const row = (a, i, subs = []) => {
      const pic = icon(a.program, 16, t.foreground);
      // The agent's own name wins over its tab's:
      // two sessions sharing a tab would otherwise read the same.
      const term = this.byAddr.get(a.address);
      const more = term?.name || term?.labels?.["tc.agent"] || detail.get(a.address);
      // An agent on another machine (`vps/t7`) says which.
      const machine = a.address.includes("/") ? a.address.split("/")[0] : null;
      if (collapsed) {
        return h_flex()
          .id(`ag-${a.address}`)
          .h(26)
          .px(8)
          .flex_none()
          .items_center()
          .gap(4)
          .hover((s) => s.bg(t.hover))
          .on_click(() => run("pane.focus", { pane: a.pane }))
          .child(div().flex_1().min_w(0).whitespace_nowrap().text_right().text_color(t.muted).child(String(i + 1)))
          .child(h_flex().w(14).flex_none().items_center().justify_center().child(this.status(t, a, true)));
      }
      const when = this.since(a);
      const idle = a.status === "idle" && !a.focused;
      const isPinned = a.pinned;
      const pin = div()
        .id(`pin-${a.address}`)
        .flex_none()
        .p(2)
        .rounded(4)
        .text_color(t.dim)
        .cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .tooltip(isPinned ? "Unpin" : "Pin to the top")
        .on_click((_e, cx) => {
          cx.stop_propagation();
          run("terminal.pin", { terminal: a.address, pinned: !isPinned });
          // The row moves away from under the pointer, and no hover-out comes.
          this.hovered = null;
          cx.notify();
        })
        .child(svg(`mods/workspace-chrome/${isPinned ? "pin-off" : "pin"}.svg`).size(13));
      // Under a space header the space goes without saying; an automatic tab number says nothing.
      // Without a space header above (priority, pinned) the row adds its space
      // to the line below, after the tab so a narrow sidebar cuts the space first.
      const full = byPriority || isPinned;
      const name = more ?? (a.program?.name || a.tab_name);
      const where = full && a.space_name && a.space_name !== name ? a.space_name : null;
      const tab = namedTab(a) !== name ? namedTab(a) : null;
      // The tab before the space, so a narrow sidebar cuts the space first.
      const after = [tab, where].filter(Boolean).join(" · ");
      const age = Boolean(when) && sidebarWidth() >= TIME_MIN_PX
        ? div().id(`when-${a.address}`).flex_none().tooltip(timeTip(a.status, now - when)).child(duration(now - when))
        : null;
      // Under the name, past the 16px icon and its 9px gap.
      const extra = this.extras(t, this.byAddr.get(a.address), a.status, pic ? 25 : 0, [], { where: after, when: age });
      return v_flex()
        .id(`ag-${a.address}`)
        .px(8)
        .pt(3)
        .pb(7)
        .flex_none()
        .rounded(8)
        .when(a.focused, (el) => el.bg(t.selected))
        .cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_hover((on, cx) => {
          if (on) this.hovered = a.address;
          else if (this.hovered === a.address) this.hovered = null;
          cx.notify();
        })
        .on_click(() => run("pane.focus", { pane: a.pane }))
        .child(h_flex()
          .h(24)
          .items_center()
          .gap(9)
          .when(Boolean(pic), el => el.child(div().id(`agent-fold-${a.address}`)
            .when(subs.length > 0, el => el.on_click((_e, cx) => {
              cx.stop_propagation();
              this.folded.has(a.address) ? this.folded.delete(a.address) : this.folded.add(a.address);
              cx.notify();
            })).child(pic)))
          .child(div().flex_1().min_w(36).truncate().text_color(idle ? t.muted : t.foreground).child(name))
          .when(Boolean(machine), el => el.child(div().text_size(10).text_color(t.dim).child(machine)))
          .when(subs.length > 0, el => el.child(fold(a, subs)))
          // The pin's slot is always there, so the name doesn't re-truncate on hover.
          .child(this.hovered === a.address ? pin : div().size(17).flex_none())
          .child(this.status(t, a, byPriority && !isPinned)))
        .children(extra);
    };

    // Groups in list order: spaces (grouped) or priority sections. Agents of a
    // space are next to each other in agents(), so neighbours make a group.
    const groups = pinned.length ? [{ id: "pinned", label: "Pinned", status: null, members: pinned }] : [];
    for (const a of rest) {
      const r = rankOf(a) || RANK.idle;
      const id = byPriority ? `sec-${r}` : `sp-${a.space}`;
      if (groups.at(-1)?.id === id) groups.at(-1).members.push(a);
      else groups.push({ id, label: byPriority ? SECTION[r] : a.space_name || "", status: byPriority ? SECTION_STATUS[r] : null, members: [a] });
    }

    // A group's header; it folds the group. Folded, it says how many and the most urgent state.
    const header = (g) => {
      const open = !this.folded.has(g.id);
      const top = g.members.reduce((m, a) => ((RANK[a.status] ?? 0) > (RANK[m] ?? 0) ? a.status : m), null);
      return h_flex()
        .id(g.id)
        .px(8)
        .pt(8)
        .h(30)
        .flex_none()
        .gap(6)
        .items_center()
        .text_size(11)
        .font_medium()
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => {
          open ? this.folded.add(g.id) : this.folded.delete(g.id);
          cx.notify();
        })
        .child(div().truncate().text_color(t[g.status] ?? t.dim).child(g.label))
        .when(byPriority || !open, (el) => el.child(div().text_color(t.dim).child(String(g.members.length))))
        .child(div().flex_1())
        .when(!open, (el) => el
          .when(!byPriority && top && top !== "idle", (el) => el.child(this.status(t, { status: top }, true)))
          .child(svg("mods/workspace-chrome/chevron-right.svg").size(11).flex_none().text_color(t.dim)));
    };
    const rows = collapsed
      ? list.flatMap(withKids)
      : groups.flatMap((g) => [header(g), ...(this.folded.has(g.id) ? [] : g.members.flatMap(withKids))]);

    return v_flex()
      .size_full()
      .min_h(0)
      .bg(t.chrome)
      .border_t(1)
      .border_color(t.border)
      .text_size(13)
      .when(!collapsed, (el) =>
        el.child(
          h_flex()
            .px(16)
            .h(41)
            .pt(14)
            .pb(5)
            .flex_none()
            .items_center()
            .justify_between()
            .child(div().text_size(11.5).font_medium().text_color(t.dim).child("Agents"))
            .child(
              div()
                .id("ag-sort")
                .text_size(11)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(() => openOverlay({ mod: "tc-agents", kind: "popup", width: 200, height: 140, props: { sortMenu: true } }))
                .tooltip(`Sort agents: ${sort.label}`)
                .child(svg(`mods/workspace-chrome/${sort.icon}.svg`).size(14)),
            ),
        ),
      )
      .when(list.length === 0 && !collapsed, (el) =>
        el.child(div().px(12).text_size(12).text_color(t.dim).child("No agent status yet. Agents show up here when they report their status. Older versions and agents inside tmux may not.")),
      )
      .child(v_flex().id("ag-list").flex_1().min_h(0).px(collapsed ? 0 : 8).overflow_y_scrollbar().mode("always").children(rows))
      .when(collapsed, (el) =>
        el.child(
          h_flex()
            .h(28)
            .items_center()
            .justify_center()
            .child(
              div()
                .id("collapse")
                .text_size(13)
                .text_color(t.dim)
                .hover((s) => s.text_color(t.foreground))
                .on_click(toggleSidebar)
                .child("»"),
            ),
        ),
      );
  }
}
