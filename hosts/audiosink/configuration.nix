{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  networkSinkPort = 4713;
in {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix
    ./raspberry_pi_binary_cache.nix

    ../../modules/common/ssh.nix
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
      trusted-users = ["root" "@wheel" "inf"];
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

  systemd.tmpfiles.settings = {
    "10-media-directory" = {
      "/srv/media-directory" = {
        d = {
          group = "media";
          user = config.systemd.services.minidlna.serviceConfig.User;
          mode = "0775";
        };
      };
      "/srv/media-directory/music" = {
        d = {
          group = "media";
          user = config.systemd.services.minidlna.serviceConfig.User;
          mode = "0775";
        };
      };
      "/srv/media-directory/videos" = {
        d = {
          group = "media";
          user = config.systemd.services.minidlna.serviceConfig.User;
          mode = "0775";
        };
      };
      "/srv/media-directory/images" = {
        d = {
          group = "media";
          user = config.systemd.services.minidlna.serviceConfig.User;
          mode = "0775";
        };
      };
    };
  };

  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      media_dir = [
        "/srv/media-directory"
      ];
      wide_links = "yes";
      inotify = "yes";
    };
  };

  sops.secrets."wifi.env" = {
    sopsFile = "${inputs.our-secrets}/secrets/common/wifi.yaml";
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
            ipv4 = {method = "auto";};
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
    syncthing.enable = true;
  };

  # Should probably be redone with home-manager(Clara: Learing curve, yayyy...)
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
          ExecStart = lib.getExe (pkgs.writeShellApplication {
            name = "closeNetworkSinkPort";
            runtimeInputs = with pkgs; [
              iptables
              nixos-firewall-tool
            ];
            text = ''
              nixos-firewall-tool reset
            '';
          });
        };
        conflicts = ["restart-network-sink.service"];
      };
      restart-network-sink = {
        description = "Restart librespot in the morning.";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (pkgs.writeShellApplication {
            name = "openNetworkSinkPort";
            text = ''
              nixos-firewall-tool open tcp ${builtins.toString networkSinkPort}
            '';
            runtimeInputs = with pkgs; [
              iptables
              nixos-firewall-tool
            ];
          });
        };
      };
      network-sink-after-boot = {
        description = "Decide after boot what state the firewall should be in..";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (pkgs.writeShellScriptBin "networkSinkPortBoot" ''
            HOUR=$(date +%H)
            if [ "$HOUR" -lt 22 ] && [ "$HOUR" -ge 8 ]; then
              systemctl start retart-network-sink.service
            else
              systemctl start stop-network-sink.service
            fi
          '');
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

  users = {
    groups = {
      media = {};
    };
    users = {
      inf = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "audio"
          "i2c"
          "podman"
          "media"
        ];
        linger = true;
      };
      minidlna.extraGroups = ["media"];
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    podman
    podman-compose
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
  # Enable common container config files in /etc/containers
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        # How do we backup this?
        volumes = ["home-assistant:/config"];
        environment.TZ = "Europe/Berlin";
        # Okay? What does this mean?
        # Note: The image will not be updated on rebuilds, unless the version label changes
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [
          # Use the host network namespace for all sockets
          "--network=host"
          # Pass devices into the container, so Home Assistant can discover and make use of them
          # "--device=/dev/ttyACM0:/dev/ttyACM0"
        ];
      };
    };
  };

  system.stateVersion = "25.05";
}
