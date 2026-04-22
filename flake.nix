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
    opencode.url = "github:anomalyco/opencode";
    # Library for easier flake manipulation
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Home Manager for user-environment configuration
    home-manager.url = "github:nix-community/home-manager";
    # Ensure home-manager uses the same nixpkgs version as this flake
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}: let
    opencodeBunCompatOverlay = final: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          if [ -f packages/script/src/index.ts ]; then
            substituteInPlace packages/script/src/index.ts \
              --replace 'const expectedBunVersionRange = `^''${expectedBunVersion}`' 'const expectedBunVersionRange = ">=1.3.11"'
          fi

          if [ -f packages/opencode/src/cli/cmd/generate.ts ]; then
            substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
              --replace 'const prettier = await import("prettier")' 'const prettier = await import(process.env.OPENCODE_PRETTIER_PACKAGE ?? "prettier")' \
              --replace 'const babel = await import("prettier/plugins/babel")' 'const babel = await import(process.env.OPENCODE_PRETTIER_BABEL_PLUGIN ?? "prettier/plugins/babel")' \
              --replace 'const estree = await import("prettier/plugins/estree")' 'const estree = await import(process.env.OPENCODE_PRETTIER_ESTREE_PLUGIN ?? "prettier/plugins/estree")'
          fi
        '';
      });
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
            opencodeBunCompatOverlay
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
            _module.args.inputs = inputs;
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
              opencodeBunCompatOverlay
            ];
          };
          opencode = {
            imports = [./default.nix];
            _module.args.inputs = inputs;
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
              opencodeBunCompatOverlay
            ];
          };
        };

        nixosModules = {
          opencode-web = {
            imports = [./nixos.nix];
            nixpkgs.overlays = [
              inputs.opencode.overlays.default
              opencodeBunCompatOverlay
            ];
          };
        };
      };
    };
}
