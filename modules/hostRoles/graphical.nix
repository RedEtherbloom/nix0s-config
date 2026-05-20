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
    environment = let
      askpass_helper = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
    in {
      systemPackages = with pkgs; [
        appimage-run
        piper-tts
      ];
      sessionVariables = {
        SUDO_ASKPASS = askpass_helper;
        SSH_ASKPASS = askpass_helper;
      };
      variables.SSH_ASKPASS = lib.mkForce askpass_helper; # Required due to nix conflict
    };
    services.speechd = {
      enable = true;
      # package = pkgs.speechd-patched;
    };
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        nerd-fonts.open-dyslexic
        # E.g. material fonts
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
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
        };
      };
    };
    stylix = {
      # DE independent
      fonts = {
        monospace = {
          # TODO: Need a better mono font
          package = pkgs.nerd-fonts.open-dyslexic;
          name = "OpenDyslexicM Nerd Font Mono";
        };
        serif = {
          package = pkgs.nerd-fonts.open-dyslexic;
          name = "OpenDyslexic Nerd Font";
        };
        sansSerif = {
          package = pkgs.nerd-fonts.open-dyslexic;
          name = "OpenDyslexic Nerd Font";
        };
        sizes = {
          applications = 10;
          desktop = 8;
          popups = 8;
          terminal = 10;
        };
      };
    };
  };
}
