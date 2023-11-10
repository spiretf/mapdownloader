{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/release-23.05";
    spire.url = "github:spiretf/nix";
    spire.inputs.nixpkgs.follows = "nixpkgs";
    spire.inputs.flake-utils.follows = "utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    spire,
  }:
    utils.lib.eachSystem spire.systems (system: let
      overlays = [spire.overlays.default];
      pkgs = (import nixpkgs) {
        inherit system overlays;
      };
      inherit (pkgs) lib;
      spEnv = pkgs.sourcepawn.buildEnv (with pkgs.sourcepawn.includes; [sourcemod curl]);
    in rec {
      packages = rec {
        mapdownloader = pkgs.buildSourcePawnScript {
          name = "mapdownloader";
          src = ./plugin/mapdownloader.sp;
          includes = with pkgs.sourcepawn.includes; [curl];
        };
        default = mapdownloader;
      };
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [spEnv];
      };
    });
}
