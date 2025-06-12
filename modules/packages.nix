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
  qpdf          # PDF manipulation tool

  # --- Document Processing ---
  typst         # Markup-based typesetting system

  # --- Data Tools ---
  csvlens       # CSV viewer

  # --- Web Development ---
  (php84.buildEnv {
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
      xdebug

      # Image Processing
      gd
      imagick

      # Data & Math
      bcmath
      gmp

      # XML & Internasionalisasi
      intl

      # Security
      openssl
    ]));

    extraConfig = ''
      [PHP]
      memory_limit = 512M
      upload_max_filesize = 100M
      post_max_size = 100M
      max_execution_time = 300

      [opcache]
      opcache.enable=1
      opcache.enable_cli=1
      opcache.memory_consumption=128
      opcache.interned_strings_buffer=8
      opcache.max_accelerated_files=4000

      [redis]
      redis.session.locking_enabled=1
    '';
  })
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
