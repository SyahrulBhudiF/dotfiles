# Pi × Claude-Mem Integration Plan

> **IMPORTANT**: Use plan-execute skill to implement this plan task-by-task.

**Goal:** Integrate claude-mem into `agents/pi` via a custom Pi extension that starts the worker, injects cross-session context, and records useful session/tool observations.
**Architecture:** Keep claude-mem worker/service untouched. Add a Pi-side adapter extension that maps Pi lifecycle events to claude-mem worker HTTP endpoints and optionally exposes manual search. Start with a minimal v1 that proves worker startup, context injection, and basic observation recording before adding richer automation.
**Tech Stack:** Pi extensions (`@mariozechner/pi-coding-agent`), Bun/Node subprocesses, claude-mem worker HTTP API, local JSON config.

---

## 0. What exists now

### Pi side
- `agents/pi/extensions/*` proves Pi supports custom extensions.
- Confirmed Pi lifecycle/events in current extensions:
  - `session_start`
  - `before_agent_start`
  - `agent_start`
  - `agent_end`
  - `turn_start`
- Confirmed extension capabilities:
  - `pi.registerCommand(...)`
  - `pi.on(...)`
  - `pi.sendUserMessage(...)`
  - `pi.appendEntry(...)`
  - `pi.exec(...)`
  - `ctx.getSystemPrompt()`
  - `ctx.ui.notify(...)`

### Claude-mem side
From `agents/claude-mem/openclaw/SKILL.md` and bundled plugin files, worker contract needed by adapters:
- `GET /health`
- `POST /api/sessions/init`
- `POST /api/sessions/observations`
- `POST /api/sessions/summarize`
- `POST /api/sessions/complete`
- `GET /api/context/inject`
- `GET /stream` exists but not needed for v1

Claude-mem native integrations rely on host lifecycle hooks:
- `before_agent_start` → init session
- `before_prompt_build` / equivalent → inject context
- tool result persistence → record observations
- `agent_end` → summarize + complete session

### Constraint
Pi is **not** Claude Code plugin-compatible. No direct install path. Must build adapter.

---

## 1. v1 scope

### In scope
Build a minimal but real Pi adapter:
1. Ensure claude-mem worker is running.
2. Initialize a claude-mem session for Pi session/workspace.
3. Fetch context from claude-mem before Pi agent runs.
4. Inject fetched context into Pi system prompt.
5. Record at least coarse observations from Pi turns.
6. Summarize + complete session on agent/session end.
7. Add manual command `/mem-search <query>` or `/mem-status` only if cheap.

### Out of scope for v1
- Perfect tool-by-tool event parity with Claude Code.
- Full MCP integration.
- SSE live feed.
- Porting claude-mem hook scripts into Pi.
- Compatibility wrappers for multiple host agents.

---

## 2. Proposed files

### Create
- `agents/pi/extensions/claude-mem.ts`
- `agents/pi/claude-mem.json` — local adapter config
- `docs/plans/2026-04-21-pi-claude-mem-integration.md` — this file

### Optional later
- `agents/pi/extensions/claude-mem-types.ts` if types get noisy

### No immediate edits
- Avoid touching `agents/claude-mem/*`
- Avoid touching `agents/pi/mcp.json` in v1 unless manual search is implemented via MCP instead of HTTP

---

## 3. Config design

Create `agents/pi/claude-mem.json`:

```json
{
  "enabled": true,
  "installDir": "/home/ryuko/dotfiles/agents/claude-mem",
  "workerHost": "127.0.0.1",
  "workerPort": 37777,
  "project": "pi",
  "injectContext": true,
  "recordObservations": true,
  "autoStartWorker": true,
  "contextCacheSeconds": 30
}
```

Notes:
- `installDir` points at cloned repo for now.
- `project` should probably include cwd-derived suffix later, eg `pi:<repo-name>`.
- Keep config explicit; no env-magic unless required.

---

## 4. Event mapping

### Pi → Claude-mem mapping

| Pi event | Adapter action | Claude-mem endpoint |
|---|---|---|
| `session_start` | load config, ensure worker, create local adapter state | `GET /health` + worker start if needed |
| `before_agent_start` | init claude-mem session if not initialized | `POST /api/sessions/init` |
| `before_agent_start` | fetch context for current project/session | `GET /api/context/inject` |
| `before_agent_start` | append context to Pi system prompt | n/a |
| `turn_start` | persist lightweight turn marker/custom entry locally | n/a |
| `agent_end` | send summarized observation payload | `POST /api/sessions/summarize` |
| `agent_end` or session-final equivalent | mark complete | `POST /api/sessions/complete` |

### Observation strategy for v1
Because Pi tool-level hooks are not yet confirmed, v1 records **coarse session/turn observations**, not exact tool events.

Observation sources v1:
- current cwd/project
- selected model/provider if available from ctx/session data
- recent assistant response text on `agent_end`
- optional recent user prompt text if accessible from entries
- optional custom entries recorded by adapter itself

This is enough to prove memory continuity even without exact tool-use parity.

---

## 5. Adapter behavior

### 5.1 Worker management
Implement helper:
- `loadConfig()`
- `workerBaseUrl(config)`
- `checkHealth()`
- `startWorker()`
- `ensureWorker()`

`startWorker()` should use Pi exec with cwd=`installDir`:
- `bun plugin/scripts/worker-service.cjs start`

Then poll `/health` for up to ~20s.

Fail behavior:
- If worker unavailable, notify user once.
- Do not hard-fail Pi session.
- Skip integration for this turn/session.

### 5.2 Session identity
Need adapter-owned session id.

Format:
- `pi-${timestamp}-${random}`

Need stable per-Pi-session state in memory:
```ts
{
  initialized: boolean,
  workerReady: boolean,
  claudeMemSessionId: string,
  project: string,
  lastContext?: string,
  lastContextAt?: number
}
```

Project naming rule v1:
- default from config
- if cwd basename exists: `${config.project}:${basename(ctx.cwd)}`

### 5.3 Context injection
On `before_agent_start`:
1. ensure worker
2. init session once
3. fetch context via `GET /api/context/inject`
4. if non-empty, append block like:

```md
<claude-mem-context>
...
</claude-mem-context>
```

Return:
```ts
{ systemPrompt: `${event.systemPrompt}\n\n${block}` }
```

Need cache to avoid repeated fetch every turn.

### 5.4 Summarize/complete
On `agent_end`:
- inspect `event.messages`
- gather last assistant message text
- POST summarize payload
- POST complete payload

If summarize payload contract differs, send minimum viable fields first and adapt after endpoint verification.

### 5.5 Optional commands
If cheap, add:
- `/mem-status` → health + active project/session info
- `/mem-search <query>` only if worker exposes simple search HTTP path or if using claude-mem MCP is trivial

For v1, `/mem-status` is safer than `/mem-search`.

---

## 6. Implementation tasks

### Phase 1 — contract verification
1. Read enough of `agents/claude-mem/plugin/scripts/worker-service.cjs` to confirm payload shapes for:
   - init
   - context inject
   - summarize
   - complete
2. Confirm whether observations endpoint is mandatory for useful summaries.
3. Confirm whether `agent_end` gives enough assistant text for summarization.

### Phase 2 — config + scaffolding
4. Create `agents/pi/claude-mem.json` with conservative defaults.
5. Create `agents/pi/extensions/claude-mem.ts` skeleton.
6. Add local types for config, state, helper responses.

### Phase 3 — worker bootstrap
7. Implement config loading from repo-local file.
8. Implement health check with global `fetch`.
9. Implement worker auto-start via `pi.exec("bun", ["plugin/scripts/worker-service.cjs", "start"], { cwd: installDir })` or equivalent.
10. Implement polling + one-shot UI notifications.

### Phase 4 — session + context
11. Generate adapter session id on `session_start`.
12. On `before_agent_start`, init claude-mem session once.
13. Fetch context injection string.
14. Cache context for `contextCacheSeconds`.
15. Append context to Pi system prompt.

### Phase 5 — coarse recording
16. Add helper to extract text from assistant/user messages.
17. On `agent_end`, build minimal summarize payload from recent assistant output + metadata.
18. Send summarize request.
19. Send complete request.
20. Record adapter diagnostics with `pi.appendEntry(...)` if useful.

### Phase 6 — manual ops
21. Add `/mem-status` command.
22. Print worker state, project, session init status, last context fetch time.

### Phase 7 — polish
23. Rate-limit error notifications.
24. Make network failures soft.
25. Document setup inline in config comments or short README note.

---

## 7. Technical notes

### Avoid
- editing upstream claude-mem worker
- trying to emulate Claude Code hook shell scripts
- adding compatibility shim layers
- making worker startup mandatory for Pi to function

### Prefer
- direct HTTP calls from adapter to worker
- narrow, explicit payloads
- graceful degradation if worker down
- adapter-owned config file

### Likely payload shape guesses
Need validation from source, but likely fields include:
- `sessionId`
- `project`
- `cwd` / `workspace`
- `agent` or `source` = `pi`
- content text for summarize/context queries

### Risk
Biggest risk: worker endpoints expect Claude-Code-specific payload schema.
Mitigation: inspect source first; if needed, use the same minimum fields as OpenClaw integration.

---

## 8. Validation plan

### Manual validation
1. Start Pi in this repo.
2. Verify worker auto-starts.
3. Run one short prompt.
4. Confirm `/mem-status` reports healthy + initialized session.
5. Run second prompt in same repo.
6. Confirm context injection happens on second prompt.
7. Open claude-mem viewer UI and confirm session/summaries exist.
8. Restart Pi, run new prompt, confirm prior context returns.

### Success criteria
- Pi still works if claude-mem is absent/down.
- Worker can be started from Pi automatically.
- A claude-mem session is created for Pi usage.
- Context appears in later prompts.
- Session completion writes something visible in viewer.

---

## 9. Future follow-ups

### v2
- tool-level observation capture if Pi exposes tool start/end hooks
- `/mem-search` command
- MCP server wiring into `agents/pi/mcp.json`
- richer project scoping
- compaction-aware context refresh

### v3
- share adapter package across repos
- better status UI/footer badge
- searchable saved memory inside Pi TUI

---

## Unresolved questions
1. Exact worker payload schemas for `init`, `summarize`, `complete`, `context/inject`?
2. Does Pi expose tool-level hooks anywhere outside current local extensions?
3. Is there a dedicated Pi event for session-final end distinct from `agent_end`?
4. Do you want project naming fixed as `pi:<repo>` or manually configured only?
5. For v1, is `/mem-status` enough, or do you also want `/mem-search` immediately?

## Concrete steps
1. Inspect claude-mem worker endpoint payload contracts.
2. Confirm Pi lifecycle/tool hooks available to extensions.
3. Create `agents/pi/claude-mem.json` + `agents/pi/extensions/claude-mem.ts` skeleton.
4. Implement worker bootstrap + health checks.
5. Implement session init + context injection.
6. Implement coarse summarize + complete flow.
7. Add `/mem-status`.
8. Manually validate in this repo.