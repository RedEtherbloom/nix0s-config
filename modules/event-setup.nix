{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.event-setup;
in {
  options.myOptions.event-setup = {
    enable = lib.mkEnableOption "System options for chaos events";
    # TODO: Implement
    hardenSystem = lib.mkOption {
      description = "STUB: Enable some extra hardening options";
      type = lib.types.bool;
      default = true;
    };
    # TODO: Implement
    closeUnnecessaryPorts = lib.mkOption {
      description = "STUB: Enable some extra hardening options";
      type = lib.types.bool;
      default = true;
    };
    enablePixelflutClient = lib.mkOption {
      description = "Install pixelflut clients";
      type = lib.types.bool;
      default = true;
    };
    # TODO: Implement
    enablePixelflutServer = lib.mkOption {
      description = "STUB: Install and enable a pixelflut server";
      type = lib.types.bool;
      default = false;
    };
  };
  # TODO: Harden system
  # TODO: Disable open ports

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf cfg.enablePixelflutClient {
      environment.systemPackages = with pkgs; [
        sturmflut
      ];
    })
  ]);
}
