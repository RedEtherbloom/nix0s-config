{
  flake.homeModules.solaar = {pkgs, ...}: let
    hiddenAutostart = pkgs.makeDesktopItem {
      name = "Solaar";
      desktopName = "Solaar";
      icon = "solaar";
      exec = "${pkgs.solaar}/bin/solaar -w hide";
    };
  in {
    home.packages = [pkgs.solaar];

    xdg.autostart.entries = [hiddenAutostart];
  };
}
