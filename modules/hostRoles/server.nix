{
  config,
  lib,
  ...
}: let
  cfg = config.myOptions.hostRoles.server;
in {
  options.myOptions.hostRoles.server.enable = lib.mkEnableOption "server options";

  config = lib.mkIf cfg.enable {
    myOptions.hostRoles.base.enable = lib.mkDefault true;
  };
}
