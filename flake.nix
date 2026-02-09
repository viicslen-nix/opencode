{
  description = "Opencode Home Manager Module";

  # Inputs define the dependencies of this flake
  inputs = {
    # The main package repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

      perSystem = {pkgs, ...}: let
        # Create a standalone Home Manager configuration
        hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./default.nix
            {
              # Basic Home Manager setup
              home.stateVersion = "25.11";
              home.username = "runner";
              home.homeDirectory = "/tmp/runner";
              modules.programs.opencode.enable = true;
            }
          ];
        };

        # Directly access the generated configuration file
        configFile = hmConfig.config.xdg.configFile."opencode/opencode.json".source;

        # Create a wrapper package that sets the OPENCODE_CONFIG env var
        opencode-wrapped = pkgs.writeShellScriptBin "opencode" ''
          export OPENCODE_CONFIG="${configFile}"
          exec ${pkgs.opencode}/bin/opencode "$@"
        '';
      in {
        # Formatter for the flake code
        formatter = pkgs.alejandra;

        # Export the configured opencode package
        packages.default = opencode-wrapped;
        packages.config = configFile;

        # Define runable applications
        apps.default = {
          type = "app";
          program = "${opencode-wrapped}/bin/opencode";
        };

        # Expose debugging attributes via legacyPackages
        legacyPackages = {
          inherit hmConfig configFile;
        };
      };

      flake = {
        # Export the module for use in other configurations
        homeManagerModules = {
          default = ./default.nix;
          opencode = ./default.nix;
        };
      };
    };
}
