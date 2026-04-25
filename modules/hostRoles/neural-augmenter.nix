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
    inputs.niri-flake.nixosModules.niri
    ../cachix/niri-flake.nix
  ];

  options.myOptions.hostRoles.neural-augmenter = {
    enable = lib.mkEnableOption "workstation options";
    setupGrubOptions = lib.mkOption {
      description = "Set common grub options among our setups.";
      type = lib.types.bool;
      default = true;
    };
    verboseSpecialisation = lib.mkOption {
      description = "Generate a second specialisation printing much more verbose boot logs.";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
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
        rtkit.enable = true;
        pam.services.login.enableGnomeKeyring = true;
        ownAdditional.yubikey = true;
      };

      nix = {
        # Attempt to keep desktop devices more responsive during e.g. builds or optimization, at expense of longer build times
        daemonCPUSchedPolicy = "idle";
        daemonIOSchedClass = "idle";

        settings = {
          keep-outputs = true; # TODO: Needed?
          keep-derivations = true; # TODO: Needed?
          tarball-ttl = 7 * 24 * 3600; # Cache tars for seven days to improve dev experience
        };
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
        niri = {
          enable = true;
          package = pkgs.niri-unstable;
        };
        nix-ld.enable = true;
        chrysalis.enable = true;
      };

      services = {
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
        wivrn = {
          enable = true;
          openFirewall = true;
          steam.importOXRRuntimes = true;
        };
        displayManager.gdm = {
          enable = true;
          wayland = true;
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
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
        tuned.enable = true;
        tlp.enable = lib.mkForce false; # Conflicts with tuned
        upower.enable = true;
        gnome.evolution-data-server.enable = true; # Noctalia calendar support
        earlyoom.enable = true; # Out of memory management
        pulseaudio = {
          enable = false;
          zeroconf.discovery.enable = true; # Just for the port. Check if I have to do this
        };
        pipewire = {
          enable = true;
          pulse.enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          jack.enable = true;
          raopOpenFirewall = true;
          wireplumber.enable = true;
        };
      };

      hardware = {
        enableAllFirmware = lib.mkDefault true;
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Experimental = true;
              KernelExperimental = true;
              ControllerMode = "bredr"; # Problems with Bose
              FastConnectable = true;
              Class = "0x000100"; # Generic desktop TODO: Do I need object major class as well?
              JustWorksRepairing = true; # Security implications?
            };
          };
        };
        i2c.enable = true;
        sensor.iio.enable = true; # Autorotation
        opentabletdriver.enable = true; # May improve krita comfort
        rtl-sdr.enable = true;
      };
      environment.systemPackages = with pkgs; [
        lm_sensors
        nftables # vopono daemon
        inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
      ];

      # Don't garbage collect flake sources for our dev machines, for faster devflows. Copied from: https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
      # system.extraDependencies = let
      #   collectFlakeInputs = input:
      #     [input] ++ builtins.concatMap collectFlakeInputs (builtins.attrValues (input.inputs or {}));
      # in
      #   builtins.concatMap collectFlakeInputs (builtins.attrValues inputs);

      nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"]; # Required by Nheko to work
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
      documentation = {
        dev.enable = true;
        man = {
          mandoc.enable = true; # For some reason search is broken. Also in less.
          man-db.enable = false;
        };
      };

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

      systemd = {
        oomd.enable = true; # Out of memory management
        services = {
          NetworkManager-wait-online.enable = lib.mkForce false; # Issues with builds randomly failing
          vopono = {
            description = "Vopono VPN";
            after = ["network.target"];
            requires = ["network.target"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              # TODO: Setup separate user
              Type = "simple";
              ExecStart = "${lib.getExe pkgs.vopono} daemon";
              Restart = "on-failure";
              RestartSec = "2s";
              Environment = ["RUST_LOG=info"]; # Structured logging
            };
          };
        };
      };
      networking = {
        networkmanager = {
          enable = true;
          wifi.powersave = false;
        };
        ownWireguard.enable = true;
        firewall = {
          allowedTCPPorts = [
            22000 # SyncThing
          ];
          allowedUDPPorts = [
            21027 # SyncThing
            22000 # SyncThing
          ];
        };
      };
      niri-flake.cache.enable = false; # We manage it ourself for readability
      boot = {
        kernelParams = [
          "PREEMPT=FULL" # Attempt to improve bluetooth reliability
        ];
      };
    }
    (lib.mkIf cfg.setupGrubOptions {
      boot = {
        loader = {
          efi.canTouchEfiVariables = true;
          timeout = 2;
          grub = lib.mkDefault {
            enable = true;
            enableCryptodisk = true;
            efiSupport = true;
            copyKernels = true;
            fsIdentifier = "uuid";
            useOSProber = true;
            device = "nodev";
            extraEntries = ''
              menuentry "Poweroff" {
                halt
              }
              menuentry "Reboot" {
                reboot
              }
              menuentry "UEFI Setup" {
                fwsetup
              }
            '';
          };
        };
        initrd.systemd.enable = true;
      };
    })
    (lib.mkIf cfg.verboseSpecialisation {
      specialisation.verbose-boot.configuration.boot.consoleLogLevel = 7;
    })
  ]);
}
