{
  config,
  lib,
  inputs,
  pkgs,
  secrets,
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
      roles = {
        i2p.enable = true;
        vtubing.enable = true;
      };
    };
    security.ownAdditional.yubikey = true;

    # Attempt to keep desktop devices more responsive during e.g. builds or optimization, at expense of longer build times
    nix = {
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
    };

    # TODO: Configure so that only e.g. grub but nothing else gets the pallet
    stylix = {
      enable = true;
      polarity = "dark";
      targets.grub = {
        enable = true;
        useWallpaper = true;
      };
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
      hyprland.enable = true; 
    };

    services = {
      tailscale.enable = true;
      # Broken as of 01.08.2025
      # udev.packages = [pkgs.platformio-core];
      mullvad-vpn = {
        enable = true;
        # GUI
        package = pkgs.mullvad-vpn;
      };
      colord.enable = true;
      samba.enable = true;
      xserver.wacom.enable = true;
      flatpak.enable = true;
      hardware.bolt.enable = true;
      blueman.enable = true;
      # Needed for Hyprland
      gnome.gnome-keyring.enable = true;
    };

    hardware = {
      # Autorotation
      sensor.iio.enable = true;
      # May improve krita comfort
      opentabletdriver.enable = true;
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
    zramSwap.enable = true;

    virtualisation = {
      containers = {
        enable = true;
        registries.search = [
          "docker.io"
          "quay.io"
          # Google mirror
          "mirror.gcr.io"
        ];
      };
      podman = {
        autoPrune.enable = true;
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

    sops.secrets."registry/dockerhub/password".sopsFile = "${secrets}/secrets/services/docker.yaml";
    # Needed for podman
    users.users."inf".autoSubUidGidRange = true;
    documentation.dev.enable = true;
  };
}
