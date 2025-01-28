{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.common;
in {
  imports = [
    ./audio.nix
    ./localisation.nix
    ./restic.nix
    ./security.nix
    ./shared_secrets.nix
    ./zsh.nix
  ];

  options.myOptions.common = {
    enableBoot = mkOption {
      description = "Enable common bootloader support";
      type = types.bool;
      default = true;
    };
  };

  config = mkMerge [
    {
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
      hardware.i2c.enable = true;
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    }
    (mkIf cfg.enableBoot {
      boot.kernelPackages = lib.mkOverride 1001 pkgs.linuxPackages_latest;
      boot.loader = {
        efi.canTouchEfiVariables = true;
        timeout = 2;
        grub = lib.mkDefault {
          enable = true;
          enableCryptodisk = true;
          efiSupport = true;
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
      };
      # Generate a second, much more verbose boot entry
      # specialisation.verbose-boot.configuration = {
      #   boot.consoleLogLevel = 7;
      #   boot.plymouth.enable = false;
      # };

      # Plymouth keeps crashing
      # Required for plymouth to work in luks
      # boot.initrd.systemd.enable = true;
      # boot.plymouth.enable = lib.mkDefault true;
    })
  ];
}
