{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.socials;
in {
  options.myOptions.socials = {
    enable = lib.mkOption {
      description = "Enable socials";
      type = lib.types.bool;
      default = false;
    };
    autostart = lib.mkOption {
      description = "Enable autostart for socials";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      telegram-desktop
      signal-desktop
      threema-desktop

      mumble
    ];
    programs = {
      nheko.enable = true;
      vesktop.enable = true;
    };
    xdg.autostart = lib.mkIf cfg.autostart {
      enable = true;
      entries = let
        signal-kde = pkgs.makeDesktopItem {
          name = "signal-desktop-kde-autostart";
          desktopName = "Signal Desktop";
          onlyShowIn = ["KDE"];
          exec = "${pkgs.gtk3}/bin/gtk-launch signal %U";
        };
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
        "${signal-kde}/share/applications/${signal-kde.name}"
        "${signal-non-kde}/share/applications/${signal-non-kde.name}"
      ];
    };

    stylix.targets.vesktop.enable = false;
  };
}
