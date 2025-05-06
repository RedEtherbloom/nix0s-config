{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix
    ./raspberry_pi_binary_cache.nix

    ../../modules/common/ssh.nix
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = ["root" "@wheel" "inf"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise = {
      automatic = true;
      dates = [
        "07:00"
      ];
    };
  };
  swapDevices = [
    {
      size = 8192;
      device = "/var/swapfile";
    }
  ];

  #boot.loader.grub.enable = false;
  #raspberry-pi-nix.uboot.enable = true;

  # Warning: Early Boot UART will be garbled due to the default 400MHz CPU freq
  # boot.kernelParams = [
  #   "console=ttyS1,115200n8"
  # ];
  # boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_rpi3;

  # raspberry-pi-nix.board = "bcm2711";
  # hardware.raspberry-pi.config = {
  #   all = {
  #     options = {
  #       # The firmware will start our u-boot binary rather than a linux kernel
  #       kernel = {
  #         enable = true;
  #         value = lib.mkForce "u-boot-rpi-arm64.bin";
  #       };
  #       arm_64bit = {
  #         enable = true;
  #         value = true;
  #       };
  #       enable_uart = {
  #         enable = true;
  #         value = true;
  #       };
  #       disable_overscan = {
  #         enable = true;
  #         value = true;
  #       };
  #     };
  #     base-dt-params = {
  #       krnbt = {
  #         enable = true;
  #         value = "on";
  #       };
  #       spi = {
  #         enable = true;
  #         value = "on";
  #       };
  #       audio = {
  #         enable = true;
  #         value = "on";
  #       };
  #     };
  #   };
  # };

  networking.hostName = "audiosink";
  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [
        config.sops.secrets."wifi.env".path
      ];
      profiles = {
        "HomeWifi" = {
          connection = {
            id = "$WIFI_SSID";
            type = "wifi";
            interface-name = "wlan0";
          };
          wifi = {
            mode = "infrastructure";
            ssid = "$WIFI_SSID";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$WIFI_PASSWORD";
          };
          ipv4 = {method = "auto";};
          ipv6 = {
            addr-gen-mode = "default";
            method = "auto";
          };
          proxy = {};
        };
      };
    };
  };

  sops.secrets."wifi.env" = {
    sopsFile = "${inputs.our-secrets}/secrets/common/wifi.yaml";
    # Whole file
    key = "wifiHome";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
    wireplumber.enable = true;
    extraConfig.pipewire-pulse = {
      "30-network-publish" = {
        "pulse.cmd" = [
          {
            cmd = "load-module";
            args = "module-native-protocol-tcp";
          }
          {
            cmd = "load-module";
            args = "module-zeroconf-publish";
          }
        ];
      };
    };
  };

  # Shitty autostart. Needs lingering on user, may start more than one
  # Should probably be redone with home-manager(Clara: Learing curve, yayyy...)
  systemd.user.services.pipewire-pulse.after = [
    "network-online.target"
    "sound.target"
    "bluetooth.target"
  ];
  systemd.user.services.pipewire-pulse.wants = [
    "network-online.target"
    "sound.target"
    "bluetooth.target"
  ];
  systemd.user.services.pipewire-pulse.wantedBy = ["default.target"];

  users.users.inf = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "i2c"
      "podman"
    ];
    linger = true;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    podman
    podman-compose
  ];

  programs.tmux.enable = true;
  programs.git.enable = true;
  programs.htop.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Advertise as Audio sink
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source";
    };
  };

  hardware.i2c.enable = true;

  services.avahi = {
    enable = true;
    # Lookup which get enabled by default
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      userServices = true;
    };
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    # Pulse Network
    4713
    # Home Assistant
    8123
  ];

  # Enable common container config files in /etc/containers
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        # How do we backup this?
        volumes = ["home-assistant:/config"];
        environment.TZ = "Europe/Berlin";
        # Okay? What does this mean?
        # Note: The image will not be updated on rebuilds, unless the version label changes
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [
          # Use the host network namespace for all sockets
          "--network=host"
          # Pass devices into the container, so Home Assistant can discover and make use of them
          # "--device=/dev/ttyACM0:/dev/ttyACM0"
        ];
      };
    };
  };

  system.stateVersion = "25.05";
}
