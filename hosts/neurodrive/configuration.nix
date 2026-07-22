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
      ../../modules/ssh.nix
      ../../modules/cachix/cuda-maintainers.nix

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
    extraModprobeConfig = ''
      options nvidia_drm modeset=1
    '';
    initrd = {
      kernelModules = [
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
  networking = {
    hostName = "neurodrive";
    networkmanager.enable = true;
    interfaces."enp0s25".wakeOnLan.enable = true;

    firewall = {
      allowedTCPPorts =
        [
          1883 # MQTT Home-Assistant
          1884 # MQTT Home-Assistant
          4333 # Feishin remote control port
          4713 # Pulseaudio Network Sharing. Probably only needed for publish
          5580 # Matter in Home-Assistant
          6052 # Matter in Home-Assistant
          8122 # Home Assistant SSH
          8123 # Home Assistant
          8883 # MQTT Home-Assistant
          8884 # MQTT Home-Assistant
          27062 # SteamVR
          (lib.mkIf config.myOptions.roles.ssdp.enable 40000)
          config.services.paperless.port
          (lib.strings.toInt config.services.restic.server.listenAddress)
          config.services.tabby.port
        ]
        ++ (lib.lists.concatMap (el: [el.port]) config.services.mosquitto.listeners);
      allowedUDPPorts = [
        9944 # SteamVR
        27062 # SteamVR
      ];
      trustedInterfaces = [
        "virbr0"
      ];
    };
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain PREROUTING {
            type nat hook prerouting priority -199; policy accept;
            tcp dport { 1883, 8122, 8883 } meta nftrace set 1 dnat to 192.168.122.189
            # iifname "enp0s25" tcp dport { 1883, 8122, 8883 } dnat to 192.168.122.189
            # iifname "wg0" tcp dport { 1883, 8122, 8883 } dnat to 192.168.122.189
            # iifname "lo" tcp dport { 1883, 8122, 8883 } dnat to 192.168.122.189
          }
        }
        '';
    };
    nat = {
      enable = true;
      internalInterfaces = [
        "virbr0"
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
    '';
    # ACTION=="add", SUBSYSTEM=="tty", ENV{DEVLINKS}=="*/dev/zigbee-ap*", RUN+="${config.systemd.package}/bin/systemctl restart podman-homeassistant.service"
    navidrome = {
      enable = true;
      openFirewall = true;
      group = "users";
      settings = {
        Address = "0.0.0.0";
        MusicFolder = "/mnt/cryptostorage/Music";
      };
    };
    caddy = {
      enable = true;
      logFormat = "level INFO";
      openFirewall = true;
      virtualHosts = {
        # MQTT
        ":1884".extraConfig = ''
          reverse_proxy http://192.168.122.189:1884
        '';
        # Matter
        ":5580".extraConfig = ''
          reverse_proxy http://192.168.122.189:5580
        '';
        # ESP-Home
        ":6052".extraConfig = ''
          reverse_proxy http://192.168.122.189:6052
        '';
        # HASS
        ":8123".extraConfig = ''
          reverse_proxy http://192.168.122.189:8123
        '';
        # MQTT
        ":8884".extraConfig = ''
          reverse_proxy http://192.168.122.189:8884
        '';
      };
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 11435;
      openFirewall = true;
    };
    avahi.reflector = true;
  };

  hardware = {
    logitech.wireless.enable = true;
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
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
    nvidia-container-toolkit.enable = true;
    sensor.hddtemp = {
      enable = true;
      drives = ["/dev/disk/by-path/*"];
    };
  };
  virtualisation = {
    docker.daemon.settings = {
      ipv6 = true;
      data-root = "/mnt/cryptostorage/var/lib/containers";
    };
    oci-containers = {
      containers = {
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
      };
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  systemd.services = let
    hddSleepCommand = ''${lib.getExe pkgs.bash} -c '${lib.getExe pkgs.hdparm} -S 90 -B 1 $(${pkgs.util-linux}/bin/lsblk -dnp -o name,rota | ${lib.getExe pkgs.gnugrep} ".*\s1" | ${pkgs.coreutils}/bin/cut -d " " -f 1)''; # Spin HDDs down when inactive. Taken from: https://www.reddit.com/r/NixOS/comments/751i5t/comment
  in {
    # "${config.virtualisation.oci-containers.containers.homeassistant.serviceName}".after = [
    #   "systemd-udevd.service"
    # ];
    "${config.virtualisation.oci-containers.containers.comfyui.serviceName}".after = [
      "network-online.target"
    ];
    i2p = {
      after = [
        "local-fs.target"
        "cryptsetup.target"
      ];
      serviceConfig.WorkingDirectory = lib.mkForce config.users.users.i2p.home;
    };
    powerUpHdd = {
      description = "Configure sleep time on HDDs.";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = hddSleepCommand;
      };
    };
    afterSleepHdd = {
      description = "Configure sleep time on HDDs after coming back from suspend.";
      wantedBy = ["sleep.target"];
      unitConfig.StopWhenUnneeded = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = hddSleepCommand;
      };
    };
  };

  myOptions = {
    hostRoles.neural-augmenter.enable = true;
    roles.gaming.enable = true;
    services.gitea.enable = true;
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
        "libvirtd"
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
    virt-manager.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      cachix
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
      nvtopPackages.full
      smartmontools

      # For VM-Host functionalities
      dnsmasq
    ];
    sessionVariables = {
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
