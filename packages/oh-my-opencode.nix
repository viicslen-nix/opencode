{ pkgs, inputs, ... }:

let
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
  configFile = hmConfigOhMy.config.xdg.configFile."opencode/opencode.json".source;
in
pkgs.writeShellScriptBin "oh-my-opencode" ''
  CONFIG_DIR="$HOME/.config/oh-my-opencode"
  CONFIG_FILE="$CONFIG_DIR/opencode.json"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Initializing oh-my-opencode configuration..."
    mkdir -p "$CONFIG_DIR"
    cp "${configFile}" "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"
  fi

  export OPENCODE_CONFIG_DIR="$CONFIG_DIR"
  exec ${pkgs.opencode}/bin/opencode "$@"
''
