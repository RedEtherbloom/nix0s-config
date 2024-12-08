{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3

    ../../modules
    ../../modules/common/ssh.nix

    ./hardware-configuration.nix
  ];
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.loader.raspberryPi.firmwareConfig = ''
    dtparam=audio=on
  '';
  # Warning: Early Boot UART will be garbled due to the default 400MHz CPU freq
  boot.kernelParams = [
    "console=ttyS1,115200n8"
  ];

  networking.hostName = "audiosink"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  time.timeZone = "Europe/Berlin";

  # Ireland as english AND correct formatting(e.g. time)
  i18n.defaultLocale = "en_IE.UTF-8";
  console.keyMap = "de";

  myOptions.hostRoles.graphical = true;
  myOptions.utilities.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
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

    ddcutil
  ];

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
        environment.TZ = config.time.timeZone;
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

  system.stateVersion = "24.05";
}
