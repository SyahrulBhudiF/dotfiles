/**
 * starship-prompt - Starship-style prompt for pi
 *
 * This is a LIBRARY package. To use it, create a local extension:
 *
 * ```typescript
 * // ~/.pi/extensions/my-editor.ts
 * import { StarshipEditor, createStarshipWidget, setupStarshipEvents } from "@elianiva/pi-starship";
 *
 * export default function (pi: ExtensionAPI) {
 *   pi.on("session_start", (_e, ctx) => {
 *     ctx.ui.setEditorComponent((tui, theme, kb) =>
 *       new StarshipEditor(tui, theme, kb, undefined, ctx)
 *     );
 *     createStarshipWidget(pi, ctx);
 *   });
 *   setupStarshipEvents(pi);
 * }
 * ```
 *
 * Or compose with other editors:
 *
 * ```typescript
 * import { StarshipEditor, createStarshipWidget, setupStarshipEvents } from "@elianiva/pi-starship";
 * import { withPickers } from "@elianiva/pi-ckers";
 * import { filePicker } from "@elianiva/pi-ckers/builtin/file";
 * import { gitPicker } from "@elianiva/pi-ckers/builtin/git";
 *
 * const ComposedEditor = withPickers(StarshipEditor, [filePicker(), gitPicker()]);
 *
 * export default function (pi: ExtensionAPI) {
 *   pi.on("session_start", (_e, ctx) => {
 *     ctx.ui.setEditorComponent((tui, theme, kb) =>
 *       new ComposedEditor(tui, theme, kb, ctx.ui.theme, ctx)
 *     );
 *     createStarshipWidget(pi, ctx);
 *   });
 *   setupStarshipEvents(pi);
 * }
 * ```
 */

import { CustomEditor } from "@mariozechner/pi-coding-agent";
import type { TUI, EditorTheme, EditorOptions } from "@mariozechner/pi-tui";
import type {
  KeybindingsManager,
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import type { AssistantMessage } from "@mariozechner/pi-ai";
import { visibleWidth, CURSOR_MARKER } from "@mariozechner/pi-tui";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

// ── vcs cache ───────────────────────────────────────────────────────────

export interface VcsInfo {
  type: "git" | "jj";
  branch: string;
  commit: string;
  commitRest?: string;
  dirty: boolean;
}

interface VcsCache {
  info: VcsInfo | null;
  time: number;
  cwd: string;
  promise: Promise<void> | null;
}

export const vcs: VcsCache = {
  info: null,
  time: 0,
  cwd: "",
  promise: null,
};

const CACHE_TTL = 2000;
const EXEC_TIMEOUT = 300;

async function getVcsInfo(cwd: string): Promise<VcsInfo | null> {
  const execOptions = { cwd, timeout: EXEC_TIMEOUT };

  try {
    const { stdout } = await execAsync(
      'jj log -r @ --no-graph -T \'change_id.shortest() ++ "\\n" ++ change_id.shortest(8) ++ "\\n" ++ self.bookmarks().join(", ")\'',
      execOptions,
    );
    const lines = stdout.trim().split("\n");
    const commitShort = lines[0]?.trim() ?? "";
    const commitLong = lines[1]?.trim() ?? "";
    return {
      type: "jj",
      branch: lines[2]?.trim().replace("*", ""),
      commit: commitShort,
      commitRest: commitLong.slice(commitShort.length),
      dirty: await execAsync("jj diff --stat", execOptions)
        .then(({ stdout }) => stdout.trim().length > 0)
        .catch(() => false),
    };
  } catch {
    // fall through to git
  }

  try {
    const [{ stdout: branchOut }, { stdout: commitOut }] = await Promise.all([
      execAsync("git branch --show-current", execOptions),
      execAsync("git rev-parse --short HEAD", execOptions),
    ]);
    return {
      type: "git",
      branch: branchOut.trim() || "HEAD",
      commit: commitOut.trim(),
      dirty: await execAsync("git diff-index --quiet HEAD --", execOptions)
        .then(() => false)
        .catch(() => true),
    };
  } catch {
    return null;
  }
}

export async function refreshVcs(cwd: string, cb?: () => void): Promise<void> {
  const now = Date.now();
  if (vcs.cwd === cwd && now - vcs.time < CACHE_TTL) {
    cb?.();
    return;
  }

  if (vcs.promise) {
    await vcs.promise;
    if (vcs.cwd === cwd && Date.now() - vcs.time < CACHE_TTL) {
      cb?.();
      return;
    }
  }

  vcs.promise = (async () => {
    vcs.cwd = cwd;
    vcs.time = now;
    try {
      vcs.info = await getVcsInfo(cwd);
    } finally {
      vcs.promise = null;
    }
  })();
  await vcs.promise;
  cb?.();
}

export function getVcs(): VcsCache {
  return vcs;
}

// ── helpers ──────────────────────────────────────────────────────────────

export function tk(n: number): string {
  if (n < 1000) return `${n}`;
  if (n >= 1000000000) {
    const b = n / 1000000000;
    return b.toFixed(b < 10 ? 1 : 0).replace(/\.0$/, "") + "B";
  }
  if (n >= 1000000) {
    const m = n / 1000000;
    return m.toFixed(m < 10 ? 1 : 0).replace(/\.0$/, "") + "M";
  }
  const k = n / 1000;
  return k.toFixed(k < 10 ? 1 : 0).replace(/\.0$/, "") + "k";
}

/**
 * StarshipEditor - Custom editor with ❯ prompt prefix and no borders
 */
export class StarshipEditor extends CustomEditor {
  private readonly ctx?: ExtensionContext;
  private readonly fallbackTheme: EditorTheme;

  constructor(
    tui: TUI,
    editorTheme: EditorTheme,
    kb: KeybindingsManager,
    opts?: EditorOptions,
    ctx?: ExtensionContext,
  ) {
    super(tui, editorTheme, kb, opts, ctx);
    this.ctx = ctx;
    this.fallbackTheme = editorTheme;
  }

  render(width: number): string[] {
    const theme = this.ctx?.ui.theme ?? this.fallbackTheme;
    const prompt = theme.bold(theme.fg("success", "❯")) + " ";
    const promptW = visibleWidth(prompt);
    const innerW = Math.max(10, width - promptW);

    // suppress borders → they become ""
    const origBorder = this.borderColor;
    this.borderColor = () => "";
    const raw = super.render(innerW);
    this.borderColor = origBorder;

    // strip empty border lines
    const lines = raw.filter((l) => l !== "");
    if (lines.length === 0) return [prompt + (this.focused ? CURSOR_MARKER : "")];

    const indent = " ".repeat(promptW);
    return [prompt + lines[0], ...lines.slice(1).map((l) => indent + l)];
  }
}

// ── widget helpers ───────────────────────────────────────────────────────

const bashDebounceTimers = new Map<string, NodeJS.Timeout | null>();

function getTimerKey(ctx: ExtensionContext): string {
  return ctx.sessionManager.sessionId ?? "default";
}

export function buildInfoLine(ctx: ExtensionContext, pi: ExtensionAPI): string {
  const t = ctx.ui.theme;
  const p: string[] = [];
  const v = getVcs();

  p.push(t.bold(t.fg("mdHeading", ` ) `)));

  const cwd = ctx.cwd;
  const home = process.env.HOME || "";
  p.push(t.bold(t.fg("error", cwd.startsWith(home) ? "~" + cwd.slice(home.length) : cwd)));

  if (v.info) {
    p.push(" on ");
    if (v.info.type === "git") {
      p.push(t.fg("accent", ` ${v.info.branch}`));
      if (v.info.dirty) p.push(t.bold(t.fg("error", "*")));
      p.push(` (${t.bold(t.fg("accent", v.info.commit))})`);
    } else {
      p.push(t.bold(t.fg("accent", ` ${v.info.commit}`)));
      if (v.info.commitRest) {
        p.push(t.fg("dim", v.info.commitRest));
        if (v.info.dirty) p.push(t.bold(t.fg("error", "*")));
      }
      if (v.info.branch) p.push(t.fg("dim", ` (${v.info.branch})`));
    }
  }

  if (ctx.model?.id) {
    p.push(" via ");
    p.push(t.bold(t.fg("syntaxString", ` ${ctx.model.id}`)));
  }

  const lvl = pi.getThinkingLevel();
  if (lvl !== "off") {
    const c: Record<string, Parameters<typeof t.fg>[0]> = {
      minimal: "thinkingMinimal",
      low: "thinkingLow",
      medium: "thinkingMedium",
      high: "thinkingHigh",
      xhigh: "thinkingXhigh",
    };
    p.push(" " + t.bold(t.fg(c[lvl] ?? "warning", `󱐋 ${lvl}`)));
  }

  // Stats
  const branch = ctx.sessionManager.getBranch();
  let inp = 0,
    out = 0,
    cacheRead = 0,
    cost = 0;
  for (const e of branch) {
    if (e.type === "message" && e.message.role === "assistant") {
      const m = e.message as AssistantMessage;
      inp += m.usage.input;
      out += m.usage.output;
      cacheRead += m.usage.cacheRead || 0;
      cost += m.usage.cost.total;
    }
  }

  p.push(t.fg("dim", " · "));
  p.push(
    t.fg("syntaxFunction", `↑ ${tk(inp)}`) +
      (cacheRead > 0 ? t.fg("dim", `/${tk(cacheRead)}`) : "") +
      " " +
      t.fg("syntaxString", `↓ ${tk(out)}`),
  );
  if (cost > 0) p.push(t.fg("dim", ` $${cost.toFixed(4)}`));

  const usage = ctx.getContextUsage();
  if (usage) {
    const limit = ctx.model?.contextWindow ?? usage.limit;
    const pct = limit > 0 ? (usage.tokens / limit) * 100 : 0;
    const color: Parameters<typeof t.fg>[0] =
      limit > 0 ? (pct > 85 ? "error" : pct > 60 ? "warning" : "success") : "dim";
    p.push(" · " + t.fg(color, `󰍛 ${tk(usage.tokens)}/${limit > 0 ? tk(limit) : "???"}`));
  }

  return p.join("");
}

export function updateWidget(ctx: ExtensionContext, pi: ExtensionAPI): void {
  ctx.ui.setWidget("starship-info", [buildInfoLine(ctx, pi)]);
}

export function debouncedVcsUpdate(ctx: ExtensionContext, pi: ExtensionAPI): void {
  const key = getTimerKey(ctx);
  const existing = bashDebounceTimers.get(key);
  if (existing) clearTimeout(existing);

  const timer = setTimeout(() => {
    bashDebounceTimers.delete(key);
    vcs.time = 0;
    refreshVcs(ctx.cwd, () => updateWidget(ctx, pi));
  }, 300);

  bashDebounceTimers.set(key, timer);
}

export function createStarshipWidget(pi: ExtensionAPI, ctx: ExtensionContext): void {
  ctx.ui.setWidget("starship-info", [buildInfoLine(ctx, pi)]);
  vcs.time = 0;
  refreshVcs(ctx.cwd, () => updateWidget(ctx, pi));
}

export function setupStarshipEvents(pi: ExtensionAPI): void {
  pi.on("session_switch", (_ev, ctx) => {
    vcs.time = 0;
    refreshVcs(ctx.cwd, () => updateWidget(ctx, pi));
  });
  pi.on("agent_start", (_ev, ctx) => updateWidget(ctx, pi));
  pi.on("turn_end", (_ev, ctx) => updateWidget(ctx, pi));
  pi.on("agent_end", (_ev, ctx) => updateWidget(ctx, pi));
  pi.on("model_select", (_ev, ctx) => updateWidget(ctx, pi));
  pi.on("user_bash", (_ev, ctx) => debouncedVcsUpdate(ctx, pi));
}

// No default export - this is a library, not an auto-loadable extension
