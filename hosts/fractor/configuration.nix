{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/common/default.nix
    ../../modules/wireguard/default.nix

    ./hardware-configuration.nix
  ];

  # X230 has 2 Cores, a 4 logical cores
  nix.settings = {
    max-jobs = 3;
    cores = 3;
  };

  boot.resumeDevice = "/dev/disk/by-uuid/8b4a84dd-2d8e-4236-b3bf-c5b961edc815";
  boot.initrd.luks.devices."crypt-nixos" = {
    device = "/dev/disk/by-uuid/6e00cfe8-f82f-4ca1-ad93-32bea67951c6";
    bypassWorkqueues = true;
    # Potential security implications
    allowDiscards = true;
  };

  networking.hostName = "fractor";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [
    #TODO: Pulseaudio Network Sharing. Probably only needed for publush
    4713
  ];

  networking.ownWireguard = {
    enabled = true;
    lastIPDigit = 2;
  };

  # Affects LUKS unlock
  console.keyMap = "de";

  # Should hopefully not mess with KDE
  services.power-profiles-daemon.enable = false;
  # Power managment, whoop whoop!
  # Valerie: Think this causes sleep issues :/
  services.tlp.enable = true;
  # Maybe this fixes it?
  services.tlp.settings = {
    WIFI_PWR_ON_BAT = "off";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.displayManager.sddm.wayland.enable = true;
  # This separate configuration is necessary?
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.enable = false;
  services.xserver.xkb = {
    layout = "de";
  };

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    foomatic-db
    foomatic-db-nonfree

    (callPackage ../../modules/drivers/printers/kyocera-classic-universal-kpdl/default.nix { })
  ];
  hardware.sane.enable = true;
  hardware.sane.drivers.scanSnap.enable = true;

  hardware.pulseaudio.enable = false;
  # Just for the Port. Need to check if I have to do this
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
  # Clara: Disable built-in bluetooth. It breaks and crashes frequently
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="21e6", ATTR{authorized}="0"
  '';

  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      ControllerMode = "bredr";

      # Die HFP mode, die, die, die!
      Disable = "Headset";
    };
  };

  environment.etc = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
      		bluez_monitor.properties = {
      			["bluez5.enable-sbc-xq"] = true,
      			["bluez5.enable-msbc"] = true,
      			["bluez5.enable-hw-volume"] = true,
                      }
      	'';
    # Trying to disable headset mode, some of these aren't as attrocious as I originally thought though
    #["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
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
    ];
    packages = with pkgs; [
      aircrack-ng
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    # Probably only needed when hosting a source server? Stays disabled for now >:³
    #dedicatedServer.openFirewall = true;
  };

  # IntelGPU Hardware Acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      #intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "i965";
  };

  # TODO: Reread secrets managment with yaml
  sops.secrets."resticPassword" = {
    format = "binary";
    sopsFile = ../../secrets/fractor/restic/resticPassword;
  };
  sops.secrets."resticRestOptions" = {
    format = "binary";
    sopsFile = ../../secrets/fractor/restic/restTransportPassword;
  };
  sops.secrets."resticExcludeFile" = {
    format = "binary";
    sopsFile = ../../secrets/fractor/restic/backup.exclude;
  };
  services.restic.backups."root" = {
    timerConfig = {
      OnCalendar = "wednesday, friday, sunday 22:00";
      Persistent = true;
    };
    # TODO: Generate Certfile and rollout #security
    # TODO: Reference neurodrive port
    repository = "rest:http://192.168.178.56:8193/infinity-fractor/";
    pruneOpts = [
      "--keep-daily 3"
      "--keep-weekly 5"
      "--keep-monthly 10"
      "--keep-yearly 50"
    ];
    paths = [ "/" ];
    passwordFile = config.sops.secrets."resticPassword".path;
    inhibitsSleep = true;
    extraBackupArgs = [
      "--exclude-caches"
      "--exclude-file ${config.sops.secrets.resticExcludeFile.path}"
    ];
    environmentFile = config.sops.secrets."resticRestOptions".path;
    createWrapper = true;
    # TODO: Write script that blocks if the wifi is a hotspot
    #backupPrepareCommand = ;
  };

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
