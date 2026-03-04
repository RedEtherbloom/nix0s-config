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
      default = false;
    };
    jjAutosync = lib.mkOption {
      description = "Automatically sync obsidian vaults using jujutsu.";
      type = lib.types.bool;
      default = false;
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
    (lib.mkIf cfg.jjAutosync {
      systemd.user = {
        services."jj-obsidian-autosync" = {
          Unit.Description = "Automatically sync default obsidian vault.";
          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.bash} ${config.xdg.userDirs.documents}/Obsidian/default/0B-Scripts/jj-sync.sh"; # Bash required, as android keeps popping the exectuable flag of the script
            WorkingDirectory = "${config.xdg.userDirs.documents}/Obsidian/default/";
          };
        };
        timers."jj-obsidian-autosync" = {
          Unit.Description = "Automatically sync default obsidian vault.";
          Timer = {
            Unit = "jj-obsidian-autosync";
            OnCalendar = "*:0/2"; # Trigger every 2 minutes
          };
          Install.WantedBy = ["timers.target"];
        };
      };
    })
  ]);
}
