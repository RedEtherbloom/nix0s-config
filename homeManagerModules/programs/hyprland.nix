{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  secrets,
  self,
  ...
}: let
  cfg = config.myOptions.roles.hyprland;
    normalizedName = name: builtins.readFile (pkgs.runCommand "normalizedName" {} ''
      echo -n "${name}" | ${pkgs.gnused}/bin/sed -E 's/[^a-zA-Z0-9-]/_/g' - | ${pkgs.coreutils}/bin/tr -d '\n' > $out
    '');
    genMonitorLayoutScript = layout: pkgs.writeShellScriptBin "hyprland-layout-${normalizedName layout.name}.sh" ''
    set -e

    ${lib.strings.concatLines (lib.lists.forEach layout.monitors (monitorLine: "hyprctl keyword ${lib.replaceStrings ["="] [" "] monitorLine}"))}

      # Remove duplicated waybars
sleep 1
    ${pkgs.systemd}/bin/systemctl restart --user waybar.service
    '' ;
    layoutScripts = lib.attrsets.mapAttrs' (_: layout: (lib.attrsets.nameValuePair "${normalizedName layout.name}" (genMonitorLayoutScript layout))) config.myOptions.roles.hyprland.displayConfigurations;
  rofiDisplayLayout = let layouts = lib.attrsets.mapAttrsToList (name: script: "${name}: ${lib.getExe script}") layoutScripts; in
    pkgs.writeShellScriptBin "rofiLayoutSelector.sh" ''
      set -e

      SELECTED="$(echo -n "${lib.strings.concatLines layouts}" | ${lib.getExe config.programs.rofi.package} -dmenu | ${lib.getExe pkgs.gnused} 's/^[^:]*: //')"
      eval "$SELECTED"
    '';
  terminalClassRegex = "^(com.mitchellh.ghostty|org.wezfurlong.wezterm|Alacritty|kitty|kitty-dropterm)$";
  # TODO: Write variation that waits for program to start(via socket) and then focuses or moves it to current ws
  focusOrStart = selector: selectorValue: program: ''hyprctl clients -j | ${pkgs.jq}/bin/jq -e '[.[] | select(.${selector} == "${selectorValue}")] | length > 0' && hyprctl dispatch focuswindow '${selector}:${selectorValue}' || hyprctl dispatch exec ${program}'';
  getWindowsOnActiveWorkspaces = pkgs.writeShellScriptBin "getWindowsOnActiveWorkspaces.sh" ''
    # Debugging
    set -x

    set -e
    activeWorkspaces="$(hyprctl -j monitors | jq 'map(.activeWorkspace.id) | sort')"
    windows="$(hyprctl -j clients | jq --argjson activeWorkspaces \"$activeWorkspaces\" 'map(select(.workspace.id as $id | $activeWorkspaces | indices($id) | length > 0))'"

    # Next: Feed the windows to rofi for choice
  '';
  rofi-home-assistant = pkgs.writeShellApplication {
    name = "rofi-home-assistant";
    runtimeInputs = with pkgs; [
      rofi
      jq
      home-assistant-cli
    ];
    text = ''
      set -e

      export HASS_SERVER="http://${osConfig.networking.ownWireguard.hosts.neurodrive.mainIP}:8123"
      HASS_TOKEN="$(cat ${config.sops.secrets.hass_cli_token.path})"
      export HASS_TOKEN

      ${inputs.rofi-home-assistant}/bin/rofi-hass
    '';
  };
  # TODO: Live output updated with filter?
  rofi-tag-switcher = pkgs.writeShellApplication {
    name = "rofi-tag-switcher";
    runtimeInputs = with pkgs; [
      jq
      hyprland
      rofi
    ];
    text = ''
      TAGGED="$(hyprctl clients -j | jq "map(select(.tags | contains([\"$1\"])))")"
      TITLES=$(echo "$TAGGED" | jq -r 'map(.title + " - " + .initialTitle)[] | @sh')
      # TODO: Pango markup for symbol
      SELECTED="$(echo "$TITLES" | rofi -dmenu -format "i")"
      WINDOW_ADDRESS="$(echo "$SELECTED" | jq -r --argjson "tagged" "$TAGGED" '$tagged.[.].address')"
      hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
    '';
  };
in {
  imports = [
    "${inputs.hyprland-zaneyos}/modules/home/hyprland/animations-end4.nix"
    inputs.hyprDynamicMonitors.homeManagerModules.default
  ];

  options.myOptions.roles.hyprland = {
    enable = lib.mkOption {
      description = "Our custom hyprland config.";
      type = lib.types.bool;
      default = false;
    };
    displayConfigurations = lib.mkOption {
      description = "(Temporary) Switch between display configurations";
      type = lib.types.nullOr (
        lib.types.attrsOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {type = lib.types.nullOr lib.types.str;};
              monitors = lib.mkOption {type = lib.types.listOf lib.types.str;};
            };
          }
        )
      );
      default = null;
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
      plugins =
        [
          inputs.hyprWorkspaceLayouts.packages.${pkgs.stdenv.hostPlatform.system}.default
        ]
        ++ (with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
          hyprscrolling
          hyprwinwrap
        ]);
      settings = {
        input = {
          kb_layout = "us,de";
          kb_variant = "colemak_dh_iso,nodeadkeys";
          # TODO: Add a compose key for e.g. chinese characters
          kb_options = "terminate:ctrl_alt_bksp,caps:escape"; # Breaks with MC 1.7.10 LWJGL in very strang ways ,shift:both_capslock";
          kb_model = "pc104";
          numlock_by_default = true;
          # May need fine tuning
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
          # Useful when refactors are needed but we really need to focus first
          # Or use: hyprctl seterror disable
          # suppress_errors = true;
        };
        gestures = {
          workspace_swipe_distance = 300;
          workspace_swipe_invert = true;
          workspace_swipe_create_new = false;
          workspace_swipe_forever = true;
        };
        binds = {
          hide_special_on_workspace_change = true;
        };
        gesture = [
          # Standard workspace swipe
          "3, horizontal, workspace"
          # Show default special workspace
          "2, pinchout, special, scratchpad"
        ];
        general = {
          layout = "workspacelayout";
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
          allow_tearing = true;
        };
        misc = {
          font_family = "OpenDyslexic Nerd Font";
          layers_hog_keyboard_focus = true;
          initial_workspace_tracking = 1;

          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;

          disable_hyprland_logo = lib.mkForce true;
          disable_splash_rendering = true;
          disable_scale_notification = false;
          enable_swallow = true;
          swallow_regex = "${terminalClassRegex}";
          vfr = true; # Variable Frame Rate
          vrr = 2; # Variable Refresh Rate  Might need to set to 0 for NVIDIA/AQ_DRM_DEVICES
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
          anr_missed_pings = 40;
        };

        dwindle = {
          # Meaning?
          pseudotile = true;
          # TODO: Evaluate if without to chaotic
          # preserve_split = true;
          # Open new to the right
          force_split = 2;
          default_split_ratio = 0.5;
          # Current window should receive the bigger size
          split_bias = 1;
        };

        master = {
          new_status = "master";
          new_on_top = true;
          # May enable more finegrained tiling control
          # allow_small_split = true;
        };
        # TODO: Get a better one. We don't like this
        animations.enabled = true;
        decoration = {
          rounding = 2;
          # TODO: Experiment with shaders
          # screen_shader = "stubPath";
          blur = {
            enabled = false;
            # size = 5;
            # May have higher GPU impact
            # TODO: Evaluate look
            passes = 1;
            # ignore_opacity = false;
            new_optimizations = true;
          };
          shadow = {
            # Evaluate performance
            enabled = false;
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
          "wl-paste --watch clipvault store"
        ];
        # TODO: Setup swallow key
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
            # Could be done via e.g. tags
            ''SUPER, N, exec, ${focusOrStart "class" "obsidian" "obsidian"}''
            "SUPER_SHIFT, N, exec, neovide --neovim-bin ${config.myOptions.roles.nvf.newPackage}/bin/nvim"
          ]
          ++ (
            builtins.concatLists (
              builtins.genList (
                i: let
                  ws = i + 1;
                in [
                  "SUPER,code:1${toString i},workspace,${toString ws}"
                  # TODO: Build a toggle mode between silent and non silent
                  "SUPER SHIFT,code:1${toString i},movetoworkspacesilent, ${toString ws}"
                ]
              )
              10
            )
            ++ [
              "SUPER,Return,exec,kitty"
              # TODO: Needs own implementation. Maybe a rendered version of this file?
              # "SUPER,K,exec,list-keybinds"
              "SUPER,Y,exec,rofi -matching fuzzy -combi-modi 'window,drun,run,ssh' -modes combi,window,drun,run,ssh -show combi"
              "SUPER SHIFT,Return,exec,rofi -matching fuzzy -combi-modi 'window,drun,run,ssh' -modes combi,window,drun,run,ssh -show combi"
              "SUPER,TAB,exec,rofi -matching fuzzy -modes window -show window"
              "SUPER SHIFT,TAB,exec,rofi -matching fuzzy -modes window -filter \"$(${getActiveWindowClass}) \" -window-match-fields 'class,title' -show window"
              "SUPER, B, exec, rofi-bluetooth"
              "SUPER, S, togglespecialworkspace, social"
              "SUPER SHIFT, S, movetoworkspacesilent, special:social"
              "SUPER, T, exec, rofi-tag-switcher current"
              "SUPER SHIFT, T, tagwindow, current"
              # TODO: I want a social media scratchpad on that combo
              # Show notification panel
              "SUPER,D,exec,swaync-client -t"
              # Toggle do not disturb
              "SUPER SHIFT,D,exec,swaync-client -d"
              # TODO: Replace with a rofi
              "SUPER SHIFT,Y,exec,emojipick"
              "SUPER,E,exec,dolphin"
              "SUPER SHIFT,E,exec,kitty -e yazi"
              # Check if xdg screenshot gets respected
              ",PRINT&A,exec,hyprshot -m output"
              ",PRINT&S,exec,hyprshot -m window"
              ",PRINT&R,exec,hyprshot -m region"
              "SUPER,C,exec,hyprpicker -a"
              # TODO: Scratchpad?
              "SUPER shift,T,exec,pypr toggle term"
              "SUPER shift,M,exec,pavucontrol"
              "SUPER, Q, killactive,"
              "SUPER shift,Q,forcekillactive,"
              "ALT,f4,forcekillactive,"
              # What is dwindle pseudo?
              "SUPER,P,pseudo,"
              # Master layout
              # TODO: How to set layout specific bindings? Crashes due to being unknown
              # "SUPER,P,swapwithmaster,"
              # TODO: How to see e.g. copied images in dmenu?
              "SUPER,V,exec, clipvault list | rofi -dmenu -display-columns 2 | clipvault get | wl-copy"
              "SUPER SHIFT,I,togglesplit,"
              "SUPER SHIFT,F,fullscreen,"
              "SUPER,F,togglefloating,"
              "SUPER ALT,F,workspaceopt, allfloat"
              "SUPER SHIFT,left,movewindow,l"
              "SUPER SHIFT,right,movewindow,r"
              "SUPER SHIFT,up,movewindow,u"
              "SUPER SHIFT,down,movewindow,d"
              "SUPER SHIFT,h,movewindow,l"
              "SUPER SHIFT,l,movewindow,r"
              "SUPER SHIFT,k,movewindow,u"
              "SUPER SHIFT,j,movewindow,d"
              "SUPER ALT, left, swapwindow,l"
              "SUPER ALT, right, swapwindow,r"
              "SUPER ALT, up, swapwindow,u"
              "SUPER ALT, down, swapwindow,d"
              "SUPER ALT, 43, swapwindow,l"
              "SUPER ALT, 46, swapwindow,r"
              "SUPER ALT, 45, swapwindow,u"
              "SUPER ALT, 44, swapwindow,d"
              "SUPER,left,movefocus,l"
              "SUPER,right,movefocus,r"
              "SUPER,up,movefocus,u"
              "SUPER,down,movefocus,d"
              "SUPER,h,movefocus,l"
              "SUPER,l,movefocus,r"
              "SUPER,k,movefocus,u"
              "SUPER,j,movefocus,d"
              "SUPER SHIFT,SPACE,movetoworkspacesilent,special:scratchpad"
              "SUPER,SPACE,togglespecialworkspace,scratchpad"
              "SUPER CONTROL,right,workspace,e+1"
              "SUPER CONTROL,left,workspace,e-1"
              # "SUPER CONTROL,j,rrsizeactive, 100% 110%"
              # "SUPER CONTROL,k,resizeactive, 100% 90%"
              # "SUPER CONTROL,h,resizeactive, 110% 100%"
              # "SUPER CONTROL,l,resizeactive, 90% 100%"
              "SUPER CONTROL,j,resizeactive, 0 50"
              "SUPER CONTROL,k,resizeactive, 0 -50"
              "SUPER CONTROL,h,resizeactive, 50 0"
              "SUPER CONTROL,l,resizeactive, -50 0"
              "SUPER,mouse_down,workspace, e+1"
              "SUPER,mouse_up,workspace, e-1"
              "SUPER,Delete,exec,hyprlock"
              # For some reason crashes sddm
              # TODO: Update, reevaluate. If still happens: switch to gddm
              "ALT CONTROL,Delete,exec,wleave"
              "ALT,Tab,cyclenext"
              "ALT,Tab,bringactivetotop"

              "SUPER, semicolon, exec, ${hyprctrlNextLayout}"
              "SUPER SHIFT, C, exec, ${lib.getExe rofiDisplayLayout}"

              ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
              ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ",XF86AudioPlay, exec, playerctl play-pause"
              ",XF86AudioPause, exec, playerctl play-pause"
              ",XF86AudioNext, exec, playerctl next"
              ",XF86AudioPrev, exec, playerctl previous"
              ",XF86MonBrightnessDown,exec,brightnessctl set 5%-"
              ",XF86MonBrightnessUp,exec,brightnessctl set +5%"
              ",XF86Display,exec,wdisplays"

              # Submaps
              "SUPER, M, submap, player"
              "SUPER CONTROL, L, submap, neovim"
              "SUPER CONTROL, S, submap, hyprctl-layout"
              "SUPER CONTROL, G, submap, hyprctl-groups"
              "SUPER SHIFT, SEMICOLON, submap, neovimnt"

              "SUPER Control, Space, exec, killall -SIGUSR1 .waybar-wrapped, Toggle waybar"
            ]
          );
        bindm = [
          # Left mouse button
          "SUPER, mouse:272, movewindow"
          # Right mouse button
          "SUPER, mouse:273, resizewindow"
        ];
        # Shortcuts that also function on lockscreen
        windowrule =
          [
            "tag +file-manager, match:class ^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|[Dd]olphin|[Yy]azi)$"
            "tag +terminal, match:class ${terminalClassRegex}"
            "tag +browser, match:class ^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$"
            "tag +browser, match:class ^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$"
            "tag +projects, match:class ^(codium|codium-url-handler|VSCodium)$"
            "tag +projects, match:class ^(VSCode|code-url-handler)$"
            "tag +projects, match:class ^(neovide)$"
            "tag +projects, match:class ${terminalClassRegex}, match:title ^(nvim|tmux)$"
            "tag +social, match:class ^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$"
            "tag +social, match:class ^([Ff]erdium)$"
            "tag +social, match:class ^([Ww]hatsapp-for-linux)$"
            "tag +social, match:class ^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$"
            "tag +games, match:class ^(gamescope)$"
            "tag +games, match:class ^(steam_app_\d+)$"
            "tag +gamestore, match:class ^([Ss]team)$"
            "tag +gamestore, match:title ^([Ll]utris)$"
            "tag +gamestore, match:class ^(com.heroicgameslauncher.hgl)$"
            "tag +settings, match:class ^(gnome-disks|wihotspot(-gui)?)$"
            "tag +settings, match:class ^([Rr]ofi)$"
            "tag +settings, match:class ^(nm-applet|nm-connection-editor|blueman-manager)$"
            "tag +settings, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
            "tag +settings, match:class ^(nwg-look|qt5ct|qt6ct|[Yy]ad)$"
            "tag +settings, match:class (xdg-desktop-portal-gtk)"
            "tag +settings, match:class (.blueman-manager-wrapped)"
            "tag +settings, match:class (nwg-displays)"
            "move 72% 7%, match:title ^(Picture-in-Picture)$"
            "center on, match:class ^([Ff]erdium)$"
            "float on, match:class ^([Ww]aypaper)$"
            "center on, match:class ^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$"
            "center on, match:class ([Tt]hunar), match:title negative:(.*[Tt]hunar.*)"
            "center on, match:title ^(Authentication Required)$"
            "idle_inhibit fullscreen, match:class ^(*)$"
            "idle_inhibit fullscreen, match:title ^(*)$"
            "idle_inhibit fullscreen, match:fullscreen true"
            "float on, match:tag settings*"
            "float on, match:class ^([Ff]erdium)$"
            "float on, match:title ^(Picture-in-Picture)$"
            "float on, match:class ^(mpv|com.github.rafostar.Clapper)$"
            "float on, match:title ^(Authentication Required)$"
            "float on, match:class (codium|codium-url-handler|VSCodium), match:title negative:(.*codium.*|.*VSCodium.*)"
            "float on, match:class ^(com.heroicgameslauncher.hgl)$, match:title negative:(Heroic Games Launcher)"
            "float on, match:class ^([Ss]team)$, match:title negative:^([Ss]team)$"
            "float on, match:class ([Tt]hunar), match:title negative:(.*[Tt]hunar.*)"
            "float on, match:initial_title (Add Folder to Workspace)"
            "float on, match:initial_title (Open Files)"
            "float on, match:initial_title (wants to save)"
            "float on, match:initial_title Edit Item, match:initial_class thunderbird"
            "size 80% 70%, match:initial_title (Open Files)"
            "size 80% 70%, match:initial_title (Add Folder to Workspace)"
            "size 80% 80%, match:tag settings*"
            "size 70% 80%, match:class ^([Ff]erdium)$"
            "opacity 0.95 0.7, match:tag browser*"
            "opacity 0.9 0.7, match:tag projects*"
            "opacity 0.94 0.7, match:tag im*"
            "opacity 0.9 0.7, match:tag file-manager*"
            "opacity 0.9 0.7, match:tag terminal*"
            "opacity 0.9 0.7, match:tag settings*"
            "opacity 0.8 0.7, match:class ^(gedit|org.gnome.TextEditor|mousepad)$"
            "opacity 0.9 0.7, match:class ^(seahorse)$ # gnome-keyring gui"
            "opacity 0.95 0.75, match:title ^(Picture-in-Picture)$"
            "pin on, match:title ^(Picture-in-Picture)$"
            "keep_aspect_ratio on, match:title ^(Picture-in-Picture)$"
            "no_blur on, match:tag games*"
            "fullscreen on, match:tag games*"
            # Prevent the fabled odd xwaylandvideobridge from wreaking havoc on our fair hyprland. Source: https://wiki.hypr.land/Useful-Utilities/Screen-Sharing/#xwayland
            "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
            "no_anim on, match:class ^(xwaylandviDeobridge)$"
            "no_initial_focus on, match:class ^(xwaylandvideobridge)$"
            "max_size 1 1, match:class ^(xwaylandvideobridge)$"
            "no_blur on, match:class ^(xwaylandvideobridge)$"
            "no_focus on, match:class ^(xwaylandvideobridge)$"
            #"no_blur on, xwayland:1" # Helps prevent odd borders/shadows for xwayland apps
            # downside it can impact other xwayland apps
            # This rule is a template for a more targeted approach
            "no_blur on, match:class ^(\bresolve\b)$, match:xwayland on" # Window rule for just resolve
          ]
          ++ [
            # TODO: All float, allow resize and maybe use a scrolling layout
            "workspace special:social, match:tag social"
          ];
        plugin = {
          wslayout = {
            default_layout = "master";
          };
          scrolling = {
            column_width = 0.7;
            fullscreen_on_one_column = true;
          };
        };
        source = [
          # Required by hyprDynamicMonitors?
          "${config.xdg.configHome}/hypr/monitors.conf"
        ];
        workspace = [
          "special:social,layoutopt:wslayout-layout:scrolling"
        ];
      };
      submaps = {
        player.settings = {
          binde = [
            ", space, exec, playerctl play-pause"
            ", j, exec, playerctl next"
            ", k, exec, playerctl previous"
            ", h, exec, playerctl position 10-"
            ", l, exec, playerctl position 10+"
          ];
          bind = [
            ", escape, submap, reset"
          ];
        };
        # Map to autoexit the map again
        neovim.settings = {
          bind = [
            ", 1, exec, neovide"
            ", 2, exec, neovide --neovim-bin ${config.myOptions.roles.nvf.newPackage}/bin/nvim"
            ", 3, exec, neovide --neovim-bin ${config.myOptions.roles.nvf.frankenPackage}/bin/nvim"
            ", 4, exec, neovide --neovim-bin ${config.myOptions.roles.nvf.maximalPackage}/bin/nvim"
            ", escape, submap, reset"
          ];
        };
        # TODO: Replace hyprctl with correct dispatchers
        hyprctl-layout.settings = {
          binde = [
            ", d, exec, hyprctl dispatch layoutmsg setlayout dwindle"
            ", s, exec, hyprctl dispatch layoutmsg setlayout scrolling"
            ", m, exec, hyprctl dispatch layoutmsg setlayout master"
          ];
          bind = [
            ", escape, submap, reset"
          ];
        };
        hyprctl-groups.settings = {
          bind = [
            ", SPACE, exec, hyprctl dispatch togglegroup"
            # TODO:Do the normal focus keys also work?
            ", J, exec, hyprctl dispatch changegroupactive b"
            ", K, exec, hyprctl dispatch changegroupactive f"
            ", escape, submap, reset"
          ];
        };
        # Neovimn't bindings, aka trying to replicate some vim-escque commands
        neovimnt.settings = {
          bind = [
            ", escape, submap, reset"
          ];
        };
      };
    };
    services = {
      hypridle = {
        enable = true;
        settings = {
          general = {
            ignore_dbus_inhibit = false;
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "${lib.getExe pkgs.playerctl} pause; loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              # Longer default
              timeout = 1800;
              on-timeout = "hyprlock";
            }
            {
              timeout = 900;
              on-timeout = "echo 'Turned off display via dpms' && hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
              # Could cause issues with e.g. videos
              ignore_inhibit = true;
            }
          ];
        };
      };
      gnome-keyring = {
        enable = true;
        # Exclude ssh component
        components = [
          "pkcs11"
          "secrets"
        ];
      };
      udiskie = {
        enable = true;
        automount = false;
      };
      hyprsunset = {
        enable = true;
        settings = {
          max-gamma = 200;
          profile = [
            {
              time = "7:30";
              identity = true;
            }
            {
              time = "22:30";
              temperature = 4800;
              gamma = 0.9;
            }
          ];
        };
      };
      swaync.enable = true;
      hyprpolkitagent.enable = true;
      hyprshell = {
        enable = false;
        settings = {
          windows = {
            scale = 8.0;
            overview = {
              launcher = {
                max_items = 6;
              };
            };
            switch = {
              modifier = "alt";
            };
          };
        };
      };
      hyprpaper = {
        enable = true;
        settings.splash = false;
      };
    };

    # TODO: New wallpaper
    programs.hyprlock = {
      enable = true;
      settings.source = [
        (pkgs.replaceVars ../../dotfiles/hypr/hyprlock.conf {
          BACKGROUND_IMAGE = config.stylix.image;
          FONT = "CommitMono Nerd Font Mono";
          SYMBOL_SCRIPT = ../../dotfiles/hypr/gen_lock_symbols.py;
        })
      ];
    };
    # TODO: Do we need pyprland?
    programs.wleave = {
      enable = true;
      settings = {
        margin = 200;
        buttons-per-row = "1/1";
        delay-command-ms = 100;
        close-on-lost-focus = true;
        show-keybinds = true;
        buttons = [
          {
            label = "lock";
            action = "loginctl lock-session";
            text = "Lock";
            keybind = "l";
            icon = "${inputs.catppuccin-wlogout}/icons/wleave/macchiato/maroon/lock.svg";
          }
          {
            label = "logout";
            # action = "loginctl terminate-user $USER";
            action = "hyprctl dispatch exit";
            text = "Logout";
            keybind = "e";
            icon = "${inputs.catppuccin-wlogout}/icons/wleave/macchiato/maroon/logout.svg";
          }
          {
            label = "hibernate";
            action = "hyprctl dispatch exit";
            text = "hibernate";
            keybind = "h";
            icon = "${inputs.catppuccin-wlogout}/icons/wleave/macchiato/maroon/hibernate.svg";
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "s";
            icon = "${inputs.catppuccin-wlogout}/icons/wleave/macchiato/maroon/shutdown.svg";
          }
          {
            label = "suspend";
            action = "systemctl suspend-then-hibernate";
            text = "Suspend";
            keybind = "u";
            icon = "${inputs.catppuccin-wlogout}/icons/wleave/macchiato/maroon/suspend.svg";
          }

          {
            label = "reboot";
            action = "systemctl reboot";
            text = "Reboot";
            keybind = "r";
            icon = "${inputs.catppuccin-wlogout}/icons/wleave/macchiato/maroon/reboot.svg";
          }
        ];
      };
      style = ''
        @import url("${inputs.catppuccin-wlogout}/themes/macchiato/maroon.css");
      '';
    };
    programs.rofi = {
      enable = true;
      extraConfig = {
        show-icons = true;
      };
      theme = ../../dotfiles/rofi/launcher.rasi;
    };
    stylix.targets = {
      rofi.enable = false;
      waybar.enable = false;
      hyprlock.enable = false;
      hyprpaper.image.override = let
        blurred_wallpaper = pkgs.runCommand "blurred-wallpaper.png" {} ''
          echo "${config.stylix.image}"
          echo "$out"
          ${pkgs.imagemagick}/bin/magick "${config.stylix.image}" -channel RGBA -blur 0x16 "$out"
        '';
      in "${blurred_wallpaper}";
    };
    # TODO: Separate bar for work workspace
    programs.waybar = {
      enable = true;
      style = "@import url(\"${self}/dotfiles/waybar/style.css\");";
      settings.mainBar = {
        position = "top";
        layer = "top";
        height = 20;
        spacing = 4;
        reload_style_on_change = true;
        # TODO: Configure sway ipc for hide
        # mode = "hide";
        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
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
          "power-profiles-daemon"
          # TODO: Integrate pomodoro
          "backlight"
          "battery"
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
          format-muted = "󰝛";
          max-volume = "175.0";
        };
        # "hyprland/workspaces" = {
        #   active-only = true;
        #   # TODO: Format with icon
        #   workspace-taskar = {
        #     enable = true;
        #     # Probably optional
        #     update-active-window = true;
        #   };
        #   # TODO: How to separate into e.g. work and private?
        # };
        "hyprland/window" = {
          icon = true;
          max-length = 80;
          separate-outputs = true;
          # Don't work
          rewrite = {
            "(\(\d+\))(.*?YouTube.*?)" = "\2"; # Remove notification number from YouTube
            "Telegram (\(\d+\))" = "Telegram";
            "(\(\d+\)) (Discord.*)" = "\2";
            "Signal (\(\d+\))" = "Signal";
            "nheko (\(\d+\))" = "nheko";
          };
        };
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
        "tray" = {
          spacing = 4;
          icon-size = 20;
          icons = {
            # TODO: Maybe turn monochrome or graysale with imagemagick
            # Remove notification badges
            "signal desktop" = "${config.home.homeDirectory}/.nix-profile/share/icons/hicolor/32x32/apps/signal-desktop.png";
            "TelegramDesktop" = "${config.home.homeDirectory}/.nix-profile/share/icons/hicolor/32x32/apps/org.telegram.desktop.png";
            "nheko" = "${config.home.homeDirectory}/.nix-profile/share/icons/hicolor/32x32/apps/nheko.png";
            # TODO: Vesktop
          };
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
        "battery" = {
          interval = 3;
          states = {
            full = 100;
            charging = 99;
            low = 30;
            critical = 10;
          };
          format = "{capacity} {icon} {time}";
          format-time = "{H}:{m}h";
          format-charging-full = "full󰁔";
          format-icons = {
            "charging" = "󰁜";
            "discharging" = "󰁃";
          };
        };
      };
      systemd = {
        enable = true;
        enableDebug = true;
        enableInspect = false;
        target = "hyprland-session.target";
      };
    };

    # Required for waybar animations to properly function
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

    programs.hyprshot = {
      enable = true;
      saveLocation = "$HOME/Pictures/Screenshots";
    };

    # TODO: Remove unneedded
    home.packages = with pkgs; [
      swww
      grim
      slurp
      wl-clipboard
      swappy
      ydotool
      hyprpolkitagent
      hyprland-qtutils # needed for banners and ANR messages
      brightnessctl
      swaynotificationcenter

      # Own
      networkmanagerapplet
      # TODO: Try networkmanager_dmenu?
      clipvault
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
      wev

      waystt
      config.home.hyprdynamicmonitors.package
      rofiDisplayLayout

      # Fonts
      nerd-fonts.commit-mono
      powerline-symbols
      powerline-fonts

      rofi-home-assistant
      rofi-tag-switcher
     ] ++ (lib.attrsets.mapAttrsToList (_: script: script) layoutScripts);

    xdg.portal = {
      enable = lib.mkForce true;
      xdgOpenUsePortal = true;
      # TODO: Config for filepicker
      extraPortals = with pkgs; [
        gnome-keyring
        xdg-desktop-portal-gtk
        osConfig.programs.hyprland.portalPackage
        kdePackages.xdg-desktop-portal-kde
      ];
      config = {
        common = {
          default = [
            "gtk"
            "kde"
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
      };
    };
    home.hyprdynamicmonitors = {
      enable = true;
      installExamples = false;
      installThemes = true;
    };
    # Rebuild cache for dolphin
    home.activation.rebuild-kde-xdg-cache = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.kdePackages.kservice.out}/bin/kbuildsycoca6
    '';

    sops.secrets."hass_cli_token" = {
      sopsFile = "${secrets}/secrets/services/home-assistant.yaml";
      key = "access_tokens/cli";
    };

    #     systemd.user.services = let
    # dbus_user_services = "${config.xdg.dataHome}/dbus-1/services";
    #       kde6_blocker_unit_name = "org.kde.kded6.service";
    #     in{
    #       create-kde6-blocker = {
    #         Unit = {
    #           Description = "Prevent kde6 from starting and stealing the notification dbus";
    #         };
    #         Service = let blocker_file = pkgs.writeText "kde6_blocker" ''
    #           [D-BUS Service]
    #           Name=org.kde.kde6
    #           Exec=/bin/false
    #         ''; in {
    #           Type = "oneshot";
    #           ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${dbus_user_services}";
    #           ExecStart = "${pkgs.coreutils}/bin/cp -f ${blocker_file} ${dbus_user_services}/${kde6_blocker_unit_name}";
    #         };
    #         Install = {
    #           WantedBy = ["hyprland.target"];
    #         };
    #       };
    #       delete-kde6-blocker = {
    #         Unit = {
    #           Description = "Delete modified kded6 service file";
    #         };
    #         Service = {
    #           Type = "oneshot";
    #           RemainAfterExit = "yes";
    #           ExecStart = "/bin/true";
    #           ExecStop = "${pkgs.coreutils}/bin/rm -f ${dbus_user_services}/${kde6_blocker_unit_name}";
    #         };
    #         Install = {
    #           WantedBy = ["hyprland.target"];
    #         };
    #       };
    #     };
  };
}
