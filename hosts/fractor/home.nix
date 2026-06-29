{pkgs, ...}: {
  imports = [
    ../../homeManagerModules
  ];

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    aircrack-ng
  ];
}
