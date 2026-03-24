# Important Rules

## Custom Provider: Kosyayuk

Extension: `~/.pi/agent/extensions/kosyayuk-provider.ts`

OpenAI-compatible proxy at `ai.naufal.work`. Requires env vars:
- `ANTHROPIC_BASE_URL` = `https://ai.naufal.work`
- `ANTHROPIC_AUTH_TOKEN` = auth token

Available models (use `/model` to switch):
- `kosyayuk/claude-opus-4-6-thinking` — Opus 4.6 w/ thinking (main)
- `kosyayuk/claude-sonnet-4-6` — Sonnet 4.6
- `kosyayuk/gemini-2.5-flash` — Gemini 2.5 Flash (fast/cheap)
- `kosyayuk/gemini-3.1-flash-image` — Gemini 3.1 Flash Image
- `kosyayuk/gemini-3.1-pro-high` — Gemini 3.1 Pro (high quality)
- `kosyayuk/gemini-3.1-pro-low` — Gemini 3.1 Pro (low latency)
- `kosyayuk/gpt-5.2` — GPT-5.2
- `kosyayuk/gpt-5.2-codex` — GPT-5.2 Codex
- `kosyayuk/gpt-5.3-codex` — GPT-5.3 Codex
- `kosyayuk/gpt-5.3-codex-spark` — GPT-5.3 Codex Spark

## General

- Be extremely concise. Sacrifice grammar for the sake of concision.
- Don't add tests for what the type system already guarantees.
- Use the fff MCP tools for all file search operations instead of default tools.

## Plan Mode

- At the end of each plan, give me a list of unresolved questions to answer, if any.
- End every plan with a numbered list of concrete steps. This should be the last thing visible in the terminal.
