{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  kclock = pkgs.kdePackages.kclock;
in {
  config = mkIf config.services.desktopManager.plasma6.enable {
    services.dbus.packages = [kclock];
    environment.systemPackages = [kclock];
  };
}
