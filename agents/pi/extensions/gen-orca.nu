#!/usr/bin/env nu

# Fetches OrcaRouter chat models and regenerates the Pi provider catalog.
# Usage: nu agents/pi/extensions/gen-orca.nu

let api_url = ($env.ORCA_BASE_URL? | default "https://api.orcarouter.ai")
let token = ($env.ORCA_API_KEY? | default "")
let pi_out_file = ($env.PI_OUT_FILE? | default ([$env.HOME "dotfiles/agents/pi/extensions/orca-provider.ts"] | path join))

if $token == "" {
  print "Error: ORCA_API_KEY not set"
  exit 1
}

print $"Fetching models from ($api_url)/v1/models ..."

let raw = (curl -s -H $"Authorization: Bearer ($token)" $"($api_url)/v1/models" | from json)

# Chat-capable only: must expose an openai endpoint and not be a tts model
let models = ($raw.data
| where {|m|
    let types = ($m.supported_endpoint_types? | default [])
    ($types | any {|t| $t == "openai" }) and not ($m.id | str contains "tts")
  }
| sort-by id
| each {|m|
  let id = $m.id
  let short = ($id | split row "/" | last)

  # Name: prefer the API's own display name, fall back to formatted id
  let name = if (($m.name? | default "") != "") {
    $m.name
  } else {
    ($short | str replace --all "-" " " | split words | each {|w|
      let chars = ($w | split chars)
      let first = ($chars | first | str upcase)
      let rest = ($chars | skip 1 | str join "")
      $"($first)($rest)"
    } | str join " ")
  }

  # Compat: claude models use anthropic max_tokens field, everything else openai
  let compat = if ($id | str contains "claude") { "compatClaude" } else { "compatGpt" }

  let reasoning = ($id =~ "opus|fable|sonnet|reasoner|thinking")

  # Input modalities from the architecture field
  let mods = ($m.architecture?.input_modalities? | default [])
  let input = if ($mods | any {|x| $x == "image" or $x == "file" }) {
    '["text", "image"]'
  } else {
    '["text"]'
  }

  # Context window, falling back to the top provider's
  let ctx = ($m.context_length? | default 0)
  let top_ctx = ($m.top_provider?.context_length? | default 0)
  let context = if $ctx > 0 { $ctx } else if $top_ctx > 0 { $top_ctx } else { 200000 }

  # Max output tokens, falling back to the top provider's
  let mt = ($m.max_completion_tokens? | default 0)
  let top_mt = ($m.top_provider?.max_completion_tokens? | default 0)
  let max_tok = if $mt > 0 { $mt } else if $top_mt > 0 { $top_mt } else if ($id | str contains "haiku") { 8192 } else { 64000 }

  # Pricing ($/M tokens) from the API
  let pin = (($m.pricing?.prompt_per_million? | default "0") | into float)
  let pout = (($m.pricing?.completion_per_million? | default "0") | into float)

  {
    id: $id
    name: $name
    compat: $compat
    reasoning: $reasoning
    input: $input
    contextWindow: $context
    maxTokens: $max_tok
    input_price: $pin
    output_price: $pout
  }
})

print $"Found ($models | length) chat models:"

$models
| select id name compat reasoning contextWindow maxTokens
| table -e
| print

print $"Generating ($pi_out_file) ..."

let model_entries = ($models | each {|m|
  let reasoning_str = if $m.reasoning { "true" } else { "false" }
  $"      {
        id: \"($m.id)\",
        name: \"($m.name)\",
        reasoning: ($reasoning_str),
        input: ($m.input),
        cost: { input: ($m.input_price), output: ($m.output_price), cacheRead: 0, cacheWrite: 0 },
        contextWindow: ($m.contextWindow),
        maxTokens: ($m.maxTokens),
        compat: ($m.compat),
      }"
} | str join ",\n")

let header = '/**
 * Custom provider for OrcaRouter OpenAI-compatible proxy (https://docs.orcarouter.ai).
 * Generated from /v1/models — regenerate with gen-orca.nu.
 *
 * Env vars:
 *   ORCA_BASE_URL  = https://api.orcarouter.ai
 *   ORCA_API_KEY   = sk-orca-...
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const baseUrl = (process.env.ORCA_BASE_URL || "https://api.orcarouter.ai") + "/v1";

  const compatClaude = {
    supportsDeveloperRole: false,
    supportsReasoningEffort: false,
    maxTokensField: "max_tokens" as const,
  };

  const compatGpt = {
    supportsDeveloperRole: true,
    supportsReasoningEffort: false,
    maxTokensField: "max_completion_tokens" as const,
  };

  pi.registerProvider("orca", {
    baseUrl,
    apiKey: "$ORCA_API_KEY",
    authHeader: true,
    api: "openai-completions",
    models: ['

let footer = '    ],
  });
}
'

let ts = [$header $model_entries $footer] | str join "\n"

$ts | save -f $pi_out_file

print $"Done! ($models | length) models written to Pi provider."
