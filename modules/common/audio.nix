# TODO: Split into NixOS and Home-Manager wireplumber configuration
{
  services.pulseaudio = {
    enable = false;
    # Just for the Port. Need to check if I have to do this
    zeroconf.discovery.enable = true;
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    raopOpenFirewall = true;
    extraConfig = {
      pipewire = {
        "10-airplay" = {
          "context.modules" = [
            {
              name = "libpipewire-module-raop-discover";
              # In case of lagging: Increase buffer size
            }
          ];
        };
      };
      pipewire-pulse = {
        "switch-on-connect" = {
          "pulse.cmd" = [
            {
              "cmd" = "load-module";
              "args" = "module-switch-on-connect";
            }
          ];
        };
      };
    };
    # JACK devices somehow break the system
    # Needed for sonic-pi
    jack.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        # "log-level-debug" = {
        #   "context.properties" = {
        #     # Output Debug log messages as opposed to only the default level (Notice)
        #     "log.level" = "I";
        #   };
        # };
        # TODO: Move to home-manager
        "bluez-audio-quality" = {
          "bluez_monitor.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
          };
        };
        "no-headset-autoswitch" = {
          "monitor.bluez.rules" = [
            {
              matches = [
                {"node.name" = "~bluez_output.*";}
                {"node.name" = "~bluez_input.*";}
              ];
              actions = {
                update-props = {
                  "bluetooth.autoswitch-to-headset-profile" = "false";
                  # Share volume with headset
                  "bluez5.enable-hw-volume" = true;
                };
              };
            }
          ];
        };
        "bluez-longer-pause" = {
          "monitor.bluez.rules" = [
            {
              # TODO: May need to be set on monitor.alsa.<etc> instead
              matches = [
                {"node.name" = "~bluez_output.*";}
                {"node.name" = "~bluez_input.*";}
              ];
              actions = {
                update-props = {
                  "session.suspend-timeout-seconds" = 15;
                };
              };
            }
          ];
        };
      };
    };
  };
}
