{
  description = "Crash";

  nixConfig = {
    extra-substituters        = "https://cache.garnix.io/";
    extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }: let
    inherit (nixpkgs) lib;

    forEachSystem = lib.genAttrs (import systems);
  in {
    devShell = forEachSystem (system: with nixpkgs.legacyPackages.${system}; mkShell {
      packages = [
        zig_0_14
        zls
        zon2nix
      ];
    });

    packages = forEachSystem (system: rec {
      inherit (self.overlays.crash null nixpkgs.legacyPackages.${system}) crash;
      default = crash;
    });

    overlays = rec {
      crash   = (final: prev: { crash = prev.callPackage ./package.nix {}; });
      default = crash;
    };
  };
}
