flake: {
  config,
  lib,
  self,
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
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pwr-cap-rs = {
      enable = true;
      description = "Run pwr-cap-rs as a systemd service";
      serviceConfig.ExecStart = lib.getExe pwr-cap-rs;
      wantedBy = ["default.target"];
    };
  };
}
