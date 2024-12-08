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
      default = cfg.scanning;
    };
    scanning = mkOption {
      description = "Enable scanning";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf (cfg.enable && cfg.scanning) {
    hardware.sane = {
      enable = true;
      drivers.scanSnap.enable = true;
    };
  };
}
