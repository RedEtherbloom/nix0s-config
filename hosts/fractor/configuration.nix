{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./restic.nix 

    ../../modules/common/default.nix
    ../../modules/common/ssh.nix
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

  # Should hopefully not mess with KDE
  services.power-profiles-daemon.enable = false;
  # Power managment, whoop whoop!
  # Valerie: Think this causes sleep issues :/
  services.tlp.enable = true;
  # Maybe this fixes it?
  services.tlp.settings = {
    WIFI_PWR_ON_BAT = "off";
  };

  services.displayManager.sddm.wayland.enable = true;
  # This separate configuration is necessary?
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "intel" ];

  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    foomatic-db
    foomatic-db-nonfree

    (callPackage ../../modules/drivers/printers/kyocera-classic-universal-kpdl/default.nix { })
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
      "i2c"
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

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
