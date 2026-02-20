{ config, ... }:
let
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.configFile = {
    "jjui" = {
      source = link "${config.home.homeDirectory}/dotfiles/jjui";
      recursive = true;
    };
    "ghostty/config".source =
      link "${config.home.homeDirectory}/dotfiles/ghostty/config";
    "fastfetch/config.jsonc".source =
      link "${config.home.homeDirectory}/dotfiles/fastfetch/config.jsonc";
    "nvim" = {
      source = link "${config.home.homeDirectory}/dotfiles/nvim";
      recursive = true;
    };
    "nu/config.nu".source =
      link "${config.home.homeDirectory}/dotfiles/nu/config.nu";
  };
}
