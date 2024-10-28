self: {
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (self.packages.x86_64-linux) pwr-cap-rs;
  inherit (lib) mkMerge mkOption mkIf types getExe strings;
  cfg = config.services.pwr-cap-rs;
  profile = types.submodule {
    options = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
        '';
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
    };
  };
in {
  options = {
    services.pwr-cap-rs = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Run pwr-cap-rs as a systemd service
        '';
      };
      quiet = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = ''
                enable quiet profile
              '';
              plugged = profile;
              unplugged = profile;
            };
          };
        };
      };
      balanced = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = ''
                enable quiet profile
              '';
              plugged = profile;
              unplugged = profile;
            };
          };
        };
      };
      performance = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              default = false;
              type = types.bool;
              description = ''
                enable quiet profile
              '';
              plugged = profile;
              unplugged = profile;
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.services.pwr-cap-rs = {
        description = "limit ryzen cpu power consumption when on power-saver";

        serviceConfig = {
          Type = "simple";
          User = "root";
          Restart = "always";
          ExecStart = getExe pwr-cap-rs;
        };
      };

      environment.etc."pwr-cap-rs.json".text =
        builtins.toJSON {
        };
    }
    (mkIf (!cfg.onlyOnBattery) {
      systemd.services.pwr-cap-rs.wantedBy = ["default.target"];
    })
    (mkIf cfg.onlyOnBattery {
      systemd.services.pwr-cap-rs = {
        wantedBy = [];
        unitConfig = {
          ConditionACPower = "false";
        };
      };

      services.udev.extraRules = let
        unplug = ''ACTION=="change", KERNEL=="AC0", SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start pwr-cap-rs.service"'';
        plug = ''ACTION=="change", KERNEL=="AC0", SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl stop pwr-cap-rs.service"'';
      in
        strings.concatLines [unplug plug];
    })
  ]);
}
