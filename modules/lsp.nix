{ pkgs, ... }:

with pkgs;
[
  # JS / web
  nodePackages.typescript-language-server
  nodePackages.bash-language-server
  vscode-langservers-extracted
  yaml-language-server
  svelte-language-server
  vue-language-server
  astro-language-server
  nodePackages.prisma
  intelephense
  oxlint

  # systems / langs
  rust-analyzer
  gopls
  basedpyright
  lua-language-server
  zls
  clang-tools
  csharp-ls
  sourcekit-lsp
  elixir-ls
  kotlin-language-server
  dart
  ocamlPackages.ocaml-lsp
  nixd
  tinymist
  terraform-ls
  gleam
  clojure-lsp
  haskell-language-server
  julia
  deno
]
