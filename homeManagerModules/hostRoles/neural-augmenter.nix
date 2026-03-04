{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.hostRoles.neural-augmenter;
  inherit
    (import ../../homeManagerModules/lib/torrent_lib.nix {inherit osConfig pkgs;})
    mullvad-torrent
    vopono-torrent
    ;
in {
  imports = [
    inputs.whisp-away.nixosModules.home-manager
  ];

  options.myOptions.hostRoles.neural-augmenter = {
    enable = lib.mkOption {
      description = "workstation hm settings";
      type = lib.types.bool;
      default = osConfig.myOptions.hostRoles.neural-augmenter.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    myOptions = {
      hostRoles.graphical.enable = lib.mkDefault true;
      roles = {
        development = {
          enable = lib.mkDefault true;
          electronics = lib.mkDefault true;
          reverseEngineering = lib.mkDefault true;
        };
        nvf.enable = lib.mkDefault true;
        gamedev.enable = lib.mkDefault true;
        art = {
          enable = lib.mkDefault true;
          stitching = lib.mkDefault true;
        };
        hyprland.enable = lib.mkDefault true;
      };

      firefox.enable = lib.mkDefault true;
      socials.enable = lib.mkDefault true;

      obsidian = {
        enable = lib.mkDefault true;
        jjAutosync = lib.mkDefault true;
      };
      taskwarrior = {
        enable = lib.mkDefault true;
        enableSync = lib.mkDefault true;
        taskopen = lib.mkDefault true;
      };
      taskwarrior-tui = {
        enable = lib.mkDefault true;
        # TODO: Update and/or move to overlay
        package = with pkgs; (taskwarrior-tui.overrideAttrs (
          _: oldAttrs: rec {
            version = oldAttrs.version + "-fix";
            src = pkgs.fetchFromGitHub {
              owner = "RedEtherbloom";
              repo = "taskwarrior-tui";
              hash = "sha256-YNd4vtaWm+1fsB8ly3toq2u74Nicmhx2ey1m557q4K8=";
              rev = "ee24bfb4a36f246933e6d2502ab85d3fc6abb85b";
            };
            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit src;
              hash = "sha256-7q85YszWmetjWry9nvc2irQeLFCWHwOAkEUHtc9CK/c=";
            };
          }
        ));
      };

      services.piper-web-tts = {
        enable = true;
        model = "en_US-libritts_r-medium";
      };
    };

    home = {
      packages =
        (
          with pkgs;
            [
              tor-browser
              bitwarden-desktop
              bitwarden-cli
              restic
              autorestic
              krita

              # KDE info packages
              clinfo
              mesa-demos
              vulkan-tools
              wayland-utils
              pciutils
              aha
              ddcutil
              usbutils

              ffmpeg-full
              gst_all_1.gst-plugins-good
              gst_all_1.gst-plugins-bad
              handbrake
              imagemagick
              yt-dlp
              bluetui

              vopono
              mullvad-torrent
              vopono-torrent
              tailscale
              # Certificate creation
              xca
              dumbpipe

              speedread

              scrcpy
              android-tools

              podman
              dive
              podman-tui
              podman-compose
              docker-compose
              distrobox

              # sonic-pi Broken as of: 04-03-2026
              reaper
              # mpd players to compare
              cantata
              plattenalbum
              # Subsonic clients
              feishin
              aonsoku

              nix-search-tv # TODO: Evaluate. If useful move to dev tools.

              systemctl-tui

              renderdoc # Debugging render scenes for Minecraft

              # Banking
              hledger
              hledger-ui
              hledger-web
              hledger-fmt
              aqbanking

              wivrn
              wayvr

              # dbus debugging
              bustle
              d-spy

              easyeffects

              qalculate-qt
              nautilus

              sdrpp

              # jambi TODO: Broken build

              camset # Webcam image settings gui

              pwvucontrol
              coppwr # Debugging and low-level configuring of pipewire
              raysession # Patchbay
              rofi-bluetooth

              # Fonts
              nerd-fonts.commit-mono
              powerline-symbols
              powerline-fonts

              # TODO: Find a file manager with vim keybinds

              (
                pkgs.writeShellScriptBin "rofi-home-assistant-sops.sh" ''
                  set -e

                  export HASS_SERVER="http://${osConfig.networking.ownWireguard.hosts.neurodrive.mainIP}:8123"
                  HASS_TOKEN="$(cat ${config.sops.secrets.hass_cli_token.path})"
                  export HASS_TOKEN

                  ${lib.getExe pkgs.rofi-home-assistant-changed}
                ''
              )
            ]
            ++ (with pkgs.kdePackages; [
              ark
              gwenview
              okular
              kate
              ktexteditor
              dolphin
              dolphin-plugins
              baloo-widgets
              ffmpegthumbs
              # Font selector
              kcharselect
            ])
        )
        ++ (lib.optionals osConfig.security.ownAdditional.yubikey (
          with pkgs; [
            yubioath-flutter
            yubikey-manager
          ]
        ));

      sessionVariables = {
        # MOZ_USE_XINPUT2 = "1"; # Smooth scrolling
        # QT_LOGGING_RULES = "*.debug=true";
        PIPEWIRE_DEBUG = 2; # Print warnings and errors
      };
      extraOutputsToInstall = [
        "doc"
        "info"
        "devdoc"
      ];
    };

    services = {
      syncthing.enable = true; # TODO: Setup options
      playerctld.enable = true;
      kdeconnect = {
        enable = true;
        indicator = false;
        package = pkgs.kdePackages.kdeconnect-kde;
      };
      whisp-away = {
        enable = true;
        defaultModel = lib.mkDefault "small.en";
        defaultBackend = lib.mkDefault "whisper-cpp"; # whisper.cpp seems more performant for our use cases
        accelerationType = lib.mkDefault "vulkan";
        useClipboard = lib.mkDefault false; # Typing at cursor position
        useCrane = false; # Broken, as craneLib missing?
      };
    };
    programs = {
      chromium = {
        enable = lib.mkDefault true;
        package = pkgs.chromium.override {enableWideVine = true;};
      };
      nushell.enable = true;
      rofi = {
        enable = lib.mkDefault false;
        terminal = "${config.programs.kitty.package}";
      };
      spotify-player.enable = true;
      bat.enable = true;
      broot.enable = true; # TODO: Give a try for better comparison
      fish.enable = true; # TODO: Try out fish as comparison to zsh
    };

    xdg = {
      autostart = {
        enable = true;
        entries = [
          "${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop"
        ];
      };
      configFile."nix-search-tv/config.json".source = pkgs.writers.writeJSON "nstw-config.json" {
        "update_interval" = "48h0m0s";
        experimental."render_docs_indexes" = {
          "nvf" = "https://notashelf.github.io/nvf/options.html";
        };
      };
    };

    stylix = {
      targets.kde.enable = false;
      enable = true;
      opacity.terminal = 0.85;
    };
  };
}
