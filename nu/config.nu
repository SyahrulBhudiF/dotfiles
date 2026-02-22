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
    | prepend $"($env.HOME)/.bun/bin"
    | prepend $"($env.HOME)/.moon/bin/"
)

$env.SSH_AUTH_SOCK = "/run/user/1000/ssh-agent.socket"

source ~/.zoxide.nu

mkdir ($nu.data-dir | path join "vendor/autoload")

alias hms = nix run nixpkgs#home-manager -- switch --flake .#ryuko
alias hmb = nix run nixpkgs#home-manager -- switch --flake .#ryuko -b backup

use ~/.config/nu/starship.nu
