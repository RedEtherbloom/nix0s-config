{
  config,
  lib,
  ...
}: let
  cfg = config.myOptions.office;
in {
  options.myOptions.office = {
    enable = lib.mkOption {
      description = "Enable office";
      type = lib.types.bool;
      default = false;
    };
    printing = lib.mkOption {
      description = "Enable printing";
      type = lib.types.bool;
      default = true;
    };
    scanning = lib.mkOption {
      description = "Enable scanning";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.printing.enable = cfg.printing;

    hardware.sane = lib.mkIf cfg.scanning {
      enable = true;
      drivers.scanSnap.enable = true;
    };
  };
}
