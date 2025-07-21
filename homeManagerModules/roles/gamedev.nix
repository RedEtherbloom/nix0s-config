{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.gamedev;
in {
  options.myOptions.roles.gamedev.enable = mkOption {
    description = "Install tooling for game development.";
    type = lib.types.bool;
    default = osConfig.myOptions.roles.gamedev.enable;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      godot
    ];
  };
}
