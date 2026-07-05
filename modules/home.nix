{ lib, pkgs, inputs, flakePkgs, config, ... }:
let
  omp = ".omp/agent";
  link = config.lib.file.mkOutOfStoreSymlink;
  starshipConfigPath = ../starship/config.toml;
  starshipSettings =
    if builtins.pathExists starshipConfigPath
    then builtins.fromTOML (builtins.readFile starshipConfigPath)
    else { };
in
{
  targets.genericLinux.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.nixGL.overlays.default ];

  home = {
    username = "ryuko";
    homeDirectory = "/home/ryuko";
    stateVersion = "25.11";

    packages =
      (import ./packages.nix {
        inherit pkgs flakePkgs;
      });

    sessionVariables = {
      COMPOSER_HOME = "${config.home.homeDirectory}/.config/composer";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
    };

    file = {
      ".zshrc".source = ../zsh/.zshrc;
      ".zshenv".source = ../zsh/.zshenv;
      ".profile".source = ../.profile;

      # OMP coding agent configs
      "${omp}/AGENTS.md".source = link "${config.home.homeDirectory}/dotfiles/agents/AGENTS.md";
      "${omp}/config.yml".source = link "${config.home.homeDirectory}/dotfiles/agents/omp/config.yml";
      "${omp}/models.yml".source = link "${config.home.homeDirectory}/dotfiles/agents/omp/models.yml";
      "${omp}/mcp.json".source = link "${config.home.homeDirectory}/dotfiles/agents/omp/mcp.json";
      "${omp}/themes" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/omp/themes";
        recursive = true;
      };
      "${omp}/skills" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/skills";
        recursive = true;
      };

      # Herdr Plus configs
      ".config/herdr/plugins/config/cloudmanic.herdr-plus/projects/dotfiles-omp.toml".source = link "${config.home.homeDirectory}/dotfiles/herdr-plus/projects/dotfiles-omp.toml";

      # antigravity (gemini cli) global skills
      ".gemini/antigravity/skills" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/skills";
        recursive = true;
      };

      # Claude Code global skills
      ".claude/skills" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/skills";
        recursive = true;
        force = true;
      };
    };
  };

  fonts.fontconfig = {
    enable = true;

    defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Inter" ];
      serif = [ "Lora" ];
    };
  };

  programs = {
    home-manager.enable = true;
    zsh = {
      enable = true;
    };

    starship = {
      enable = true;
      settings = starshipSettings;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "${config.home.homeDirectory}/dotfiles/";
    };

    zoxide.enable = true;

    bat = {
      enable = true;
      config = {
        theme = "base16";
        "italic-text" = "always";
        style = "numbers,changes,header";
        pager = "less -RF";
      };
    };
  };

  home.activation = {
    setEnvironment = ''
      export HOME="${config.home.homeDirectory}"
    '';
  };
}
