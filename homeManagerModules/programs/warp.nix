{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.warp;
in {
  options.myOptions.warp = {
    enable = lib.mkOption {
      description = "Enable warp";
      type = lib.types.bool;
      default = osConfig.myOptions.utilities.wormhole && config.myOptions.hostRoles.graphical.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.warp
    ];
  };
}
