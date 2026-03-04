{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.gamedev;
in {
  options.myOptions.roles.gamedev.enable = lib.mkOption {
    description = "Install tooling for game development.";
    type = lib.types.bool;
    default = osConfig.myOptions.roles.gamedev.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      godot
    ];
  };
}
