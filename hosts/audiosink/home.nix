{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.stateVersion = "25.05";
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  xdg.configFile."pulse/cookie" = {
    enable = true;
    source = "${inputs.our-secrets}/secrets/common/pulse_cookie";
  };

  services = {
    # TODO: Think if we wouldn't rather use mopidy-spotify instead
    librespot = {
      enable = true;
      package = pkgs.librespot;
      settings = {
        "name" = "spotify_pi";
        "device-type" = "speaker";
        "enable-oauth" = true;
        # Headless login
        "oauth-port" = 0;
      };
    };
    mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/Music";
      network.listenAddress = "any";
      extraConfig = ''
        audio_output {
          type "pipewire"
          name "PipeWire Sound Server"
        }
      '';
    };
    mpdris2.enable = true;
    mopidy = {
      enable = true;
      extensionPackages = with pkgs; [
        mopidy-mpd
        mopidy-mpris
      ];
      settings = {
        file = {
          media_dirs = [
            "$HOME/Music|Music"
            "/srv/media-directory/music|Global music"
          ];
          follow_symlinks = true;
        };
        mpd = {
          # Listen on all IPs
          hostname = "::";
          port = 6601; 
        };
      };
    };
  };

  systemd.user = {
    services = {
      stop-librespot = {
        Unit = {
          Description = "Stop librespot during the night.";
        };
        Service = {
          Type = "oneshot";
          # TODO: Insert systemd unit name
          # Maybe this should be a list?
          Conflicts = "librespot.service restart-librespot.service";
        };
      };
      restart-librespot = {
        Unit = {
          Description = "Restart librespot in the morning.";
        };
        Service = {
          Wants = "librespot.service";
        };
      };
    };
    timers = {
      # Stop during the night to avoid accidental pairing
      stop-librespot = {
        Unit = {
          Description = "Stop librespot during the night.";
        };
        Timer = {
          Persistent = true;
          OnCalendar = "*-*-* 22:00:00";
        };
      };
      restart-librespot = {
        Unit = {
          Description = "Restart librespot on the new day.";
        };
        Timer = {
          # Avoid accidental start durng the night, in case of inconvenient reboot
          Persistent = false;
          OnCalendar = "*-*-* 08:00:00";
        };
      };
    };
  };
}
