{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.warp;
in {
  options.myOptions.warp = {
    enable = mkOption {
      description = "Enable warp";
      type = with types; bool;
      default = osConfig.myOptions.utilities.wormhole && config.myOptions.hostRoles.graphical.enable;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.warp];
  };
}
