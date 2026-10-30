#!/usr/bin/env nu

# Fetches kosyayuk models and regenerates the Pi, OMP, OpenCode and Amp catalogs.
# Usage: nu agents/pi/extensions/gen-kosyayuk.nu
#
# Amp is account state, not a file: the generator writes the model mapping to
# agents/amp/kosyayuk-model-mapping.txt and prints the `amp config
# model-providers edit-key` command that applies it. Set AMP_APPLY=1 to run
# that command instead of just printing it.
#
# It also writes an agent-mode plugin to the personal plugins repository, which
# is what makes the provider models selectable in the Amp mode picker. Commit
# and push that repository for the modes to take effect everywhere.
#
# Keep the `kosyayuk/` namespace: mapping the canonical IDs instead makes this
# connection steal models such as openai/gpt-5.6-luna from the ChatGPT
# subscription, and the user wants both connections usable side by side.

let api_url = ($env.BASE_URL? | default "https://ai.naufal.work")
let token = ($env.AUTH_TOKEN? | default "")
let amp_namespace = ($env.AMP_NAMESPACE? | default "kosyayuk")
let pi_out_file = ($env.PI_OUT_FILE? | default ([$env.HOME "dotfiles/agents/pi/extensions/kosyayuk-provider.ts"] | path join))
let omp_out_file = ($env.OMP_OUT_FILE? | default ([$env.HOME "dotfiles/agents/omp/models.yml"] | path join))
let opencode_file = ($env.OPENCODE_FILE? | default ([$env.HOME "dotfiles/agents/opencode/opencode.json"] | path join))
let amp_out_file = ($env.AMP_OUT_FILE? | default ([$env.HOME "dotfiles/agents/amp/kosyayuk-model-mapping.txt"] | path join))
let amp_connection = ($env.AMP_CONNECTION_ID? | default "1ea9a9da-915d-4333-9a14-abc51e64d91f")
let amp_plugin_file = ($env.AMP_PLUGIN_FILE? | default ([$env.HOME ".cache/amp/repositories/ampcode.com-user-plugins/kosyayuk-modes.ts"] | path join))

if $token == "" {
  print "Error: AUTH_TOKEN not set"
  exit 1
}

print $"Fetching models from ($api_url)/v1/models ..."

let raw = (curl -s -H $"Authorization: Bearer ($token)" $"($api_url)/v1/models" | from json)

# An empty catalog means the upstream is broken, not that every model was
# removed. Abort before overwriting good catalogs with empty ones.
if ($raw.data | is-empty) {
  print $"Error: ($api_url)/v1/models returned no models; nothing written."
  exit 1
}

let models = ($raw.data | sort-by id | each {|m|
  let id = $m.id

  # Determine compat type: claude models use anthropic compat, everything else uses openai compat
  let compat = if ($id =~ "claude|haiku|sonnet|opus") {
    "compatClaude"
  } else {
    "compatGpt"
  }

  # Determine reasoning
  let reasoning = if ($id | str contains "opus") {
    true
  } else if ($id =~ "sonnet-4-[56]") {
    true
  } else {
    false
  }

  # Determine input modalities
  let input = if ($id | str contains "gpt-3") {
    '["text"]'
  } else if ($id =~ "deepseek|minimax|qwen") {
    '["text"]'
  } else {
    '["text", "image"]'
  }

  # Determine context window
  let ctx = if ($id =~ "gpt|claude") {
    272000
  } else {
    1000000
  }

  # Determine max tokens
  let max_tok = if ($id | str contains "haiku") {
    8192
  } else if ($id | str contains "gpt-3") {
    4096
  } else if ($id =~ "gpt-4|deepseek|qwen") {
    16384
  } else if ($id =~ "minimax") {
    64000
  } else {
    64000
  }

  # Determine cost ($/M tokens)
  let cost = if ($id | str contains "opus") {
    { input: 5, output: 25, cache_read: 0.5, cache_write: 6.25 }
  } else if ($id | str contains "sonnet") {
    { input: 3, output: 15, cache_read: 0.3, cache_write: 3.75 }
  } else if ($id | str contains "haiku") {
    { input: 0.8, output: 4, cache_read: 0.08, cache_write: 1 }
  } else {
    { input: 0, output: 0, cache_read: 0, cache_write: 0 }
  }

  # Build display name from id: "claude-opus-4-6" → "Claude Opus 4 6"
  let name = ($id | str replace --all "-" " " | split words | each {|w|
    let chars = ($w | split chars)
    let first = ($chars | first | str upcase)
    let rest = ($chars | skip 1 | str join "")
    $"($first)($rest)"
  } | str join " ")

  {
    id: $id
    name: $name
    reasoning: $reasoning
    input: $input
    cost: $cost
    contextWindow: $ctx
    maxTokens: $max_tok
    compat: $compat
  }
})

print $"Found ($models | length) models:"

$models
| select id name compat reasoning input contextWindow maxTokens cost
| update input {|row| $row.input | from json | str join ", " }
| update cost {|row| $"in:($row.cost.input) out:($row.cost.output) cr:($row.cost.cache_read) cw:($row.cost.cache_write)" }
| table -e
| print

print $"Generating ($pi_out_file), ($omp_out_file), ($opencode_file) and ($amp_out_file) ..."

# Build the models array entries
let model_entries = ($models | each {|m|
  let reasoning_str = if $m.reasoning { "true" } else { "false" }
  $"      {
        id: \"($m.id)\",
        name: \"($m.name)\",
        reasoning: ($reasoning_str),
        input: ($m.input),
        cost: { input: ($m.cost.input), output: ($m.cost.output), cacheRead: ($m.cost.cache_read), cacheWrite: ($m.cost.cache_write) },
        contextWindow: ($m.contextWindow),
        maxTokens: ($m.maxTokens),
        compat: ($m.compat),
      }"
} | str join ",\n")

# Generate the full file
let header = '/**
 * Custom provider for ai.naufal.work OpenAI-compatible proxy.
 * Auto-generated by gen-kosyayuk.nu — do not edit manually.
 *
 * Env vars:
 *   BASE_URL  = https://ai.naufal.work
 *   AUTH_TOKEN = <your token>
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const baseUrl =
    (process.env.BASE_URL || "https://ai.naufal.work") + "/v1";

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

  pi.registerProvider("kosyayuk", {
    baseUrl,
    apiKey: "$AUTH_TOKEN",
    authHeader: true,
    api: "openai-completions",
    models: ['

let footer = '    ],
  });
}
'

let ts = [$header $model_entries $footer] | str join "\n"

$ts | save -f $pi_out_file

{
  providers: {
    kosyayuk: {
      baseUrl: $"($api_url)/v1"
      apiKey: "AUTH_TOKEN"
      api: "openai-completions"
      auth: "apiKey"
      models: ($models | each {|m|
        {
          id: $m.id
          name: $m.name
          reasoning: $m.reasoning
          input: ($m.input | from json)
          cost: {
            input: $m.cost.input
            output: $m.cost.output
            cacheRead: $m.cost.cache_read
            cacheWrite: $m.cost.cache_write
          }
          contextWindow: $m.contextWindow
          maxTokens: $m.maxTokens
        }
      })
    }
  }
} | to yaml | save -f $omp_out_file

# OpenCode: upsert provider.kosyayuk in place, leaving every other key untouched.
mut opencode_cfg = (open --raw $opencode_file | from json)
$opencode_cfg.provider.kosyayuk = {
  npm: "@ai-sdk/openai-compatible"
  name: "Kosyayuk"
  options: { baseURL: $"($api_url)/v1", apiKey: "{env:AUTH_TOKEN}" }
  models: ($models | reduce -f {} {|m, acc|
    $acc | upsert $m.id {
      name: $m.name
      limit: { context: $m.contextWindow, output: $m.maxTokens }
      modalities: { input: ($m.input | from json), output: ["text"] }
    }
  })
}
$opencode_cfg | to json --indent 2 | save -f $opencode_file

# Amp: resolve every provider model that exists in Amp's current catalog.
# The catalog is authoritative for which models Amp can drive as an agent, so a
# provider can add or remove supported models without duplicating a
# hand-maintained list here. The mapping exposes each model under the
# `kosyayuk/` namespace instead of Amp's canonical ID: one canonical ID is only
# ever served by one connection, so mapping `openai/gpt-5.6-luna` here would
# take that model away from the ChatGPT subscription. Namespaced IDs keep both
# connections usable side by side, and the modes below pin them.
let amp_catalog = (^amp plugins show-agent-options --json
  | from json
  | get models
  | reduce -f {} {|model, catalog| $catalog | upsert $model.name $model })

let amp_matched = ($models | where {|m| ($amp_catalog | get -o $m.id) != null })

let amp_lines = ($amp_matched
  | each {|m| $"($amp_namespace)/($m.id) -> ($m.id)" }
  | str join "\n")

$"# Generated by gen-kosyayuk.nu — do not edit.
# Amp connection: ($amp_connection)

($amp_lines)\n" | save -f $amp_out_file

# Amp agent modes: one mode per matched model, pinned to the namespaced model
# ID so the mode routes through this connection without stealing the canonical
# model from another connection such as the ChatGPT subscription.
# Amp caps mode keys and labels at 24 characters, so anything longer is
# skipped with a warning instead of failing registration at plugin load.
let mode_color = "#f59e0b"
let amp_modes = ($amp_matched | each {|m|
  let canonical = ($amp_catalog | get $m.id)
  let key = if $m.id == "gemini-3.5-flash-lite" {
    "kosyayuk-g35-flash-lite"
  } else if $m.id == "gemini-3.8-flash" {
    "kosyayuk-g38-flash"
  } else {
    $"($amp_namespace)-($canonical.name)"
  }
  let label = if $m.id == "gemini-3.5-flash-lite" {
    "Kosyayuk G35 Flash Lite"
  } else if $m.id == "gemini-3.8-flash" {
    "Kosyayuk G38 Flash"
  } else {
    $"Kosyayuk ($canonical.displayName)"
  }
  if (($key | str length) > 24) or (($label | str length) > 24) {
    print $"Skipping agent mode for ($m.id): key or label is longer than 24 characters"
    null
  } else {
    { key: $key, label: $label, model: $"($amp_namespace)/($m.id)" }
  }
} | where {|mode| $mode != null })

let mode_directives = ($amp_modes | each {|mode|
  $'// @amp-agent-mode {"key":"($mode.key)","label":"($mode.label)","color":"($mode_color)"}'
} | str join "\n")

let mode_entries = ($amp_modes | each {|mode|
  $'  { key: "($mode.key)", label: "($mode.label)", model: "($mode.model)" },'
} | str join "\n")

mkdir ($amp_plugin_file | path dirname)

let amp_plugin = ([
  $mode_directives
  ''
  '/**'
  ' * Kosyayuk agent modes — auto-generated by gen-kosyayuk.nu — do not edit.'
  ' *'
  ' * One mode per Kosyayuk model that Amp can serve, pinned to the kosyayuk/'
  ' * model namespace so the mode routes through the Kosyayuk connection without'
  ' * taking the canonical model ID from another connection. Regenerate with:'
  ' *   nu agents/pi/extensions/gen-kosyayuk.nu'
  ' */'
  'import type { PluginAPI } from "@ampcode/plugin"'
  ''
  'export const description = "Kosyayuk provider models as agent modes"'
  ''
  'const MODES = ['
  $mode_entries
  '] as const'
  ''
  'export default function (amp: PluginAPI) {'
  '  for (const mode of MODES) {'
  '    const agent = amp.createAgent({'
  '      extends: "medium",'
  '      model: mode.model,'
  $'      display: { label: mode.label, color: "($mode_color)" },'
  '    })'
  ''
  '    amp.registerAgentMode({'
  '      key: mode.key,'
  '      label: mode.label,'
  '      description: "Kosyayuk-served " + mode.model + ". Use for work that should run on the Kosyayuk provider.",'
  $'      color: "($mode_color)",'
  '      agent: agent.definition,'
  '    })'
  '  }'
  '}'
  ''
] | str join "\n")

$amp_plugin | save -f $amp_plugin_file

let amp_apply = ($env.AMP_APPLY? | default "0") == "1"
# The CLI takes the mapping comma-separated; the file keeps it one per line.
let amp_mapping = ($amp_lines | str replace --all (char newline) ",")

if $amp_apply {
  ^amp config model-providers edit-key $amp_connection --model-mapping $amp_mapping
} else {
  print $"amp config model-providers edit-key ($amp_connection) --model-mapping '($amp_mapping)'"
}

print $"Done! ($models | length) models written to Pi, OMP and OpenCode; ($amp_lines | lines | length) Amp model mappings and ($amp_modes | length) Amp agent modes written to ($amp_plugin_file)."
