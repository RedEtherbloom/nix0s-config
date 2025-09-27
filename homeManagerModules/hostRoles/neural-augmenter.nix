{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.hostRoles.neural-augmenter;
  inherit (import ../../homeManagerModules/lib/torrent_lib.nix {inherit osConfig pkgs;}) mullvad-torrent vopono-torrent;
in {
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
      };
      vscode.enable = lib.mkDefault true;

      firefox.enable = lib.mkDefault true;
      socials.enable = lib.mkDefault true;

      obsidian.enable = lib.mkDefault true;
      taskwarrior = {
        enable = lib.mkDefault true;
        enableSync = lib.mkDefault true;
        taskopen = lib.mkDefault true;
      };
      taskwarrior-tui = {
        enable = lib.mkDefault true;
        # TODO: Update and/or move to overlay
        package = with pkgs; (taskwarrior-tui.overrideAttrs (_: oldAttrs: rec {
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
        }));
      };
    };

    home = {
      packages =
        (with pkgs; [
          tor-browser
          bitwarden
          bitwarden-cli

          krita-upstream

          # KDE info packages
          clinfo
          glxinfo
          vulkan-tools
          wayland-utils
          pciutils
          aha
          # Monitor brightness control
          ddcutil
          usbutils

          # TODO: Move to restic module
          restic
          autorestic

          ffmpeg-full
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
          handbrake
          imagemagick
          yt-dlp

          tailscale
          # Certificate creation
          xca

          # Speedreading
          speedread

          scrcpy
          dumbpipe

          # mpd players to compare
          cantata
          plattenalbum

          podman
          dive # look into docker image layers
          podman-tui
          podman-compose
          docker-compose # start group of containers for dev
          distrobox

          # Music production
          nixpkgs-stable.sonic-pi
          # FLStudio esque software
          reaper
          reaper-sws-extension
          bitwig-studio5
          yabridge
          yabridgectl

          vopono
          mullvad-torrent
          vopono-torrent

          # TODO: Evaluate. If useful move to dev tools.
          nix-search-tv

          systemctl-tui
        ])
        ++ (lib.optionals osConfig.security.ownAdditional.yubikey (with pkgs; [
          yubioath-flutter
          yubikey-manager
        ]));
      # May not work due to https://github.com/nix-community/home-manager/issues/1011
      sessionVariables = {
        # Smooth scrolling
        MOZ_USE_XINPUT2 = "1";
        QT_LOGGING_RULES = "kscreenlocker.debug=true";
      };
      extraOutputsToInstall = [
        "doc"
        "info"
        "devdoc"
      ];
    };

    services = {
      # TODO: Setup options
      syncthing.enable = true;
      playerctld.enable = true;
      easyeffects.enable = true;
    };
    programs = {
      chromium = {
        enable = lib.mkDefault true;
        package = pkgs.chromium.override {enableWideVine = true;};
      };
      nushell.enable = true;
      # Currently useless due to missing KDE support
      rofi = {
        enable = lib.mkDefault false;
        terminal = "${config.programs.kitty.package}";
        package = pkgs.rofi-wayland;
      };
      spotify-player.enable = true;
      bat.enable = true;
      # TODO: Try out then reevaluate
      broot.enable = true;
      # TODO: Does this improve completion speed?
      # TODO: This breaks normal completion with e.g. --user option for systemd too often
      # carapace.enable = true;
    };

    xdg = {
      autostart = {
        enable = true;
        entries = [
          "${pkgs.obsidian}/share/applications/obsidian.desktop"
        ];
      };
      configFile."nix-search-tv/config.json".source = pkgs.writers.writeJSON "nstw-config.json" {
        "update_interval" = "48h0m0s";
        experimental."render_docs_indexes" = {
          "nvf" = "https://notashelf.github.io/nvf/options.html";
          "plasma_manager" = "https://nix-community.github.io/plasma-manager/options.xhtml";
        };
      };
    };

    # Set terminal opacity using stlyix instead
    stylix = {
      enable = false;
      opacity.terminal = 0.85;
    };
  };
}
