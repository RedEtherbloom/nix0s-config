{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs.kdePackages) kclock;
in {
  options.myOptions.roles.plasma.enableKclock = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  config = lib.mkIf (config.services.desktopManager.plasma6.enable && config.myOptions.roles.plasma.enableKclock) {
    services.dbus.packages = [kclock];
    environment.systemPackages = [kclock];
  };
}
