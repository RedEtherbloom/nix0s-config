{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in {
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  options.myOptions.hostRoles.neural-augmenter.enable = mkEnableOption "workstation options";

  config = mkIf cfg.enable {
    myOptions = {
      hostRoles.graphical.enable = lib.mkDefault true;
      office.enable = true;
      utilities = {
        rescueTools = true;
        binaryTools = true;
        pdfUtils = true;
        diskUtilities = true;
      };
      roles.i2p.enable = true;
    };
    security.ownAdditional.yubikey = true;

    stylix = {
      enable = true;
      polarity = "dark";
      targets.grub.useImage = true;
    };

    programs = {
      # Open the ports for KDE-Connect and install it here as well.
      # HM can't open ports sadly.
      kdeconnect = {
        enable = true;
        package = mkForce pkgs.kdePackages.kdeconnect-kde;
      };

      adb.enable = true;

      ausweisapp = {
        enable = true;
        openFirewall = true;
      };
    };

    services = {
      tailscale.enable = true;

      udev.packages = with pkgs; [
        platformio-core
      ];
    };

    environment.systemPackages = with pkgs; [
      # For some reason this keeps getting pulled in since stylix and then recycled by ghc
      ghc
      gnupg

      lm_sensors
    ];

    # Required for Nheko to work
    nixpkgs.config.permittedInsecurePackages = [
      "olm-3.2.16"
    ];

    virtualisation = {
      containers = {
        enable = true;
        registries.search = [
          "docker.io"
          "quay.io"
        ];
      };
      podman = {
        dockerSocket.enable = true;
        enable = true;
        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
      oci-containers = {
        backend = "podman";
      };
    };

    users.users."inf".subUidRanges = [
      {
        count = 65534;
        startUid = 100001;
      }
    ];
    users.users."inf".subGidRanges = [
      {
        count = 999;
        startGid = 1001;
      }
    ];
  };
}
