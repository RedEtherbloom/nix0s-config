{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.hostRoles.graphical;
  appimage-run = pkgs.appimage-run.override {
    extraPkgs = pkgs:
    # Potentially may need more dependencies
      with pkgs; [
        ffmpeg
        imagemagick
        fuse
      ];
  };
in {
  options.myOptions.hostRoles.graphical.enable = lib.mkEnableOption "graphical session settings";

  config = lib.mkIf cfg.enable {
    myOptions = {
      roles.ssdp.enable = lib.mkDefault true;
      hostRoles.base.enable = lib.mkDefault true;
    };

    programs.appimage = {
      binfmt = true;
      package = appimage-run;
    };

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
