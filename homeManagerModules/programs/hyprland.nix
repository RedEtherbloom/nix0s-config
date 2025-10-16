{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.myOptions.roles.hyprland;
in {
  options.myOptions.roles.hyprland = {
    enable = lib.mkOption {
      description = "Our custom hyprland config.";
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    # Inspired by:
    # - https://gitlab.com/Zaney/zaneyos/-/blob/main/modules/home/hyprland/default.nix
    wayland.windowManager.hyprland = {
      enable = true;
      # set the Hyprland and XDPH packages to null to use the ones from the NixOS module
      package = null;
      portalPackage = null;
      systemd = {
        enable = true;
        enableXdgAutostart = true;
        # Properly setup systemd
        variables = ["--all"];
      };
      xwayland.enable = true;
      settings = {
        input = {
          kb_layout = "us,de";
          kb_variant = "colemak_dh_iso,nodeadkeys";
          # TODO: Add a compose key for e.g. chinese characters
          kb_options = "terminate:ctrl_alt_bksp,caps:escape,shift:both_capslock";
          kb_model = "pc104";
          numlock_by_default = true;
          resolve_binds_by_sym = false;
          scroll_method = "scroll_method";
          follow_mouse = 1;
          # May need fine tuning
          float_switch_override_focus = 0;
          # What does this do?
          special_fallthrough = false;
          touchpad = {
            disable_while_typing = false;
            natural_scroll = true;
            tap-to-click = true;
            drag_lock = 1;
            drag_3fg = true;
          };
        };
        debug = {
          disable_logs = false;
          disable_time = false;
          overlay = true;
        };
        snap = {
          enabled = true;
        };
        gestures = {
          workspace_swipe_distance = 300;
          workspace_swipe_invert = true;
          workspace_swipe_create_new = false;
          workspace_swipe_forever = true;
        };
        gesture = [
          # Standard workspace swipe
          "3, horizontal, workspace"
          # Show default special workspace
          "2, pinchout, special"
        ];
        general = {
          # Required for the binds, for now. TODO: Merge with mod or ditch
          "$modifier" = "SUPER";
          no_border_on_floating = false;
          layout = "dwindle";
          gaps_in = 6;
          gaps_out = 8;
          border_size = 2;
          resize_on_border = true;
          extend_border_grab_area = 15;
          # TODO: Check if stylix does this automatically
          # "col.active_border" = "rgb(${config.lib.stylix.colors.base08}) rgb(${config.lib.stylix.colors.base0C}) 45deg";
          # "col.inactive_border" = "rgb(${config.lib.stylix.colors.base01})";
          # Attempt to build better mental model of our workscreen
          no_focus_fallback = true;
        };
        misc = {
          font_family = "OpenDyslexic Nerd Font";
          layers_hog_keyboard_focus = true;
          # Keep new windows contained to their desktop by default
          initial_workspace_tracking = 2;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
          disable_hyprland_logo = lib.mkForce false;
          disable_splash_rendering = false;
          disable_scale_notification = false;
          enable_swallow = true;
          vfr = true; # Variable Frame Rate
          vrr = 2; #Variable Refresh Rate  Might need to set to 0 for NVIDIA/AQ_DRM_DEVICES
          # Screen flashing to black momentarily or going black when app is fullscreen
          # Try setting vrr to 0
          # Can cause weird window looks
          # animate_manual_resizes = true;
          # animate_mouse_windowdragging = true;
          focus_on_activate = true;
          middle_click_paste = true;
          # maybe required for e.g. video player lagging
          # render_unfocused_fps = true;

          #  Application not responding (ANR) settings
          enable_anr_dialog = true;
          anr_missed_pings = 10;
        };

        dwindle = {
          pseudotile = true;
          # TODO: Evaluate if without to chaotic
          # preserve_split = true;
          force_split = 2;
        };

        master = {
          new_status = "master";
          new_on_top = true;
          # May enable more finegrained tiling control
          # allow_small_split = true;
        };
        decoration = {
          rounding = 10;
          # TODO: Experiment with shaders
          # screen_shader = "stubPath";
          blur = {
            enabled = true;
            size = 5;
            # May have higher GPU impact
            passes = 3;
            ignore_opacity = false;
            new_optimizations = true;
          };
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
          };
        };
        ecosystem = {
          no_donation_nag = true;
          no_update_news = false;
        };
        cursor = {
          sync_gsettings_theme = true;
          enable_hyprcursor = true;
          # warp_on_change_workspace = 2;
          # no_warps = true;
        };
        render = {
          # Potentially improve rendering performance on laptop
          new_render_scheduling = true;
        };
        xwayland = {
          # Ensure Xwayland windows render at integer scale; compositor scales them
          force_zero_scaling = true;
        };
        opengl = {
          nvidia_anti_flicker = true;
        };
        # TODO: Monitor config
        bind =
          [
            "SUPER, E, exec, firefox"
            "SUPER_SHIFT, E, exec, firefox -P work"
            # TODO: Work mode shortcut with: Work firefox, youtube music, obsidian
            "SUPER, Enter, exec, kitty"
            # TODO: Setup to autoswitch to it on the same keybinding
            "SUPER, N, exec, obsidian"
            "SUPER_SHIFT, N, exec, neovide"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
            builtins.concatLists (builtins.genList (
                i: let
                  ws = i + 1;
                in [
                  "$mod, code:1${toString i}, workspace, ${toString ws}"
                  "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
                ]
              )
              9)
          );
      };
    };

    # TODO: Look over
    home.packages = with pkgs; [
      swww
      grim
      slurp
      wl-clipboard
      swappy
      ydotool
      hyprpolkitagent
      hyprshot
      hyprland-qtutils # needed for banners and ANR messages
    ];
  };
}
