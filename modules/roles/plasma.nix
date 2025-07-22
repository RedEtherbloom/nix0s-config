{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  inherit (pkgs.kdePackages) kclock;
in {
  config = mkIf config.services.desktopManager.plasma6.enable {
    services = {
      dbus.packages = [kclock];
      desktopManager.plasma6.enableQt5Integration = true;
    };
    environment.systemPackages = [kclock];
  };
}
