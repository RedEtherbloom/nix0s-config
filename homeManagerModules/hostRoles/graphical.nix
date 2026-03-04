{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.hostRoles.graphical;
in {
  imports = [
    ../services/piper-web-tts.nix
  ];

  options.myOptions.hostRoles.graphical.enable = mkOption {
    description = "graphical hostRole hm settings";
    type = with types; bool;
    default = osConfig.myOptions.hostRoles.graphical.enable;
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;

    home = {
      packages = with pkgs; [
        pavucontrol
        wl-clipboard
        brightnessctl
        hyfetch

        # Attempts at notifications
        kdePackages.kdialog
        libnotify

        vlc
        # TODO: Recreate old shortcuts and configure via options instead
        feh

        pied # Piper-tts voice management
      ];
      sessionVariables = let 
        askpass_helper = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      in {
        # Native Wayland for Chromium apps
        NIXOS_OZONE_WL = "1";
        SUDO_ASKPASS = askpass_helper;
        SSH_ASKPASS = askpass_helper;
      };
    };

    programs = {
      mpv = {
        enable = true;
        config = {
          # Video acceleration
          hwdec = "auto-safe";
          vo = "gpu";
          profile = "gpu-hq";
          gpu-context = "wayland";
        };
        scripts = with pkgs.mpvScripts; [
          mpris
        ];
      };
      kitty = {
        enable = true;
        enableGitIntegration = true;
        settings = {
          background_blur = 2;
          dynamic_background_opacity = true;
          background_tint = 0.1;
          visual_bell_color = "#0c0933";
          enable_audio_bell = "no";
          visual_bell_duration = 0.15;
          cursor_trail = 2;
          # cursor_shape = "beam";
          cursor_shape_unfocused = "hollow";
          # TODO: Does not seem to have an effect
          # cursor = "#2ccc1b";
          confirm_os_window_close = 0;
        };
      };
      tmux = {
        enable = true;
        clock24 = true;
        historyLimit = 10000;
        # Hope this doesn't blow up
        keyMode = "vi";
        mouse = true;
        newSession = true;
        # May require passthrough set to all
        extraConfig = ''
          set -g allow-passthrough on
        '';
      };
      fzf.tmux.enableShellIntegration = true;
      btop.enable = true;
    };

    fonts.fontconfig.enable = true;
  };
}
