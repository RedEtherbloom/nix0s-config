{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/cachix.nix

    ../../modules/common/default.nix
    ../../modules/wireguard/default.nix

    ./hardware-configuration.nix
  ];

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
    lastIPDigit = 3;
  };

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.printing.enable = true;
  hardware.sane.enable = true;
  hardware.sane.drivers.scanSnap.enable = true;

  hardware.pulseaudio.enable = false;
  hardware.pulseaudio.zeroconf.discovery.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.enable = true;
  };

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

  myOptions.basePkgs.enabled = true;
  users.users.inf = {
    isNormalUser = true;
    description = "Infinity";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "scanner"
      "lp"
      "docker"
    ];

    packages = with pkgs; [
      krita

      # FNV Mod launcher
      zenity
      yad
      # Does my bar approach need this?
      openal

      koboldcpp
    ];
  };

  environment.systemPackages = with pkgs; [
    cachix
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    nvtopPackages.full
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # Includes Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

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
    open = true;
  };

  sops.secrets."restic_server/private_certificate" = {
    format = "binary";
    sopsFile = ../../secrets/neurodrive/restic_server/certificate.priv;
  };

  services.restic.server = {
    enable = true;
    privateRepos = true;
    dataDir = "/mnt/restic_data/restic";
    listenAddress = "8193";
    extraFlags = [
      "--tls"
      "--tls-key ${config.sops.secrets."restic_server/private_certificate".path}"
      "--tls-cert ${config.sops.secrets."restic_server/public_certificate".path}"
    ];
  };

  system.stateVersion = "24.05";
}
