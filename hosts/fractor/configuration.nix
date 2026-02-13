{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
    ../../modules
    ../../modules/common/ssh.nix
    # TODO: Remove once hm sops-nix supports secrets
    ../../modules/common/taskwarrior-secrets.nix
    ./restic.nix
    ./hardware-configuration.nix
  ];

  # TODO: Lookup proper X270 settings
  nix.settings = {
    max-jobs = 6;
    cores = 6;
  };

  boot = {
    binfmt.emulatedSystems = ["aarch64-linux"];
    # Attempt to fix some intel stuttering
    # kernelParams = [
    #   "i915.enable_psr=0"
    #   "i915.enable_fbc=0"
    #   "intel_idle.max_cstate=1"
    # ];
    kernelParams = [
      "iwlwifi.bt_coex_active=0" # Attempt to improve bluetooth reliability
    ];
    resumeDevice = "/dev/disk/by-uuid/6960c42d-4b92-474d-aeae-e550d670be12";
    initrd = {
      systemd.enable = true;
      luks.devices."luks" = {
        device = "/dev/disk/by-uuid/7da6adea-a5ff-4044-bd33-38decf43fd60";
        # Needs to be enrolled with systemd-cryptenroll, with sudo systemd-cryptenroll --fido2-with-client-pin=true --fido2-device=auto <disk id>
        crypttabExtraOpts = ["fido2-device=auto"];
        bypassWorkqueues = true;
        # Potential security implications
        allowDiscards = true;
      };
    };
  };

  networking = {
    hostName = "fractor";
    # Set MTU to account for some pickier wifi's
    wireguard.interfaces = {
      "wg0".mtu = 1312;
      "wg1".mtu = 1312;
    };
  };

  services = {
    # Does this have to be replaced with home-manager?
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        foomatic-db
        foomatic-db-nonfree
      ];
    };
    udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0a5c", ATTRS{idProduct}=="21e6", ATTR{authorized}="0"
    '';
  };

  hardware = {
    sane = {
      enable = true;
      drivers.scanSnap.enable = true;
    };
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        libvdpau-va-gl
      ];
    };
  };

  environment = {
    sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  };

  myOptions = {
    hostRoles.laptop.enable = true;
    roles.gaming.enable = true;
    roles.i2p.enable = lib.mkForce false; # Broken as of: 15.10.2025
  };

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
      "dialout"
    ];
  };

  stylix.image = "${secrets}/dotfiles/wallpapers/cyborg_girl_tactical.jpg";
  system.stateVersion = "23.11";
}
