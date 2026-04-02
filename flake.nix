{
  description = "Opencode Home Manager Module";

  # Inputs define the dependencies of this flake
  inputs = {
    # The main package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # The Opencode application and related tools
    opencode.url = "github:anomalyco/opencode";
    # Library for easier flake manipulation
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Home Manager for user-environment configuration
    home-manager.url = "github:nix-community/home-manager";
    # Ensure home-manager uses the same nixpkgs version as this flake
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}: let
    nodeModulesHashOverrides = {
      x86_64-linux = "sha256-I/I7YGrZPmnIPSh/BzvgAfQOMn90Jh3aFABVMqUn+Xw=";
    };

    opencodeOverlay = _final: prev: let
      system = prev.stdenvNoCC.hostPlatform.system;
      hash = nodeModulesHashOverrides.${system} or null;
      rev =
        if inputs.opencode ? shortRev
        then inputs.opencode.shortRev
        else if inputs.opencode ? rev
        then builtins.substring 0 7 inputs.opencode.rev
        else "dirty";
    in
      if hash == null
      then {}
      else {
        opencode = prev.opencode.override {
          node_modules = prev.callPackage "${inputs.opencode}/nix/node_modules.nix" {
            inherit rev hash;
          };
        };
      };
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
            opencodeOverlay
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

        # Define runable applications
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
            imports = [./default.nix];
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
              opencodeOverlay
            ];
          };
          opencode = {
            imports = [./default.nix];
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
              opencodeOverlay
            ];
          };
        };
      };
    };
}
