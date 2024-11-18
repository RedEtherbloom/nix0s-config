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

  # TODO: Replace with grub
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # TODO: This is a bit too verbose for my taste
  # Sedna: Can we build a second boot entry that uses this consoleLogLevel? 
  boot.consoleLogLevel = 7;
  # TODO: Redo
  boot.plymouth.enable = true;

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
