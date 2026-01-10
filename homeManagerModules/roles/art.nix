{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.art;
in {
  options.myOptions.roles.art = {
    enable = lib.mkOption {
      description = "Enable art and creative tools.";
      type = lib.types.bool;
      default = false;
    };
    inkscape = lib.mkOption {
      description = "Enable inkscape for vector graphics.";
      type = lib.types.bool;
      default = false;
    };
    stitching = lib.mkOption {
      description = "Enable embroidery tooling.";
      type = lib.types.bool;
      default = false;
    };
    # TODO: Turn krita into option
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = with pkgs;
        lib.optionals cfg.inkscape [
          (inkscape-with-extensions.override {inkscapeExtensions = with inkscape-extensions; lib.optionals cfg.stitching [inkstitch];})
        ];
    }
    (lib.mkIf cfg.stitching {
      myOptions.roles.art.inkscape = lib.mkDefault true;
    })
  ]);
}
