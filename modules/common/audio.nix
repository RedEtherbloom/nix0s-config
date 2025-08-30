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
    extraConfig.pipewire-pulse = {
      "switch-on-connect" = {
        "pulse.cmd" = [
          {
            "cmd" = "load-module";
            "args" = "module-switch-on-connect";
          }
        ];
      };
    };
    # JACK devices somehow break the system
    # Needed for sonic-pi
    jack.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        "c310-sample-rate" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "device.product.name" = "Webcam C310";
                  "device.product.id" = "0x081b";
                  "device.vendor.id" = "0x046d";
                }
              ];
              actions = {
                update-props = {
                  "default.clock.rate" = 16000;
                };
              };
            }
            {
              matches = [
                {
                  "node.name" = "~alsa_input.usb-046d_081b*";
                }
              ];
              actions = {
                update-props = {
                  # Disable Pro Audio, it does weird things
                  "audio.position" = "MONO";
                };
              };
            }
          ];
        };
        # "log-level-debug" = {
        #   "context.properties" = {
        #     # Output Debug log messages as opposed to only the default level (Notice)
        #     "log.level" = "D";
        #   };
        # };
        "bose-qc35" = {
          "monitor.bluez.rules" = [
            {
              matches = [
                {
                  # Match any bluetooth device with ids equal to that of a WH-1000XM3
                  "device.name" = "~bluez_card.*";
                  "device.product.id" = "0x4020";
                  # Hope this won't match our bluetooth adapter
                  "device.vendor.id" = "bluetooth:009e";
                }
              ];
              actions = {
                update-props = {
                  # Set quality to high quality instead of the default of auto
                  "bluez5.a2dp.ldac.quality" = "hq";
                  "bluetooth.autoswitch-to-headset-profile" = "false";
                  # Share volume with headset
                  "bluez5.enable-hw-volume" = true;
                };
              };
            }
          ];
        };
        "bluez-longer-pause" = {
          # TODO: May need to be set on monitor.alsa.<etc> instead
          "monitor.bluez.rules" = [
            {
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
