{
  config,
  lib,
  osConfig,
  pkgs,
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
    home.packages = [
      (pkgs.warp.overrideAttrs
        (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [(pkgs.gst_all_1.gst-plugins-bad.override {enableZbar = true;})];
        }))
    ];
  };
}
