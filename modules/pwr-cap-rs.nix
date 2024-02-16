# https://github.com/reckenrode/nix-foundryvtt/blob/main/flake.nix
# Why do we have to pass the flake as an argument?
# Why can't I just use self for the package?
flake: {
  config,
  lib,
  ...
}: let
  inherit (flake.packages.x86_64-linux) pwr-cap-rs;
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
        type = lib.types.ints.unsigned;
        default = 7000;
        description = ''
          Sustained Power Limit
        '';
      };
      fast-limit = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 7000;
        description = ''
          Actual Power Limit
        '';
      };
      slow-limit = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 7000;
        description = ''
          Average Power Limit
        '';
      };
      tctl-temp = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 69;
        description = ''
          Tctl Temperature Limit (Celsius)
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pwr-cap-rs = {
      enable = true;
      description = "Run pwr-cap-rs as a systemd service";
      serviceConfig.ExecStart = lib.getExe pwr-cap-rs;
      wantedBy = ["default.target"];
    };

    environment.etc."pwr-cap-rs.json".text = builtins.toJSON {
      sus_pl = cfg.stapm-limit;
      actual_pl = cfg.fast-limit;
      avg_pl = cfg.slow-limit;
      max_tmp = cfg.tctl-temp;
    };
  };
}
