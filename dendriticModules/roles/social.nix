{
  flake.homeModules.socials = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.roles.social.autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Autostart socials applications";
    };
    home.packages = with pkgs; [
      telegram-desktop
      signal-desktop
      threema-desktop

      mumble
      beeper
    ];
    programs = {
      nheko.enable = true;
      vesktop = {
        enable = true;
        package = pkgs.vesktop-rtc-fix;
      };
    };
    xdg.autostart = lib.mkIf config.roles.socials.autostart {
      enable = true;
      entries = let
        # signal-kde = pkgs.makeDesktopItem {
        #   name = "signal-desktop-kde-autostart";
        #   desktopName = "Signal Desktop";
        #   onlyShowIn = ["KDE"];
        #   exec = "${pkgs.gtk3}/bin/gtk-launch signal %U";
        # };
        signal-non-kde = pkgs.makeDesktopItem {
          name = "signal-desktop-non-kde-autostart";
          desktopName = "Signal Desktop";
          notShowIn = ["KDE"];
          exec = "signal-desktop --password-store=gnome-libsecret %U";
        };
        telegram-desktop-in-tray = pkgs.makeDesktopItem {
          name = "telegram-intray-autostart";
          desktopName = "Telegram Desktop Autostart in tray";
          exec = "${pkgs.telegram-desktop}/bin/Telegram -startintray -- %u";
        };
        vesktop-start-minimized = pkgs.makeDesktopItem {
          name = "vesktop-start-minimized";
          desktopName = "Start Vesktop minimized";
          exec = "${config.programs.vesktop.package}/bin/vesktop --start-minimized %U";
        };
      in [
        "${config.programs.nheko.package}/share/applications/nheko.desktop"
        "${vesktop-start-minimized}/share/applications/${vesktop-start-minimized.name}"
        "${telegram-desktop-in-tray}/share/applications/${telegram-desktop-in-tray.name}"
        # "${signal-kde}/share/applications/${signal-kde.name}"
        "${signal-non-kde}/share/applications/${signal-non-kde.name}"
        "${pkgs.beeper}/share/applications/beepertexts.desktop"
      ];
    };
  };
}
