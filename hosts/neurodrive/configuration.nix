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
      # !EXCEPTION TO GET AUDIOSINK KICK-STARTED! #
      ../audiosink/raspberry_pi_binary_cache.nix
      ../../modules
      ../../modules/cachix.nix
      ../../modules/common/ssh.nix
      ../../modules/hdd.nix
      # TODO: Remove once hm sops-nix supports secrets
      ../../modules/common/taskwarrior-secrets.nix

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
    kernelModules = ["coretemp" "nct6775"];
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
      cryptostorage UUID=b61e25b7-2cc5-49b9-b406-3b9a26806a23 ${config.sops.secrets.cryptostorage.path}
    '';
  };
  fileSystems = {
    "/mnt/restic_data" = {
      device = "/dev/disk/by-uuid/2645230e-f8d1-4b00-ad11-c9ec192448cf";
      fsType = "ext4";
      options = ["nofail"];
    };
    "/mnt/windows_data" = {
      device = "/dev/disk/by-uuid/587488F374FD109E";
      fsType = "ntfs3";
      options = ["nofail"];
    };
    "/mnt/cryptostorage" = {
      device = "/dev/mapper/vg--cryptostorage-lv--cryptostorage";
      fsType = "ext4";
      options = ["nofail"];
    };
  };

  systemd.services = {
    i2p = {
      after = ["local-fs.target" "cryptsetup.target"];
      serviceConfig.WorkingDirectory = lib.mkForce config.users.users.i2p.home;
    };
    # Issues with builds randomly failing
    NetworkManager-wait-online.enable = lib.mkForce false;
  };
  # Networking
  networking = {
    hostName = "neurodrive";
    networkmanager.enable = true;
    interfaces."enp0s25".wakeOnLan.enable = true;

    firewall = {
      allowedTCPPorts =
        [
          # Pulseaudio Network Sharing. Probably only needed for publish
          4713
          # Home Assistant
          8123
          9757 # WiVrn
          # SteamVR
          27062
          config.services.paperless.port
          config.services.matter-server.port
          (lib.strings.toInt config.services.restic.server.listenAddress)
          config.services.tabby.port
          (lib.strings.toInt config.virtualisation.oci-containers.containers.esphome.environment.PORT)
        ]
        ++ (lib.lists.concatMap (el: [el.port]) config.services.mosquitto.listeners);
      allowedUDPPorts = [
        # SteamVR
        9944
        27062
        9757 # WiVrn
      ];
    };
    ownWireguard = {
      enabled = true;
      currentHost = config.networking.ownWireguard.hosts.neurodrive;
    };
  };

  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;
    xserver.videoDrivers = ["nvidia"];
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
    };
    paperless = {
      enable = true;
      consumptionDirIsPublic = true;
      address = "0.0.0.0";
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
      enable = true;
      acceleration = "cuda";
      host = "0.0.0.0";
      openFirewall = true;
    };
    nextjs-ollama-llm-ui = {
      enable = true;
      # May need to set CORS in ollama variables for VPN to work
      hostname = "${config.networking.ownWireguard.hosts.neurodrive.mainIP}";
      # Reasonably close to ollama
      port = 8154;
      # May have to set ollamURL to a VPN url
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
    tabby = {
      enable = true;
      acceleration = "cuda";
      # TODO: Is there a wildcard address that matches both IPv4 and 6?
      host = "0.0.0.0";
    };
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          # Problems with Bose
          ControllerMode = "bredr";
        };
      };
    };
    # Manage logitech options via solaar
    logitech.wireless.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs; [
        vaapiVdpau
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
    };
    nvidia-container-toolkit.enable = true;
  };
  virtualisation = {
    docker.daemon.settings = {
      ipv6 = true;
      # Store containers on second harddrive to save space
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
          cmd = ["dashboard" "--port=${environment.PORT}" "/config"];
          environment = {
            PORT = "8152";
          };
        };
      };
    };
  };
  systemd.services = {
    "${config.virtualisation.oci-containers.containers.homeassistant.serviceName}".after = ["systemd-udevd.service"];
    "${config.virtualisation.oci-containers.containers.comfyui.serviceName}".after = ["network-online.target"];
    "${config.virtualisation.oci-containers.containers.esphome.serviceName}".serviceConfig.Restart = "always";
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
  stylix.image = "${secrets}/dotfiles/wallpapers/current_wallpaper";

  programs = {
    coolercontrol = {
      enable = true;
      nvidiaSupport = true;
    };
    alvr = {
      enable = true;
      openFirewall = true;
      # package = pkgs.alvr-nightly;
    };
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
    # Copied from Bitwarden
    # TODO: Cross-sync bitwarden and secret store
    "paperless/admin_password" = {
      owner = "paperless";
      format = "yaml";
      sopsFile = "${secrets}/secrets/services/paperless.yaml";
    };
  };
}
