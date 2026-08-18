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
    # cache.nixos.org is implicitly imported
    ../cachix/nix-community.nix
  ];

  options.myOptions.hostRoles.base.enable = lib.mkOption {
    description = "The base role required by pretty much all hosts";
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    myOptions.utilities.enable = lib.mkDefault true;

    system.build.nixos-rebuild = lib.mkForce pkgs.lixPackageSets.latest.nixos-rebuild-ng;
    security.pki.certificateFiles = ["${secrets}/secrets/root_ca/root_ca.crt"];

    services = {
      fwupd.enable = lib.mkDefault true;
      fstrim.enable = lib.mkDefault true;
    };

    programs = {
      nix-index-database.comma.enable = lib.mkDefault true;
      # Fallback in case of e.g. broken system
      neovim = {
        enable = true;
        defaultEditor = true;
      };
      fish.enable = true;
    };
    users.defaultUserShell = pkgs.fish;

    # See: https://github.com/nix-community/home-manager/blob/master/modules/misc/xdg-portal.nix
    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];

    stylix = {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
      targets.gtksourceview.enable = lib.mkForce false; # See: https://github.com/nix-community/stylix/issues/1686
    };

    nix = {
      package = pkgs.lixPackageSets.latest.lix;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operator"
        ];
        trusted-users = ["root" "@wheel" "inf"];
      };
      gc = {
        automatic = lib.mkDefault true;
        dates = "daily";
        options = "--delete-older-than 5d";
      };
      optimise = {
        automatic = lib.mkDefault true;
        dates = ["15:00"];
      };
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      tmp.cleanOnBoot = true;
    };
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
