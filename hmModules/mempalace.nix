{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.programs.opencode.mempalace;
  opencodeCfg = config.modules.programs.opencode;
in {
  options.modules.programs.opencode.mempalace = {
    enable = mkEnableOption (mdDoc "mempalace integration for opencode");
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = opencodeCfg.enable;
        message = "`modules.programs.opencode.mempalace.enable` requires `modules.programs.opencode.enable = true`.";
      }
    ];

    programs.opencode = {
      skills = {
        mempalace = ../skills/mempalace.md;
      };

      commands = {
        mempalace-help = ../commands/mempalace/help.md;
        mempalace-init = ../commands/mempalace/init.md;
        mempalace-mine = ../commands/mempalace/mine.md;
        mempalace-search = ../commands/mempalace/search.md;
        mempalace-status = ../commands/mempalace/status.md;
      };

      settings.mcp = {
        mempalace = {
          type = "local";
          command = ["${lib.getExe' inputs.packages.packages.${pkgs.system}.python.mempalace "mempalace-mcp"}"];
          enabled = true;
        };
      };
    };
  };
}
