{
  lib,
  config,
  ...
}: let
  cfg = config.myOptions.services.taskchampion;
in {
  options.myOptions.services.taskchampion = {
    enable = lib.mkOption {
      description = "Enable the taskchampion server on the current device";
      type = lib.types.bool;
      default = false;
    };
    taskchampionPort = lib.mkOption {
      description = "Port that hosts the taskchampion server";
      type = lib.types.port;
      default = 10222; # Default taskchampion port used by taskchampion
    };
  };

  config = lib.mkIf cfg.enable {
    services.taskchampion-sync-server = {
      enable = true;
      port = config.myOptions.services.taskchampion.taskchampionPort;
      host = "0.0.0.0";
      openFirewall = true;
      snapshot = {
        versions = 10;
        days = 1;
      };
    };
  };
}
