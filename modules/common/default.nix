{ lib, pkgs, ... }:
{
  imports = [
    ./audio.nix
    ./base_pkgs.nix
    ./localisation.nix
    ./restic.nix
    ./security.nix
    ./zsh.nix
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 14d";
    };
    optimise = {
      automatic = true;
      dates = [
        "15:00"
      ];
    };
  };
  programs.nix-ld.enable = true;
  programs.appimage.binfmt = true;

  hardware.i2c.enable = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    enableCryptodisk = true;
    efiSupport =  true;
    copyKernels = true;
    fsIdentifier = "uuid";
    useOSProber = true;
    device = "nodev";

    memtest86.enable = true;
    extraEntries = ''
      menuentry "Poweroff" {
        halt
      }

      menuentry "Reboot" {
        reboot
      }

      menuentry "UEFI Setup" {
        fwsetup
      }
    '';
  };
  # Generate a second, much more verbose boot entry
  specialisation.verbose-boot.configuration.boot.consoleLogLevel = 7;

  # Required for plymouth to work in luks
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}