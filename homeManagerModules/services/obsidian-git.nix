# NOTE: THIS MODULE IS DEPRECATED IN FAVOR OF THE OBSIDIAN-GIT PLUGIN
{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.obsidian;
  vars = import ../variables.nix {inherit config osConfig;};

  DEFAULT_SYNC_INTERVAL = 900;
  OBSIDIAN_VAULTS = "Obsidian";

  generate_vault_dir_path = config.xdg.userDirs.documents + "/" + OBSIDIAN_VAULTS;

  generate_repository = vault-name: {
    path = generate_vault_dir_path + "/${vault-name}/";
    interval = DEFAULT_SYNC_INTERVAL;
    uri = "ssh://${config.home.username}@${vars.data-server-ip}${vars.own-hm-data-directory}/obsidian-vaults/${vault-name}";
  };
in {
  config = mkIf cfg.enableSync {
    # TODO: Needs to be reloaded after config changes
    services.git-sync = {
      enable = true;
      repositories = {
        obsidian-default-vault = generate_repository "default";
      };
    };
  };
}
