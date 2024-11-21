{ pkgs, ... }:{
  imports = [
    ../../homeManagerModules/hostRoles/laptop.nix
  ];

  home.stateVersion = "24.05";
  # Main taskwarrior client
  programs.taskwarrior.config."recurrence" = "on";

  home.packages = with pkgs; [
    comfyuiPackages.krita-with-extensions
  ];
}