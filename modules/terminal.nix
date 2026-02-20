{ config, pkgs, ... }:
let
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "ghostty" ''
      exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.ghostty}/bin/ghostty "$@"
    '')
  ];

  xdg.configFile = {
    "ghostty/config".source =
      link "${config.home.homeDirectory}/dotfiles/ghostty/config";
  };
}
