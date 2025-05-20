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
  options.myOptions.hostRoles.graphical.enable = mkOption {
    description = "graphical hostRole hm settings";
    type = with types; bool;
    default = osConfig.myOptions.hostRoles.graphical.enable;
  };

  config = mkIf cfg.enable {
    myOptions.hostRoles.base.enable = mkDefault true;

    # Remove files for stylix
    # TODO: Try to disable this in KDE
    home.activation = {
      removeStylixBlockersAction = lib.hm.dag.entryBefore ["checkFilesChanged"] ''
        run rm -rf ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.gtkrc-2.0
      '';
    };

    myOptions.plasma-manager.enable = true;

    home.packages = with pkgs; [
      helvum
      pavucontrol
      wl-clipboard
      hyfetch

      # Attempts at notifications
      kdePackages.kdialog
      libnotify

      vlc
      feh
    ];

    programs.mpv = {
      enable = true;
      config = {
        # Video acceleration
        hwdec = "auto-safe";
        vo = "gpu";
        profile = "gpu-hq";
        gpu-context = "wayland";
      };
    };

    programs.kitty = {
      enable = true;
      settings = {
        background_blur = 2;
        dynamic_background_opacity = true;
        background_tint = 0.2;

        visual_bell_color = "#0c0933";
        enable_audio_bell = "no";
        visual_bell_duration = 0.15;
        cursor_trail = 3;
        cursor_shape = "beam";
        cursor_shape_unfocused = "hollow";
        # TODO: Does not seem to have an effect
        cursor = "#2ccc1b";
      };
    };

    programs.tmux = {
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
    programs.fzf.tmux.enableShellIntegration = true;

    home.sessionVariables = {
      # Native Wayland for Chromium apps
      NIXOS_OZONE_WL = "1";
    };

    fonts.fontconfig = {
      enable = true;
      # TODO: Does stylix set the fontconfig options?
    };
  };
}
