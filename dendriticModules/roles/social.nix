{self, ...}: {
  flake.homeModules.social = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.flatpak
    ];

    options.roles.social.autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Autostart socials applications";
    };
    config = {
      home.packages = [
        pkgs.telegram-desktop
        pkgs.signal-desktop
        pkgs.threema-desktop

        pkgs.mumble
        pkgs.beeper
      ];

      programs.vesktop.enable = true;

      services.flatpak.packages = [
        {
          appId = "moe.sable.client";
          origin = "flathub";
        }
      ];
      xdg.autostart = lib.mkIf config.roles.social.autostart {
        enable = true;
        entries = let
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
          "${vesktop-start-minimized}/share/applications/${vesktop-start-minimized.name}"
          "${telegram-desktop-in-tray}/share/applications/${telegram-desktop-in-tray.name}"
          "${signal-non-kde}/share/applications/${signal-non-kde.name}"
          "${pkgs.beeper}/share/applications/beepertexts.desktop"
        ];
      };
    };
  };
}
