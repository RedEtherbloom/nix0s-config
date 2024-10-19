{ pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  hardware.enableRedistributableFirmware = true;

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
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

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Ireland as english AND correct formatting(e.g. time)
  i18n.defaultLocale = "en_IE.UTF-8";
  console.keyMap = "de";

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
  systemd.user.services.pipewire-pulse.wantedBy = [ "default.target" ];

  users.users.inf = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "i2c"
    ];
    linger = true;
    packages = with pkgs; [
      librespot
    ];
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi

    tmux
    dua
    ddcutil

    magic-wormhole
    mosh
    curl
    wget
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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
    publish.enable = true;
    publish.addresses = true;
    publish.domain = true;
    publish.userServices = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    # Pulse Network
    4713
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
