{ lib, pkgs, inputs, flakePkgs, config, ... }:
let
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  targets.genericLinux.enable = true;
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "ryuko";
    homeDirectory = "/home/ryuko";
    stateVersion = "24.11";

    packages = import ./packages.nix {
      inherit pkgs flakePkgs;
    };

    sessionVariables = {
      COMPOSER_HOME = "${config.home.homeDirectory}/.config/composer";
    };

    file = {
      ".zshrc".source = link "${config.home.homeDirectory}/dotfiles/zsh/.zshrc";
      ".zshenv".source = link "${config.home.homeDirectory}/dotfiles/zsh/.zshenv";
      ".profile".source = link "${config.home.homeDirectory}/dotfiles/.profile";
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
    "ghostty/config".source = link "${config.home.homeDirectory}/dotfiles/ghostty/config";
    "fastfetch/config.jsonc".source = link "${config.home.homeDirectory}/dotfiles/fastfetch/config.jsonc";
    "nvim" = {
      source = link "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
    "nu/config.nu".source = link "${config.home.homeDirectory}/dotfiles/nu/config.nu";
  };

  home.activation = {
    setEnvironment = ''
      export HOME="${config.home.homeDirectory}"
    '';
  };
}
