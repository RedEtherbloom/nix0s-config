{
  lib,
  inputs,
  self,
  specialArgs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-index-database.nixosModules.nix-index
    inputs.sops-nix.nixosModules.sops

    ../default.nix
  ];

  nixpkgs = {
    overlays = self.overlay.defaults;
    config = {
      allowUnfree = true;
      joypixels.acceptLicense = true;
    };
  };

  home-manager = {
    backupFileExtension = "home_manager_backup_move";
    extraSpecialArgs = specialArgs;
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
  };

  programs.nix-index-database.comma.enable = lib.mkDefault true;
}
