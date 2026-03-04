{
  config,
  lib,
  ...
}: let
  cfg = config.myOptions.roles.i2p;
in {
  options.myOptions.roles.i2p = {
    enable = lib.mkOption {
      description = "Enable i2p";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.i2p.enable = true;
    networking.firewall.interfaces."wg0".allowedTCPPorts = [
      # Router console
      7657
      # Own site port
      7658
    ];
  };
}
