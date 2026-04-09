{ lib, pkgs, inputs, flakePkgs, config, ... }:
let
  pi = ".pi/agent";
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
      ".zshrc".source = link "${config.home.homeDirectory}/dotfiles/zsh/.zshrc";
      ".zshenv".source = link "${config.home.homeDirectory}/dotfiles/zsh/.zshenv";
      ".profile".source = link "${config.home.homeDirectory}/dotfiles/.profile";

      # pi coding agent configs
      "${pi}/AGENTS.md".source = link "${config.home.homeDirectory}/dotfiles/agents/AGENTS.md";
      "${pi}/settings.json".source = link "${config.home.homeDirectory}/dotfiles/agents/pi/settings.json";
      "${pi}/mcp.json".source = link "${config.home.homeDirectory}/dotfiles/agents/pi/mcp.json";
      "${pi}/package.json".source = link "${config.home.homeDirectory}/dotfiles/agents/pi/package.json";
      "${pi}/extensions" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/extensions";
        recursive = true;
      };
      "${pi}/themes" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/pi/themes";
        recursive = true;
      };
      "${pi}/skills" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/skills";
        recursive = true;
      };

      # antigravity (gemini cli) global skills
      ".gemini/antigravity/skills" = {
        source = link "${config.home.homeDirectory}/dotfiles/agents/skills";
        recursive = true;
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
