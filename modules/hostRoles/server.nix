{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.server;
in {
  options.myOptions.hostRoles.server.enable = mkEnableOption "server options";

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = lib.mkDefault true;
  };
}
