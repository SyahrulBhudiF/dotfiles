#!/usr/bin/env bash
set -euo pipefail

test "$(nix eval --raw .#homeConfigurations.ryuko.config.home.username)" = ryuko
test "$(nix eval --raw .#homeConfigurations.ryuko.config.home.homeDirectory)" = /home/ryuko
nix build --no-link .#homeConfigurations.ryuko.activationPackage
