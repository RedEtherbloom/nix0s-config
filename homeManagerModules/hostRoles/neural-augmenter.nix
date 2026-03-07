{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  secrets,
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
      description = "Workstation hm settings";
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
      };
      firefox.enable = lib.mkDefault true;
      socials.enable = lib.mkDefault true;
      obsidian = {
        enable = lib.mkDefault true;
        jjAutosync = lib.mkDefault true;
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
              rofi-rbw
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
              imagemagick
              yt-dlp

              gnome-keyring
              seahorse
              gcr

              vopono
              mullvad-torrent
              vopono-torrent
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
              waystt

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
              wdisplays
              wev
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
              kcharselect # Font selector
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
      pointerCursor = {
        gtk.enable = true;
        package = pkgs.lyra-cursors;
        name = "LyraG-cursors";
        size = 36;
      };
      activation.rebuildKdeXdgCache = lib.hm.dag.entryAfter ["writeBoundary"] "run ${pkgs.kdePackages.kservice.out}/bin/kbuildsycoca6"; # Rebuild cache for dolphin
    };

    services = {
      syncthing.enable = true;
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
        extraConfig.show-icons = true;
        theme = ../../dotfiles/rofi/launcher.rasi;
      };
      spotify-player.enable = true;
      bat.enable = true;
      broot.enable = true; # TODO: Give a try for better comparison
      fish.enable = true; # TODO: Try out fish as comparison to zsh
    };

    xdg = {
      autostart = {
        enable = true;
        entries = ["${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop"];
      };
      portal = {
        enable = lib.mkForce true;
        xdgOpenUsePortal = true;
        extraPortals = with pkgs; [
          gnome-keyring
          xdg-desktop-portal-gtk
        ];
      };
      stateFile."piper-models/.keep".text = "";
    };

    stylix = {
      enable = true;
      targets = {
        kde.enable = true;
        rofi.enable = false;
      };
      opacity.terminal = 0.8;
    };

    # Required for waybar and some other animations to properly function
    gtk = {
      gtk2.extraConfig = ''
        gtk-enable-animations = true;
      '';
      gtk3.extraConfig.gtk-enable-animations = true;
      gtk4.extraConfig.gtk-enable-animations = true;
    };
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        enable-animations = true;
      };
    };
    sops.secrets."hass_cli_token" = {
      sopsFile = "${secrets}/secrets/services/home-assistant.yaml";
      key = "access_tokens/cli";
    };
  };
}
