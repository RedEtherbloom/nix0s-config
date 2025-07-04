{
  config,
  inputs,
  lib,
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
    # TODO: Do we need a path of our overlayed nixpkgs?
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    myOptions.utilities.enable = lib.mkDefault true;
    security.pki.certificateFiles = [
      "${inputs.our-secrets}/secrets/root_ca/root_ca.crt"
    ];

    services = {
      fwupd.enable = lib.mkDefault true;
      fstrim.enable = lib.mkDefault true;
    };

    programs = {
      nix-index-database.comma.enable = lib.mkDefault true;
      # Fallback in case of e.g. broken system
      neovim = {
        enable = lib.mkDefault true;
        defaultEditor = lib.mkDefault true;
      };
    };
  };
}
