{pkgs, ...}: {
  imports = [
    ../../homeManagerModules
  ];

  home.stateVersion = "24.05";
  programs.taskwarrior.config."recurrence" = "on";

  home.packages = with pkgs; [
    aircrack-ng
  ];
}
