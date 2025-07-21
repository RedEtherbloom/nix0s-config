{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  restic_private_key = config.sops.secrets."restic_server/restic.key".path;
  restic_public_certificate = "${inputs.our-secrets}/secrets/neurodrive/restic_server/restic.crt";
in {
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
    max-jobs = 10;
    # Max make some builds non deterministic
    cores = 10;
  };
  nixpkgs.config = {
    cudaSupport = true;
    cudnnSupport = true;
    cudaCapabilities = ["7.5"];
  };
  # Eve: Host-specific package overrides
  nixpkgs.overlays = [
    (_: prev: {
      # Eve: Account for bug: https://fractalsoftworks.com/forum/index.php?topic=30633.0
      starsector = prev.starsector.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [pkgs.makeWrapper];
        postInstall =
          (oldAttrs.postInstall or "")
          + ''
            wrapProgram "$out/bin/starsector" --set __GL_THREADED_OPTIMIZATIONS 0
          '';
      });
    })
  ];

  boot = {
    # Quarry: Cross-compilation support for audiosink
    binfmt.emulatedSystems = ["aarch64-linux"];
    # Hoping to increase audio quality/reliability
    kernelParams = ["btusb.enable_autosuspend=n"];
    kernelModules =
      ["coretemp" "nct6775"]
      ++
      # Attempt to fix ALVR/NvEnc problems
      ["nvidia" "i915" "nvidia_modeset" "nvidia_drm"];
    initrd = {
      availableKernelModules = [
        # Speedup decryption
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
      allowedTCPPorts = [
        # Mosquitto
        1883
        8883
        #TODO: Pulseaudio Network Sharing. Probably only needed for publish
        4713
        # Matter
        config.services.matter-server.port
        (lib.strings.toInt config.services.restic.server.listenAddress)
        # Home Assistant
        8123
        config.services.paperless.port
        # SteamVR
        27062
      ];
      allowedUDPPorts = [
        # SteamVR
        9944
        27062
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
    # Includes Wayland
    xserver.videoDrivers = ["nvidia"];
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
    };
    paperless = {
      # For some reason broken today
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
    esphome.enable = true;
    ollama = {
      enable = true;
      acceleration = "cuda";
      host = "0.0.0.0";
      # Privacy at home?
      openFirewall = true;
    };
    nextjs-ollama-llm-ui = {
      enable = true;
      # May need to set CORS in ollama variables for VPN to work
      hostname = "${config.networking.ownWireguard.hosts.neurodrive.mainIP}";
      # Reasonably close to ollama
      port = 11440;
      # May have to set ollamURL to a VPN url
    };
    mosquitto = {
      enable = true;
      logType = ["all"];
      listeners = [
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
        restic_private_key
        "--tls-cert"
        restic_public_certificate
      ];
    };
    smartd = {
      enable = true;
      autodetect = true;
      notifications = {
        systembus-notify.enable = true;
      };
      # Short daily self-test, long weekly exteded test
      # https://search.nixos.org/options?channel=unstable&show=services.smartd.defaults.monitored
      defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
    };
    udev.extraRules = ''
      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee-ap"
      ACTION=="add", SUBSYSTEM=="tty", ENV{DEVLINKS}=="*/dev/zigbee-ap*", RUN+="${config.systemd.package}/bin/systemctl restart podman-homeassistant.service"
    '';
    # ALVR alternative while the nvenc is broken
    wivrn = {
      enable = true;
      openFirewall = true;
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
      powerManagement.enable = true;
      nvidiaSettings = true;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      #
      # May have improved now
      #
      # Incompability with vaapi-driver
      # See: https://github.com/elFarto/nvidia-vaapi-driver/issues/312
      # TODO: Check if this helps with the ALVR nvenc problems
      open = true;
    };
    # Required for GPU passthrough
    nvidia-container-toolkit.enable = true;
  };
  virtualisation.oci-containers = {
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
          "--device=nvidia.com/gpu=all"
          "--security-opt=label=disable"
        ];
      };
    };
  };
  systemd.services."${config.virtualisation.oci-containers.containers.homeassistant.serviceName}" = {
    after = ["systemd-udevd.service"];
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
  stylix.image = "${inputs.our-secrets}/dotfiles/wallpapers/current_wallpaper";

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
      sopsFile = "${inputs.our-secrets}/secrets/neurodrive/cryptstorage.key";
      format = "binary";
    };
    "restic_server/restic.key" = {
      owner = "restic";
      format = "binary";
      sopsFile = "${inputs.our-secrets}/secrets/neurodrive/restic_server/restic.key";
    };
    "mosquitto/users/root" = {
      uid = config.ids.uids.mosquitto;
      gid = config.ids.gids.mosquitto;
      format = "yaml";
      sopsFile = "${inputs.our-secrets}/secrets/neurodrive/mosquitto.yaml";
    };
    "mosquitto/users/client" = {
      uid = config.ids.uids.mosquitto;
      gid = config.ids.gids.mosquitto;
      format = "yaml";
      sopsFile = "${inputs.our-secrets}/secrets/neurodrive/mosquitto.yaml";
    };
    # Copied from Bitwarden
    # TODO: Cross-sync bitwarden and secret store
    "paperless/admin_password" = {
      owner = "paperless";
      format = "yaml";
      sopsFile = "${inputs.our-secrets}/secrets/services/paperless.yaml";
    };
  };
}
