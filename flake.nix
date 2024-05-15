{
  description = "Crash";

  nixConfig = {
    extra-substituters        = "https://cache.garnix.io/";
    extra-trusted-public-keys = "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }: with nixpkgs.lib; foldl' recursiveUpdate {} (map (system: let
    pkgs = import nixpkgs { inherit system; };
  in {
    devShell.${system} = pkgs.mkShell {
      packages = with pkgs; [
        zig_0_12
        zls
        zon2nix
      ];
    };

    packages.${system} = rec {
      crash   = pkgs.callPackage ./package.nix {};
      default = crash;
    };

  }) [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ]);
}
