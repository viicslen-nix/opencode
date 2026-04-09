{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  name = "opencode-web";
  namespace = "services";

  cfg = config.modules.${namespace}.${name};

  enabledUsers = filterAttrs (_: u: u.enable) cfg.users;
in {
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption "opencode web server service";

    package = mkOption {
      type = types.package;
      default = pkgs.opencode;
      defaultText = literalExpression "pkgs.opencode";
      description = "The opencode package to use for the web service.";
    };

    port = mkOption {
      type = types.port;
      default = 43037;
      description = "The port the opencode web server will listen on.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "The host address the opencode web server will bind to.";
    };

    hostname = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "opencode.local";
      description = ''
        Optional hostname that should resolve to this service.
        When set it is appended to networking.hosts."127.0.0.1".
      '';
    };

    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to run the opencode web service for this user.";
          };

          environmentFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            example = literalExpression "config.age.secrets.opencode-web.path";
            description = ''
              Path to a file containing environment variables for the service,
              such as OPENCODE_SERVER_PASSWORD. Must not be in the Nix store.
            '';
          };
        };
      });
      default = {};
      description = "Per-user opencode web service configuration.";
    };
  };

  config = mkIf cfg.enable {
    networking.hosts = mkIf (cfg.hostname != null) {
      "127.0.0.1" = [cfg.hostname];
    };

    home-manager.users = mapAttrs (user: userCfg:
      mkIf userCfg.enable {
        systemd.user.services.${name} = {
          Unit = {
            Description = "Opencode web server";
            After = ["network.target"];
          };

          Service =
            {
              ExecStart = "${lib.getExe cfg.package} web --hostname ${cfg.host} --port ${toString cfg.port}";
              Restart = "on-failure";
              RestartSec = "5s";
            }
            // optionalAttrs (userCfg.environmentFile != null) {
              EnvironmentFile = userCfg.environmentFile;
            };

          Install = {
            WantedBy = ["default.target"];
          };
        };
      }
    ) enabledUsers;
  };
}
