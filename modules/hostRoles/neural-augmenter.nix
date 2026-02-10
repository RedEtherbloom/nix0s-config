{
  config,
  lib,
  inputs,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in {
  imports = [
    inputs.stylix.nixosModules.stylix
    ../binary-cache/hyprland.nix
  ];

  options.myOptions.hostRoles.neural-augmenter.enable = lib.mkEnableOption "workstation options";

  config = lib.mkIf cfg.enable {
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
    security = {
      pam.services.login.enableGnomeKeyring = true;
      ownAdditional.yubikey = true;
    };

    # Attempt to keep desktop devices more responsive during e.g. builds or optimization, at expense of longer build times
    nix = {
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
    };

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
        package = lib.mkForce pkgs.kdePackages.kdeconnect-kde;
      };
      ausweisapp = {
        enable = true;
        openFirewall = true;
      };
      extra-container.enable = true;
      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };
    };

    services = {
      tailscale.enable = true; # TODO: Read up on tailscale
      udev.packages = with pkgs; [
        platformio-core
        probe-rs-tools
      ];
      mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn; # Contains GUI
      };
      colord.enable = true;
      samba.enable = true;
      xserver.wacom.enable = true;
      flatpak.enable = true;
      hardware = {
        bolt.enable = true;
        openrgb = {
          enable = true;
          package = pkgs.openrgb-with-all-plugins;
        };
      };
      blueman.enable = true;
      upower.enable = true; # HyprDynamicMonitors dependency
      wivrn = {
        enable = true;
        openFirewall = true;
        defaultRuntime = true;
        steam.importOXRRuntimes = true;
      };
      displayManager.sddm = {
        wayland.enable = true;
        enable = true;
        theme = "sddm-astronaut-theme";
        package = lib.mkForce pkgs.sddm-fallback-patched;
        extraPackages = [pkgs.kdePackages.qtmultimedia];
      };
      ollama = {
        enable = true;
        environmentVariables.OLLAMA_ORIGINS = "*"; # Fix CORS errors on localhost
        loadModels = [
          "qwen3:1.7b"
          "qwen3:4b"
        ];
      };
      nextjs-ollama-llm-ui = {
        enable = true;
        port = 8154; # Reasonably close to ollama
      };
    };

    hardware = {
      sensor.iio.enable = true; # Autorotation
      opentabletdriver.enable = true; # May improve krita comfort
    };
    environment.systemPackages = with pkgs; [
      lm_sensors
      (sddm-astronaut.override {embeddedTheme = "black_hole";})
    ];

    # Don't garbage collect flake sources for our dev machines, for faster devflows. Copied from: https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
    system.extraDependencies = let
      collectFlakeInputs = input:
        [input] ++ builtins.concatMap collectFlakeInputs (builtins.attrValues (input.inputs or {}));
    in
      builtins.concatMap collectFlakeInputs (builtins.attrValues inputs);

    nixpkgs.config.permittedInsecurePackages = [
      "olm-3.2.16" # Required for Nheko to work
    ];
    zramSwap.enable = true;

    virtualisation = {
      containers = {
        enable = true;
        registries.search = [
          "docker.io"
          "quay.io"
          "mirror.gcr.io" # Google mirror
        ];
      };
      podman = {
        enable = true;
        dockerSocket.enable = true;
        autoPrune.enable = true;
        dockerCompat = true; # Docker alias
        defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
      };
      oci-containers.backend = "podman";
      waydroid.enable = true;
    };

    sops.secrets."registry/dockerhub/password".sopsFile = "${secrets}/secrets/services/docker.yaml";
    users = {
      users."inf" = {
        autoSubUidGidRange = true; # Needed for podman
        extraGroups = [
          "plugdev"
        ];
      };
      groups.plugdev = {};
    };
    documentation.dev.enable = true;

    # See: https://github.com/NixOS/nixpkgs/issues/409986
    environment.etc."xdg/menus/applications.menu".source = let
      applications-menu = "menu/desktop/plasma-applications.menu";
      src = pkgs.fetchFromGitHub {
        owner = "KDE";
        repo = "plasma-workspace";
        tag = "v${pkgs.kdePackages.plasma-workspace.version}";
        hash = "sha256-BFjGHITdV29B4h6UhhK/1kB+Gwuq+AhFnyjTSofZZuo=";
        sparseCheckout = ["${applications-menu}"];
      };
    in "${src}/${applications-menu}";

    networking.firewall = { 
      allowedTCPPorts = [
        22000 # SyncThing
      ];
      allowedUDPPorts = [
        21027 # SyncThing
        22000 # SyncThing
      ];
    };
  };
}
