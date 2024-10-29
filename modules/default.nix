self: {
  config,
  lib,
  ...
}: let
  inherit (self.packages.x86_64-linux) pwr-cap-rs;
  inherit (lib) mkOption mkIf types getExe;
  cfg = config.services.pwr-cap-rs;
  profile = {
    type = types.submodule {
      options = {
        enable = mkOption {
          default = false;
          type = types.bool;
          description = "";
        };
        stapm_limit = mkOption {
          default = null;
          type = with types; nullOr ints.unsigned;
          description = "";
        };
        fast_limit = mkOption {
          default = null;
          type = with types; nullOr ints.unsigned;
          description = "";
        };
        slow_limit = mkOption {
          default = null;
          type = with types; nullOr ints.unsigned;
          description = "";
        };
        apu_slow_limit = mkOption {
          default = null;
          type = with types; nullOr ints.unsigned;
          description = "";
        };
      };
    };
  };
in {
  options = {
    services.pwr-cap-rs = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Run pwr-cap-rs as a systemd service";
      };
      tctl_limit = mkOption {
        default = null;
        type = with types; nullOr ints.unsigned;
        description = "";
      };
      quiet = mkOption {
        type = types.submodule {
          options = {
            unplugged = mkOption profile;
            plugged = mkOption profile;
          };
        };
      };
      balanced = mkOption {
        type = types.submodule {
          options = {
            unplugged = mkOption profile;
            plugged = mkOption profile;
          };
        };
      };
      performance = mkOption {
        type = types.submodule {
          options = {
            unplugged = mkOption profile;
            plugged = mkOption profile;
          };
        };
      };
    };
  };

  config =
    mkIf cfg.enable
    {
      systemd.services.pwr-cap-rs = {
        description = "limit ryzen cpu power consumption when on power-saver";

        serviceConfig = {
          Type = "simple";
          User = "root";
          Restart = "always";
          ExecStart = getExe pwr-cap-rs;
        };

        wantedBy = ["default.target"];
      };

      environment.etc."pwr-cap-rs.json".text = builtins.toJSON {
        inherit (cfg) quiet;
        inherit (cfg) balanced;
        inherit (cfg) performance;
        inherit (cfg) tctl_limit;
      };
    };
}
