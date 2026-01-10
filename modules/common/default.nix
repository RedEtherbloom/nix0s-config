{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.myOptions.common;
in {
  imports = [
    ./audio.nix
    ./localisation.nix
    ./security.nix
    ./shared_secrets.nix
    ./zsh.nix
  ];

  options.myOptions.common = {
    enableBoot = lib.mkOption {
      description = "Enable common bootloader support";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkMerge [
    {
      nix = {
        package = pkgs.lixPackageSets.latest.lix;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            # Not yet supported by Lix
            #"pipe-operators"
          ];
          trusted-users = ["root" "@wheel" "inf"];
          keep-outputs = true;
          keep-derivations = true;
          # Cache tars for seven days to improve dev experience
          tarball-ttl = 7 * 24 * 3600;
        };
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 5d";
        };
        optimise = {
          automatic = true;
          dates = ["15:00"];
        };
      };
      programs.nix-ld.enable = true;
      hardware.i2c.enable = true;
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    }
    (lib.mkIf cfg.enableBoot {
      boot = {
        kernelPackages = lib.mkOverride 1001 pkgs.linuxPackages_latest;
        loader = {
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
        # Required for plymouth to work in luks
        initrd.systemd.enable = true;
        plymouth.enable = lib.mkDefault true;

        tmp.cleanOnBoot = true;
      };

      # Out of memory management
      systemd.oomd.enable = true;
      services.earlyoom.enable = true;
      # Generate a second, much more verbose boot entry
      # specialisation.verbose-boot.configuration = {
      #   boot.consoleLogLevel = 7;
      #   boot.plymouth.enable = false;
      # };
    })
  ];
}
