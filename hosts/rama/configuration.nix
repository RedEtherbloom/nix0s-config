{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports =
    [
      ../../modules
      ../../modules/cachix.nix
      ../../modules/common/ssh.nix
      ../../modules/hdd.nix
      ./hardware-configuration.nix
    ]
    ++ (with inputs.nixos-hardware.nixosModules; [
      common-pc
      common-pc-ssd
      # Xeon CPU, Westerson
      common-cpu-intel-cpu-only
    ]);

  system.stateVersion = "25.05";
  nix.settings = {
    max-jobs = 20;
    cores = 24;
  };
  sops.secrets."ssh_crypto_key" = {
    sopsFile = "${inputs.our-secrets}/secrets/rama/ssh_crypto_ed25519_key";
    format = "binary";
  };
  boot = {
    kernelModules = ["coretemp" "nct6775"];
    initrd = {
      luks.devices."osdisk" = {
        bypassWorkqueues = true;
        allowDiscards = true;
        device = "/dev/disk/by-uuid/62b8013d-4b21-4bed-98ff-a6316fd23474";
      };
      availableKernelModules = [
        "wireguard"
        # Network adapters
        "bnx2"
        "igb"
        "ixgbe"

        # Dependencies for network kernel mods
        "xfrm_algo"
        "mdio_devres"
        "libphy"
        "ptp"
        "pps_core"
        "mdio"
        "dca"
        "i2c_algo_bit"
        "led_class"
        "fwnode_mdio"
        "fixed_phy"
        "of_mdio"


        # Dependencies for Wireguard
        "curve25519_x86_64"
        "libchacha20poly1305"
        "libcurve25519_generic"
        "ip6_udp_tunnel"
        "udp_tunnel"
        "chacha_x86_64"
        "poly1305_x86_64"
        "libchacha"

        # Speedup decryption
        "aesni_intel"
        "crypto_simd"
        "gf128mul"
      ];
      network = {
        enable = true;
        flushBeforeStage2 = true;
        ssh = {
          enable = true;
          port = 2222;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHKCccanhW2Z05AiItTPhw+CnPFdo66Uszt6K7UuR3r RedEtherbloom @ Neurodrive"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHb7QwlVoCUFmV8O4A5vvo3xERVe/iGlt+k+CbPjXPun RedEtherbloom @ Fractor"
          ];
          hostKeys = [
            config.sops.secrets."ssh_crypto_key".path
          ];
        };
      };
      systemd = {
        extraBin = {
          ping = "${pkgs.iputils}/bin/ping"; 
          tracepath = "${pkgs.iputils}/bin/tracepath"; 
          ip = "${pkgs.iproute2}/bin/ip"; 
          ss = "${pkgs.iproute2}/bin/ss"; 
          ifstat = "${pkgs.iproute2}/bin/ifstat"; 
          rfstat = "${pkgs.iproute2}/bin/rfstat"; 
          lnstat = "${pkgs.iproute2}/bin/lnstat"; 
          devlink = "${pkgs.iproute2}/bin/lnstat"; 
        };
        enable = true;
        services.systemd-networkd = {
          environment.SYSTEMD_LOG_LEVEL = "debug";
          serviceConfig.LoadCredential = ["network.wireguard.private.30-wg1-initrd:/etc/secrets/30-wg1-initrd.key"];
        };
        network = {
          netdevs."30-wg1-initrd" = {
            netdevConfig = {
              Kind = "wireguard";
              Name = "wg1-initrd";
            };
            wireguardPeers = [
              {
                AllowedIPs = ["10.68.0.1/32"];
                PublicKey = "81mzxX6r5pTzNqeofAA3L/xYmzrjOiBKQ8tuvBAWOR8=";
                Endpoint = "51.15.91.213:51820";
                PersistentKeepalive = 25;
              }
            ];
          };
          networks = {
            # DHCP should be auto-configured by systemd, because of initrd.network.enable and networking.useDHCP for ethernet adapters
            "30-wg1-initrd" = {
              name = "wg1-initrd";
              addresses = [
                {
                  Address = "10.68.0.100/24";
                }
              ];
            };
          };
        };
        services.remote-unlock = {
          description = "Unlock via SSH";
          wantedBy = ["initrd.target"];
          after = ["systemd-networkd.service"];
          serviceConfig.Type = "oneshot";
          script = ''
            echo "systemctl default" >> /root/.profile
          '';
        };
      };
      secrets."/etc/secrets/30-wg1-initrd.key" = config.sops.secrets."wireguard/wg1_private".path;
    };
  };

  sops.secrets.cryptostorage = {
    sopsFile = "${inputs.our-secrets}/secrets/rama/cryptstorage.key";
    format = "binary";
  };
  environment.etc."crypttab" = {
    mode = "0600";
    # TOOD: Fill in UUID
    text = ''
      cryptohdd1 UUID=1b8e85bc-1fa5-40e1-a8a1-41a1fbeee936 ${config.sops.secrets.cryptostorage.path} nofail
      cryptohdd2 UUID=ec63cca8-597b-4062-95b3-702088f2359e ${config.sops.secrets.cryptostorage.path} nofail
      cryptossd1 UUID=c5eb36d1-0cdc-43d1-8f20-aa247747d260 ${config.sops.secrets.cryptostorage.path} nofail
    '';
  };
  fileSystems = {
    "/srv/cryptohdd" = {
      device = "/dev/mapper/cryptohdd_vg-cryptohdd";
      fsType = "ext4";
      options = [
        "nofail"
      ];
    };
    "/srv/cryptossd" = {
      device = "/dev/mapper/cryptossd_vg-cryptossd";
      fsType = "ext4";
      options = [
        "nofail"
      ];
    };
  };

  networking = {
    hostName = "rama";
    # Too lazy to figure out proper systemd options
    useNetworkd = true;
    useDHCP = true;

    ownWireguard = {
      enabled = true;
      # TODO: Transfer to server
      currentHost = config.networking.ownWireguard.hosts.rama;
    };
  };

  services = {
    avahi = {
      enable = true;
      openFirewall = true;
    };
    smartd = {
      enable = true;
      autodetect = true;
      notifications = {
        systembus-notify.enable = true;
      };
      defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
    };
  };

  hardware.enableAllFirmware = true;
  myOptions.hostRoles.server.enable = true;
  users.users.inf = {
    isNormalUser = true;
    description = "Infinity";
    initialPassword = "foobar";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHKCccanhW2Z05AiItTPhw+CnPFdo66Uszt6K7UuR3r RedEtherbloom @ Neurodrive"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHb7QwlVoCUFmV8O4A5vvo3xERVe/iGlt+k+CbPjXPun RedEtherbloom @ Fractor"
    ];
    extraGroups = [
      "networkmanager"
      "wheel"
      # Optional, would have to lookup
      "lp"
      "i2c"
      "dialout"
    ];
  };
  environment.systemPackages = with pkgs; [
    smartmontools
  ];
}
