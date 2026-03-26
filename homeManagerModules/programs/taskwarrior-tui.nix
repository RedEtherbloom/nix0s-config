{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.taskwarrior-tui;
in {
  options.myOptions.taskwarrior-tui = {
    enable = lib.mkOption {
      description = "Enable taskwarrior-tui";
      type = lib.types.bool;
      default = false;
    };
    package = lib.mkOption {
      description = "Taskwarrior-tui package to use";
      type = lib.types.package;
      default = pkgs.taskwarrior-tui;
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."task/taskwarrior-tui.rc".source = ../../dotfiles/taskwarrior/taskwarrior-tui.rc;

    xdg.configFile."task/taskwarrior-tui-shim".text = ''
      include ${config.xdg.configHome}/task/taskrc
      include ${config.home.homeDirectory}/${config.xdg.configFile."task/taskwarrior-tui.rc".target}
    '';

    home.packages = [
      (cfg.package.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.makeWrapper];

        postInstall =
          (oldAttrs.postInstall or "")
          + ''
            wrapProgram "$out/bin/taskwarrior-tui" --set TASKRC ${config.home.homeDirectory}/${config.xdg.configFile."task/taskwarrior-tui-shim".target}
          '';
      }))
    ];
  };
}
