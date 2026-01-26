{
  description = "Opencode Home Manager Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { pkgs, ... }: {
        formatter = pkgs.alejandra;
        packages.default = pkgs.opencode;
        apps.default = {
          type = "app";
          program = "${pkgs.opencode}/bin/opencode";
        };
      };
      flake = {
        homeManagerModules = {
          default = ./default.nix;
          opencode = ./default.nix;
        };
      };
    };
}
