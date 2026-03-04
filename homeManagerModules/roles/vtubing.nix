{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.roles.vtubing;
in {
  options.myOptions.roles.vtubing.enable = lib.mkOption {
    description = "Various vtubing software and utilities.";
    type = lib.types.bool;
    default = osConfig.myOptions.roles.vtubing.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      openseeface
    ];
    programs.mangohud.enable = true;
  };
}
