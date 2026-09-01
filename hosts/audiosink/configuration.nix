{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}: let
  networkSinkPort = 4713;
in {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix

    ../../modules/ssh.nix
    ../../modules/roles/ssdp.nix
    # TODO: Try to insert normal modules again
  ];

  myOptions.roles.ssdp.enable = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise = {
      automatic = true;
      dates = ["07:00"];
    };
  };
  swapDevices = [
    {
      size = 8192;
      device = "/var/swapfile";
    }
  ];

  sops.secrets."wifi.env" = {
    sopsFile = "${secrets}/secrets/common/wifi.yaml";
    # Whole file
    key = "wifiHome";
  };
  networking = {
    hostName = "audiosink";
    networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [
          config.sops.secrets."wifi.env".path
        ];
        profiles = {
          "HomeWifi" = {
            connection = {
              id = "$WIFI_SSID";
              type = "wifi";
              interface-name = "wlan0";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$WIFI_SSID";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PASSWORD";
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              addr-gen-mode = "default";
              method = "auto";
            };
            proxy = {};
          };
        };
      };
    };
    firewall.allowedTCPPorts = [
      # MPD1
      6600
      # MPD2
      6601
      # Modidy HTTP
      6680
      # TODO: Insert mediatomb port
      # Home Assistant
      8123
    ];
  };

  security.rtkit.enable = true;
  services = {
    timesyncd.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false;
      wireplumber.enable = true;
      extraConfig.pipewire-pulse = {
        "30-network-publish" = {
          "pulse.cmd" = [
            {
              cmd = "load-module";
              args = "module-native-protocol-tcp";
            }
            {
              cmd = "load-module";
              args = "module-zeroconf-publish";
            }
          ];
        };
      };
    };
    avahi = {
      enable = true;
      # Lookup which get enabled by default
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        userServices = true;
      };
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
    };
    syncthing = {
      enable = true;
      openDefaultPorts = true;
    };
  };

  # Should probably be redone with home-manager(Clara: Learning curve, yayyy...)
  systemd = {
    user.services = {
      pipewire-pulse = {
        after = [
          "network-online.target"
          "sound.target"
          "bluetooth.target"
        ];
        wants = [
          "network-online.target"
          "sound.target"
          "bluetooth.target"
        ];
        wantedBy = ["default.target"];
      };
    };
    services = {
      stop-network-sink = {
        description = "Close the port for the pipewire service during night.";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "closeNetworkSinkPort";
              runtimeInputs = with pkgs; [
                iptables
                nixos-firewall-tool
              ];
              text = ''
                nixos-firewall-tool reset
              '';
            }
          );
        };
        conflicts = ["restart-network-sink.service"];
      };
      restart-network-sink = {
        description = "Restart librespot in the morning.";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "openNetworkSinkPort";
              text = ''
                nixos-firewall-tool open tcp ${toString networkSinkPort}
              '';
              runtimeInputs = with pkgs; [
                iptables
                nixos-firewall-tool
              ];
            }
          );
        };
      };
      network-sink-after-boot = {
        description = "Decide after boot what state the firewall should be in..";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (
            pkgs.writeShellScriptBin "networkSinkPortBoot" ''
              HOUR=$(date +%H)
              if [ "$HOUR" -lt 22 ] && [ "$HOUR" -ge 8 ]; then
                systemctl start retart-network-sink.service
              else
                systemctl start stop-network-sink.service
              fi
            ''
          );
        };
      };
    };
    timers = {
      # Stop during the night to avoid accidental pairing
      stop-network-sink = {
        # TODO: Need additional boot condition
        timerConfig = {
          Persistent = true;
          OnCalendar = "*-*-* 22:00:00";
        };
      };
      restart-network-sink = {
        # TODO: Need additional boot condition
        timerConfig = {
          # Avoid accidental start durng the night, in case of inconvenient reboot
          Persistent = false;
          OnCalendar = "*-*-* 08:00:00";
        };
      };
    };
  };

  users.users.inf = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio"
      "i2c"
    ];
    linger = true;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  programs = {
    tmux.enable = true;
    git.enable = true;
    htop.enable = true;
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      # Advertise as Audio sink
      settings.General.Enable = "Source";
    };
    i2c.enable = true;
  };

  system.stateVersion = "25.05";
}
