self: {
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (self.packages.x86_64-linux) pwr-cap-rs;
  cfg = config.services.pwr-cap-rs;
in {
  options = {
    services.pwr-cap-rs = {
      enable = lib.mkOption {
        default = false;
        type = with lib.types; bool;
        description = ''
          "Run pwr-cap-rs as a systemd service"
        '';
      };
      stapm-limit = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        description = ''
          Sustained Power Limit (mW)
        '';
      };
      fast-limit = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 9000;
        description = ''
          Actual Power Limit, cannot be null (mW)
        '';
      };
      slow-limit = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        description = ''
          Average Power Limit (mW)
        '';
      };
      tctl-temp = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        description = ''
          Tctl Temperature Limit (Celsius)
        '';
      };
      onlyOnBattery = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Wether to stop the service when the laptop is plugged in
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.pwr-cap-rs = {
        description = "limit ryzen cpu power consumption when on power-saver";

        serviceConfig = {
          Type = "simple";
          User = "root";
          Restart = "always";
          ExecStart = lib.getExe pwr-cap-rs;
        };
        wantedBy = ["default.target"];
      };

      environment.etc."pwr-cap-rs.json".text = builtins.toJSON {
        sus_pl = cfg.stapm-limit;
        actual_pl = cfg.fast-limit;
        avg_pl = cfg.slow-limit;
        max_tmp = cfg.tctl-temp;
      };
    }
    (lib.mkIf cfg.onlyOnBattery {
      systemd.services.pwr-cap-rs = {
        unitConfig = {
          ConditionACPower = "false";
        };

        services.udev.extraRules = let
          unplug = ''ACTION=="change", KERNEL=="AC0", SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start pwr-cap-rs.service"'';
          plug = ''ACTION=="change", KERNEL=="AC0", SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl stop pwr-cap-rs.service"'';
        in
          lib.strings.concatLines [unplug plug];
      };
    })
  ]);
}
