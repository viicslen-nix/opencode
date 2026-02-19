{ pkgs, inputs, ... }:

let
  hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../default.nix
      {
        home.stateVersion = "25.11";
        home.username = "runner";
        home.homeDirectory = "/tmp/runner";
        modules.programs.opencode.enable = true;
      }
    ];
  };
  configFile = hmConfig.config.xdg.configFile."opencode/opencode.json".source;
in
pkgs.writeShellScriptBin "opencode" ''
  export OPENCODE_CONFIG="${configFile}"
  exec ${pkgs.opencode}/bin/opencode "$@"
''
