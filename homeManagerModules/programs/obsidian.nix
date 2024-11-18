{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.myOptions.obsidian;
in
{
  options.myOptions.obsidian = {
    enable = mkOption {
      description = "Enable Obsidian";
      type = with types; boolean;
      default = false;
    };
    enableSync = mkOption {
      description = "Enable the standard obsidian-git integration";
      type = with types; boolean;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        obsidian
      ];
    }
    (mkIf cfg.enableSync {
      
    })
  ]);
}
