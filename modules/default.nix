self: {
  config,
  lib,
  ...
}: let
  inherit (self.packages.x86_64-linux) pwr-cap-rs;
  inherit (lib) mkOption mkEnableOption mkIf types getExe;
  cfg = config.services.pwr-cap-rs;
  profile = {
    default = {};
    type = types.submodule {
      options = {
        enable = mkEnableOption "profile";
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
      enable = mkEnableOption "pwr-cap-rs service";
      tctl_limit = mkOption {
        default = null;
        type = with types; nullOr ints.unsigned;
        description = "";
      };
      quiet = mkOption {
        default = {};
        type = types.submodule {
          options = {
            enable = mkEnableOption "quiet profile";
            unplugged = mkOption profile;
            plugged = mkOption profile;
          };
        };
      };
      balanced = mkOption {
        default = {};
        type = types.submodule {
          options = {
            enable = mkEnableOption "balanced profile";
            unplugged = mkOption profile;
            plugged = mkOption profile;
          };
        };
      };
      performance = mkOption {
        default = {};
        type = types.submodule {
          options = {
            enable = mkEnableOption "performance profile";
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
        description = "tweak ryzen cpu power consumption";

        serviceConfig = {
          Type = "simple";
          User = "root";
          Restart = "always";
          ExecStart = getExe pwr-cap-rs;
        };

        wantedBy = ["default.target"];
      };

      environment.etc."pwr-cap-rs.json".text = builtins.toJSON {
        inherit (cfg) quiet balanced performance tctl_limit;
      };
    };
}
