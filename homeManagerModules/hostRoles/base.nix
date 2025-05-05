{
  config,
  lib,
  inputs,
  osConfig,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.base;
in {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    inputs.sops-nix.homeManagerModules.sops
  ];

  options.myOptions.hostRoles.base.enable = mkOption {
    description = "base options for hm settings";
    type = with types; bool;
    default = osConfig.myOptions.hostRoles.base.enable;
  };

  config = mkIf cfg.enable {
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    xdg.userDirs.createDirectories = true;
    programs.home-manager.enable = true;

    programs.nix-index-database.comma.enable = osConfig.programs.nix-index-database.comma.enable;
  };
}
