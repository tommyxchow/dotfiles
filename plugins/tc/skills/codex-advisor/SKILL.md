---
name: codex-advisor
description: >-
  On-demand second opinion from Codex (GPT-5.6 Sol via MCP): architecture
  decisions, hard debugging advice, code-review judgments, and "am I wrong?"
  checks. Host stays executor; Codex is read-only consultant. Triggers on
  /codex-advisor, /tc:codex-advisor, "ask Codex", "second opinion from Codex",
  "Codex review", "consult Codex". Manual only — do not auto-invoke.
argument-hint: "[<question> | architecture | debug | review] [high | xhigh | max]"
disable-model-invocation: true
---

# Codex advisor — second opinion via MCP

You are the **orchestrator**. Codex is a read-only senior engineering consultant
(GPT via the user's ChatGPT Codex subscription). You remain the primary agent.
Do not ask Codex to implement. Do not implement yourself unless the user
separately asks after the consult.

## When this is for

Hard or high-leverage questions: architecture, thorny bugs, review judgments,
tradeoff calls, "second opinion / am I wrong?". Skip trivia — don't burn a
consult on something you can answer confidently in one pass.

## 1. Discover the Codex MCP server

Find the connected MCP server that exposes tools named `codex` and
`codex-reply` (Cursor may prefix the server id, e.g. `user-codex`; Claude Code
often uses `codex`). If missing: say whether the failure looks like auth,
executable not on PATH, MCP not connected, or plugin not loaded — then stop.

## 2. Assemble a self-contained consultation prompt

Include, scrubbed of secrets:

1. The user's exact question (text after the command).
2. Relevant conversation context and your current proposed approach (if any).
3. Key files/symbols/errors/constraints (cite paths). Allow Codex to inspect
   the repo itself for more.
4. The specific uncertainty or decision you want adjudicated.

Never attach `.env`, credentials, tokens, or private keys.

## 3. Call `codex` with fixed safety + quality settings

Pinned defaults (re-verify with `codex debug models` only if the model call
fails as unknown-model):

- `model`: `gpt-5.6-sol` (else latest Sol GPT-5.6 slug from catalog; else verified GPT-5.6)
- `cwd`: absolute workspace root for this project
- `sandbox`: `read-only`
- `approval-policy`: `never`
- `config`:
  - `model_reasoning_effort`: `high` (default — see effort policy below)
  - `service_tier`: `fast`
  - `features.fast_mode`: `true`

### Reasoning effort policy

Default **`high`** (OpenAI’s tier for hard reasoning / complex workflows; elevate
only when justified). Drop or raise when appropriate:

| Effort | When |
|--------|------|
| `high` | Default for second opinions, architecture, review judgment |
| `xhigh` | User asks, or long/deep research-style consults where quality clearly needs more |
| `max` | User asks for max / deepest reasoning, or unusually hard / high-stakes decisions |

Honor an explicit user request (`high` / `xhigh` / `max`) over the default. Never use `ultra` (delegation).

### Fallback order (retry the tool; don't give up on first reject)

1. Sol + chosen effort + Fast
2. Sol + chosen effort, no Fast overrides
3. If chosen was `max` and rejected → Sol + `xhigh` + Fast, then without Fast
4. If chosen was `xhigh` and rejected → Sol + `high` + Fast, then without Fast
5. Same sequence on the next verified GPT-5.6 slug if Sol is unavailable

Never escalate sandbox above `read-only`.

Ask Codex to answer with exactly:

1. Recommended approach
2. Why it is preferable
3. Important risks / overlooked issues
4. Strongest reasonable alternative
5. Concrete next step
6. Confidence + material uncertainties

## 4. After Codex returns

- Label the block as **Codex recommendation**.
- Give a short **host analysis** (agree / disagree / partial).
- Surface disagreements explicitly — do not silently merge.
- Do not implement unless the user asks in a later message.
- Keep the reply focused on the original question.

## 5. Follow-ups (same advisor thread)

Codex keeps **its own** thread history via `threadId` (`structuredContent.threadId`
when present). It does **not** automatically see new host-chat messages, tool
results, or edits. For each `codex-reply`:

- Pass the exact `threadId` from the first `codex` call in this consult.
- Include the user's latest question.
- Summarize material developments since the last Codex call (new errors, files,
  test results, constraints, or host recommendations you want challenged).
- Do not resend unchanged bulk context.

Start a **new** `codex` session (do not reuse threadId) when: the user says
"new consultation", the topic is unrelated, they invoke `/tc:codex-advisor`
again for a separate decision, or `codex-reply` fails with session-not-found
(MCP process restarted — threads are in-process, not disk-resumable like
`codex exec resume`). On that failure, start fresh `codex` and bridge prior
Codex conclusions + new host deltas into the prompt.

Never shell out to `codex exec` / `codex exec resume` for this skill — MCP
`codex` + `codex-reply` is the structured path. CLI extras (TUI, disk resume,
`codex review`, etc.) are out of scope for the advisor workflow.
