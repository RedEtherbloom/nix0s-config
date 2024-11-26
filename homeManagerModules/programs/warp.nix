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
          buildInputs = oldAttrs.buildInputs ++ [pkgs.gst_all_1.gst-plugins-good (pkgs.gst_all_1.gst-plugins-bad.override {enableZbar = true;})];
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.gst_all_1.gstreamer];

          preFixup = ''
            gappsWrapperArgs+=(
              # vp8enc preset
              --prefix GST_PRESET_PATH : "${pkgs.gst_all_1.gst-plugins-good}/share/gstreamer-1.0/presets"
            )
          '';
        }))
    ];
  };
}
