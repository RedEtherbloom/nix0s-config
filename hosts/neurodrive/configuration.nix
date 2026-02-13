{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}: {
  imports =
    [
      ../../modules
      ../../modules/common/ssh.nix
      ../../modules/hdd.nix
      # TODO: Remove once hm sops-nix supports secrets
      ../../modules/common/taskwarrior-secrets.nix
      ../../modules/binary-cache/cuda-maintainers.nix

      ./hardware-configuration.nix
    ]
    ++ (with inputs.nixos-hardware.nixosModules; [
      common-pc
      common-pc-ssd
      common-hidpi
      # Xeon CPU
      common-cpu-intel-cpu-only
      common-gpu-nvidia-nonprime
    ]);

  system.stateVersion = "24.05";

  nix.settings = {
    # Logical cores: 12
    max-jobs = 8;
    cores = 8;
  };
  nixpkgs.config = {
    cudaSupport = true;
    cudnnSupport = true;
    cudaCapabilities = ["7.5"];
  };

  boot = {
    binfmt.emulatedSystems = ["aarch64-linux"];
    # Hoping to increase audio quality/reliability
    kernelParams = ["btusb.enable_autosuspend=n"];
    kernelModules = [
      "coretemp"
      "nct6775"
    ];
    initrd = {
      availableKernelModules = [
        # TODO: Lookup remainng crypto models
        "aesni_intel"
      ];
      systemd.enable = true;
      luks.devices = {
        "nixos-root" = {
          device = "/dev/disk/by-uuid/36e0d35b-4ac0-41a9-a8a9-15a07696c2c4";
          crypttabExtraOpts = ["fido2-device=auto"];
          bypassWorkqueues = true;
          # Weakens security
          allowDiscards = true;
        };
        "nixos-swap" = {
          device = "/dev/disk/by-uuid/69bd8d21-1c47-4aff-8533-31bf2610c181";
          # Necessary?
          crypttabExtraOpts = ["fido2-device=auto"];
          bypassWorkqueues = true;
          # Weakens security
          allowDiscards = true;
        };
      };
    };
  };
  environment.etc."crypttab" = {
    mode = "0600";
    text = ''
      cryptostorage1 UUID=580fff0d-1c11-442b-9601-839ed7f712d0 ${config.sops.secrets.cryptostorage.path}
      cryptostorage2 UUID=33c2f6e5-41a4-46fc-86c5-c3b2d46646fe ${config.sops.secrets.cryptostorage.path}
      restic_storage1 UUID=b43181b9-5377-4e2b-a66e-5714ca9b0beb ${config.sops.secrets.cryptostorage.path}
    '';
  };
  fileSystems = {
    "/mnt/windows_data" = {
      device = "/dev/disk/by-uuid/587488F374FD109E";
      fsType = "ntfs3";
      options = ["nofail"];
    };
    "/mnt/restic_data" = {
      device = "/dev/mapper/restic_storage--4096bsize-restic_storage";
      fsType = "ext4";
      options = ["nofail"];
    };
    "/mnt/cryptostorage" = {
      device = "/dev/mapper/cryptostorage--512bsize-cryptostorage";
      fsType = "ext4";
      options = ["nofail"];
    };
  };

  systemd.services = {
    i2p = {
      after = [
        "local-fs.target"
        "cryptsetup.target"
      ];
      serviceConfig.WorkingDirectory = lib.mkForce config.users.users.i2p.home;
    };
  };

  networking = {
    hostName = "neurodrive";
    networkmanager.enable = true;
    interfaces."enp0s25".wakeOnLan.enable = true;

    firewall = {
      allowedTCPPorts =
        [
          4333 # Feishin remote control port
          4713 # Pulseaudio Network Sharing. Probably only needed for publish
          8123 # Home Assistant
          10222 # Taskwarrior
          27062 # SteamVR
          (lib.mkIf config.myOptions.roles.ssdp.enable 40000)
          config.services.paperless.port
          (lib.strings.toInt config.services.restic.server.listenAddress)
          config.services.tabby.port
          (lib.strings.toInt config.virtualisation.oci-containers.containers.esphome.environment.PORT)
        ]
        ++ (lib.lists.concatMap (el: [el.port]) config.services.mosquitto.listeners);
      allowedUDPPorts = [
        9944 # SteamVR
        27062 # SteamVR
      ];
    };
  };

  services = {
    xserver.videoDrivers = ["nvidia"];
    paperless = rec {
      enable = true;
      consumptionDirIsPublic = true;
      address = "0.0.0.0";
      domain = address;
      port = 8150;
      passwordFile = config.sops.secrets."paperless/admin_password".path;
      settings = {
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_LANGUAGE = "eng+deu";
        # Sadly incompatible with deskew
        PAPERLESS_OCR_MODE = "redo";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
      };
    };
    ollama = {
      package = pkgs.ollama-cuda;
      host = "0.0.0.0";
      openFirewall = true;
    };
    nextjs-ollama-llm-ui = {
      # May need to set CORS in ollama variables for VPN to work
      hostname = "${config.networking.ownWireguard.hosts.neurodrive.mainIP}";
    };
    mosquitto = {
      enable = true;
      logType = ["all"];
      listeners = [
        # TODO: Add encrypted listener
        {
          port = 1883;
          # By default everyone may read everything
          acl = ["pattern read #"];
          users = {
            root = {
              acl = ["readwrite #"];
              passwordFile = config.sops.secrets."mosquitto/users/root".path;
            };
            client = {
              # R/W to everything for now until I figure out the proper settings
              acl = ["readwrite #"];
              passwordFile = config.sops.secrets."mosquitto/users/client".path;
            };
          };
          settings = {
            allow_anonymous = false;
          };
        }
      ];
    };
    matter-server = {
      enable = true;
      openFirewall = true;
      logLevel = "debug";
    };
    restic.server = {
      enable = true;
      privateRepos = true;
      dataDir = "/mnt/restic_data/restic";
      listenAddress = "8193";
      extraFlags = [
        "--tls"
        "--tls-key"
        config.sops.secrets."restic_server/restic.key".path
        "--tls-cert"
        "${secrets}/secrets/neurodrive/restic_server/restic.crt"
      ];
    };
    systembus-notify.enable = lib.mkForce true;
    smartd = {
      enable = true;
      autodetect = true;
      notifications.systembus-notify.enable = true;
      # Short daily self-test, long weekly exteded test
      # https://search.nixos.org/options?channel=unstable&show=services.smartd.defaults.monitored
      defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
    };
    udev.extraRules = ''
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee-ap"
      ACTION=="add", SUBSYSTEM=="tty", ENV{DEVLINKS}=="*/dev/zigbee-ap*", RUN+="${config.systemd.package}/bin/systemctl restart podman-homeassistant.service"
    '';
    # Disabled due to invidious-companion needing packaging first https://github.com/NixOS/nixpkgs/issues/415116
    # invidious = {
    #   enable = true;
    #   # domain = "${config.networking.ownWireguard.hosts.neurodrive.mainIP}";
    #   port = invidiousSigHelperPort + 1;
    #   # Personal and work/music only
    #   serviceScale = 2;
    #   nginx.enable = true;
    #   # Faster loading speeds
    #   http3-ytproxy.enable = true;
    #   # Sig helper is broken and should be replaced with the companion app. additionally google seems to often shadownban(inabilit to load videos after a while).
    # };
    # # Individious
    # nginx.virtualHosts."${config.networking.ownWireguard.hosts.neurodrive.mainIP}" = {
    #   forceSSL = false;
    #   enableACME = false;
    # };
    navidrome = {
      enable = true;
      openFirewall = true;
      group = "users";
      settings = {
        Address = "0.0.0.0";
        MusicFolder = "/mnt/cryptostorage/Music";
      };
    };
  };

  hardware = {
    logitech.wireless.enable = true; # Manage logitech options via solaar
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs; [
        libva-vdpau-driver
      ];
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = false;
      };
      nvidiaSettings = true;
      open = true;
      # Fixes: https://github.com/NixOS/nixpkgs/issues/467814
      # Fix from: https://github.com/NixOS/nixpkgs/issues/467814#issuecomment-3620802561
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
    nvidia-container-toolkit.enable = true;
  };
  virtualisation = {
    docker.daemon.settings = {
      ipv6 = true;
      data-root = "/mnt/cryptostorage/var/lib/containers";
    };
    oci-containers = {
      containers = {
        homeassistant = {
          volumes = ["home-assistant:/config"];
          devices = [
            "/dev/zigbee-ap:/dev/ttyUSB0"
          ];
          environment.TZ = config.time.timeZone;
          image = "ghcr.io/home-assistant/home-assistant:stable";
          # Use the host network namespace for all sockets
          extraOptions = [
            "--network=host"
            "--stop-timeout=30"
          ];
          capabilities = {
            CAP_NET_RAW = true;
          };
        };
        comfyui = {
          # Broken and needs debugging
          autoStart = false;
          volumes = ["comfyui:/root"];
          environment.TZ = config.time.timeZone;
          image = "docker.io/yanwk/comfyui-boot:cu124-megapak";
          pull = "newer";
          ports = [
            "127.0.0.1:8188:8188"
            "192.168.190.180:8188:8188"
            "${config.networking.ownWireguard.hosts.${config.networking.hostName}.mainIP}:8188:8188"
          ];
          extraOptions = [
            "--security-opt=label=disable"
          ];
          # TODO: How to set this as default
          login = {
            username = "redetherbloom";
            passwordFile = config.sops.secrets."registry/dockerhub/password".path;
            registry = "docker.io";
          };
        };
        esphome = rec {
          image = "ghcr.io/esphome/esphome";
          pull = "newer";
          environment.TZ = config.time.timeZone;
          volumes = [
            "esphome:/config"
          ];
          privileged = true;
          extraOptions = [
            "--network=host"
            "--stop-timeout=30"
          ];
          cmd = [
            "dashboard"
            "--port=${environment.PORT}"
            "/config"
          ];
          environment = {
            PORT = "8152";
          };
        };
      };
    };
  };
  systemd.services = {
    "${config.virtualisation.oci-containers.containers.homeassistant.serviceName}".after = [
      "systemd-udevd.service"
    ];
    "${config.virtualisation.oci-containers.containers.comfyui.serviceName}".after = [
      "network-online.target"
    ];
  };

  myOptions = {
    hostRoles.desktop.enable = true;
    roles.gaming.enable = true;
    services = {
      taskchampion.enable = true;
      gitea.enable = true;
    };
  };
  users.users = {
    inf = {
      isNormalUser = true;
      description = "Infinity";
      extraGroups = [
        "networkmanager"
        "wheel"
        "adbusers"
        "scanner"
        "lp"
        "i2c"
        "podman"
        "dialout"
      ];
    };
    i2p.home = lib.mkForce "/mnt/cryptostorage/i2p";
  };
  stylix.image = "${secrets}/dotfiles/wallpapers/cyborg_girl_tactical.jpg";

  programs = {
    coolercontrol.enable = true;
    alvr = {
      enable = true;
      openFirewall = true;
    };
    nix-ld.libraries = with pkgs; [
      libxkbcommon
      libGL
      wayland
      libva
      # After here it became iirc steamvr issues. Probably needs a newer steam linux runtime
      SDL2
      glib
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      cachix
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      nvtopPackages.full
      smartmontools
    ];
    sessionVariables = {
      #LIBVA_DRIVER_NAME = "nvidia";
      #MOZ_DISABLE_RDD_SANDBOX = "1";

      # Necessary to correctly enable va-api (video codec hardware
      # acceleration). If this isn't set, the libvdpau backend will be
      # picked, and that one doesn't work with most things, including
      # Firefox.
      LIBVA_DRIVER_NAME = "nvidia";
      # Required to run the correct GBM backend for nvidia GPUs on wayland
      GBM_BACKEND = "nvidia-drm";
      # Apparently, without this nouveau may attempt to be used instead
      # (despite it being blacklisted)
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # Hardware cursors are currently broken on nvidia
      WLR_NO_HARDWARE_CURSORS = "1";

      # Required to use va-api it in Firefox. See
      # https://github.com/elFarto/nvidia-vaapi-driver/issues/96
      MOZ_DISABLE_RDD_SANDBOX = "1";
      # It appears that the normal rendering mode is broken on recent
      # nvidia drivers:
      # https://github.com/elFarto/nvidia-vaapi-driver/issues/213#issuecomment-1585584038
      # TODO: I think this may be the culprit that broke it...
      NVD_BACKEND = "direct";
      # Required for firefox 98+, see:
      # https://github.com/elFarto/nvidia-vaapi-driver#firefox
      EGL_PLATFORM = "wayland";
    };
  };

  sops.secrets = {
    cryptostorage = {
      sopsFile = "${secrets}/secrets/neurodrive/cryptstorage.key";
      format = "binary";
    };
    "restic_server/restic.key" = {
      owner = "restic";
      format = "binary";
      sopsFile = "${secrets}/secrets/neurodrive/restic_server/restic.key";
    };
    "mosquitto/users/root" = {
      uid = config.ids.uids.mosquitto;
      gid = config.ids.gids.mosquitto;
      format = "yaml";
      sopsFile = "${secrets}/secrets/neurodrive/mosquitto.yaml";
    };
    "mosquitto/users/client" = {
      uid = config.ids.uids.mosquitto;
      gid = config.ids.gids.mosquitto;
      format = "yaml";
      sopsFile = "${secrets}/secrets/neurodrive/mosquitto.yaml";
    };
    # Copied from Bitwarden TODO: Cross-sync bitwarden and secret store
    "paperless/admin_password" = {
      owner = "paperless";
      format = "yaml";
      sopsFile = "${secrets}/secrets/services/paperless.yaml";
    };
  };
}
