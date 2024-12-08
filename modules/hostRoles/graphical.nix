{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.graphical;
in {
  options.myOptions.hostRoles.graphical.enable = mkEnableOption "graphical session settings";

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;
  };
}
