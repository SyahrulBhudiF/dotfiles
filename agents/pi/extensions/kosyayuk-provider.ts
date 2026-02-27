/**
 * Custom provider for ai.naufal.work OpenAI-compatible proxy.
 *
 * Env vars:
 *   ANTHROPIC_BASE_URL  = https://ai.naufal.work
 *   ANTHROPIC_AUTH_TOKEN = <your token>
 *
 * Models:
 *   kosyayuk/claude-opus-4-6-thinking
 *   kosyayuk/claude-sonnet-4-6
 *   kosyayuk/gemini-2.5-flash
 *   kosyayuk/gemini-3.1-flash-image
 *   kosyayuk/gemini-3.1-pro-high
 *   kosyayuk/gemini-3.1-pro-low
 *   kosyayuk/gpt-5.2
 *   kosyayuk/gpt-5.2-codex
 *   kosyayuk/gpt-5.3-codex
 *   kosyayuk/gpt-5.3-codex-spark
 *
 * Usage:
 *   /model kosyayuk/claude-opus-4-6-thinking
 *   /model kosyayuk/gemini-3.1-pro-high
 *   /model kosyayuk/gpt-5.3-codex
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const baseUrl =
    (process.env.ANTHROPIC_BASE_URL || "https://ai.naufal.work") + "/v1";

  const compatClaude = {
    supportsDeveloperRole: false,
    supportsReasoningEffort: false,
    maxTokensField: "max_tokens" as const,
  };

  const compatGemini = {
    supportsDeveloperRole: false,
    supportsReasoningEffort: false,
    maxTokensField: "max_tokens" as const,
  };

  const compatGpt = {
    supportsDeveloperRole: true,
    supportsReasoningEffort: false,
    maxTokensField: "max_completion_tokens" as const,
  };

  pi.registerProvider("kosyayuk", {
    baseUrl,
    apiKey: "ANTHROPIC_AUTH_TOKEN",
    authHeader: true,
    api: "openai-completions",
    models: [
      // --- Claude ---
      {
        id: "claude-opus-4-6-thinking",
        name: "Claude Opus 4.6 Thinking (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 5, output: 25, cacheRead: 0.5, cacheWrite: 6.25 },
        contextWindow: 200000,
        maxTokens: 64000,
        compat: compatClaude,
      },
      {
        id: "claude-sonnet-4-6",
        name: "Claude Sonnet 4.6 (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 3, output: 15, cacheRead: 0.3, cacheWrite: 3.75 },
        contextWindow: 200000,
        maxTokens: 64000,
        compat: compatClaude,
      },
      // --- Gemini ---
      {
        id: "gemini-2.5-flash",
        name: "Gemini 2.5 Flash (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 1048576,
        maxTokens: 65536,
        compat: compatGemini,
      },
      {
        id: "gemini-3.1-flash-image",
        name: "Gemini 3.1 Flash Image (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 1048576,
        maxTokens: 65536,
        compat: compatGemini,
      },
      {
        id: "gemini-3.1-pro-high",
        name: "Gemini 3.1 Pro High (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 1048576,
        maxTokens: 65536,
        compat: compatGemini,
      },
      {
        id: "gemini-3.1-pro-low",
        name: "Gemini 3.1 Pro Low (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 1048576,
        maxTokens: 65536,
        compat: compatGemini,
      },
      // --- GPT ---
      {
        id: "gpt-5.2",
        name: "GPT-5.2 (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 65536,
        compat: compatGpt,
      },
      {
        id: "gpt-5.2-codex",
        name: "GPT-5.2 Codex (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 65536,
        compat: compatGpt,
      },
      {
        id: "gpt-5.3-codex",
        name: "GPT-5.3 Codex (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 65536,
        compat: compatGpt,
      },
      {
        id: "gpt-5.3-codex-spark",
        name: "GPT-5.3 Codex Spark (Kosyayuk)",
        reasoning: false,
        input: ["text", "image"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 65536,
        compat: compatGpt,
      },
    ],
  });
}
