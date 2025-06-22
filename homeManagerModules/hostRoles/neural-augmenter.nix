{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.neural-augmenter;
in {
  options.myOptions.hostRoles.neural-augmenter = {
    enable = mkOption {
      description = "workstation hm settings";
      type = with types; bool;
      default = osConfig.myOptions.hostRoles.neural-augmenter.enable;
    };
  };

  config = mkIf cfg.enable {
    myOptions = {
      hostRoles.graphical.enable = mkDefault true;

      roles = {
        development = {
          enable = true;
          electronics = true;
        };
        nvf.enable = true;
      };
      vscode.enable = true;

      firefox.enable = true;
      socials.enable = true;

      obsidian.enable = true;
      taskwarrior = {
        enable = true;
        enableSync = true;
        taskopen = true;
      };
      taskwarrior-tui = {
        enable = true;
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

    programs.nushell.enable = true;

    home.packages = with pkgs;
      [
        (chromium.override {enableWideVine = true;})
        tor-browser
        bitwarden
        # bitwarden-cli

        comfyuiPackages.krita-with-extensions
        yt-dlp

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

        imagemagick

        tailscale

        # Certificate creation
        xca

        # Speedreading
        speedread
        hottext

        distrobox

        # nvf music-controls.nvim
        playerctl

        code-cursor

        gtypist

        handbrake
        scrcpy
        dumbpipe

        # mpd players to compare
        cantata
        plattenalbum

        podman
        dive # look into docker image layers
        podman-tui # status of containers in the terminal
        podman-compose
        docker-compose # start group of containers for dev

        # Music production
        sonic-pi
      ]
      ++ (lib.optionals osConfig.security.ownAdditional.yubikey (with pkgs; [
        yubioath-flutter
      ]));

    services.yubikey-agent = {
      enable = osConfig.security.ownAdditional.yubikey;
    };

    # May not work due to https://github.com/nix-community/home-manager/issues/1011
    home.sessionVariables = {
      # Smooth scrolling
      MOZ_USE_XINPUT2 = "1";
    };

    home.extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];

    programs.rofi = {
      enable = true;
      terminal = "${config.programs.kitty.package}";
      package = pkgs.rofi-wayland;
    };

    # Set terminal opacity using stlyix instead
    stylix.opacity.terminal = 0.8;

    programs.spotify-player.enable = true;

    # TODO: Setup options
    services.syncthing = {
      enable = true;
    };

    # Giving helix a shot, nvim takes too many things for now to be somewhat functional
    programs.helix.enable = true;
  };
}
