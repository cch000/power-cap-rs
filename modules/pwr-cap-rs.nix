self: {
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
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pwr-cap-rs = {
      description = "limit ryzen cpu power consumption when on power-saver";
      wantedBy = ["default.target"];
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = lib.getExe pwr-cap-rs;
      };
    };

    environment.etc."pwr-cap-rs.json".text = builtins.toJSON {
      sus_pl = cfg.stapm-limit;
      actual_pl = cfg.fast-limit;
      avg_pl = cfg.slow-limit;
      max_tmp = cfg.tctl-temp;
    };
  };
}
