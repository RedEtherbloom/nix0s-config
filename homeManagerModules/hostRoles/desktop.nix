{
  config,
  lib,
  osConfig,
  ...
}: let
  cfg = config.myOptions.hostRoles.desktop;
in {
  options.myOptions.hostRoles.desktop = {
    enable = lib.mkOption {
      description = "Enable desktop";
      type = lib.types.bool;
      default = osConfig.myOptions.hostRoles.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = lib.mkDefault true;
  };
}
