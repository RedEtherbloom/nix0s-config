{
  config,
  inputs,
  osConfig,
  ...
}:
{
  imports = [
    inputs.nix-index-database.hmModules.nix-index
    inputs.sops-nix.homeManagerModules.sops

    ./programs/zsh.nix
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  xdg.userDirs.createDirectories = true;
  programs.home-manager.enable = true;

  programs.nix-index-database.comma.enable = osConfig.programs.nix-index-database.comma.enable;
}
