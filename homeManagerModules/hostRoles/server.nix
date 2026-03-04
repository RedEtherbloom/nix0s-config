{
  config,
  lib,
  osConfig,
  ...
}: let
  cfg = config.myOptions.hostRoles.server;
in {
  options.myOptions.hostRoles.server = {
    enable = lib.mkOption {
      description = "Enable server";
      type = lib.types.bool;
      default = osConfig.myOptions.hostRoles.server.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    myOptions.hostRoles.base.enable = lib.mkDefault true;
  };
}
