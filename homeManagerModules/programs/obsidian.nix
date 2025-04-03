{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.obsidian;
  vars = import ../variables.nix {inherit config osConfig pkgs;};
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
        lazygitSyncVaultDefault = vars.lazygitCommandWindow "lazygitSyncVaultDefault" "~/Documents/Obsidian/default";
        syncObsidianPhone = pkgs.writeShellApplication {
          name = "syncObsidianPhone";
          runtimeInputs = [pkgs.libnotify];
          excludeShellChecks = [
            # Bash variables in single-quotes.
            "SC2016"
          ];
          text = ''
            set -e

            # Pull first for immediate sync
            ${lazygitSyncVaultDefault.name}
            # Sync with phone. Has $ variables in single quotes allowed.
            kitten ssh user@10.69.0.5 -p 8022 -t '/data/data/com.termux/files/home/scripts/obsidian-sync.sh && cd /data/data/com.termux/files/home/storage/shared/Documents/Obsidian/default && exit || lazygit' 2&>1 | tee /tmp/kitty_ssh_log || notify-send "Could not reach phone for Obsidian sync" --expire-time=8000
            # Try to merge any changes
            ${lazygitSyncVaultDefault.name}
          '';
        };
      in {
        home.packages = [
          lazygitSyncVaultDefault
          syncObsidianPhone
        ];
        programs.plasma.hotkeys.commands = {
          "obsidian-pull-shortcut" = {
            # .name to avoid the path breaking after rebuild until logout
            command = syncObsidianPhone.name;
            keys = ["meta+o"];
            comment = "Pull and rebase Obsidian vault, drop into lazygit on failure";
          };
        };
      }))
  ]);
}
