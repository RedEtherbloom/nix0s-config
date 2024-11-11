{ pkgs, ... }:
{
  imports = [
    ../../homeManagerModules/desktop.nix
  ];  

  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    solaar

    krita

    # FNV Mod launcher
    zenity
    yad
    # Does my bar approach need this?
    openal

    koboldcpp

    # TODO: Maybe this will make KRunner less laggy
    egl-wayland
  ];
}
