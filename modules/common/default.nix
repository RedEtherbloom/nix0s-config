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

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.joypixels.acceptLicense = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
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

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.consoleLogLevel = 7;
  # TODO: Redo
  boot.plymouth = with pkgs; {
    enable = true;
    theme = "breeze";
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  hardware.i2c.enable = true;
}
