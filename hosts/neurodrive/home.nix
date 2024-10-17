{ pkgs, ... }:
{
  home-manager.users.inf.home.packages = with pkgs; [
    solaar

    krita

    # FNV Mod launcher
    zenity
    yad
    # Does my bar approach need this?
    openal

    koboldcpp
  ];
}
