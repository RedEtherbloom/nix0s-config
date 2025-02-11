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
    myOptions.hostRoles.graphical.enable = mkDefault true;
    myOptions.socials.enable = true;
    myOptions.roles.development.enable = true;
    myOptions.roles.nvf.enable = true;
    myOptions.vscode.enable = true;
    myOptions.obsidian.enable = true;
    myOptions.taskwarrior = {
      enable = true;
      enableSync = true;
      taskopen = true;
    };
    myOptions.taskwarrior-tui = {
      enable = true;
      package = with pkgs; (taskwarrior-tui.overrideAttrs (finalAttrs: oldAttrs: rec {
        version = oldAttrs.version + "-fix";

        src = (
          pkgs.fetchFromGitHub {
            owner = "RedEtherbloom";
            repo = "taskwarrior-tui";
            hash = "sha256-YNd4vtaWm+1fsB8ly3toq2u74Nicmhx2ey1m557q4K8=";
            rev = "ee24bfb4a36f246933e6d2502ab85d3fc6abb85b";
          }
        );

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-7q85YszWmetjWry9nvc2irQeLFCWHwOAkEUHtc9CK/c=";
        };
      }));
    };

    myOptions.firefox.enable = true;
    programs.nushell.enable = true;

    home.packages = with pkgs; [
      (chromium.override {enableWideVine = true;})
      tor-browser
      bitwarden
      bitwarden-cli

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
    ];

    # May not work due to https://github.com/nix-community/home-manager/issues/1011
    home.sessionVariables = {
      # Smooth scrolling
      MOZ_USE_XINPUT2 = "1";
    };

    programs.rofi = {
      enable = true;
      terminal = "${config.programs.kitty.package}";
      package = pkgs.rofi-wayland;
    };
    
    # Set terminal opacity using stlyix instead
    stylix.opacity.terminal = 0.8;

    # Workaround until stylix is fixed upstream
    qt = {
      enable = true;
      platformTheme.package = with pkgs.kdePackages; [
        plasma-integration
        # I don't remember why I put this is here, maybe it fixes the theme of the system setttings
        systemsettings
      ];
      style = {
        package = lib.mkForce pkgs.kdePackages.breeze;
        name = lib.mkForce "Breeze";
      };
    };
    systemd.user.sessionVariables = lib.mkForce {QT_QPA_PLATFORMTHEME = "kde";};
  };
}
