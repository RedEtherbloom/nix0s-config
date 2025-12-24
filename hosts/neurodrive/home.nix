{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (import ../../homeManagerModules/lib/plasma_lib.nix { inherit pkgs; })
    define-kscreen-layout
    ;
  inherit (import ../../homeManagerModules/lib/torrent_lib.nix { inherit osConfig pkgs; })
    vopono-torrent
    ;
in
{
  imports = [
    ../../homeManagerModules
  ];

  options.myOptions.services = {
    piper-web-tts = {
      enable = lib.mkOption {
        description = "Autostart a local piper server for fluid tts playback.";
        type = lib.types.bool;
        default = false;
      };
      package = lib.mkOption {
        description = "Piper package to use";
        type = lib.types.package;
        default = pkgs.piper-tts;
      };
      model = lib.mkOption {
        description = "Name of model or part to model";
        type = lib.types.either lib.types.str lib.types.path;
      };
      data-dir = lib.mkOption {
        description = "Data directory for model download";
        type = lib.types.either lib.types.str lib.types.path;
        default = "$HOME/.local/share/piper";
      };
      install-in-speech-dispatcher = lib.mkOption {
        description = "Whether to install this piper instance as a speech-dispatcher option automatically";
        type = lib.types.bool;
        default = false;
      };
    };
  };

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
          plasma-manager.enable = true;
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
        # 22.11.2025: Temporary until KDE issues with QT/Stylix can be resolved
        stylix.targets.qt.enable = false;

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
              "monitor=desc:LG Electronics LG TV,1920x1080@60.00000,00x0,1.00000000,transform,0,vrr,0"
              "monitor=desc:BNQ BenQ xl2411t,disable"
              "monitor=desc:AOC 2369M,disable"
            ];
          };
        };

        myOptions.services.piper-web-tts = {
          enable = true;
          model = "en_US-libritts_r-medium";
        };
      }
    )
    (define-kscreen-layout "benq"
      "output.DP-3.disable output.HDMI-A-1.disable output.DP-2.enable output.DP-2.rotation.normal output.DP-2.position.0,0"
      "ctrl+shift+f1"
    )
    (define-kscreen-layout "dual"
      "output.HDMI-A-1.disable output.DP-2.enable output.DP-2.position.1080,420 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.right output.DP-3.position.0,0"
      "ctrl+shift+f2"
    )
    (define-kscreen-layout "aoc"
      "output.HDMI-A-1.disable output.DP-3.enable output.DP-3.position.0,0 output.DP-3.rotation.right output.DP-2.disable"
      "ctrl+shift+f3"
    )
    (define-kscreen-layout "lg"
      "output.DP-2.disable output.DP-3.disable output.HDMI-A-1.enable output.HDMI-A-1.position.0,0"
      "ctrl+shift+f4"
    )
    (define-kscreen-layout "lg-aoc"
      "output.DP-2.disable output.HDMI-A-1.enable output.HDMI-A-1.position.1080,420 output.HDMI-A-1.priority.1 output.DP-3.enable output.DP-3.position.0,0 output.DP-3.rotation.right"
      "ctrl+shift+f5"
    )
    (define-kscreen-layout "lg-benq"
      "output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.disable output.HDMI-A-1.enable output.HDMI-A-1.position.1920,0 output.HDMI-A-1.rotation.normal output.HDMI-A-1.priority.2"
      "ctrl+shift+f6"
    )
    (define-kscreen-layout "trial"
      "output.DP-2.enable output.DP-2.position.1080,420 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.right output.DP-3.position.0,0 output.DP-3.priority.2 output.HDMI-A-1.enable output.HDMI-A-1.position.3000,420 output.HDMI-A-1.rotation.normal output.HDMI-A-1.priority.3"
      "ctrl+shift+f7"
    )
    (define-kscreen-layout "dual-both-horizontal"
      "output.HDMI-A-1.disable output.DP-2.enable output.DP-2.position.1920,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.normal output.DP-3.position.0,0"
      "ctrl+shift+f8"
    )
    (lib.mkIf config.myOptions.services.piper-web-tts.enable {
      systemd.user = {
        services = {
          piper-web-tts = {
            Unit = {
              Description = "Local Piper-Web Service for local TTS Streaming";
            };
            Service = {
              Type = "exec";

              ExecStart =
                let
                  python = pkgs.python313.withPackages (
                    ps: with ps; [
                      (pkgs.python3Packages.toPythonModule config.myOptions.services.piper-web-tts.package)
                    ]
                  );
                in
                lib.getExe (
                  pkgs.writeShellApplication {
                    name = "piper-web-tts";
                    runtimeInputs = with pkgs; [
                      fd
                      python
                      config.myOptions.services.piper-web-tts.package
                    ];

                    excludeShellChecks = [
                      "SC2046"
                      "SC2050"
                    ];

                    text = ''
                      export DATA_DIR="${config.myOptions.services.piper-web-tts.data-dir}"

                      mkdir -p "$DATA_DIR"

                      # Check if the model is already downloaded, in case model is not a path.
                      if ! [[ "${config.myOptions.services.piper-web-tts.model}" =~ "/" ]] && ! [ $(fd -q "${config.myOptions.services.piper-web-tts.model}" "$DATA_DIR" ) ]; then
                        python -m piper.download_voices "${config.myOptions.services.piper-web-tts.model}"
                      fi

                      python -m piper.http_server -m ${config.myOptions.services.piper-web-tts.model}

                    '';
                  }
                );
            };
            Install = {
              # Auto-start, to avoid delay
              # TODO: Offer startup via TCP socket
              WantedBy = [ "default.target" ];
            };
          };
        };
      };

    })
  ];
}
