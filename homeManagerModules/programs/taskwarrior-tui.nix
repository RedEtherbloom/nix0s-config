{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.myOptions.taskwarrior-tui;
in
{
  options.myOptions.taskwarrior-tui = {
    enable = mkOption {
      description = "Enable taskwarrior-tui";
      type = with types; bool;
      default = false;
    };
    package = mkOption {
      description = "Taskwarrior-tui package to use";
      type = with types; package;
      default = pkgs.taskwarrior-tui;
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."task/taskwarrior-tui.rc".source = ../../dotfiles/taskwarrior/taskwarrior-tui.rc;

    programs.taskwarrior.extraConfig = ''
      include ${config.home.homeDirectory}/${config.xdg.configFile."task/taskwarrior-tui.rc".target}
    '';
  };
}
