{
  description = "Opencode Home Manager Module";

  # Inputs define the dependencies of this flake
  inputs = {
    # The main package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    packages = {
      url = "github:viicslen-nix/packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The Opencode application and related tools
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Library for easier flake manipulation
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Home Manager for user-environment configuration
    home-manager.url = "github:nix-community/home-manager";
    # Ensure home-manager uses the same nixpkgs version as this flake
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # Supported system architectures
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = {
        lib,
        config,
        system,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.opencode.overlays.default
          ];
        };
      in {
        # Formatter for the flake code
        formatter = pkgs.alejandra;

        # Export the configured opencode package
        packages = {
          default = pkgs.callPackage ./packages/opencode.nix {inherit inputs;};
          oh-my-opencode = pkgs.callPackage ./packages/oh-my-opencode.nix {inherit inputs;};
        };

        # Define runnable applications
        apps = {
          default = {
            type = "app";
            program = lib.getExe config.packages.default;
          };
          oh-my-opencode = {
            type = "app";
            program = lib.getExe config.packages.oh-my-opencode;
          };
        };
      };

      flake = {
        # Export the module for use in other configurations
        homeManagerModules = {
          default = {
            imports = [./hmModules/default.nix];
            _module.args.inputs = inputs;
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
            ];
          };
          opencode = {
            imports = [./hmModules/default.nix];
            _module.args.inputs = inputs;
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
            ];
          };
        };

        nixosModules = {
          opencode-web = {
            imports = [./nixos.nix];
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
            ];
          };
        };
      };
    };
}
