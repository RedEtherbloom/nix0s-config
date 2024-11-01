{ lib, config, ... }:
with lib;
let
  cfg = config.myOptions.services.taskchampion;
in
{
  options.myOptions.services.taskchampion = {
    enable = mkOption {
      description = "Enable the taskchampion server on the current device";
      type = types.bool;
      default = false;
    };
    taskchampionPort = mkOption {
      description = "Port that hosts the taskchampion server";
      type = types.port;
      # Default taskchampion port used by taskchampion
      default = 10222;
    };
    taskchampionIP = mkOption {
      description = "IP under which the taskchampion server runs";
      type = types.singleLineStr;
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
