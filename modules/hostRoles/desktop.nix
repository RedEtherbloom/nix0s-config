{
  config,
  lib,
  ...
}: let
  cfg = config.myOptions.hostRoles.desktop;
in {
  options.myOptions.hostRoles.desktop.enable = lib.mkEnableOption "desktop options";

  config = lib.mkIf cfg.enable {
    myOptions.hostRoles.neural-augmenter.enable = lib.mkDefault true;
  };
}
