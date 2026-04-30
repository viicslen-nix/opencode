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
        help = ../commands/mempalace/help.md;
        init = ../commands/mempalace/init.md;
        mine = ../commands/mempalace/mine.md;
        search = ../commands/mempalace/search.md;
        status = ../commands/mempalace/status.md;
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
