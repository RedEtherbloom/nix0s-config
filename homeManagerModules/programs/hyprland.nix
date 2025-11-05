{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.myOptions.roles.hyprland;
in {
  imports = [
    "${inputs.hyprland-zaneyos}/modules/home/hyprland/animations-end4.nix"
  ];

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
          kb_options = "terminate:ctrl_alt_bksp,caps:escape"; # Breaks with MC 1.7.10 LWJGL in very strang ways ,shift:both_capslock";
          kb_model = "pc104";
          numlock_by_default = true;
          resolve_binds_by_sym = false;
          scroll_method = "edge";
          follow_mouse = 1;
          # May need fine tuning
          float_switch_override_focus = 0;
          # What does this do?
          special_fallthrough = false;
          sensitivity = 0.15;
          touchpad = {
            disable_while_typing = false;
            natural_scroll = true;
            tap-to-click = true;
            # drag_lock = 1;
            # drag_3fg = true;
          };
        };
        debug = {
          disable_logs = false;
          disable_time = false;
          # FPS overlay
          overlay = false;
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
          "$mod" = "SUPER";
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
          snap = {
            enabled = true;
          };
        };
        misc = {
          font_family = "OpenDyslexic Nerd Font";
          layers_hog_keyboard_focus = true;
          initial_workspace_tracking = 1;
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
          animate_manual_resizes = true;
          animate_mouse_windowdragging = true;
          # TODO: This is soft broken as e.g. telegram getting a notification forces us to switch to that desktop
          focus_on_activate = false;
          middle_click_paste = true;
          # maybe required for e.g. video player lagging. Performance though?
          render_unfocused_fps = false;

          #  Application not responding (ANR) settings
          enable_anr_dialog = true;
          anr_missed_pings = 20;
        };

        dwindle = {
          # Meaning?
          pseudotile = true;
          # TODO: Evaluate if without to chaotic
          # preserve_split = true;
          # force_split = 2;
        };

        master = {
          new_status = "master";
          new_on_top = true;
          # May enable more finegrained tiling control
          # allow_small_split = true;
        };
        # TODO: Get a better one. We don't like this
        decoration = {
          rounding = 4;
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
          hide_on_key_press = true;
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
        monitor = [
          # Fallback
          ", preferred, auto, 1"
        ];
        exec-once = [
          "nm-applet --indicator"
        ];
        # TODO: Setup swallow
        bind = let
          getActiveWindowClass = pkgs.writeShellScript "hyprActiveWindow.sh" ''
            set -e
            hyprctl activewindow -j | jq  .class
          '';

          # TODO: Generalize
          # https://www.reddit.com/r/hyprland/comments/12x9724/comment/lzyt1wr
          hyprctrlNextLayout = pkgs.writeShellScript "hyprctrlNextLayout.sh" ''
                        next_layout = "$(hyprctl getoption general:layout | grep -q 'dwindle' && echo 'master' || echo 'dwindle')";
            hyprctl keyword general:layout "$next_layout";

          '';
        in
          [
            "SUPER, W, exec, firefox"
            "SUPER_SHIFT, W, exec, firefox -P work"
            # TODO: Work mode shortcut with: Work firefox, youtube music, obsidian
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
                  "$mod,code:1${toString i},workspace,${toString ws}"
                  # TODO: Build a toggle mode between silent and non silent
                  "$mod SHIFT,code:1${toString i},movetoworkspacesilent, ${toString ws}"
                ]
              )
              10)
            ++ [
              "$modifier,Return,exec,kitty"
              # TODO: Needs own implementation. Maybe a rendered version of this file?
              "$modifier,K,exec,list-keybinds"
              "$modifier,Y,exec,rofi -matching fuzzy -combi-mode 'window,drun,ssh' -modes combi,window,drun,ssh -show combi"
              "$modifier SHIFT,Return,exec,rofi -matching fuzzy -combi-mode 'window,drun,ssh' -modes combi,window,drun,ssh -show combi"
              "$modifier,TAB,exec,rofi -matching fuzzy -modes window -show window"
              # TODO: Switcher that matches active window class as preselect
              "$modifier SHIFT,TAB,exec,rofi -matching fuzzy -modes window -filter \"$(${getActiveWindowClass}) \" -window-match-fields 'class,title' -show window"
              # TODO: I want a social media scratchpad on that combo
              "$modifier SHIFT,D,exec,swaync-client -rs"
              # TODO: Replace with a rofi
              "$modifier SHIFT,Y,exec,emojipick"
              "$modifier,E,exec,dolphin"
              "$modifier SHIFT,E,exec,kitty -e yazi"
              # Check if xdg screenshot gets respected
              ",PRINT&A,exec,hyprshot -m output"
              ",PRINT&S,exec,hyprshot -m window"
              ",PRINT&R,exec,hyprshot -m region"
              "$modifier,C,exec,hyprpicker -a"
              # TODO: Scratchpad?
              "$modifier shift,T,exec,pypr toggle term"
              "$modifier,M,exec,pavucontrol"
              "$modifier,Q,killactive,"
              "ALT,f4,killactive,"
              # What is dwindle pseudo?
              "$modifier,P,pseudo,"
              # Master layout
              # TODO: How to set layout specific bindings? Crashes due to being unknown
              # "$modifier,P,swapwithmaster,"
              # TODO: How to setup a database behind clipist?
              "$modifier,V,exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
              "$modifier SHIFT,I,togglesplit,"
              "$modifier SHIFT,F,fullscreen,"
              "$modifier,F,togglefloating,"
              "$modifier ALT,F,workspaceopt, allfloat"
              # TODO: Prompt for option via dialog
              "$modifier SHIFT,C,exit,"
              "$modifier SHIFT,left,movewindow,l"
              "$modifier SHIFT,right,movewindow,r"
              "$modifier SHIFT,up,movewindow,u"
              "$modifier SHIFT,down,movewindow,d"
              "$modifier SHIFT,h,movewindow,l"
              "$modifier SHIFT,l,movewindow,r"
              "$modifier SHIFT,k,movewindow,u"
              "$modifier SHIFT,j,movewindow,d"
              "$modifier ALT, left, swapwindow,l"
              "$modifier ALT, right, swapwindow,r"
              "$modifier ALT, up, swapwindow,u"
              "$modifier ALT, down, swapwindow,d"
              "$modifier ALT, 43, swapwindow,l"
              "$modifier ALT, 46, swapwindow,r"
              "$modifier ALT, 45, swapwindow,u"
              "$modifier ALT, 44, swapwindow,d"
              "$modifier,left,movefocus,l"
              "$modifier,right,movefocus,r"
              "$modifier,up,movefocus,u"
              "$modifier,down,movefocus,d"
              "$modifier,h,movefocus,l"
              "$modifier,l,movefocus,r"
              "$modifier,k,movefocus,u"
              "$modifier,j,movefocus,d"
              "$modifier SHIFT,SPACE,movetoworkspace,special"
              "$modifier,SPACE,togglespecialworkspace"
              "$modifier CONTROL,right,workspace,e+1"
              "$modifier CONTROL,left,workspace,e-1"
              # "$modifier CONTROL,j,rrsizeactive, 100% 110%"
              # "$modifier CONTROL,k,resizeactive, 100% 90%"
              # "$modifier CONTROL,h,resizeactive, 110% 100%"
              # "$modifier CONTROL,l,resizeactive, 90% 100%"
              "$modifier CONTROL,j,resizeactive, 0 50"
              "$modifier CONTROL,k,resizeactive, 0 -50"
              "$modifier CONTROL,h,resizeactive, 50 0"
              "$modifier CONTROL,l,resizeactive, -50 0"
              "$modifier,mouse_down,workspace, e+1"
              "$modifier,mouse_up,workspace, e-1"
              "$modifier,Delete,exec,hyprlock"
              "ALT,Tab,cyclenext"
              "ALT,Tab,bringactivetotop"

              "$modifier, semicolon, exec, ${hyprctrlNextLayout}"

              ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
              ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ",XF86AudioPlay, exec, playerctl play-pause"
              ",XF86AudioPause, exec, playerctl play-pause"
              ",XF86AudioNext, exec, playerctl next"
              ",XF86AudioPrev, exec, playerctl previous"
              ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
              ",XF86MonBrightnessUp,exec,brightnessctl set +5%"
            ]
          );
        bindm = [
          # Left mouse button
          "$modifier, mouse:272, movewindow"
          # Right mouse button
          "$modifier, mouse:273, resizewindow"
        ];
        windowrule = [
          #"noblur, xwayland:1" # Helps prevent odd borders/shadows for xwayland apps
          # downside it can impact other xwayland apps
          # This rule is a template for a more targeted approach
          "noblur, class:^(\bresolve\b)$, xwayland:1" # Window rule for just resolve
          "tag +file-manager, class:^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|[Dd]olphin|[Yy]azi)$"
          "tag +terminal, class:^(com.mitchellh.ghostty|org.wezfurlong.wezterm|Alacritty|kitty|kitty-dropterm)$"
          "tag +browser, class:^(Brave-browser(-beta|-dev|-unstable)?)$"
          "tag +browser, class:^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$"
          "tag +browser, class:^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"
          "tag +browser, class:^([Tt]horium-browser|[Cc]achy-browser)$"
          "tag +projects, class:^(codium|codium-url-handler|VSCodium)$"
          "tag +projects, class:^(VSCode|code-url-handler)$"
          "tag +im, class:^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$"
          "tag +im, class:^([Ff]erdium)$"
          "tag +im, class:^([Ww]hatsapp-for-linux)$"
          "tag +im, class:^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$"
          "tag +im, class:^(teams-for-linux)$"
          "tag +games, class:^(gamescope)$"
          "tag +games, class:^(steam_app_\d+)$"
          "tag +gamestore, class:^([Ss]team)$"
          "tag +gamestore, title:^([Ll]utris)$"
          "tag +gamestore, class:^(com.heroicgameslauncher.hgl)$"
          "tag +settings, class:^(gnome-disks|wihotspot(-gui)?)$"
          "tag +settings, class:^([Rr]ofi)$"
          "tag +settings, class:^(file-roller|org.gnome.FileRoller)$"
          "tag +settings, class:^(nm-applet|nm-connection-editor|blueman-manager)$"
          "tag +settings, class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
          "tag +settings, class:^(nwg-look|qt5ct|qt6ct|[Yy]ad)$"
          "tag +settings, class:(xdg-desktop-portal-gtk)"
          "tag +settings, class:(.blueman-manager-wrapped)"
          "tag +settings, class:(nwg-displays)"
          "move 72% 7%,title:^(Picture-in-Picture)$"
          "center, class:^([Ff]erdium)$"
          "float, class:^([Ww]aypaper)$"
          "center, class:^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
          "center, class:([Tt]hunar), title:negative:(.*[Tt]hunar.*)"
          "center, title:^(Authentication Required)$"
          "idleinhibit fullscreen, class:^(*)$"
          "idleinhibit fullscreen, title:^(*)$"
          "idleinhibit fullscreen, fullscreen:1"
          "float, tag:settings*"
          "float, class:^([Ff]erdium)$"
          "float, title:^(Picture-in-Picture)$"
          "float, class:^(mpv|com.github.rafostar.Clapper)$"
          "float, title:^(Authentication Required)$"
          "float, class:(codium|codium-url-handler|VSCodium), title:negative:(.*codium.*|.*VSCodium.*)"
          "float, class:^(com.heroicgameslauncher.hgl)$, title:negative:(Heroic Games Launcher)"
          "float, class:^([Ss]team)$, title:negative:^([Ss]team)$"
          "float, class:([Tt]hunar), title:negative:(.*[Tt]hunar.*)"
          "float, initialTitle:(Add Folder to Workspace)"
          "float, initialTitle:(Open Files)"
          "float, initialTitle:(wants to save)"
          "size 70% 60%, initialTitle:(Open Files)"
          "size 70% 60%, initialTitle:(Add Folder to Workspace)"
          "size 70% 70%, tag:settings*"
          "size 60% 70%, class:^([Ff]erdium)$"
          "opacity 1.0 1.0, tag:browser*"
          "opacity 0.9 0.8, tag:projects*"
          "opacity 0.94 0.86, tag:im*"
          "opacity 0.9 0.8, tag:file-manager*"
          "opacity 0.8 0.7, tag:terminal*"
          "opacity 0.8 0.7, tag:settings*"
          "opacity 0.8 0.7, class:^(gedit|org.gnome.TextEditor|mousepad)$"
          "opacity 0.9 0.8, class:^(seahorse)$ # gnome-keyring gui"
          "opacity 0.95 0.75, title:^(Picture-in-Picture)$"
          "pin, title:^(Picture-in-Picture)$"
          "keepaspectratio, title:^(Picture-in-Picture)$"
          "noblur, tag:games*"
          "fullscreen, tag:games*"
          # Prevent the fabled odd xwaylandvideobridge from wreaking havoc on our fair hyprland. Source: https://wiki.hypr.land/Useful-Utilities/Screen-Sharing/#xwayland
          "opacity 0.0 override, class:^(xwaylandvideobridge)$"
          "noanim, class:^(xwaylandviDeobridge)$"
          "noinitialfocus, class:^(xwaylandvideobridge)$"
          "maxsize 1 1, class:^(xwaylandvideobridge)$"
          "noblur, class:^(xwaylandvideobridge)$"
          "nofocus, class:^(xwaylandvideobridge)$"
        ];
      };
    };
    services = {
      hypridle = {
        enable = true;
        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch dpms on";
            ignore_dbus_inhibit = false;
            lock_cmd = "hyprlock";
          };
          listener = [
            {
              timeout = 900;
              on-timeout = "hyprlock";
            }
            {
              timeout = 1200;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
      gnome-keyring.enable = true;
    };
    stylix.targets.qt.platform = lib.mkForce "qtct";

    # TODO: New wallpaper
    # TODO: Nice, fancy theme
    programs.hyprlock.enable = true;
    # TODO: Do we need pyprland?
    # TODO: Needs to be bigger. Preferrably use a prefab config
    programs.rofi = {
      enable = true;
      extraConfig = {
        show-icons = true;
      };
      # Theme should get autogenerated by stylix
    };
    stylix.targets.waybar.enable = false;
    # TODO: Separate bar for work workspace
    programs.waybar = {
      enable = true;
      # TODO: clearer separators
      style = builtins.readFile "${self}/dotfiles/waybarstyle.css";
      settings.mainBar = {
        position = "top";
        # TODO: Evaluate
        layer = "top";
        # Try dynamic
        # height = 30;
        spacing = 6;
        # TODO: Configure sway ipc for hide
        reload_style_on_change = true;
        # mode = "hide";
        modules-left = [
          "hyprland/submap"
          "hyprland/workspaces"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          # TODO: Tag social media with windowrules
          # Notifications/DND
          # Audio visualizer
          # "cava"
          # "idle_inhibitor"
          "wireplumber"
          "bluetooth"
          # TODO: Shorten and only use e.g. Colemak as name
          "mpris"
          "hyprland/language"
          # TODO: needs configuring for e.g. speed and showing available networks
          # "network"
          # TODO:: Needs other things setup first
          # "power-profiles-daemon"
          # TODO: Integrate pomodoro
          "backlight"
          "battery"
          # TODO: Disable blue underline
          "clock"
          "tray"
        ];
        "bluetooth" = {
          format = "";
          format-disabled = "dis";
          format-connected = "";
          format-no-connected = "";
          # TODO: More info on tooltip
          # Bluetooth scanner on right click
        };
        "wireplumber" = {
          format = "󰝚 {volume}% {node_name:.8}";
          # TODO: New wallpaper
          format-muted = "󰝛";
          max-volume = "175.0";
        };
        "hyprland/workspaces" = {
          # active-only = true;
          # TODO: Format with idon
          workspace-taskar = {
            enable = true;
            # Probably optional
            update-active-window = true;
          };
          # TODO: How to separate into e.g. work and private?
        };
        "hyprland/window" = {
          # format = "{icon} {title}";
          max-length = 60;
          separate-outputs = true;
          # TODO: Strip leading parenthesis(e.g. youtube notifications)
          rewrite = {
          };
        };
        # See: https://github.com/Alexays/Waybar/wiki/Module:-Backlight-Slider
        # "backlight/slider" = {
        #   min = 2;
        #   max = 100;
        #   orientation = "vertical";
        #   # TODO: How to use for all devices?
        #   # device =
        # };
        "backlight" = rec {
          interval = 2;
          min = interval;
          max = 100;
          format = "{icon}{percent}%";
          format-icons = [
            "🕯️"
            "🔥"
            "☀️"
            # Supernova
            "💥"
          ];
        };
        # Autohide?

        "tray" = {
          spacing = 8;
          icon-size = 24;
        };
        "power-profiles-daemon" = {
          dynamic-len = 30;
        };
        "mpris" = {
          format = "{player_icon}{dynamic}";
          format-paused = "{status_icon}";
          # TODO: Can we use the programs icons somehow?
          player-icons = {
            default = "🏳️‍⚧️";
            kdeconnect = "📱";
            firefox = "🐦‍🔥";
            mpv = "👩🏽‍🔬";
            vlc = "🚥";
            ytmusic = "🎛️";
            speech-dispatcher = "🦻🏿";
            subsonic = "🔉";
          };
          status-icons = {
            # TODO: Missing fonst. What provides the md_ symbols?
            paused = "󰏤";
          };
          dynamic-len = 30;
          dynamic-separator = "🏳️‍⚧️";
          dynamic-importance-order = [
            "position"
            "length"
            "title"
            "artist"
            "album"
          ];
        };
        "hyprland/language" = {
          format = "{}";
          format-en-colemak_dh_iso = "col";
          format-de = "de";
          format-de_nodeadkeys = "de";
        };
      };
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
    };
    programs.hyprshot = {
      enable = true;
      saveLocation = "$HOME/Pictures/Screenshots";
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
      hyprland-qtutils # needed for banners and ANR messages

      # Own
      networkmanagerapplet
      # TODO: Try networkmanager_dmenu?
      cliphist
      emojipick
      hyprpicker
      rofi-bluetooth
      rofi-calc
      rofi-emoji
      rofi-nerdy
      rofi-power-menu
      # TODO: Implement bitwarden
      rofi-rbw
      rofi-file-browser
      rofi-screenshot
      rofi-menugen
      rofi-pulse-select
      rofi-network-manager

      gnome-keyring
      seahorse
      gcr

      wdisplays
    ];

    xdg.portal = {
      enable = lib.mkForce true;
      xdgOpenUsePortal = true;
      # TODO: Config for secret(gnome?) and filepicker
      extraPortals = with pkgs; [
        gnome-keyring
        xdg-desktop-portal-gtk
        kdePackages.xdg-desktop-portal-kde
      ];
      config = {
        common = {
          default = [
            "gtk"
            "kde"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
        hyprland = {
          default = [
            "hyprland"
            "gtk"
            "kde"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
        kde = {
          default = [
            "kde"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "kwallet"
          ];
        };
      };
    };
  };
}
