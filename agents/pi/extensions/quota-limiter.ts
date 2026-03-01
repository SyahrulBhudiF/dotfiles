/**
 * Quota Limiter Extension
 *
 * Tracks daily token usage across all kosyayuk models and soft-blocks
 * when usage exceeds 40% of the daily limit.
 *
 * Config:
 *   DAILY_TOKEN_LIMIT  = 50,000,000 (50M)
 *   SOFT_THRESHOLD     = 0.40 (40%)
 *   Soft block at      = 20,000,000 (20M)
 *
 * Data persisted in session via pi.appendEntry("quota-usage", ...).
 * Also writes daily totals to ~/.pi/agent/quota-usage.json for cross-session tracking.
 *
 * Commands:
 *   /quota        - Show current usage
 *   /quota-reset  - Reset daily usage
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

const DAILY_TOKEN_LIMIT = 50_000_000; // 50M tokens/day
const SOFT_THRESHOLD = 0.40; // 40%
const SOFT_LIMIT = Math.floor(DAILY_TOKEN_LIMIT * SOFT_THRESHOLD); // 20M
const QUOTA_FILE = path.join(
  process.env.HOME || "~",
  ".pi/agent/quota-usage.json"
);

interface QuotaData {
  date: string; // YYYY-MM-DD
  totalTokens: number;
  totalCost: number;
  requestCount: number;
  byModel: Record<string, { tokens: number; cost: number; requests: number }>;
}

function todayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function loadQuota(): QuotaData {
  try {
    const raw = fs.readFileSync(QUOTA_FILE, "utf-8");
    const data: QuotaData = JSON.parse(raw);
    if (data.date === todayStr()) return data;
  } catch {}
  return {
    date: todayStr(),
    totalTokens: 0,
    totalCost: 0,
    requestCount: 0,
    byModel: {},
  };
}

function saveQuota(data: QuotaData): void {
  fs.writeFileSync(QUOTA_FILE, JSON.stringify(data, null, 2));
}

function formatTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return String(n);
}

function usagePercent(data: QuotaData): number {
  return (data.totalTokens / DAILY_TOKEN_LIMIT) * 100;
}

function quotaStatusLine(data: QuotaData): string {
  const pct = usagePercent(data);
  const used = formatTokens(data.totalTokens);
  const limit = formatTokens(DAILY_TOKEN_LIMIT);
  const softLimit = formatTokens(SOFT_LIMIT);
  const bar = pct >= SOFT_THRESHOLD * 100 ? "⚠️" : "✅";
  return `${bar} Quota: ${used}/${limit} (${pct.toFixed(1)}%) | Soft limit: ${softLimit} | Reqs: ${data.requestCount}`;
}

export default function (pi: ExtensionAPI) {
  let quota = loadQuota();

  // Update footer status
  function updateStatus(ctx?: { ui: { setStatus: (id: string, text: string) => void } }) {
    ctx?.ui.setStatus("quota", quotaStatusLine(quota));
  }

  // --- Session start: load quota & show status ---
  pi.on("session_start", async (_event, ctx) => {
    quota = loadQuota();
    updateStatus(ctx);
  });

  // --- Before agent start: check quota ---
  pi.on("before_agent_start", async (event, ctx) => {
    quota = loadQuota(); // Reload in case another session updated it

    if (quota.totalTokens >= SOFT_LIMIT) {
      const pct = usagePercent(quota);
      const used = formatTokens(quota.totalTokens);
      const limit = formatTokens(DAILY_TOKEN_LIMIT);

      ctx.ui.notify(
        `⚠️ QUOTA EXCEEDED: ${used}/${limit} (${pct.toFixed(1)}%) — Soft limit (${SOFT_THRESHOLD * 100}%) reached. Use /quota-reset to override.`,
        "warning"
      );

      const ok = await ctx.ui.confirm(
        "Quota Limit Reached",
        `Daily usage: ${used}/${limit} (${pct.toFixed(1)}%)\n\nSoft limit of ${SOFT_THRESHOLD * 100}% (${formatTokens(SOFT_LIMIT)}) exceeded.\nContinue anyway?`
      );

      if (!ok) {
        return {
          message: {
            customType: "quota-blocked",
            content: `🚫 Request blocked — daily quota soft limit reached (${used}/${limit}, ${pct.toFixed(1)}%). Use /quota-reset to reset or confirm the prompt to continue.`,
            display: true,
          },
        };
      }
    }

    updateStatus(ctx);
  });

  // --- Message end: track usage ---
  pi.on("message_end", async (event, ctx) => {
    const msg = event.message as any;
    if (msg.role !== "assistant" || !msg.usage) return;

    const { totalTokens = 0, cost } = msg.usage;
    const totalCost = cost?.total ?? 0;
    const model = msg.model || "unknown";

    // Ensure date is current
    if (quota.date !== todayStr()) {
      quota = {
        date: todayStr(),
        totalTokens: 0,
        totalCost: 0,
        requestCount: 0,
        byModel: {},
      };
    }

    quota.totalTokens += totalTokens;
    quota.totalCost += totalCost;
    quota.requestCount += 1;

    if (!quota.byModel[model]) {
      quota.byModel[model] = { tokens: 0, cost: 0, requests: 0 };
    }
    quota.byModel[model].tokens += totalTokens;
    quota.byModel[model].cost += totalCost;
    quota.byModel[model].requests += 1;

    saveQuota(quota);
    updateStatus(ctx);
  });

  // --- /quota command: show usage ---
  pi.registerCommand("quota", {
    description: "Show daily token quota usage",
    handler: async (_args, ctx) => {
      quota = loadQuota();
      const pct = usagePercent(quota);
      const lines = [
        `📊 Daily Quota Usage (${quota.date})`,
        ``,
        `Total: ${formatTokens(quota.totalTokens)} / ${formatTokens(DAILY_TOKEN_LIMIT)} (${pct.toFixed(1)}%)`,
        `Soft limit: ${formatTokens(SOFT_LIMIT)} (${(SOFT_THRESHOLD * 100).toFixed(0)}%)`,
        `Cost: $${quota.totalCost.toFixed(4)}`,
        `Requests: ${quota.requestCount}`,
      ];

      if (Object.keys(quota.byModel).length > 0) {
        lines.push(``, `By Model:`);
        for (const [model, stats] of Object.entries(quota.byModel).sort(
          (a, b) => b[1].tokens - a[1].tokens
        )) {
          lines.push(
            `  ${model}: ${formatTokens(stats.tokens)} tokens, $${stats.cost.toFixed(4)}, ${stats.requests} reqs`
          );
        }
      }

      const status = pct >= SOFT_THRESHOLD * 100 ? "⚠️ OVER SOFT LIMIT" : "✅ OK";
      lines.push(``, `Status: ${status}`);

      ctx.ui.notify(lines.join("\n"), pct >= SOFT_THRESHOLD * 100 ? "warning" : "info");
    },
  });

  // --- /quota-reset command: reset usage ---
  pi.registerCommand("quota-reset", {
    description: "Reset daily token quota",
    handler: async (_args, ctx) => {
      const ok = await ctx.ui.confirm(
        "Reset Quota",
        `Reset daily quota? Current: ${formatTokens(quota.totalTokens)} (${usagePercent(quota).toFixed(1)}%)`
      );
      if (!ok) return;

      quota = {
        date: todayStr(),
        totalTokens: 0,
        totalCost: 0,
        requestCount: 0,
        byModel: {},
      };
      saveQuota(quota);
      updateStatus(ctx);
      ctx.ui.notify("✅ Quota reset!", "success");
    },
  });
}
