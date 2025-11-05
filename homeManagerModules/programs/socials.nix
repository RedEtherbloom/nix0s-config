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
      element-desktop
      fluffychat
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
      entries = [
        "${config.programs.nheko.package}/share/applications/nheko.desktop"
        "${config.programs.vesktop.package}/share/applications/vesktop.desktop"
        "${pkgs.telegram-desktop}/share/applications/org.telegram.desktop.desktop"
        "${pkgs.signal-desktop-bin}/share/applications/signal.desktop"
      ];
    };
  };
}
