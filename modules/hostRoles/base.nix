{
  config,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.base;
in {
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  options.myOptions.hostRoles.base.enable = mkOption {
    description = "The base role required by pretty much all hosts";
    type = with types; bool;
    default = true;
  };

  config = mkIf cfg.enable {
    # Supposedly required by nixd
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    programs.nix-index-database.comma.enable = lib.mkDefault true;

    security.pki.certificateFiles = [
      "${inputs.our-secrets}/secrets/root_ca/root_ca.crt"
    ];

    myOptions.utilities.enable = true;

    services.fwupd.enable = true;
    services.fstrim.enable = true;

    # TODO: Figure out how to merge this with home-manager
    programs.neovim = {
      enable = lib.mkDefault true;
      defaultEditor = lib.mkDefault true;
    };
  };
}
