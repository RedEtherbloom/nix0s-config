{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.server;
in {
  options.myOptions.hostRoles.server = {
    enable = mkOption {
      description = "Enable server";
      type = with types; bool;
      default = osConfig.myOptions.hostRoles.server.enable;
    };
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;
  };
}
