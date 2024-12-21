{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.raspberry-pi-nix.nixosModules.raspberry-pi

    ./disko.nix
    ./hardware-configuration.nix

    ./raspberry_pi_binary_cache.nix
    ../../modules/common/shared_secrets.nix
    #../../modules
    ../../modules/common/ssh.nix
  ];

  users.users = lib.mkMerge [
    (lib.attrsets.genAttrs ["root" "inf"]
      (name: {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHKCccanhW2Z05AiItTPhw+CnPFdo66Uszt6K7UuR3r RedEtherbloom@neurodrive"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHKCccanhW2Z05AiItTPhw+CnPFdo66Uszt6K7UuR3r RedEtherbloom@fractor"
        ];
      }))

    {root.initialPassword = "password123";}
    {
      inf = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "audio"
          "i2c"
          "podman"
        ];
        linger = true;
      };
    }
  ];
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  nixpkgs.system = "aarch64-linux";
  # nixpkgs.hostPlatform.system = "aarch64-linux";
  # nixpkgs.buildPlatform.system = "x86_64-linux";

  boot.enableContainers = false;
  documentation.nixos.enable = false;
  environment.defaultPackages = [pkgs.perl];
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  raspberry-pi-nix.uboot.enable = true;
  # myOptions.common.enableBoot = false;

  # Warning: Early Boot UART will be garbled due to the default 400MHz CPU freq
  boot.kernelParams = [
    "console=ttyS1,115200n8"
  ];
  # Override, due to https://github.com/nix-community/raspberry-pi-nix/issues/95
  # May or may not boot normally, if it doesn't I just have to compile the entire kernel
  # boot.kernelPackages = lib.mkForce pkgs.linuxKernel.packages.linux_rpi3;

  # Cross-compile shenangians
  # programs.neovim.package = lib.mkForce (pkgs.neovim.override {withRuby = false;});
  programs.neovim.enable = lib.mkForce false;
  programs.vim.enable = false;
  # programs.vim.defaultEditor = true;
  # myOptions.utilities.cmdFileManagers = false;
  # myOptions.utilities.pdfUtils = false;
  # networking.networkmanager.plugins = lib.mkForce [];
  services.fwupd.enable = lib.mkForce false;

  raspberry-pi-nix.board = "bcm2711";
  hardware.raspberry-pi.config = {
    all = {
      options = {
        # The firmware will start our u-boot binary rather than a
        # linux kernel.
        kernel = {
          enable = true;
          value = lib.mkForce "u-boot-rpi-arm64.bin";
        };
        arm_64bit = {
          enable = true;
          value = true;
        };
        enable_uart = {
          enable = true;
          value = true;
        };
        disable_overscan = {
          enable = true;
          value = true;
        };
      };
      base-dt-params = {
        krnbt = {
          enable = true;
          value = "on";
        };
        spi = {
          enable = true;
          value = "on";
        };
        audio = {
          enable = true;
          value = "on";
        };
      };
    };
  };

  networking.hostName = "audiosink";
  #networking.networkmanager.enable = true;
  networking.useDHCP = true;

  # myOptions.hostRoles.base.enable = true;
  # myOptions.utilities.enable = lib.mkForce false;

  # Enable sound.
  security.rtkit.enable = lib.mkForce false;
  services.pipewire = {
    enable = lib.mkForce false;
    alsa.enable = lib.mkForce false;
    alsa.support32Bit = lib.mkForce false;
    pulse.enable = lib.mkForce false;
    jack.enable = lib.mkForce false;
    wireplumber.enable = lib.mkForce false;
    # extraConfig.pipewire-pulse = {
    #   "30-network-publish" = {
    #     "pulse.cmd" = [
    #       {
    #         cmd = "load-module";
    #         args = "module-native-protocol-tcp";
    #       }
    #       {
    #         cmd = "load-module";
    #         args = "module-zeroconf-publish";
    #       }
    #     ];
    #   };
    # };
  };

  # Shitty autostart. Needs lingering on user, may start more than one
  # Should probably be redone with home-manager(Clara: Learing curve, yayyy...)
  # systemd.user.services.pipewire-pulse.after = [
  #   "network-online.target"
  #   "sound.target"
  #   "bluetooth.target"
  # ];
  # systemd.user.services.pipewire-pulse.wants = [
  #   "network-online.target"
  #   "sound.target"
  #   "bluetooth.target"
  # ];
  # systemd.user.services.pipewire-pulse.wantedBy = ["default.target"];

  environment.systemPackages = with pkgs; [
    #libraspberrypi
    # podman
    # podman-compose

    # ddcutil
    age
    ssh-to-age
    sops
  ];

  # hardware.enableRedistributableFirmware = true;
  # hardware.bluetooth.enable = true;
  # hardware.bluetooth.powerOnBoot = true;
  # # Advertise as Audio sink
  # hardware.bluetooth.settings = {
  #   General = {
  #     Enable = "Source";
  #   };
  # };

  # hardware.i2c.enable = true;

  # services.avahi = {
  #   enable = true;
  #   # Lookup which get enabled by default
  #   # publish = {
  #   #   enable = true;
  #   #   addresses = true;
  #   #   domain = true;
  #   #   userServices = true;
  #   # };
  #   nssmdns4 = true;
  #   nssmdns6 = true;
  #   openFirewall = true;
  # };

  # networking.firewall.allowedTCPPorts = [
  #   # Pulse Network
  #   4713
  #   # Home Assistant
  #   8123
  # ];

  # Enable common container config files in /etc/containers
  #   virtualisation = {
  #    containers.enable = false;
  #    podman = {
  #      enable = false;
  #      # Create a `docker` alias for podman, to use it as a drop-in replacement
  #      dockerCompat = true;
  #      # Required for containers under podman-compose to be able to talk to each other.
  #      defaultNetwork.settings.dns_enabled = true;
  #   };
  # oci-containers = {
  #   backend = "podman";
  #   containers.homeassistant = {
  #     # How do we backup this?
  #     volumes = ["home-assistant:/config"];
  #     environment.TZ = config.time.timeZone;
  #     # Okay? What does this mean?
  #     # Note: The image will not be updated on rebuilds, unless the version label changes
  #     image = "ghcr.io/home-assistant/home-assistant:stable";
  #     extraOptions = [
  #       # Use the host network namespace for all sockets
  #       "--network=host"
  #       # Pass devices into the container, so Home Assistant can discover and make use of them
  #       # "--device=/dev/ttyACM0:/dev/ttyACM0"
  #     ];
  #   };
  # };
  # };

  system.stateVersion = "24.11";
}
