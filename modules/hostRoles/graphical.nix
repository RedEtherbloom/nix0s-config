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
      piper-tts
    ];
    services.speechd = {
      enable = true;
      package = pkgs.speechd-patched;
    };
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        nerd-fonts.open-dyslexic
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
      ];
      fontconfig = {
        # The default of slight always felt to fuzzy
        hinting.style = "medium";
        defaultFonts = {
          serif = ["OpenDyslexic Nerd Font"];
          sansSerif = ["OpenDyslexic Nerd Font"];
          monospace = ["OpenDyslexicM Nerd Font Mono"];
          emoji = ["Noto Color Emoji"];
          # OpenDyslexic is very large by default. Too large for our taste.
          # TODO: No clear equivalent without stylix
          # sizes = {
          #   applications = 10;
          #   desktop = 8;
          #   popups = 8;
          #   terminal = 10;
          # };
        };
      };
    };
  };
}
