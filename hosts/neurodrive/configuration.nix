{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  restic_certificate = config.sops.secrets."restic_server/private_certificate".path;
  restic_public_key = config.sops.secrets."restic_server/public_certificate".path;
in {
  imports =
    [
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

  nixpkgs.system = "x86_64-linux";
  nixpkgs.config = {
    cudaSupport = true;
    cudnnSupport = true;
  };

  nix.settings = {
    # Logical cores: 12
    max-jobs = 10;
    # Max make some builds non deterministic
    cores = 10;
  };

  # Quarry: Cross-compilation support for audiosink
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  # Cache for krita...
  programs.ccache.enable = true;
  nix.settings.extra-sandbox-paths = [config.programs.ccache.cacheDir];
  #ä Although this may not work, as using krita directly here leads to a werid home-manager crash about stdenv. Maybe the CCache wrappers still needs to be added for this host?
  programs.ccache.packageNames = ["krita-unwrapped"];

  # Filesystems
  boot.initrd.luks.devices."nixos-root" = {
    device = "/dev/disk/by-uuid/36e0d35b-4ac0-41a9-a8a9-15a07696c2c4";
    bypassWorkqueues = true;
    # Weakens security
    allowDiscards = true;
  };
  boot.initrd.luks.devices."nixos-swap" = {
    device = "/dev/disk/by-uuid/69bd8d21-1c47-4aff-8533-31bf2610c181";
    bypassWorkqueues = true;
    # Weakens security
    allowDiscards = true;
  };
  fileSystems."/mnt/restic_data" = {
    device = "/dev/disk/by-uuid/2645230e-f8d1-4b00-ad11-c9ec192448cf";
    fsType = "ext4";
    options = [
      "nofail"
    ];
  };

  # Networking
  networking.hostName = "neurodrive";
  networking.networkmanager.enable = true;
  networking.interfaces."enp0s25".wakeOnLan.enable = true;
  # Issues with builds randomly failing
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [
    #TODO: Pulseaudio Network Sharing. Probably only needed for publush
    4713
    (lib.strings.toInt config.services.restic.server.listenAddress)
  ];

  networking.ownWireguard = {
    enabled = true;
    currentHost = config.networking.ownWireguard.hosts.neurodrive;
  };

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  # Does this have to be replaced with home-manager?
  services.desktopManager.plasma6.enable = true;

  hardware.enableAllFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      # Problems with Bose
      ControllerMode = "bredr";
    };
  };

  services.pipewire.wireplumber.extraConfig = {
    "disable-hfp-autoswitch" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
    "monitor.bluez.properties" = {
      "bluez5.enable-hw-volume" = true;
    };
    "bose-qc35-2-ldac-hq" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            {
              # Match any bluetooth device with ids equal to that of a Bose QC 35 ||
              "device.name" = "~bluez_card.*";
              "device.product.id" = "0x4020";
              "device.vendor.id" = "bluetooth:009e";
            }
          ];
          actions = {
            update-props = {
              # Set quality to high quality instead of the default of auto
              "bluez5.a2dp.ldac.quality" = "hq";
            };
          };
        }
      ];
    };

    #"log-level-debug" = {
    #  "context.properties" = {
    #      # Output Debug log messages as opposed to only the default level (Notice)
    #      "log.level" = "D";
    #    };
    #};
  };

  myOptions.hostRoles.desktop.enable = true;
  myOptions.roles.gaming.enable = true;
  users.users.inf = {
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
    ];
  };
  stylix.image = "${inputs.our-secrets}/dotfiles/wallpapers/kaiju_girl_extended.png";

  environment.systemPackages = with pkgs; [
    cachix
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    nvtopPackages.full
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
  ];

  environment.sessionVariables = {
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
    NVD_BACKEND = "direct";
    # Required for firefox 98+, see:
    # https://github.com/elFarto/nvidia-vaapi-driver#firefox
    EGL_PLATFORM = "wayland";
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  # Manage logitech options via solaar
  hardware.logitech.wireless.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # Includes Wayland
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;

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
    # TODO: Reevaluate if open works now
    open = false;
  };

  sops.secrets."restic_server/private_certificate" = {
    owner = "restic";
    format = "binary";
    sopsFile = "${inputs.our-secrets}/secrets/neurodrive/restic_server/certificate.priv";
  };

  services.restic.server = {
    enable = true;
    privateRepos = true;
    dataDir = "/mnt/restic_data/restic";
    listenAddress = "8193";
    extraFlags = [
      "--tls"
      "--tls-key"
      restic_certificate
      "--tls-cert"
      restic_public_key
    ];
  };

  services.smartd = {
    enable = true;
    notifications = {
      # Do we need this? https://search.nixos.org/options?channel=unstable&show=services.smartd.notifications.systembus-notify.enable
      systembus-notify.enable = true;
    };
    # Short daily self-test, long weekly exteded test
    # https://search.nixos.org/options?channel=unstable&show=services.smartd.defaults.monitored
    defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
  };

  myOptions.services.taskchampion = {
    enable = true;
  };

  myOptions.services.gitea.enable = true;

  # Required for GPU passthrough
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  system.stateVersion = "24.05";
}
