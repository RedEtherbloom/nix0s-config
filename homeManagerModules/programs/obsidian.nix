{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.obsidian;
  lazygitSyncVaultDefault = vars.lazygitCommandWindow "SyncVaultDefault" "~/Documents/Obsidian/default";
  syncObsidianPhone = pkgs.writeShellApplication {
    name = "syncObsidianPhone";
    runtimeInputs = [pkgs.libnotify];
    excludeShellChecks = [
      # Bash variables in single-quotes.
      "SC2016"
    ];
    text = ''
      # Pull first for immediate sync
      ${lazygitSyncVaultDefault.name}
      # Sync with phone. Has $ variables in single quotes allowed.
      ssh user@10.69.0.5 -p 8022 -t '/data/data/com.termux/files/home/scripts/obsidian-sync.sh && cd /data/data/com.termux/files/home/storage/shared/Documents/Obsidian/default && exit || lazygit' 2>&1 | tee /tmp/kitty_ssh_log || notify-send "Could not reach phone for Obsidian sync" --expire-time=8000
      # Try to merge any changes
      ${lazygitSyncVaultDefault.name}
    '';
  };
  vars = import ../variables.nix {inherit config osConfig pkgs;};
in {
  options.myOptions.obsidian = {
    enable = lib.mkOption {
      description = "Enable Obsidian";
      type = lib.types.bool;
      default = false;
    };
    enableSync = lib.mkOption {
      description = "Enable the standard obsidian-git integration";
      type = lib.types.bool;
      default = false;
    };
    pullShortcut = lib.mkOption {
      description = "Shortcut to pull and rebase remote changes";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [pkgs.obsidian];
    }
    (lib.mkIf cfg.pullShortcut {
      home.packages = [
        lazygitSyncVaultDefault
        syncObsidianPhone
      ];
    })
  ]);
}
