{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.roles.vtubing;
in {
  options.myOptions.roles.vtubing.enable = mkOption {
    description = "Various vtubing software and utilities.";
    type = with types; bool;
    default = osConfig.myOptions.roles.vtubing.enable;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      openseeface
    ];
    programs.mangohud.enable = true;
  };
}
