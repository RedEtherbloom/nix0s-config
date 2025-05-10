{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.graphical;
in {
  options.myOptions.hostRoles.graphical.enable = mkEnableOption "graphical session settings";

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;

    programs.appimage.binfmt = true;

    environment.systemPackages = with pkgs; [
      appimage-run
      nerd-fonts.open-dyslexic
    ];

    fonts.fontDir.enable = true;

    stylix.fonts = {
      serif = {
        package = pkgs.nerd-fonts.open-dyslexic;
        name = "OpenDyslexic Nerd Font";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.open-dyslexic;
        name = "OpenDyslexic Nerd Font";
      };
      monospace = {
        package = pkgs.nerd-fonts.open-dyslexic;
        name = "OpenDyslexicM Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      # OpenDyslexic is very large by default. Too large for our taste.
      sizes = {
        applications = 10;
        desktop = 8;
        popups = 8;
        terminal = 10;
      };
    };
  };
}
