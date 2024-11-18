{ config, lib, ... }:
with lib;
let
  cfg = config.myOptions.taskwarrior-tui;
in
{
  options.myOptions.taskwarrior-rc = {
    enable = mkOption {
      description = "Enable taskwarrior-rc";
      type = with types; bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."task/taskwarrior-tui.rc".source = ../../dotfiles/taskwarrior/taskwarrior-tui.rc;

    programs.taskwarrior.extraConfig = ''
      include ${config.home.homeDirectory}/${config.xdg.configFile."task/taskwarrior-tui.rc".target}
    '';
  };
}
