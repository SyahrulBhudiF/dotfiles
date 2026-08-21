/** Exa web search via the canonical remote MCP server. */
import type { SearchResult } from "./storage";

const EXA_MCP_URL = "https://mcp.exa.ai/mcp";
const TIMEOUT_MS = 60_000;

interface ExaMcpItem {
  title: string;
  url: string;
  content: string;
}

export interface SearchOptions {
  numResults?: number;
  recencyFilter?: "day" | "week" | "month" | "year";
  domainFilter?: string[];
  signal?: AbortSignal;
}

export interface SearchOutput {
  answer: string;
  results: SearchResult[];
  provider: string;
}

export async function searchWeb(
  query: string,
  options: SearchOptions = {},
): Promise<SearchOutput> {
  const advanced = Boolean(options.recencyFilter || options.domainFilter?.length);
  const text = await callMcp(query, options, advanced);
  const items = parseMcpResults(text);

  if (items.length === 0) {
    return { answer: text, results: [], provider: "exa-mcp" };
  }

  return {
    answer: items
      .map((item) => `${item.content}\nSource: ${item.title} (${item.url})`)
      .join("\n\n"),
    results: items.map((item, index) => ({
      title: item.title || `Source ${index + 1}`,
      url: item.url,
      snippet: item.content.replace(/\s+/g, " ").trim().slice(0, 300),
    })),
    provider: "exa-mcp",
  };
}

function signalWithTimeout(signal?: AbortSignal): AbortSignal {
  const timeout = AbortSignal.timeout(TIMEOUT_MS);
  return signal ? AbortSignal.any([signal, timeout]) : timeout;
}

async function callMcp(
  query: string,
  options: SearchOptions,
  advanced: boolean,
): Promise<string> {
  const apiKey = process.env.EXA_API_KEY?.trim();
  const tools = advanced
    ? "web_search_exa,web_fetch_exa,web_search_advanced_exa"
    : "web_search_exa,web_fetch_exa";
  const url = new URL(EXA_MCP_URL);
  url.searchParams.set("tools", tools);

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    Accept: "application/json, text/event-stream",
  };
  if (apiKey) headers["Authorization"] = `Bearer ${apiKey}`;

  const numResults = clamp(options.numResults ?? 5);
  const args: Record<string, unknown> = { query, numResults };
  if (advanced) {
    args.type = "auto";
    if (options.recencyFilter) args.startPublishedDate = recencyToDate(options.recencyFilter);
    applyDomainFilter(args, options.domainFilter ?? []);
  }

  const res = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: advanced ? "web_search_advanced_exa" : "web_search_exa",
        arguments: args,
      },
    }),
    signal: signalWithTimeout(options.signal),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Exa MCP ${res.status}: ${text.slice(0, 300)}`);
  }

  return parseMcpResponse(await res.text());
}

function parseMcpResponse(raw: string): string {
  const payloads = raw.includes("data:")
    ? raw.split("\n").filter((line) => line.startsWith("data:")).map((line) => line.slice(5).trim())
    : [raw];

  for (const payload of payloads) {
    if (!payload) continue;
    let parsed: {
      result?: { content?: Array<{ type?: string; text?: string }>; isError?: boolean };
      error?: { message?: string };
    };
    try {
      parsed = JSON.parse(payload);
    } catch {
      continue;
    }
    if (parsed.error) throw new Error(parsed.error.message ?? "Exa MCP error");
    const text = parsed.result?.content?.find((content) => content.type === "text")?.text;
    if (parsed.result?.isError) throw new Error(text ?? "Exa MCP error");
    if (text) return text;
  }

  throw new Error("Exa MCP returned empty response");
}

function parseMcpResults(text: string): ExaMcpItem[] {
  return text
    .split(/(?=^Title: )/m)
    .map((block) => {
      const title = block.match(/^Title: (.+)/m)?.[1]?.trim() ?? "";
      const url = block.match(/^URL: (.+)/m)?.[1]?.trim() ?? "";
      const textStart = block.indexOf("\nText: ");
      const content = textStart < 0
        ? ""
        : block.slice(textStart + 7).replace(/\n---\s*$/, "").trim();
      return { title, url, content };
    })
    .filter((item) => item.url.length > 0);
}

function clamp(n: number): number {
  return Math.max(1, Math.min(Math.floor(n), 20));
}

function recencyToDate(filter: SearchOptions["recencyFilter"]): string {
  const days = { day: 1, week: 7, month: 30, year: 365 };
  return new Date(Date.now() - days[filter!] * 86_400_000).toISOString();
}

function applyDomainFilter(body: Record<string, unknown>, filters: string[]): void {
  const includeDomains = filters.filter((d) => !d.startsWith("-")).map((d) => d.trim()).filter(Boolean);
  const excludeDomains = filters.filter((d) => d.startsWith("-")).map((d) => d.slice(1).trim()).filter(Boolean);
  if (includeDomains.length) body.includeDomains = includeDomains;
  if (excludeDomains.length) body.excludeDomains = excludeDomains;
}
