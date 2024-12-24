{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.desktop;
in {
  options.myOptions.hostRoles.desktop.enable = mkEnableOption "desktop options";

  config = mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = lib.mkDefault true;
  };
}
