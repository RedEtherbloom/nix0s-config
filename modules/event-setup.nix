{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.event-setup;
in {
  options.myOptions.event-setup = {
    enable = mkEnableOption "System options for chaos events";
    # TODO: Implement
    hardenSystem = mkOption {
      description = "STUB: Enable some extra hardening options";
      type = types.bool;
      default = true;
    };
    # TODO: Implement
    closeUnnecessaryPorts = mkOption {
      description = "STUB: Enable some extra hardening options";
      type = types.bool;
      default = true;
    };
    enablePixelflutClient = mkOption {
      description = "Install pixelflut clients";
      type = types.bool;
      default = true;
    };
    # TODO: Implement
    enablePixelflutServer = mkOption {
      description = "STUB: Install and enable a pixelflut server";
      type = types.bool;
      default = false;
    };
  };
  # TODO: Harden system
  # TODO: Disable open ports

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.enablePixelflutClient {
      home-manager.sharedModules = [
        {
          home.packages = with pkgs; [
            sturmflut
          ];
        }
      ];
    })
  ]);
}
