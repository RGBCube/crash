{
  description = "Crash";

  nixConfig = {
    extra-substituters        = "https://cache.garnix.io/";
    extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    inherit (nixpkgs) lib;

    forEachSystem = lib.genAttrs [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];
  in {
    devShell = forEachSystem (system: with nixpkgs.legacyPackages.${system}; mkShell {
      packages = [
        zig_0_12
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
