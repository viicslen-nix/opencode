{ pkgs, inputs, ... }:

let
  inherit (pkgs) lib;
  hmConfigOhMy = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../default.nix
      {
        home.stateVersion = "25.11";
        home.username = "runner";
        home.homeDirectory = "/tmp/runner";
        modules.programs.opencode.enable = true;
        programs.opencode.settings.plugin = [
          "oh-my-opencode@latest"
        ];
      }
    ];
  };

  # Helper to find all opencode configuration files
  opencodeConfigFiles = lib.filterAttrs (name: _: lib.hasPrefix "opencode/" name) hmConfigOhMy.config.xdg.configFile;

  # Create installation commands for each file
  installCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: ''
    rel_path="${lib.removePrefix "opencode/" name}"
    target="$CONFIG_DIR/$rel_path"
    mkdir -p "$(dirname "$target")"
    
    # Only install if not present, to respect user modifications
    if [ ! -f "$target" ]; then
      cp "${file.source}" "$target"
      chmod 644 "$target"
      echo "Installed $rel_path"
    fi
  '') opencodeConfigFiles);
in
pkgs.writeShellScriptBin "oh-my-opencode" ''
  CONFIG_DIR="$HOME/.config/oh-my-opencode"

  # Ensure the directory exists
  mkdir -p "$CONFIG_DIR"

  ${installCommands}

  export OPENCODE_CONFIG_DIR="$CONFIG_DIR"
  exec ${pkgs.opencode}/bin/opencode "$@"
''
