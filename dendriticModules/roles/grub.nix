{
  flake.nixosModules.grub = {
    pkgs,
    lib,
    ...
  }: {
    boot = {
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
      initrd.systemd = {
        enable = true;
        package = pkgs.systemd-token-timeout-patched;
      };
    };
  };
}
