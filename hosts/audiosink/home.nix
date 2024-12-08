{pkgs, ...}: {
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    librespot
  ];
}
