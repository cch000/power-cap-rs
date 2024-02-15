{
  config,
  self,
  lib,
  ...
}: let
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
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ryzenadj = {
      enable = true;
      description = "Run pwr-cap-rs as a systemd service";
      serviceConfig.ExecStart = lib.getExe self.packages.pwr-cap-rs;
      wantedBy = ["default.target"];
    };
  };
}
