{
  config,
  lib,
  inputs,
  pkgs,
  osConfig,
  ...
}: let
  # TODO: Move to own file, then upstream as home-manager option
  mkWlrConfig = name: menu:
    pkgs.writeTextFile {
      name = "${name}-config.yaml";
      text = pkgs.lib.generators.toYAML {} {
        anchor = "right";
        font = "CommitMono Nerd Font Mono 14";
        margin_right = 12;

        inherit menu;
      };
      checkPhase = ''
        ${lib.getExe pkgs.wlr-which-key-fork} --only-validate-config $out
      '';
    };
  mkWlrMenu = name: menu:
    pkgs.writeShellScriptBin "wlr-menu-${name}.sh" ''
      exec ${lib.getExe pkgs.wlr-which-key} ${mkWlrConfig name menu}
    '';
  noctaliaIpcCommand = command: "${config.programs.noctalia.package}/bin/noctalia msg ${command}";
  shikaneProfileSelector = let
    rofiSep = "|";
  in
    pkgs.writeShellScriptBin "shikaneProfileSelector.sh" ''
      ${pkgs.toml-cli}/bin/toml get ${config.xdg.configHome}/shikane/config.toml . | ${lib.getExe pkgs.jq} -r '.profile | map(.name) | join("${rofiSep}")' | ${lib.getExe pkgs.rofi} -dmenu -sep '${rofiSep}' | ${pkgs.findutils}/bin/xargs ${pkgs.shikane}/bin/shikanectl switch
    '';
  wlrLaunchers = {
    common = mkWlrMenu "noctalia-common" [
      {
        key = "l";
        desc = "Launchers";
        submenu = [
          {
            key = "c";
            desc = "Clipboard";
            cmd = noctaliaIpcCommand "panel-toggle clipboard";
          }
          {
            key = "e";
            desc = "Emoji";
            cmd = noctaliaIpcCommand "panel-toggle launcher /emo";
          }
          {
            key = "w";
            desc = "Window switcher";
            cmd = noctaliaIpcCommand "panel-toggle launcher /win";
          }
          {
            key = "s";
            desc = "Settings search";
            cmd = noctaliaIpcCommand "panel-toggle settings-toggle";
          }
          {
            key = "c";
            desc = "Start calculator";
            cmd = "${lib.getExe pkgs.qalculate-qt}";
          }
        ];
      }
      {
        key = "s";
        desc = "System managment commands";
        submenu = [
          {
            key = "b";
            desc = "Brightness";
            submenu = [
              {
                key = "j";
                desc = "Decrease brightness";
                cmd = noctaliaIpcCommand "brightness-down";
                keep_open = true;
              }
              {
                key = "k";
                desc = "Increase brightness";
                cmd = noctaliaIpcCommand "brightness-up";
                keep_open = true;
              }
              {
                key = "n";
                desc = "Toggle eye strain dimmer(nightlight)";
                cmd = noctaliaIpcCommand "nightlight-force-toggle";
                keep_open = true;
              }
              {
                key = "p";
                desc = "Lock screen and power off monitors";
                cmd = "${noctaliaIpcCommand "session lock"} && niri msg action power-off-monitors";
              }
              {
                key = "P";
                desc = "Power off monitors";
                cmd = "niri msg action power-off-monitors";
              }
            ];
          }
          {
            key = "p";
            desc = "Power management and power profiles";
            submenu = [
              {
                key = "s";
                desc = "Powersaver";
                cmd = noctaliaIpcCommand "power-set power-saver";
              }
              {
                key = "b";
                desc = "Balanced";
                cmd = noctaliaIpcCommand "power-set balanced";
              }
              {
                key = "p";
                desc = "Performance";
                cmd = noctaliaIpcCommand "power-set performance";
              }
              {
                key = "c";
                desc = "Cycle power profiles";
                cmd = noctaliaIpcCommand "power-cycle";
              }
            ];
          }
        ];
      }
      {
        key = "c";
        desc = "Clipboard";
        cmd = noctaliaIpcCommand "panel-toggle clipboard";
      }
      {
        key = "e";
        desc = "Emoji";
        cmd = noctaliaIpcCommand "launcher /emo";
      }
      {
        key = "f";
        desc = "Zen Browser";
        cmd = "zen-beta";
      }
      {
        key = "t";
        desc = "Thunar";
        cmd = "thunar";
      }
      {
        key = "m";
        desc = "YouTube Music";
        cmd = "${lib.getExe config.programs.kitty.package} -e${lib.getExe pkgs.ytui-music}";
      }
      {
        key = "M";
        desc = "ShellBeats!";
        cmd = "${lib.getExe config.programs.kitty.package} -e ${lib.getExe pkgs.shellbeats}";
      }
      {
        key = "d";
        desc = "Select display configuration via shikane";
        cmd = "${lib.getExe shikaneProfileSelector}";
      }
      {
        key = "D";
        desc = "Display configuration";
        cmd = "${lib.getExe pkgs.wdisplays}";
      }
      {
        key = "n";
        desc = "Notifications";
        submenu = [
          {
            key = "d";
            desc = "Toggle do not disturb";
            cmd = noctaliaIpcCommand "notification-dnd-toggle";
          }
          {
            key = "D";
            desc = "Turn on do not disturb";
            cmd = noctaliaIpcCommand "notification-dnd-set on";
          }
          {
            key = "t";
            desc = "Toggle notification display";
            cmd = noctaliaIpcCommand "notifications toggleHistory";
          }
          {
            key = "x";
            desc = "Dismiss all notifications";
            cmd = noctaliaIpcCommand "panel-toggle control-center notifications";
          }
        ];
      }
      {
        key = "M";
        desc = "Noctalia Media Control";
        submenu = [
          {
            key = "w";
            desc = "Configure pipewire volumes";
            cmd = "${lib.getExe pkgs.pwvucontrol}";
          }
          {
            key = "W";
            desc = "Pipewire patchbay";
            cmd = "${pkgs.raysession}/bin/raysession";
          }
          {
            key = "space";
            desc = "Toggle playback status";
            cmd = noctaliaIpcCommand "media toggle";
            keep_open = true;
          }
          {
            key = "n";
            desc = "Next track";
            cmd = noctaliaIpcCommand "media next";
            keep_open = true;
          }
          {
            key = "N";
            desc = "Previous track";
            cmd = noctaliaIpcCommand "media previous";
            keep_open = true;
          }
          {
            key = "j";
            desc = "Lower volume";
            cmd = noctaliaIpcCommand "volume-down";
            keep_open = true;
          }
          {
            key = "k";
            desc = "Raise volume";
            cmd = noctaliaIpcCommand "volume-up";
            keep_open = true;
          }
          # TODO: Implement with playerctl instead
          # {
          #   key = "h";
          #   desc = "Seek back 5s";
          #   cmd = noctaliaIpcCommand "media seekRelative -5";
          #   keep_open = true;
          # }
          # {
          #   key = "l";
          #   desc = "Seek forward 5s";
          #   cmd = noctaliaIpcCommand "media seekRelative +5";
          #   keep_open = true;
          # }
          {
            key = "m";
            desc = "Mute";
            cmd = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            keep_open = true;
          }
          {
            key = "M";
            desc = "Mute microphone";
            cmd = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            keep_open = true;
          }
          {
            key = "p";
            desc = "Toggle media panel";
            cmd = noctaliaIpcCommand "media toggle";
          }
        ];
      }
      {
        key = "H";
        desc = "Home assistant via rofi";
        cmd = "rofi-home-assistant-sops.sh";
      }
      {
        key = "b";
        desc = "Rofi bluetooth switcher";
        cmd = "${lib.getExe pkgs.rofi-bluetooth}";
      }
      {
        key = "o";
        desc = "Switch to or start Obsidian";
        cmd = "${lib.getExe niriSwitchToWindow} app_id obsidian || obsidian";
      }
      {
        key = "k";
        keep_open = true;
        desc = "Switch to next niri keyboard layout";
        cmd = "niri msg action switch-layout next";
      }
    ];
    dev-tools =
      mkWlrMenu "dev-tools"
      [
        {
          key = "e";
          desc = "Launch Emacs";
          cmd = "emacsclient -a \"\" -c";
        }
        {
          key = "E";
          desc = "Restart Emacs daemon, then launch Emacs";
          cmd = "systemctl restart --user emacs.service && emacsclient -a \"\" -c";
        }
        {
          key = "v";
          desc = "TODO: Voxd gui dictation";
          cmd = "voxd --gui";
        }
      ];
  };
  splitSpace = string: lib.strings.splitString " " string;
  niriSwitchToWindow = pkgs.writeShellScriptBin "niriSwitchToWindow.sh" ''
    set -e

    raw_json="$(niri msg -j windows)"
    filtered="$(${lib.getExe pkgs.jq} --arg filterField "$1" --arg filterValue "$2" 'map(select(.[$filterField] == $filterValue))' <<< "$raw_json")"
    echo "Found $(${lib.getExe pkgs.jq} 'length' <<< "$filtered") windows matching criteria"
    id="$(${lib.getExe pkgs.jq} 'first | .id' <<< "$filtered")"
    echo "Switching to window with ID $id"
    niri msg action focus-window --id "$id"
  '';
  muteAllSinks = pkgs.writeShellScriptBin "muteAllSinks.sh" ''
    set -e
          ${pkgs.pipewire}/bin/pw-dump | ${lib.getExe pkgs.jq} 'map(select(.info.props."media.class" | contains("Audio/Sink")?).id)[]' | ${pkgs.findutils}/bin/xargs -I{} ${pkgs.wireplumber}/bin/wpctl set-mute {} 1
  '';
in {
  imports = [
    inputs.niri-flake.homeModules.niri
    inputs.noctalia-shell.homeModules.default
  ];

  programs.niri = {
    enable = true;
    inherit (osConfig.programs.niri) package;
    settings = {
      input = {
        keyboard = {
          xkb = {inherit (osConfig.services.xserver.xkb) model layout variant options;};
          numlock = true;
        };
        touchpad = {
          accel-profile = "adaptive";
          tap = true;
          drag-lock = true;
          natural-scroll = true;
          scroll-method = "two-finger";
        };
        mouse = {
          accel-profile = "flat";
          natural-scroll = true;
        };
        trackpoint = {
          natural-scroll = false;
          accel-profile = "flat";
          scroll-method = "on-button-down";
          scroll-button-lock = true;
          middle-emulation = true;
          # scroll-button 273
        };
        warp-mouse-to-focus.enable = false;
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
      };

      layout = {
        background-color = "transparent";
        gaps = 16;
        empty-workspace-above-first = true;
        center-focused-column = "on-overflow";
        always-center-single-column = true;

        default-column-width = {
          proportion = 1. / 2.;
        };
        preset-column-widths = [
          {proportion = 1. / 3.;}
          {proportion = 1. / 2.;}
          {proportion = 2. / 3.;}
        ];
        preset-window-heights = [
          {proportion = 1. / 3.;}
          {proportion = 1. / 2.;}
          {proportion = 2. / 3.;}
        ];
        focus-ring = {
          width = 3;
          # active-color "#7fc8ff" # Hope that noctalia takes care of this
          # inactive-color "#505050" # Hope that noctalia takes care of this
          # You can also use gradients. They take precedence over solid colors.
        };
        border.enable = false; # If you enable the border, you probably want to disable the focus ring.
        shadow = {
          enable = false;
          # By default, the shadow draws only around its window, and not behind it.
          # Can lead to some weird issues.
          draw-behind-window = true;
          softness = 30; # Softness controls the shadow blur radius.
          spread = 5; # Spread expands the shadow.
          offset = {
            x = 0;
            y = 5;
          };
        };
        insert-hint = {
          enable = true;
          display.color = "#ffc87f80";
        };
        struts = {
          left = 8.0;
          right = 8.0;
          top = -4.0;
          bottom = -4.0;
        };
      };
      prefer-no-csd = true;
      screenshot-path = "${config.xdg.userDirs.pictures}/Screenshots/%Y-%m-%d_%H-%M-%S.png";
      window-rules = [
        {
          # Noctalia requirement
          geometry-corner-radius = {
            top-left = 7.0;
            top-right = 7.0;
            bottom-left = 7.0;
            bottom-right = 7.0;
          };
          clip-to-geometry = true;
          # Fun gimmicks
          # baba-is-float = true;
        }
        {
          matches = [
            {
              app-id = "firefox$";
              title = "^Picture-in-Picture$";
            }
          ];
          open-floating = true;
        }
      ];
      layer-rules = [
        {
          matches = [{namespace = "^noctalia-wallpaper*";}];
          place-within-backdrop = true;
        }
      ];
      overview.workspace-shadow.enable = false;
      debug.honor-xdg-activation-with-invalid-serial = true; # Required by Noctalia
      xwayland-satellite = {
        enable = true;
        path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
      };
      hotkey-overlay = {
        hide-not-bound = true;
        skip-at-startup = true;
      };
      cursor = {
        inherit (config.home.pointerCursor) size;
        theme = config.home.pointerCursor.name;
        hide-after-inactive-ms = 15 * 1000;
        hide-when-typing = true;
      };
      spawn-at-startup = [
        {sh = "noctalia";}
      ];
      switch-events.lid-close.action.spawn = splitSpace (noctaliaIpcCommand "session lock");
      binds = {
        "Mod+Shift+Slash".action.show-hotkey-overlay = [];

        "Mod+T" = {
          hotkey-overlay.title = "Spawn terminal";
          action.spawn = "${lib.getExe config.programs.kitty.package}";
        };
        "Mod+Shift+T".action.spawn = splitSpace "${pkgs.kitty}/bin/kitten quick-access-terminal";
        "Mod+Y" = {
          hotkey-overlay.title = "Wlr: Various launchers and common applications";
          action.spawn = "${lib.getExe wlrLaunchers.common}";
        };
        "Mod+Shift+O" = {
          hotkey-overlay.title = "Org capture";
          action.spawn = "org-capture";
        };
        "Mod+Alt+L" = {
          hotkey-overlay.title = "Lock screen";
          action.spawn = splitSpace "${noctaliaIpcCommand "session lock"} && niri msg action power-off-monitors";
        };

        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action.spawn = splitSpace (noctaliaIpcCommand "volume-up");
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action.spawn = splitSpace (noctaliaIpcCommand "volume-down");
        };
        "Mod+Ctrl+Shift+Space" = {
          allow-inhibiting = false;
          allow-when-locked = true;
          action.spawn = lib.getExe muteAllSinks;
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };
        "XF86AudioPlay" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${lib.getExe pkgs.playerctl} play-pause";
        };
        "XF86AudioStop" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${lib.getExe pkgs.playerctl} stop";
        };
        "XF86AudioPrev" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${lib.getExe pkgs.playerctl} previous";
        };
        "XF86AudioNext" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${lib.getExe pkgs.playerctl} next";
        };

        "XF86MonBrightnessUp" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${lib.getExe pkgs.brightnessctl} --class=backlight set +10%";
        };
        "XF86MonBrightnessDown" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${lib.getExe pkgs.brightnessctl} --class=backlight set 10%-";
        };

        # You can also move the mouse into the top-left hot corner or do a four-finger swipe up on a touchpad.
        "Mod+O" = {
          repeat = false;
          action.toggle-overview = [];
        };
        "Mod+Q" = {
          repeat = false;
          action.close-window = [];
        };

        "Mod+Left".action.focus-column-left = [];
        "Mod+Down".action.focus-window-down = [];
        "Mod+Up".action.focus-window-up = [];
        "Mod+Right".action.focus-column-right = [];
        "Mod+H".action.focus-column-left = [];
        "Mod+J".action.focus-window-down = [];
        "Mod+K".action.focus-window-up = [];
        "Mod+L".action.focus-column-right = [];

        "Mod+Shift+Left".action.move-column-left = [];
        "Mod+Shift+Down".action.move-window-down = [];
        "Mod+Shift+Up".action.move-window-up = [];
        "Mod+Shift+Right".action.move-column-right = [];
        "Mod+Shift+H".action.move-column-left = [];
        "Mod+Shift+J".action.move-window-down = [];
        "Mod+Shift+K".action.move-window-up = [];
        "Mod+Shift+L".action.move-column-right = [];

        # TODO: Try alternative commands that move across workspaces when reaching the first or last window in a column.
        # "Mod+J" = { focus-window-or-workspace-down; };
        # "Mod+Ctrl+J" = { move-window-down-or-to-workspace-down; };

        "Mod+Home".action.focus-column-first = [];
        "Mod+End".action.focus-column-last = [];
        "Mod+Shift+Home".action.move-column-to-first = [];
        "Mod+Shift+End".action.move-column-to-last = [];

        "Mod+Ctrl+Left".action.focus-monitor-left = [];
        "Mod+Ctrl+Down".action.focus-monitor-down = [];
        "Mod+Ctrl+Up".action.focus-monitor-up = [];
        "Mod+Ctrl+Right".action.focus-monitor-right = [];
        "Mod+Ctrl+H".action.focus-monitor-left = [];
        "Mod+Ctrl+J".action.focus-monitor-down = [];
        "Mod+Ctrl+K".action.focus-monitor-up = [];
        "Mod+Ctrl+L".action.focus-monitor-right = [];

        "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [];
        "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [];
        "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [];
        "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [];
        "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [];
        "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [];
        "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [];
        "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [];

        "Mod+Page_Down".action.focus-workspace-down = [];
        "Mod+Page_Up".action.focus-workspace-up = [];
        "Mod+U".action.focus-workspace-down = [];
        "Mod+I".action.focus-workspace-up = [];
        "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [];
        "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [];
        "Mod+Ctrl+U".action.move-column-to-workspace-down = [];
        "Mod+Ctrl+I".action.move-column-to-workspace-up = [];

        "Mod+Shift+Page_Down".action.move-workspace-down = [];
        "Mod+Shift+Page_Up".action.move-workspace-up = [];
        "Mod+Shift+U".action.move-workspace-down = [];
        "Mod+Shift+I".action.move-workspace-up = [];

        "Mod+WheelScrollDown" = {
          cooldown-ms = 150;
          action.focus-workspace-down = [];
        };
        "Mod+WheelScrollUp" = {
          cooldown-ms = 150;
          action.focus-workspace-up = [];
        };
        "Mod+Ctrl+WheelScrollDown" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-down = [];
        };
        "Mod+Ctrl+WheelScrollUp" = {
          cooldown-ms = 150;
          action.move-column-to-workspace-up = [];
        };

        "Mod+WheelScrollRight".action.focus-column-right = [];
        "Mod+WheelScrollLeft".action.focus-column-left = [];
        "Mod+Ctrl+WheelScrollRight".action.move-column-right = [];
        "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [];

        # Usually scrolling up and down with Shift in applications results in
        # horizontal scrolling; these binds replicate that.
        "Mod+Shift+WheelScrollDown".action.focus-column-right = [];
        "Mod+Shift+WheelScrollUp".action.focus-column-left = [];
        "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [];
        "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [];

        # Niri workspace numbers may work differently than we assume
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        "Mod+Ctrl+1".action.move-column-to-workspace = 1;
        "Mod+Ctrl+2".action.move-column-to-workspace = 2;
        "Mod+Ctrl+3".action.move-column-to-workspace = 3;
        "Mod+Ctrl+4".action.move-column-to-workspace = 4;
        "Mod+Ctrl+5".action.move-column-to-workspace = 5;
        "Mod+Ctrl+6".action.move-column-to-workspace = 6;
        "Mod+Ctrl+7".action.move-column-to-workspace = 7;
        "Mod+Ctrl+8".action.move-column-to-workspace = 8;
        "Mod+Ctrl+9".action.move-column-to-workspace = 9;

        # Alternatively, there are commands to move just a single window:
        # Mod+Ctrl+1 = { move-window-to-workspace 1; };

        # The following binds move the focused window in and out of a column.
        "Mod+BracketLeft".action.consume-or-expel-window-left = [];
        "Mod+BracketRight".action.consume-or-expel-window-right = [];

        "Mod+R".action.switch-preset-column-width = [];
        "Mod+Shift+R".action.switch-preset-window-height = [];
        "Mod+Ctrl+R".action.reset-window-height = [];
        "Mod+F".action.maximize-column = [];
        "Mod+Shift+F".action.fullscreen-window = [];
        "Mod+M".action.maximize-window-to-edges = [];
        "Mod+Ctrl+F".action.expand-column-to-available-width = []; # Expand the focused column to space not taken up by other fully visible columns.

        "Mod+C".action.center-column = [];
        "Mod+Ctrl+C".action.center-visible-columns = [];

        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";

        "Mod+Shift+Minus".action.set-window-height = "-10%";
        "Mod+Shift+Equal".action.set-window-height = "+10%";

        "Mod+V".action.toggle-window-floating = [];
        "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

        "Mod+W" = {
          hotkey-overlay.title = "Toggle tabbed column";
          action.toggle-column-tabbed-display = [];
        };

        "Print".action.screenshot = [];
        "Ctrl+Print".action.screenshot-screen = [];
        "Alt+Print".action.screenshot-window = [];

        "Mod+Escape" = {
          allow-inhibiting = false;
          action.toggle-keyboard-shortcuts-inhibit = [];
        }; # Safety hatch for e.g. RDP clients that capture all keyboard input

        "Mod+Shift+E" = {
          hotkey-overlay.title = "Show session menu";
          action.spawn-sh = noctaliaIpcCommand "panel-toggle session";
        };
        "Ctrl+Alt+Delete" = {
          hotkey-overlay.title = "Show system monitor";
          action.spawn-sh = "kitty -e btop";
        };

        "Mod+Shift+P" = {
          hotkey-overlay.title = "Lock the screen and power it off";
          action.spawn-sh = "${noctaliaIpcCommand "session lock"} && niri msg action power-off-monitors";
        };
        "Mod+Shift+Ctrl+P" = {
          hotkey-overlay.title = "Power off the screens";
          action.power-off-monitors = [];
        };

        "Mod+Space" = {
          hotkey-overlay.title = "Show launcher";
          action.spawn-sh = noctaliaIpcCommand "panel-toggle launcher";
        };
        "Mod+Shift+Space" = {
          hotkey-overlay.title = "Toggle playback";
          action.spawn = splitSpace "${lib.getExe pkgs.playerctl} play-pause";
        };
        "Mod+Shift+Tab" = {
          hotkey-overlay.title = "Window switcher";
          action.spawn = splitSpace (noctaliaIpcCommand "panel-toggle launcher /win");
        };
        "Mod+Comma" = {
          hotkey-overlay.title = "Show control center";
          action.spawn-sh = noctaliaIpcCommand "panel-toggle control-center";
        };
        "Mod+Shift+Comma" = {
          hotkey-overlay.title = "Show settings menu";
          action.spawn-sh = noctaliaIpcCommand "settings-toggle";
        };
        "Mod+N" = {
          hotkey-overlay.title = "Dev tools and note taking";
          action.spawn-sh = "${lib.getExe wlrLaunchers.dev-tools}";
        };
        # "Mod+Shift+O" = {
        #   hotkey-overlay.title = "Switch to Obsidian";
        #   action.spawn-sh = "${lib.getExe niriSwitchToWindow} app_id obsidian || obsidian";
        # };
      };
    };
  };

  programs.noctalia = {
    enable = true;
    package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
  stylix.targets.noctalia-shell.enable = false;

  home = {
    # Solution by 0x0013: https://github.com/noctalia-dev/noctalia-shell/issues/2272#issuecomment-4263496085
    activation.restartNoctaliaIfUpdated = let
      # this will correspond to noctalia in the just-activated home-manager generation
      noctaliaExe = lib.getExe config.programs.noctalia.package;
    in
      lib.hm.dag.entryAfter ["linkGeneration"]
      # bash
      ''
        if [[ ! -v oldGenPath || ! -x "$oldGenPath/home-path/bin/noctalia" ]]; then
        exit 0
        fi

        oldExe="$(readlink -f "$oldGenPath/home-path/bin/noctalia")"

        if [[ "$oldExe" != "${noctaliaExe}" ]]; then

        # this will use noctalia from the previous generation,
        # and tie the kill command to the instance of that generation
        "$oldExe" kill --any-display || true

        # start in daemon mode of the new generation
        "${noctaliaExe}" -d
        fi
      '';
    packages = with pkgs; [
      # Optional noctalia dependencies
      cliphist
      cava
      ddcutil
      nautilus

      # Fonts, cursors, etc.
      breeze-hacked-cursor-theme

      # Helper script block
      shikaneProfileSelector
      niriSwitchToWindow
      wlrLaunchers.common
      wlrLaunchers.dev-tools
      muteAllSinks

      # Own
      thunarWithExtensions
      ytui-music
      shellbeats
      gnome-calendar
    ];
  };

  # TODO: Set up fcitx5
  services = {
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
    shikane.enable = true;
  };
  xdg = {
    # cacheFile."noctalia/wallpapers.json".text = builtins.toJSON {
    #   defaultWallpaper = config.stylix.image;
    # };
    configFile."Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
      <action>
        <icon>utilities-terminal</icon>
        <name>Start terminal here</name>
        <submenu></submenu>
        <unique-id>1772009767743084-1</unique-id>
        <command>kitty -d %d</command>
        <description></description>
        <range></range>
        <patterns>*</patterns>
        <startup-notify/>
        <audio-files/>
        <image-files/>
        <other-files/>
        <text-files/>
        <video-files/>
      </action>
      <action>
        <icon></icon>
        <name>Start terminal in this directory</name>
        <submenu></submenu>
        <unique-id>1777313197096717-1</unique-id>
        <command>kitty -d %f</command>
        <description></description>
        <range></range>
        <patterns>*</patterns>
        <startup-notify/>
        <directories/>
      </action>
      </actions>
    '';
  };
}
