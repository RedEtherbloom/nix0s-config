{ lib, config, ... }:
with lib;
let
  cfg = config.myOptions.taskchampion;
in
{
  options.myOptions.taskchampion = {
    enableServer = mkOption {
      description = "Enable the taskchampion server on the current device";
      type = types.bool;
      default = false;
    };
    taskchampionPort = {
      description = "Port that hosts the taskchampion server";
      type = types.port;
      # Default taskchampion port used by taskchampion
      default = 10222;
    };
    taskchampionIP = {
      description = "IP under which the taskchampion server runs";
      type = types.IPv4;
      default = config.networking.ownWireguard.hosts.neurodrive.mainIP;
    };
  };

  config = mkIf cfg.enableServer {
    services.taskchampion-sync-server = {
      enable = true;
      port = config.myOptions.taskchampion.taskchampionPort;
      openFirewall = true;
    };
  };
}
