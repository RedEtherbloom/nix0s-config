{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.obsidian;
  vars = import ../variables.nix {inherit config lib osConfig pkgs;};
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
    pullShortcut = mkOption {
      description = "Shortcut to pull and rebase remote changes";
      type = with types; bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        obsidian
      ];
    }
    (mkIf cfg.pullShortcut
      (let
        obsidian-pull-shortcut = vars.lazygitCommandWindow "obsidian-default" "~/Documents/Obsidian/default";
      in {
        home.packages = [obsidian-pull-shortcut];
        programs.plasma.hotkeys.commands = {
          "obsidian-pull-shortcut" = {
            command = obsidian-pull-shortcut;
            keys = ["meta+o"];
            comment = "Pull and rebase Obsidian vault, drop into lazygit on failure";
          };
        };
      }))
  ]);
}
