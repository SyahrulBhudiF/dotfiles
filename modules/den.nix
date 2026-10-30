{ inputs, flakePkgs, ... }:
{
  den.default.homeManager.home.stateVersion = "25.11";

  den.homes.x86_64-linux.ryuko = {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [
        (final: _:
          let
            nixGLPkgs = final // {
              pcre = final.pcre2;
              writeTextFile = args: final.writeTextFile (args // {
                checkPhase = final.lib.replaceStrings [ "pcregrep" ] [ "pcre2grep" ] args.checkPhase;
              });
              callPackage = final.lib.callPackageWith nixGLPkgs;
            };
          in {
            nixgl = import inputs.nixGL {
              pkgs = nixGLPkgs;
              enable32bits = final.stdenv.hostPlatform.isx86;
              enableIntelX86Extensions = final.stdenv.hostPlatform.isx86;
            };
          })
      ];
    };
    instantiate = args:
      inputs.home-manager.lib.homeManagerConfiguration (args // {
        extraSpecialArgs = { inherit inputs flakePkgs; };
      });
  };
}
