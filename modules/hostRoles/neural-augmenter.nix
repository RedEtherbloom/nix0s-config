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

    # TODO: Configure so that only e.g. grub but nothing else gets the pallet
    stylix = {
      enable = true;
      polarity = "dark";
      targets.grub.useImage = true;
    };

    programs = {
      # Open the ports for KDE-Connect as home manager sadly can't do it
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
      udev.packages = [pkgs.platformio-core];
      mullvad-vpn = {
        enable = true;
        # GUI
        package = pkgs.mullvad-vpn;
      };
    };

    environment.systemPackages = [pkgs.lm_sensors];

    # Don't garbage collect flake sources for our dev machines, for faster devflows. Copied from: https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
    system.extraDependencies = let
      collectFlakeInputs = input: [input] ++ builtins.concatMap collectFlakeInputs (builtins.attrValues (input.inputs or {}));
    in
      builtins.concatMap collectFlakeInputs (builtins.attrValues inputs);

    nixpkgs.config.permittedInsecurePackages = [
      # Required for Nheko to work
      "olm-3.2.16"
      "fluffychat-linux-1.27.0"
    ];

    virtualisation = {
      containers = {
        enable = true;
        registries.search = [
          "docker.io"
          "quay.io"
        ];
      };
      # TODO: Are UIDs for root separated by default?
      podman = {
        dockerSocket.enable = true;
        enable = true;
        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
      oci-containers.backend = "podman";
      waydroid.enable = true;
    };

    # TODO: Replace with home-manager option
    # This is a workaround for podman containers not starting correctly
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
