{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (import ../../homeManagerModules/lib/torrent_lib.nix { inherit osConfig pkgs; })
    vopono-torrent
    ;
in
{
  imports = [
    ../../homeManagerModules
  ];

  config = lib.mkMerge [
    (
      let
        vopono-torrent-desktop = pkgs.makeDesktopItem {
          name = "Vopono_Torrent";
          desktopName = "Vopono Torrent";
          exec = "${lib.getExe vopono-torrent}";
          icon = "qbittorrent";
          comment = "Start qbittorrent and associated plugins and applications in a vopono workspace.";
          categories = [
            "X-Multimedia"
            "X-Internet"
            "X-Utilities"
          ];
        };
      in
      {
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
            # ALVR alternative while nvenc is broken
            wivrn

            vopono-torrent-desktop

            byar-launcher
            starsector-gl-fix
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
        };

        xdg = {
          desktopEntries = {
            start-vrchat =
              let
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
              in
              {
                name = "Start_VRChat";
                exec = "${lib.getExe launch-vrchat}";
                icon = pkgs.fetchurl {
                  url = "https://wiki-files.vrchat.com/VRLogo.png";
                  hash = "sha256-bmgCzkMDuj/IDnC5F3IzEwXVv1g55By2W0Anh3wbchM=";
                };
                # TODO: Remove after functionality is confirmed
                terminal = true;
                comment = "Launch VRChat using WiVrn with OscAvMgr in the background for proper tracking.";
                categories = [ "X-Games" ];
              };
          };
          autostart = {
            enable = true;
            entries = lib.lists.map (desktop: "${desktop}/share/applications/${desktop.name}") [
              vopono-torrent-desktop
            ];
          };
        };

        myOptions.roles.hyprland.displayConfigurations = {
          dual = {
            name = "Dual";
            monitors = [
              "monitor=desc:BNQ BenQ xl2411t,1920x1080@60.00000,1920x0,1.00000000,transform,0,vrr,0"
              "monitor=desc:AOC 2369M,1920x1080@60.00000,0x0,1.00000000,transform,0,vrr,0"
              "monitor=desc:LG Electronics LG TV,disable"
            ];
          };
          tv = {
            name = "It's TV-Time!";
            monitors = [
              "monitor=desc:LG Electronics LG TV,1920x1080@60.00000,0x0,1.00000000,transform,0,vrr,0"
              "monitor=desc:BNQ BenQ xl2411t,disable"
              "monitor=desc:AOC 2369M,disable"
            ];
          };
        };
        systemd.user = {
          services."morning-layout" =
            {
              Unit.Description = "Switch back to a defined easy layout in the morning, for a blank slate.";
              Service = {
                Type = "oneshot";
                ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/hyprland-layout-Dual.sh";
              };
            };
          timers."morning-layout" = {
            Unit.Description = "Switch back to a defined easy layout in the morning, for a blank slate.";
            Timer = {
              Unit = "morning-layout.service";
              OnCalendar = "07:00:00";
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        };
        # Bind with description on lock screen.
wayland.windowManager.hyprland.settings.binddl = [
          "SUPER SHIFT, R, Reset layout to Dual even when locked, exec, hyprland-layout-Dual.sh" # Intent: 'Reset' combination to bring Hyprland(just monitors for now) back to a good state.
        ];
      }
    )
  ];
}
