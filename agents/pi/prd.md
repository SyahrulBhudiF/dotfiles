# Pi × Zed ACP — Product Requirements Document

> **Status**: Planning  
> **Runtime**: Bun  
> **Protocol**: Agent Client Protocol (ACP) v1  
> **Target**: Zed IDE ≥ 0.160

---

## 1. Ringkasan

Tujuan project ini adalah membuat **Pi** (`@mariozechner/pi-coding-agent`) bisa dipakai sebagai agent AI di dalam **Zed IDE** melalui **Agent Client Protocol (ACP)**.

Dengan ini, pengguna Zed bisa memilih "Pi" di Agent Panel Zed — persis seperti Claude Code atau Gemini CLI — dan Pi akan berjalan dengan LLM backend sendiri (kosyayuk / github-copilot).

---

## 2. Arsitektur

```
┌─────────────────────────────────────┐
│              Zed IDE                │
│         (ACP Client side)           │
│                                     │
│  Agent Panel ──► spawn subprocess   │
└──────────────┬──────────────────────┘
               │ stdio (JSON-RPC)
               │ stdin ← requests dari Zed
               │ stdout → responses + notifications ke Zed
               │
┌──────────────▼──────────────────────┐
│       zed-acp-server.ts             │  ← FILE BARU (entry point)
│   (AgentSideConnection wrapper)     │
│                                     │
│  • initialize handshake             │
│  • manage session map               │
│  • bridge ACP ↔ Pi internal API     │
│  • stream ACP SessionUpdate         │
└──────────────┬──────────────────────┘
               │ Pi programmatic API
               │
┌──────────────▼──────────────────────┐
│    @mariozechner/pi-coding-agent    │
│         (Pi Core)                   │
│                                     │
│  • agent run / cancel               │
│  • tool execution                   │
│  • context management               │
└──────────────┬──────────────────────┘
               │ provider API
               │
┌──────────────▼──────────────────────┐
│   kosyayuk-provider / copilot       │
│   (LLM Backend)                     │
│                                     │
│  • ai.naufal.work (OpenAI-compat)   │
│  • Claude Sonnet/Haiku via proxy    │
└─────────────────────────────────────┘
```

### Alur Session Lengkap

```
Zed                          zed-acp-server.ts              Pi Core
 │                                 │                           │
 │──── initialize ────────────────►│                           │
 │◄─── InitializeResponse ─────────│                           │
 │     (capabilities, agent_info)  │                           │
 │                                 │                           │
 │──── new_session ───────────────►│                           │
 │     (cwd, mcp_servers)          │── createAgentInstance ───►│
 │                                 │◄─ instance ───────────────│
 │◄─── NewSessionResponse ─────────│                           │
 │     (session_id, models)        │                           │
 │                                 │                           │
 │──── prompt ────────────────────►│                           │
 │     (session_id, messages)      │── agent.run(messages) ───►│
 │                                 │   (streaming)             │
 │◄─── session/notification ───────│◄─ text delta ─────────────│
 │◄─── session/notification ───────│◄─ tool_call ──────────────│
 │──── request_permission ────────►│                           │
 │◄─── permission_response ────────│                           │
 │◄─── session/notification ───────│◄─ tool_call_update ───────│
 │◄─── session/notification ───────│◄─ done ───────────────────│
 │◄─── PromptResponse ─────────────│                           │
 │     (stop_reason: end_turn)     │                           │
 │                                 │                           │
 │──── cancel (optional) ─────────►│── agent.abort() ─────────►│
 │◄─── PromptResponse ─────────────│◄─ cancelled ──────────────│
 │     (stop_reason: cancelled)    │                           │
```

---

## 3. Komponen yang Dibuat

### 3.1 `extensions/zed-acp-server.ts` ← **File Utama**

Entry point yang di-spawn Zed. Implements `AgentSideConnection` dari `@agentclientprotocol/sdk`.

**Tanggung jawab:**
- ACP `initialize` — deklarasi capabilities Pi ke Zed
- ACP `new_session` — buat Pi agent instance, simpan di session map
- ACP `prompt` — jalankan Pi, convert output stream ke `SessionUpdate`
- ACP `cancel` — abort Pi agent run secara graceful
- ACP `read_text_file` — request baca file ke Zed (bukan langsung dari disk)
- ACP `write_text_file` — request tulis file ke Zed

**Skeleton kasar:**

```typescript
import { AgentSideConnection } from "@agentclientprotocol/sdk";

const server = new AgentSideConnection({
  async initialize(req) {
    return {
      protocolVersion: "v1",
      agentInfo: { name: "pi" },
      agentCapabilities: {
        promptCapabilities: { embeddedContext: true },
        loadSession: false,
      },
      authMethods: [],
    };
  },

  async newSession(req) {
    const session = await createPiSession(req.cwd);
    sessions.set(req.sessionId, session);
    return {
      sessionId: req.sessionId,
      models: getPiModels(),
    };
  },

  async prompt(req, sendUpdate) {
    const session = sessions.get(req.sessionId);
    await session.run(req.messages, {
      onText: (delta) => sendUpdate({ type: "text_delta", delta }),
      onToolCall: (tc) => sendUpdate({ type: "tool_call", ...tc }),
      onDone: () => {},
    });
    return { stopReason: "end_turn" };
  },

  async cancel(req) {
    sessions.get(req.sessionId)?.abort();
  },
});

server.listen(process.stdin, process.stdout);
```

### 3.2 `extensions/zed-acp-provider.ts` ← **Pi Extension**

Pi extension yang dimuat saat Pi berjalan dalam mode ACP. Dikontrol via env var `PI_ZED_ACP=1`.

**Tanggung jawab:**
- Detect mode ACP, skip TUI initialization
- Register `kosyayuk` provider sebagai LLM backend di Pi
- Override file I/O Pi → route ke ACP read/write callbacks
- Load agent profile yang cocok untuk context Zed

---

## 4. Dependencies

### Baru (perlu install)

```bash
bun add @agentclientprotocol/sdk
```

| Package | Alasan |
|---|---|
| `@agentclientprotocol/sdk` | TypeScript SDK resmi ACP — provides `AgentSideConnection` |

### Sudah Ada (peer deps)

| Package | Versi |
|---|---|
| `@mariozechner/pi-coding-agent` | 0.55.4 |
| `@mariozechner/pi-ai` | 0.55.4 |
| `@mariozechner/pi-tui` | 0.55.4 |

---

## 5. Konfigurasi Zed

Tambahkan ke `~/.config/zed/settings.json`:

```json
{
  "agent_servers": {
    "pi": {
      "command": "/home/ryuko/.bun/bin/bun",
      "args": [
        "run",
        "/home/ryuko/dotfiles/agents/pi/extensions/zed-acp-server.ts"
      ],
      "env": {
        "PI_ZED_ACP": "1",
        "PI_CONFIG_DIR": "/home/ryuko/dotfiles/agents/pi",
        "ANTHROPIC_AUTH_TOKEN": "${env:ANTHROPIC_AUTH_TOKEN}",
        "ANTHROPIC_BASE_URL": "${env:ANTHROPIC_BASE_URL}"
      }
    }
  }
}
```

---

## 6. Risks & Mitigations

| ID | Risiko | Impact | Mitigasi |
|---|---|---|---|
| R1 | Pi TUI pakai stdin/stdout yang sama dengan ACP stdio | 🔴 Tinggi | Detect `PI_ZED_ACP=1`, skip TUI init; pakai headless mode Pi |
| R2 | Pi output format tidak mapping ke ACP `SessionUpdate` | 🟡 Sedang | Tulis `PiOutputAdapter` — konversi Pi events ke `TextDelta`, `ToolCall`, dll |
| R3 | Pi file I/O langsung ke disk, Zed tidak tahu | 🟡 Sedang | Override fs via Pi extension, route ke ACP `write_text_file` / `read_text_file` |
| R4 | Versi ACP SDK vs Zed internal ACP bisa mismatch | 🟢 Rendah | Pin SDK, test dengan Zed terbaru, ACP v1 sudah stable |
| R5 | Pi belum tentu support headless/programmatic invocation | 🔴 Tinggi | **Eksplorasi Pi API dulu** (lihat Section 7) |

---

## 7. Exploration Plan — Yang Harus Diinvestigasi

> Ini bagian terpenting sebelum nulis kode. Setiap poin di bawah adalah pertanyaan yang harus dijawab lewat eksplorasi kode.

---

### 7.1 🔍 Pi Headless API

**Pertanyaan:** Apakah `@mariozechner/pi-coding-agent` punya API untuk menjalankan agent secara programmatic tanpa TUI?

**Yang perlu dilihat:**
```
node_modules/@mariozechner/pi-coding-agent/
  ├── src/
  │   ├── agent.ts          ← apakah ada class Agent yang bisa di-instantiate?
  │   ├── run.ts            ← apakah ada fungsi run() yang bisa dipanggil?
  │   └── headless.ts       ← mungkin ada mode ini?
  ├── index.ts              ← apa yang di-export?
  └── types.ts              ← lihat interface/type yang tersedia
```

**Yang dicari:**
- Export `createAgent(config)` atau `Agent` class
- Method `agent.run(messages)` yang return stream/async iterator
- Method `agent.abort()` atau `agent.cancel()`
- Event emitter untuk output streaming
- Flag untuk disable TUI

**Eksplorasi awal:**
```bash
bun run -e "const pi = require('@mariozechner/pi-coding-agent'); console.log(Object.keys(pi))"
```

---

### 7.2 🔍 Pi Output Stream Format

**Pertanyaan:** Bagaimana Pi mengoutput hasil kerjanya? Event-based? Stream? Callback?

**Yang perlu dilihat:**
- Tipe return dari `agent.run()` atau equivalent
- Apakah ada `onMessage`, `onToolCall`, `onComplete` callbacks
- Apakah outputnya token-by-token atau per-message
- Apakah ada typing untuk output events

**Mapping yang dibutuhkan untuk ACP:**

| Pi Output Event | ACP SessionUpdate Type |
|---|---|
| Text streaming | `{ type: "text_delta", delta: "..." }` |
| Tool call start | `{ type: "tool_call", toolCallId, title, ... }` |
| Tool call update | `{ type: "tool_call_update", toolCallId, output }` |
| Tool call done | `{ type: "tool_call_update", toolCallId, done: true }` |
| Agent done | return `{ stopReason: "end_turn" }` |
| Agent error | return `{ stopReason: "error" }` |

---

### 7.3 🔍 Pi Extension API (`ExtensionAPI`)

**Pertanyaan:** Apa saja yang bisa dilakukan Pi extension? Khususnya untuk override file I/O.

**Yang perlu dilihat:**
```typescript
// Di kosyayuk-provider.ts sudah ada:
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerProvider("kosyayuk", { ... });
}
```

**Yang dicari di `ExtensionAPI`:**
- `pi.registerProvider()` — sudah dipakai
- `pi.onFileRead(handler)` — apakah ada hook untuk intercept file reads?
- `pi.onFileWrite(handler)` — apakah ada hook untuk intercept file writes?
- `pi.registerTool()` — apakah bisa tambah custom tool?
- `pi.onBeforeRun()` / `pi.onAfterRun()` — lifecycle hooks?
- `pi.setHeadless(true)` — apakah ada ini?

**Cara eksplorasi:**
```bash
# Lihat semua method di ExtensionAPI
bun run -e "
  const pi = require('@mariozechner/pi-coding-agent');
  const api = new pi.ExtensionAPI();
  console.log(Object.getOwnPropertyNames(Object.getPrototypeOf(api)));
"
```

---

### 7.4 🔍 Pi Config & Extensions Loading

**Pertanyaan:** Bagaimana Pi memuat extensions? Apakah kita bisa load `zed-acp-provider.ts` secara programmatic?

**Yang perlu dilihat:**
- `settings.json` sudah ada `"packages"` array — apakah extension lokal bisa ditambah?
- Apakah ada API `pi.loadExtension(path)`?
- Apakah ada env var atau CLI flag untuk spesifikasi config dir?

**Dari settings.json yang ada:**
```json
{
  "packages": [
    "npm:pi-mcp-adapter",
    "npm:pi-hashline-edit"
  ]
}
```

**Pertanyaan:** Apakah format `"file:./extensions/zed-acp-provider.ts"` atau `"local:./extensions/..."` bisa dipakai?

---

### 7.5 🔍 ACP SDK `@agentclientprotocol/sdk` API

**Pertanyaan:** Bagaimana tepatnya menggunakan `AgentSideConnection`?

**Yang perlu dilihat:**
- NPM page: https://www.npmjs.com/package/@agentclientprotocol/sdk
- GitHub: https://github.com/agentclientprotocol/agent-client-protocol (di folder `src/`)
- Contoh implementasi agent (Gemini CLI adalah referensi production)

**Method yang perlu diimplementasi:**
```typescript
interface AgentSideConnection {
  // Required
  initialize(req: InitializeRequest): Promise<InitializeResponse>
  newSession(req: NewSessionRequest): Promise<NewSessionResponse>
  prompt(req: PromptRequest, sendUpdate: (update: SessionUpdate) => void): Promise<PromptResponse>
  cancel(req: CancelRequest): Promise<void>
  
  // Optional
  loadSession?(req: LoadSessionRequest): Promise<LoadSessionResponse>
  listSessions?(req: ListSessionsRequest): Promise<ListSessionsResponse>
  setSessionModel?(req: SetSessionModelRequest): Promise<void>
  authenticate?(req: AuthenticateRequest): Promise<void>
  
  // Client callbacks (Zed → Pi requests)
  readTextFile?(req: ReadTextFileRequest): Promise<ReadTextFileResponse>
  writeTextFile?(req: WriteTextFileRequest): Promise<WriteTextFileResponse>
  requestPermission?(req: RequestPermissionRequest): Promise<RequestPermissionResponse>
}
```

**Cara listen di stdio:**
```typescript
// Kemungkinan caranya:
connection.listen(process.stdin, process.stdout)
// atau:
connection.start({ stdin: process.stdin, stdout: process.stdout })
```

---

### 7.6 🔍 Gemini CLI Sebagai Referensi

**Pertanyaan:** Bagaimana Gemini CLI mengimplementasikan ACP server? Ini adalah referensi production terbaik.

**Yang perlu dilihat:**
- Repo: https://github.com/google-gemini/gemini-cli
- Cari file yang berkaitan dengan ACP:
  ```
  gemini-cli/
    packages/cli/
      src/
        acp/          ← kemungkinan ada folder ini
        server.ts     ← atau di sini
  ```

**Yang dicari:**
- Cara mereka implement `AgentSideConnection`
- Cara mereka stream output ke Zed
- Cara mereka handle `requestPermission`
- Cara mereka handle file system callbacks

---

### 7.7 🔍 Pi CLI Invocation

**Pertanyaan:** Apakah Pi punya CLI mode yang bisa dipakai sebagai subprocess (non-interactive)?

**Yang perlu dilihat:**
```bash
# Cek binary Pi yang tersedia
which pi
bun run pi --help

# Atau via bunx
bunx @mariozechner/pi-coding-agent --help

# Cek apakah ada flag --headless, --no-tui, --json, dsb
```

**Alternatif approach:** Jika Pi tidak punya headless mode, kita bisa:
1. **Wrap Pi CLI**: Spawn Pi sebagai subprocess dari `zed-acp-server.ts`, parse stdout Pi
2. **Import Pi library**: Import Pi sebagai library, tidak pakai CLI
3. **Hybrid**: Pakai Pi library untuk core, bypass TUI

---

## 8. Implementation Steps (Setelah Eksplorasi)

Urutan implementasi setelah semua exploration selesai:

```
Phase 1 — Foundation
  [x] prd.json dibuat
  [x] prd.md dibuat
  [ ] Eksplorasi Pi headless API (7.1)
  [ ] Eksplorasi Pi Extension API (7.3)
  [ ] Install @agentclientprotocol/sdk
  [ ] Baca ACP SDK docs + contoh

Phase 2 — Skeleton
  [ ] Buat zed-acp-server.ts dengan AgentSideConnection
  [ ] Implement initialize() dan new_session() (basic)
  [ ] Test koneksi: tambah ke Zed settings, lihat apakah Zed detect Pi

Phase 3 — Core
  [ ] Implement prompt() — jalankan Pi, return dummy response dulu
  [ ] Implement output streaming ke ACP SessionUpdate
  [ ] Implement cancel()

Phase 4 — Integration
  [ ] Buat zed-acp-provider.ts — Pi extension untuk Zed mode
  [ ] Route file I/O ke ACP callbacks
  [ ] Test full flow: prompt di Zed → Pi run → hasil muncul di Zed

Phase 5 — Polish
  [ ] Model selector (expose Pi providers ke Zed)
  [ ] Error handling & reconnect
  [ ] Permission dialog untuk tool calls
  [ ] Update gen-kosyayuk.nu agar bisa generate model list untuk ACP juga
```

---

## 9. File yang Akan Dibuat / Diubah

| File | Action | Keterangan |
|---|---|---|
| `extensions/zed-acp-server.ts` | **CREATE** | Entry point ACP server |
| `extensions/zed-acp-provider.ts` | **CREATE** | Pi extension untuk Zed mode |
| `package.json` | **UPDATE** | Tambah `@agentclientprotocol/sdk` |
| `prd.json` | ✅ Done | Machine-readable spec |
| `prd.md` | ✅ Done | Dokumen ini |

---

## 10. Referensi

| Resource | URL |
|---|---|
| ACP Spec | https://agentclientprotocol.com |
| ACP TypeScript SDK | https://www.npmjs.com/package/@agentclientprotocol/sdk |
| ACP GitHub | https://github.com/agentclientprotocol/agent-client-protocol |
| Zed `agent_servers` source | `zed/crates/agent_servers/src/acp.rs` |
| Zed `custom.rs` (cara Zed spawn agent) | `zed/crates/agent_servers/src/custom.rs` |
| Gemini CLI (referensi ACP production impl) | https://github.com/google-gemini/gemini-cli |
| Existing kosyayuk-provider | `agents/pi/extensions/kosyayuk-provider.ts` |