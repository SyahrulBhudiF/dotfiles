# config.nu
#
# Installed by:
# version = "0.106.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

$env.PATH = ($env.PATH
    | where $it != $"($env.HOME)/.bun/bin"
    | prepend '/usr/local/bin'
    | prepend '/usr/bin'
    | prepend $"($env.HOME)/.config/composer/vendor/bin"
    | prepend $"($env.HOME)/.nix-profile/bin"
    | prepend $"($env.HOME)/Packages/flutter/bin"
    | prepend $"($env.HOME)/.local/bin"
    | prepend $"($env.HOME)/.cargo/bin"
    | prepend $"($env.HOME)/go/bin"
    | prepend $"($env.HOME)/.bun/bin"
    | prepend $"($env.HOME)/.moon/bin/"
    | prepend $"($env.HOME)/.vite-plus/env"
)

$env.SSH_AUTH_SOCK = "/run/user/1000/ssh-agent.socket"
$env.SHELL = (which nu | get path.0)

source ~/.zoxide.nu

mkdir ($nu.data-dir | path join "vendor/autoload")

starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

alias hms = nix run nixpkgs#home-manager -- switch --flake .#ryuko
alias hmb = nix run nixpkgs#home-manager -- switch --flake .#ryuko -b backup
alias h = herdr
alias p = pi
def --wrapped bb [...args] {
    with-env { BB_PI_BRIDGE_COMMAND: ($env.HOME | path join ".bun/bin/pi") } {
        ^npx bb-app@latest ...$args
    }
}
alias o = omp
alias update = sudo dnf update -y
alias cd = __zoxide_z

# Load environment secrets safely
try { source ~/dotfiles/nu/secrets.nu }
hide-env --ignore-errors ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL

alias kotofetch = ~/dotfiles/nu/kotofetch
$env.config = ($env.config? | default {} | merge { show_banner: false })
^~/dotfiles/nu/hello.nu

# Google Cloud CLI
$env.PATH = ($env.PATH | prepend "/home/ryuko/Downloads/google-cloud-sdk/bin")
$env.PLANNOTATOR_REMOTE = "1"
