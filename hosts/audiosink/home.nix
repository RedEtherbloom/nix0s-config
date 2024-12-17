{pkgs, ...}: {
  imports = [
    ../../homeManagerModules
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    #librespot
  ];
}
