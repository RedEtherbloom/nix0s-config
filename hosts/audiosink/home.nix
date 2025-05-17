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

  services.librespot = {
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
