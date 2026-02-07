{
  config,
  inputs,
  lib,
  secrets,
  pkgs,
  ...
}: let
  cfg = config.myOptions.hostRoles.base;
in {
  imports = [
    ../binary-cache
  ];

  options.myOptions.hostRoles.base.enable = lib.mkOption {
    description = "The base role required by pretty much all hosts";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    myOptions.utilities.enable = lib.mkDefault true;
    security.pki.certificateFiles = [
      "${secrets}/secrets/root_ca/root_ca.crt"
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

    # See: https://github.com/nix-community/home-manager/blob/master/modules/misc/xdg-portal.nix
    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
  };
}
