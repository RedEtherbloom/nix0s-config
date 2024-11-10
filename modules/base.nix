{ lib, inputs, ... }:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    inputs.sops-nix.nixosModules.sops

    ./default.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "home_manager_backup_move";
  home-manager.verbose = true;

  programs.nix-index-database.comma.enable = lib.mkDefault true;
}
