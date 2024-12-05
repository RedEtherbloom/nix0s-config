{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.obsidian;
in {
  options.myOptions.obsidian = {
    enable = mkOption {
      description = "Enable Obsidian";
      type = with types; bool;
      default = false;
    };
    enableSync = mkOption {
      description = "Enable the standard obsidian-git integration";
      type = with types; bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
    ];
  };
}
