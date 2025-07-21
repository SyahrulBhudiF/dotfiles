{ lib, pkgs, inputs, flakePkgs, config, ... }:

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
      COMPOSER_HOME = "/home/ryuko/.config/composer";
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
      enable = false;
    };

    # direnv = {
    #   enable = true;
    #   nix-direnv.enable = true;
    # };

    starship.enable = false;

    zoxide.enable = false;

    bat = {
      enable = true;
      config = {
        theme = "base16";
        "italic-text" = "always";
        style = "numbers,changes,header";
        pager = "less -RF";
      };
    };

    btop = {
      enable = true;
      settings = {
        color_theme = "tty";
        vim_keys = true;
      };
    };
  };

  home.file = {
  };

  home.activation = {
    setEnvironment = ''
      export HOME="${config.home.homeDirectory}"
    '';
  };
}
