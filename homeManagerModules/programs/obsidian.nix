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
    (mkIf cfg.pullShortcut {
      home.packages = [];
      programs.plasma.hotkeys.commands = {
        "obsidianPullShortcut" = {
          command = let
            command = pkgs.writeShellScript "obsidianPullShortcut.sh" ''
              cd ~/Documents/Obsidian/default
              gprav
            '';
          in "${command}";
          keys = ["meta+o"];
          comment = "Pull and rebase Obsidian vault";
        };
      };
    })
  ]);
}
