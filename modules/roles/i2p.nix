{ config, lib, ... }:
with lib;
let
  cfg = config.myOptions.roles.i2p;
in
{
  options.myOptions.roles.i2p = {
  enable = mkOption {
    description = "Enable i2p";
    type = with types; bool;
    default = false;
  };
  };

  config = mkIf cfg.enable {
    services.i2p.enable = true;
      networking.firewall.interfaces."wg0".allowedTCPPorts = [ 
        # Router console
        7657 
        # Own site port
        7658 
    ]; 
  };
}