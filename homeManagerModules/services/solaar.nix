{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.solaar;
in {
  options.myOptions.solaar = {
    enable = mkOption {
      description = "Enable solaar";
      type = with types; bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.solaar;
    };
    autostart = {
      enable = mkOption {
        description = "Autostart solaar";
        type = types.bool;
        default = false;
      };
      windowMode = mkOption {
        description = "Window mode to autostart in";
        type = types.str;
        default = "hide";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [cfg.package];
    }
    (mkIf cfg.autostart.enable (
      # TODO: Reuse this
      let
        name = "Solaar";
        out = pkgs.makeDesktopItem {
          inherit name;
          desktopName = name;
          icon = strings.toLower name;
          exec = "${cfg.package}/bin/solaar -w ${cfg.autostart.windowMode}";
        };
      in {
        xdg.configFile."autostart/${name}.desktop".source = "${out}/share/applications/${name}.desktop";
      }
    ))
  ]);
}
