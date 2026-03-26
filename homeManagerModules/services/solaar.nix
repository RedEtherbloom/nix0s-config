{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.solaar;
in {
  options.myOptions.solaar = {
    enable = lib.mkOption {
      description = "Enable solaar";
      type = lib.types.bool;
      default = false;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.solaar;
    };
    autostart = {
      enable = lib.mkOption {
        description = "Autostart solaar";
        type = lib.types.bool;
        default = false;
      };
      windowMode = lib.mkOption {
        description = "Window mode to autostart in";
        type = lib.types.str;
        default = "hide";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [cfg.package];
    }
    (lib.mkIf cfg.autostart.enable (
      # TODO: Reuse this
      let
        name = "Solaar";
        out = pkgs.makeDesktopItem {
          inherit name;
          desktopName = name;
          icon = lib.strings.toLower name;
          exec = "${cfg.package}/bin/solaar -w ${cfg.autostart.windowMode}";
        };
      in {
        xdg.configFile."autostart/${name}.desktop".source = "${out}/share/applications/${name}.desktop";
      }
    ))
  ]);
}
