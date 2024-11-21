{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.desktop;
in {
  options.myOptions.hostRoles.desktop = {
    enable = mkOption {
      description = "Enable desktop";
      type = with types; bool;
      default = osConfig.myOptions.hostRoles.desktop.enable;
    };
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = mkDefault true;
  };
}
