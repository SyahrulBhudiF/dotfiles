{ pkgs, flakePkgs, ... }:

with pkgs; [
   # --- CLI Tools ---
  dust          # Disk usage tool (like du)
  ripgrep       # Fast grep alternative
  fd            # Fast find alternative
  rclone        # Cloud storage sync
  yt-dlp        # YouTube downloader
  yazi          # TUI file manager
  pass          # Password manager (password-store)
  yq            # YAML/JSON/XML processor (like jq)
  eza           # Modern 'ls' replacement
  grpcurl       # gRPC client (like curl)

  # --- Document Processing ---
  typst         # Markup-based typesetting system

  # --- Data Tools ---
  csvlens       # CSV viewer

  # --- Web Development ---
  # PHP (diperlukan untuk intelephense LSP)
  (php.buildEnv {
    extensions = ({enabled, all}: enabled ++ (with all; [
      # Database
      pdo
      pdo_mysql
      pdo_pgsql
      mysqli

      # Cache & Performance
      redis
      opcache
      apcu

      # Essentials
      mbstring
      curl
      dom
      zip

      # Image Processing
      gd
      imagick

      # Data & Math
      bcmath
      gmp

      # XML & Internasionalisasi
      intl
      xml

      # Security
      openssl
    ])))
  php84Packages.composer # PHP dependency manager
  bun           # JavaScript runtime/bundler/package manager

  # --- Git Tools ---
  git-filter-repo # Rewrite Git history (remove secrets, etc.)
  delta         # Advanced git diff viewer
  difftastic    # Structural diff tool

  # --- Rust Development ---
  rustc         # Rust compiler
  cargo         # Rust package manager/build tool

  # --- Font ---
  monaspace     # Monospace font family from GitHub
  inter         # Sans-serif font (sudah ada sebelumnya)
  lora          # Serif font
] ++ [
  flakePkgs.bash-env-json
]
