{
  lib,
  osConfig,
  pkgs,
  ...
}: {
  imports = [
    ../../homeManagerModules
  ];

  config = {
    home = {
      stateVersion = "24.05";
      packages = with pkgs; [
        # FNV Mod launcher
        zenity
        yad

        koboldcpp
        sillytavern

        coolercontrol.coolercontrol-gui
        gsmartcontrol

        # VRChat tools
        oscavmgr
        vrcadvert
        vrcx
        sidequest
        wivrn

        beyond-all-reason
        starsector-gl-fix

        shikane
      ];
    };

    myOptions = {
      solaar = {
        enable = true;
        autostart.enable = true;
      };
    };

    # Let's try out McFly on our beefier machine
    programs = {
      mcfly = {
        enable = false;
        fzf.enable = true;
        keyScheme = "vim";
      };
      btop.package = pkgs.btop-cuda;
      obs-studio.enable = true;
      niri.settings.binds."Mod+Ctrl+Equal" = {
        hotkey-overlay.title = "Reset displays to dual layout";
        allow-inhibiting = false;
        allow-when-locked = true;
        action.spawn = lib.strings.splitString " " "${pkgs.shikane}/bin/shikanectl switch dual";
      };
    };

    xdg = {
      desktopEntries = {
        start-vrchat = let
          launch-oscavmgr = pkgs.writeShellApplication {
            name = "launch-oscavmgr";
            runtimeInputs = with pkgs; [
              oscavmgr
              vrcadvert
            ];
            text = ''
              # Kill all applications once the non-bged exits
              trap 'jobs -p | xargs kill' EXIT

              VrcAdvert OscAvMgr 9402 9002 --tracking &
              # Wivrn support
              oscavmgr openxr
            '';
          };
          launch-vrchat = pkgs.writeShellApplication {
            name = "launch-vrchat";
            runtimeInputs = [
              launch-oscavmgr
              osConfig.programs.steam.package
            ];
            text = ''
              launch-oscavmgr &
              # VRChat App ID
              steam -applaunch 438100
            '';
          };
        in {
          name = "Start_VRChat";
          exec = "${lib.getExe launch-vrchat}";
          icon = pkgs.fetchurl {
            url = "https://wiki-files.vrchat.com/VRLogo.png";
            hash = "sha256-bmgCzkMDuj/IDnC5F3IzEwXVv1g55By2W0Anh3wbchM=";
          };
          # TODO: Remove after functionality is confirmed
          terminal = true;
          comment = "Launch VRChat using WiVrn with OscAvMgr in the background for proper tracking.";
          categories = ["X-Games"];
        };
      };
      autostart.enable = true;
    };
    systemd.user = {
      services."morning-layout-niri" = {
        Unit = {
          Description = "Switch back to a defined easy layout in the morning, for a blank slate.";
          ConditionEnvironment = lib.mkForce [
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP=niri"
          ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.shikane}/bin/shikanectl switch dual";
        };
      };
      timers."morning-layout-niri" = {
        Unit.Description = "Switch back to a defined easy layout in the morning, for a blank slate.";
        Timer = {
          Unit = "morning-layout-niri.service";
          OnCalendar = "07:00:00";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
    # Go back to a normal layout after long inactivity. Hoping for this to be especially useful in the morning
    services.swayidle.timeouts = [
      {
        timeout = 2 * 60 * 60;
        command = "${pkgs.systemd}/bin/systemctl start --user morning-layout-niri.service";
      }
    ];
  };
}
