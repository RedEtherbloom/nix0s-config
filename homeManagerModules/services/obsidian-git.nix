{
  config,
  lib,
  osConfig,
  ...
}:
let
  vars = import ../variables.nix { inherit config osConfig; };

  # A hour sounds like a good preset
  DEFAULT_SYNC_INTERVAL = 3600;
  # Spaces in name blocked by this: https://github.com/simonthum/git-sync/issues/33
  OBSIDIAN_VAULTS = "Obsidian";

  generate_vault_dir_path = config.xdg.userDirs.documents + "/" + OBSIDIAN_VAULTS;

  generate_repository = vault-name: {
    path = (generate_vault_dir_path + "/${vault-name}/");
    interval = DEFAULT_SYNC_INTERVAL;
    uri = "ssh://${config.home.username}@${vars.data-server-ip}${vars.own-hm-data-directory}/obsidian-vaults/${vault-name}";
  };
in
{
  services.git-sync = {
    enable = true;
    repositories = {
      obsidian-default-vault = generate_repository "default";
    };
  };
}
