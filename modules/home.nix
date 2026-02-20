{ lib, pkgs, inputs, flakePkgs, config, ... }:
let
  pi = ".pi/agent";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  targets.genericLinux.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.nixGL.overlays.default ];

  home = {
    username = "ryuko";
    homeDirectory = "/home/ryuko";
    stateVersion = "24.11";

    packages = import ./packages.nix {
      inherit pkgs flakePkgs;
    };

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

    starship.enable = true;

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

  xdg.configFile = {
    "jjui" = {
      source = link "${config.home.homeDirectory}/dotfiles/jjui";
      recursive = true;
    };
    "fastfetch/config.jsonc".source = link "${config.home.homeDirectory}/dotfiles/fastfetch/config.jsonc";
    "nvim" = {
      source = link "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
    "nushell/config.nu".source = link "${config.home.homeDirectory}/dotfiles/nu/config.nu";
  };

  home.activation = {
    setEnvironment = ''
      export HOME="${config.home.homeDirectory}"
    '';
  };
}
