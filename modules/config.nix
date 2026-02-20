{ config, ... }:
let
  link = config.lib.file.mkOutOfStoreSymlink;
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  xdg.configFile = {
    "jjui" = {
      source = link "${dotfiles}/jjui";
      recursive = true;
    };
    "ghostty/config".source =
      link "${dotfiles}/ghostty/config";
    "fastfetch/config.jsonc".source =
      link "${dotfiles}/fastfetch/config.jsonc";
    "nvim" = {
      source = link "${dotfiles}/nvim";
      recursive = true;
    };
    "nushell/config.nu".source =
      link "${dotfiles}/nushell/config.nu";
    "opencode/opencode.json".source = link "${dotfiles}/agents/opencode/opencode.json";
    "opencode/AGENTS.md".source = link "${dotfiles}/agents/AGENTS.md";
    "opencode/skills" = {
      source = link "${dotfiles}/agents/skills";
      recursive = true;
    };
  };
}
