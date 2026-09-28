{
  description = "ryuko nix config";
  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/release-25.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixGL = {
      url = "github:nix-community/nixGL/310f8e49a149e4c9ea52f1adf70cdc768ec53f8a";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bash-env-json = {
      url = "github:tesujimath/bash-env-json/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    evil-helix = {
      url = "github:usagi-flow/evil-helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    den.url = "github:denful/den";
  };

  outputs = inputs@{ nixpkgs, bash-env-json, evil-helix, ... }:
    let
      system = "x86_64-linux";
      flakePkgs = {
        bash-env-json = bash-env-json.packages.${system}.default;
        evil-helix = evil-helix.packages.${system}.default;
      };
    in
    (nixpkgs.lib.evalModules {
      modules = [
        inputs.den.flakeModule
        ./modules/den.nix
        ./modules/home.nix
        ./modules/git.nix
        ./modules/config.nix
        ./modules/terminal.nix
      ];
      specialArgs = { inherit inputs flakePkgs; };
    }).config.flake;

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
