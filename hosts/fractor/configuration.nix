{
  inputs,
  self,
  ...
}: {
  flake = {
    nixosModules = {
      fractor = {
        lib,
        pkgs,
        secrets,
        ...
      }: {
        imports = [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
          self.nixosModules.neural-augmenter
          self.nixosModules.gaming
          self.nixosModules.fractor-restic
          self.nixosModules.fractor-hardware-configuration
          ./hardware-configuration.nix
        ];
        home-manager.sharedModules = [
          self.homeModules.fractor
        ];

        # TODO: Lookup proper X270 settings
        nix.settings = {
          max-jobs = 6;
          cores = 6;
        };

        boot = {
          binfmt.emulatedSystems = ["aarch64-linux"];
          resumeDevice = "/dev/disk/by-uuid/6960c42d-4b92-474d-aeae-e550d670be12";
          initrd = {
            kernelModules = [
              "aesni_intel"
            ];
            systemd.enable = true;
            luks.devices."luks" = {
              device = "/dev/disk/by-uuid/7da6adea-a5ff-4044-bd33-38decf43fd60";
              # Needs to be enrolled with systemd-cryptenroll, with sudo systemd-cryptenroll --fido2-with-client-pin=true --fido2-device=auto <disk id>
              crypttabExtraOpts = [
                # "fido2-device=auto"
                "token-timeout=10s"
              ];
              bypassWorkqueues = true;
              # Potential security implications
              allowDiscards = true;
            };
          };
        };

        networking.hostName = "fractor";
        services = {
          # Does this have to be replaced with home-manager?
          printing = {
            enable = true;
            drivers = [
              pkgs.gutenprint
              pkgs.foomatic-db
              pkgs.foomatic-db-nonfree
            ];
          };
          # Disable inbuilt bluetooth to avoid wifi-bluetooth issues
          udev.extraRules = ''
            SUBSYSTEM=="usb", ATTRS{idVendor}=="8087", ATTRS{idProduct}=="0a2b", ATTR{authorized}="0"
          '';
        };

        hardware = {
          sane = {
            enable = true;
            drivers.scanSnap.enable = true;
          };
          graphics = {
            enable = true;
            extraPackages = [
              pkgs.intel-media-driver
              pkgs.intel-vaapi-driver
              pkgs.libvdpau-va-gl
            ];
          };
        };

        environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

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
      };
      fractor-hardware-configuration = {
        imports = [./hardware-configuration.nix];
      };
    };
    homeModules.fractor = {pkgs, ...}: {
      home = {
        stateVersion = "24.05";
        packages = [
          pkgs.aircrack-ng
        ];
      };

      programs.niri.settings.outputs."eDP-1".scale = 1.0;
    };
  };
}
