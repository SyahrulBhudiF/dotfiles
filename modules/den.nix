{ inputs, flakePkgs, ... }:
{
  den.default.homeManager.home.stateVersion = "25.11";

  den.homes.x86_64-linux.ryuko = {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [ inputs.nixGL.overlays.default ];
    };
    instantiate = args:
      inputs.home-manager.lib.homeManagerConfiguration (args // {
        extraSpecialArgs = { inherit inputs flakePkgs; };
      });
  };
}
