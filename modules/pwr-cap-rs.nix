self: {
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (self.packages.x86_64-linux) pwr-cap-rs;
  inherit (lib) mkMerge mkOption mkIf types getExe strings;
  cfg = config.services.pwr-cap-rs;
in {
  options = {
    services.pwr-cap-rs = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          "Run pwr-cap-rs as a systemd service"
        '';
      };
      stapm-limit = mkOption {
        type = with types; nullOr ints.unsigned;
        default = null;
        description = ''
          Sustained Power Limit (mW)
        '';
      };
      fast-limit = mkOption {
        type = types.ints.unsigned;
        default = null;
        description = ''
          Actual Power Limit (mW).
          Cannot be null, you must set a value that suits your usecase.
        '';
      };
      slow-limit = mkOption {
        type = with types; nullOr ints.unsigned;
        default = null;
        description = ''
          Average Power Limit (mW)
        '';
      };
      tctl-temp = mkOption {
        type = with types; nullOr ints.unsigned;
        default = null;
        description = ''
          Tctl Temperature Limit (Celsius)
        '';
      };
      onlyOnBattery = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Wether to stop the service when the laptop is plugged in
        '';
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

      environment.etc."pwr-cap-rs.json".text = builtins.toJSON {
        sus_pl = cfg.stapm-limit;
        actual_pl = cfg.fast-limit;
        avg_pl = cfg.slow-limit;
        max_tmp = cfg.tctl-temp;
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
