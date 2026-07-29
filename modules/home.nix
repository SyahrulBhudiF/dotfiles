{ lib, pkgs, inputs, flakePkgs, config, ... }:
let
  pi = ".pi/agent";
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

      # Pi coding agent configs
      "${pi}/AGENTS.md" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/AGENTS.md";
        force = true;
      };
      "${pi}/settings.json" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/settings.json";
        force = true;
      };
      "${pi}/mcp.json" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/mcp.json";
        force = true;
      };
      "${pi}/package.json" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/package.json";
        force = true;
      };
      "${pi}/extensions" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/extensions";
        recursive = true;
        force = true;
      };
      "${pi}/themes" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/themes";
        recursive = true;
        force = true;
      };
      "${pi}/skills" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/skills";
        recursive = true;
        force = true;
      };

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

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
      settings = {
        globalOptions.Hotkey.TriggerKeys = "Control+space";
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "mozc";
        };
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
