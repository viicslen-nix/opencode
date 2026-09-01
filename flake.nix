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
    # home-manager is reached through omniflake's index rather than carrying an
    # input of its own; see the `inputs` binding in `outputs` below. Consumers
    # should point this at their own omniflake so only one copy is locked.
    omniflake = {
      url = "github:fzakaria/omniflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = rawInputs @ {flake-parts, ...}: let
    # home-manager under its old name, so every `inputs.home-manager` below —
    # the two packages and `_module.args.inputs` — is unchanged.
    inputs = rawInputs // {home-manager = rawInputs.omniflake.flakes.home-manager;};
  in
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
          };
          opencode = {
            imports = [./hmModules/default.nix];
            _module.args.inputs = inputs;
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
