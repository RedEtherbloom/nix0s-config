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
    security.pam.services = {
      login.kwallet = {
        enable = true;
        package = lib.mkDefault pkgs.kdePackages.kwallet-pam;
      };
      # Copied from: https://github.com/NixOS/nixpkgs/issues/258296
      kde = {
        allowNullPassword = true;
        kwallet.enable = true;
      };
    };
  };
}
