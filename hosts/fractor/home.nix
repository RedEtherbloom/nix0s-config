{ pkgs, ... }:
{
  imports = [
    ../../homeManagerModules
  ];

  home.stateVersion = "24.05";
  # Main taskwarrior client
  programs.taskwarrior.config."recurrence" = "on";

  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1, 1920x1080@60.00Hz, 0x0, 1"
  ];
  services.hypridle.settings.listener = [
    {
      timeout = 600;
      on-timeout = "hyprlock";
    }
  ];

  home.packages = with pkgs; [
    aircrack-ng
  ];
}
