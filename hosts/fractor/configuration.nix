{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x230

    ../../modules
    ../../modules/common/ssh.nix
    # TODO: Remove once hm sops-nix supports secrets
    ../../modules/common/taskwarrior-secrets.nix

    ./restic.nix
    ./hardware-configuration.nix
  ];

  nixpkgs.system = "x86_64-linux";
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];
  # X230 has 2 Cores, a 4 logical cores
  nix.settings = {
    max-jobs = 6;
    cores = 6;
  };

  # boot.loader.grub.gfxmodeEfi = "1366x768";
  boot.resumeDevice = "/dev/disk/by-uuid/6960c42d-4b92-474d-aeae-e550d670be12";
  boot.initrd.luks.devices."luks" = {
    device = "/dev/disk/by-uuid/7da6adea-a5ff-4044-bd33-38decf43fd60";
    bypassWorkqueues = true;
    # Potential security implications
    allowDiscards = true;
  };

  networking.hostName = "fractor";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [
    #TODO: Pulseaudio Network Sharing. Probably only needed for publish
    4713
  ];

  networking.ownWireguard = {
    enabled = true;
    currentHost = config.networking.ownWireguard.hosts.fractor;
  };

  # Should hopefully not mess with KDE
  services.power-profiles-daemon.enable = true;
  # Power managment, whoop whoop!
  # Valerie: Think this causes sleep issues :/
  # services.tlp.enable = true;
  # Maybe this fixes it?
  # services.tlp.settings = {
  #   WIFI_PWR_ON_BAT = "off";
  #   USB_EXCLUDE_BTUSB = 1;
  # };

  services.displayManager.sddm.wayland.enable = true;
  # This separate configuration is necessary?
  services.displayManager.sddm.enable = true;
  # Does this have to be replaced with home-manager?
  services.desktopManager.plasma6.enable = true;

  services.xserver.enable = false;
  # May break due to age on the X230
  services.xserver.videoDrivers = ["modesetting"];

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    foomatic-db
    foomatic-db-nonfree

    # (callPackage ../../modules/drivers/printers/kyocera-classic-universal-kpdl/default.nix {})
  ];
  hardware.sane.enable = true;
  hardware.sane.drivers.scanSnap.enable = true;

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

  myOptions.hostRoles.laptop.enable = true;
  myOptions.roles.gaming.enable = true;
  # Setup event setup and hardening etc.
  myOptions.event-setup.enable = false;
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
      "dialout"
    ];
    packages = with pkgs; [
      aircrack-ng
    ];
  };
  stylix.image = "${inputs.our-secrets}/dotfiles/wallpapers/current_wallpaper";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # Recommended against in docs
    # nssmdns6 = true;
    openFirewall = true;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      # intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
