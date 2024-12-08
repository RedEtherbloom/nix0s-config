{
  config,
  lib,
  inputs,
  self,
  specialArgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.base;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-index-database.nixosModules.nix-index
    inputs.sops-nix.nixosModules.sops
  ];

  options.myOptions.hostRoles.base.enable = mkOption {
    description = "The base role required by pretty much all hosts";
    type = with types; bool;
    default = true;
  };

  config = mkIf cfg.enable {
    nixpkgs = {
      overlays = self.overlay.defaults;
      config = {
        allowUnfree = true;
      };
    };

    # Supposedly required by nixd
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    home-manager = {
      backupFileExtension = "home_manager_backup_move";
      extraSpecialArgs = specialArgs;
      useGlobalPkgs = true;
      useUserPackages = true;
    };

    programs.nix-index-database.comma.enable = lib.mkDefault true;

    security.pki.certificateFiles = [
      "${inputs.our-secrets}/secrets/root_ca/root_CA.crt"
    ];

    myOptions.utilities.enable = true;

    services.fwupd.enable = true;
    services.fstrim.enable = true;

    # TODO: Figure out how to merge this with home-manager
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
