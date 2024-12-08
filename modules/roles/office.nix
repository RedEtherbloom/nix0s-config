{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.office;
in {
  options.myOptions.office = {
    enable = mkOption {
      description = "Enable office";
      type = with types; bool;
      default = false;
    };
    printing = mkOption {
        description = "Enable printing";
        type = types.bool;
        default = true;
    };
    scanning = mkOption {
      description = "Enable scanning";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.printing.enable = cfg.printing;

    hardware.sane = mkIf cfg.scanning {
      enable = true;
      drivers.scanSnap.enable = true;
    };
  };
}
