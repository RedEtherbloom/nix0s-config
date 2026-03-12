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
  noctaliaPackage = config.programs.noctalia-shell.package;
  noctaliaIpcCommand = command: "${noctaliaPackage}/bin/noctalia-shell ipc call ${command}";
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
            cmd = noctaliaIpcCommand "launcher clipboard";
          }
          {
            key = "e";
            desc = "Emoji";
            cmd = noctaliaIpcCommand "launcher emoji";
          }
          {
            key = "r";
            desc = "Command runner";
            cmd = noctaliaIpcCommand "launcher command";
          }
          {
            key = "w";
            desc = "Window switcher";
            cmd = noctaliaIpcCommand "launcher windows";
          }
          {
            key = "s";
            desc = "Settings search";
            cmd = noctaliaIpcCommand "launcher settings";
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
                cmd = noctaliaIpcCommand "brightness decrease";
                keep_open = true;
              }
              {
                key = "k";
                desc = "Increase brightness";
                cmd = noctaliaIpcCommand "brightness increase";
                keep_open = true;
              }
              {
                key = "n";
                desc = "Toggle eye strain dimmer(nightlight)";
                cmd = noctaliaIpcCommand "nightLight toggle";
                keep_open = true;
              }
              {
                key = "p";
                desc = "Lock screen and power off monitors";
                cmd = "${noctaliaIpcCommand "lockScreen lock"} && ${lib.getExe config.programs.niri.package} msg action power-off-monitors";
              }
              {
                key = "P";
                desc = "Power off monitors";
                cmd = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";
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
                cmd = noctaliaIpcCommand "powerProfile set powersaver";
              }
              {
                key = "b";
                desc = "Balanced";
                cmd = noctaliaIpcCommand "powerProfile set balanced";
              }
              {
                key = "p";
                desc = "Performance";
                cmd = noctaliaIpcCommand "powerProfile set performance";
              }
              {
                key = "c";
                desc = "Cycle power profiles";
                cmd = noctaliaIpcCommand "powerProfile cycle";
              }
            ];
          }
        ];
      }
      {
        key = "c";
        desc = "Clipboard";
        cmd = noctaliaIpcCommand "launcher clipboard";
      }
      {
        key = "e";
        desc = "Emoji";
        cmd = noctaliaIpcCommand "launcher emoji";
      }
      {
        key = "f";
        desc = "Firefox";
        cmd = "firefox";
      }
      {
        key = "t";
        desc = "File manager";
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
            cmd = noctaliaIpcCommand "notifications toggleDND";
          }
          {
            key = "D";
            desc = "Turn on do not disturb";
            cmd = noctaliaIpcCommand "notifications enableDND";
          }
          {
            key = "t";
            desc = "Toggle notification display";
            cmd = noctaliaIpcCommand "notifications toggleHistory";
          }
          {
            key = "x";
            desc = "Dismiss all notifications";
            cmd = noctaliaIpcCommand "notifications dismissAll";
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
    ];
    media-control = mkWlrMenu "noctalia-media-control" [
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
        cmd = noctaliaIpcCommand "media playPause";
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
        cmd = noctaliaIpcCommand "volume decrease";
        keep_open = true;
      }
      {
        key = "k";
        desc = "Raise volume";
        cmd = noctaliaIpcCommand "volume increase";
        keep_open = true;
      }
      {
        key = "h";
        desc = "Seek back 5s";
        cmd = noctaliaIpcCommand "media seekRelative -5";
        keep_open = true;
      }
      {
        key = "l";
        desc = "Seek forward 5s";
        cmd = noctaliaIpcCommand "media seekRelative +5";
        keep_open = true;
      }
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
    dev-tools =
      mkWlrMenu "dev-tools"
      [
        {
          key = "n";
          desc = "Neovide";
          cmd = "neovide";
        }
        {
          key = "N";
          desc = "Nvf stock maximal configuration as fallback";
          cmd = "neovide --neovim-bin ${config.myOptions.roles.nvf.maximalPackage}/bin/nvim";
        }
        {
          key = "w";
          desc = "Speech to text";
          submenu = [
            {
              key = "s";
              desc = "Listen to speech";
              cmd = "whisp-away start";
              keep_open = true;
            }
            {
              key = "S";
              desc = "Stop listening to speech";
              cmd = "whisp-away stop";
              keep_open = true;
            }
          ];
        }
      ];
  };
  splitSpace = string: lib.strings.splitString " " string;
  niriSwitchToWindow = pkgs.writeShellScriptBin "niriSwitchToWindow.sh" ''
    set -e

    raw_json="$(${lib.getExe config.programs.niri.package} msg -j windows)"
    filtered="$(${lib.getExe pkgs.jq} --arg filterField "$1" --arg filterValue "$2" 'map(select(.[$filterField] == $filterValue))' <<< "$raw_json")"
    echo "Found $(${lib.getExe pkgs.jq} 'length' <<< "$filtered") windows matching criteria"
    id="$(${lib.getExe pkgs.jq} 'first | .id' <<< "$filtered")"
    echo "Switching to window with ID $id"
    ${lib.getExe config.programs.niri.package} msg action focus-window --id "$id"
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
          numlock = true; # Numlock on startup
        };
        touchpad = {
          accel-profile = "flat";
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
        warp-mouse-to-focus.enable = true;
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
      };

      layout = {
        background-color = "transparent";
        gaps = 16;

        preset-column-widths = [
          {proportion = 1.0 / 3.0;} # Default
          {proportion = 1.0 / 2.0;} # Default
          {proportion = 2.0 / 3.0;} # Default
        ];
        # Missing from niri-flake. If required: Extra config
        # preset-column-heights = [
        #   {proportion = 1.0 / 3.0;} # Default
        #   {proportion = 1.0 / 2.0;} # Default
        #   {proportion = 2.0 / 3.0;} # Default
        # ];
        focus-ring = {
          width = 2;
          # active-color "#7fc8ff" # Hope that noctalia takes care of this
          # inactive-color "#505050" # Hope that noctalia takes care of this
          # You can also use gradients. They take precedence over solid colors.
        };
        border.enable = false; # If you enable the border, you probably want to disable the focus ring.
        shadow = {
          enable = true;
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
        struts = {
          top = 8;
          right = 8;
          bottom = 8;
          left = 8;
        };
      };
      prefer-no-csd = true;
      screenshot-path = "${config.xdg.userDirs.pictures}/Screenshots/%Y-%m-%d_%H-%M-%S.png";
      window-rules = [
        {
          # Noctalia requirement
          geometry-corner-radius = {
            top-left = 5.0;
            top-right = 5.0;
            bottom-left = 5.0;
            bottom-right = 5.0;
          };
          clip-to-geometry = true;
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
      # TODO: Disable overview wallpaper in noctalia for niri overview background
      debug.honor-xdg-activation-with-invalid-serial = true; # Required by noctalia
      xwayland-satellite = {
        enable = true;
        path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
      };
      hotkey-overlay.hide-not-bound = true;
      cursor = {
        theme = "LyraQ-cursors";
        size = 36;
        hide-after-inactive-ms = 15 * 1000;
        hide-when-typing = true;
      };
      binds = {
        "Mod+Shift+Slash".action.show-hotkey-overlay = [];

        "Mod+T" = {
          hotkey-overlay.title = "Spawn terminal";
          action.spawn = "${lib.getExe config.programs.kitty.package}";
        };
        "Mod+D" = {
          hotkey-overlay.title = "Wlr: Various launchers and common applications";
          action.spawn = "${lib.getExe wlrLaunchers.common}";
        };
        "Mod+Alt+L" = {
          hotkey-overlay.title = "Lock screen";
          action.spawn = splitSpace (noctaliaIpcCommand "lockScreen lock");
        };

        # "-l 1.0" limits the volume to 100%.
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action.spawn = splitSpace (noctaliaIpcCommand "volume increase");
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action.spawn = splitSpace (noctaliaIpcCommand "volume decrease");
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn = splitSpace "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        # TODO: Force kill command for unresponsive playback using e.g. muting pipewire outputs that works on lockscreen
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
        };

        "Mod+Shift+E" = {
          hotkey-overlay.title = "Show session menu";
          action.spawn-sh = noctaliaIpcCommand "sessionMenu toggle";
        };
        "Ctrl+Alt+Delete" = {
          hotkey-overlay.title = "Show system monitor";
          action.spawn-sh = noctaliaIpcCommand "systemMonitor toggle";
        };

        "Mod+Shift+P" = {
          hotkey-overlay.title = "Lock the screen and power it off";
          action.spawn-sh = "${noctaliaIpcCommand "lockScreen lock"} && ${lib.getExe config.programs.niri.package} msg action power-off-monitors";
        };
        "Mod+Shift+Ctrl+P" = {
          hotkey-overlay.title = "Power off the screens";
          action.power-off-monitors = [];
        };

        "Mod+Space" = {
          hotkey-overlay.title = "Show launcher";
          action.spawn-sh = noctaliaIpcCommand "launcher toggle";
        };
        "Mod+Shift+Space" = {
          hotkey-overlay.title = "Show window switcher";
          action.spawn-sh = noctaliaIpcCommand "launcher windows";
        };
        "Mod+Comma" = {
          hotkey-overlay.title = "Show control center";
          action.spawn-sh = noctaliaIpcCommand "controlCenter toggle";
        };
        "Mod+Shift+Comma" = {
          hotkey-overlay.title = "Show settings menu";
          action.spawn-sh = noctaliaIpcCommand "settings toggle";
        };
        "Mod+P" = {
          hotkey-overlay.title = "Media control";
          action.spawn-sh = "${lib.getExe wlrLaunchers.media-control}";
        };
        "Mod+N" = {
          hotkey-overlay.title = "Dev tools and note taking";
          action.spawn-sh = "${lib.getExe wlrLaunchers.dev-tools}";
        };
      };
    };
  };

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default.override {calendarSupport = true;};
    systemd.enable = true; # TODO: Replace with uwsm asap. Unsupported and begins to cause issues(e.g. the sporadic qs crashes).
    plugins = {
      sources = [
        {
          enabled = true;
          name = "Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        activate-linux = {
          enabled = false;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        catwalk = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        kagi-quick-search = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        keybind-cheatsheet = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        niri-overview-launcher = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        pomodoro = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        translator = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 2;
    };
    settings = {
      appLauncher = {
        autoPasteClipboard = false;
        clipboardWatchImageCommand = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch cliphist store";
        clipboardWatchTextCommand = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch cliphist store";
        clipboardWrapText = true;
        customLaunchPrefix = "";
        customLaunchPrefixEnabled = false;
        density = "default";
        enableClipPreview = true;
        enableClipboardHistory = true;
        enableSessionSearch = true;
        enableSettingsSearch = true;
        enableWindowsSearch = true;
        iconMode = "tabler";
        ignoreMouseInput = false;
        overviewLayer = false;
        pinnedApps = [];
        position = "center";
        screenshotAnnotationTool = "";
        showCategories = true;
        showIconBackground = false;
        sortByMostUsed = true;
        terminalCommand = "${config.programs.kitty.package}/bin/kitty -e";
        useApp2Unit = false;
        viewMode = "list";
      };
      audio = {
        cavaFrameRate = 30;
        mprisBlacklist = [];
        preferredPlayer = "";
        visualizerType = "linear";
        volumeFeedback = false;
        volumeOverdrive = false;
        volumeStep = 5;
      };
      bar = {
        autoHideDelay = 500;
        autoShowDelay = 150;
        backgroundOpacity = 0.93;
        barType = "simple";
        capsuleColorKey = "none";
        capsuleOpacity = 1;
        density = "default";
        displayMode = "always_visible";
        floating = false;
        frameRadius = 12;
        frameThickness = 8;
        hideOnOverview = false;
        marginHorizontal = 4;
        marginVertical = 4;
        monitors = [];
        outerCorners = false;
        position = "bottom";
        screenOverrides = [];
        showCapsule = true;
        showOutline = false;
        useSeparateOpacity = false;
        widgets = {
          center = [
            {
              characterCount = 2;
              colorizeIcons = false;
              emptyColor = "secondary";
              enableScrollWheel = true;
              focusedColor = "primary";
              followFocusedScreen = false;
              groupedBorderOpacity = 1;
              hideUnoccupied = false;
              iconScale = 0.8;
              id = "Workspace";
              labelMode = "index";
              occupiedColor = "secondary";
              pillSize = 0.6;
              reverseScroll = false;
              showApplications = false;
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 1;
            }
          ];
          left = [
            {
              icon = "rocket";
              iconColor = "none";
              id = "Launcher";
            }
            {
              clockColor = "none";
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              tooltipFormat = "HH:mm ddd, MMM dd";
              useCustomFont = false;
            }
            {
              compactMode = true;
              diskPath = "/";
              iconColor = "none";
              id = "SystemMonitor";
              showCpuFreq = false;
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskAvailable = false;
              showDiskUsage = false;
              showDiskUsageAsPercent = false;
              showGpuTemp = false;
              showLoadAverage = false;
              showMemoryAsPercent = false;
              showMemoryUsage = true;
              showNetworkStats = false;
              showSwapUsage = false;
              textColor = "none";
              useMonospaceFont = true;
              usePadding = false;
            }
            {
              colorizeIcons = false;
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 145;
              scrollingMode = "hover";
              showIcon = true;
              textColor = "none";
              useFixedWidth = false;
            }
            {
              compactMode = false;
              compactShowAlbumArt = true;
              compactShowVisualizer = false;
              hideMode = "hidden";
              hideWhenIdle = false;
              id = "MediaMini";
              maxWidth = 145;
              panelShowAlbumArt = true;
              panelShowVisualizer = true;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = false;
              textColor = "none";
              useFixedWidth = false;
              visualizerType = "linear";
            }
          ];
          right = [
            {
              blacklist = [];
              chevronColor = "none";
              colorizeIcons = false;
              drawerEnabled = true;
              hidePassive = false;
              id = "Tray";
              pinned = [];
            }
            {
              hideWhenZero = false;
              hideWhenZeroUnread = false;
              iconColor = "none";
              id = "NotificationHistory";
              showUnreadBadge = true;
              unreadBadgeColor = "primary";
            }
            {
              deviceNativePath = "__default__";
              displayMode = "graphic-clean";
              hideIfIdle = false;
              hideIfNotDetected = true;
              id = "Battery";
              showNoctaliaPerformance = false;
              showPowerProfiles = false;
            }
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "Volume";
              middleClickCommand = "${lib.getExe pkgs.pwvucontrol} || ${lib.getExe pkgs.pavucontrol}";
              textColor = "none";
            }
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "Brightness";
              textColor = "none";
            }
            {
              colorizeDistroLogo = false;
              colorizeSystemIcon = "none";
              customIconPath = "";
              enableColorization = false;
              icon = "noctalia";
              id = "ControlCenter";
              useDistroLogo = false;
            }
            {id = "plugin:keybind-cheatsheet";}
            {id = "plugin:pomodoro";}
            {id = "plugin:catwalk";}
          ];
        };
      };
      brightness = {
        brightnessStep = 5;
        enableDdcSupport = true;
        enforceMinimum = true;
      };
      calendar = {
        cards = [
          {
            enabled = true;
            id = "calendar-header-card";
          }
          {
            enabled = true;
            id = "calendar-month-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
        ];
      };
      colorSchemes = {
        darkMode = true;
        generationMethod = "tonal-spot";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        monitorForColors = "";
        predefinedScheme = "Eldritch";
        schedulingMode = "off";
        useWallpaperColors = false;
      };
      controlCenter = {
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = false;
            id = "brightness-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
        diskPath = "/";
        position = "close_to_bar_button";
        shortcuts = {
          left = [
            {id = "Network";}
            {id = "Bluetooth";}
            {id = "WallpaperSelector";}
            {id = "NoctaliaPerformance";}
          ];
          right = [
            {id = "Notifications";}
            {id = "PowerProfile";}
            {id = "KeepAwake";}
            {id = "NightLight";}
          ];
        };
      };
      desktopWidgets = {
        enabled = true;
        gridSnap = false;
        monitorWidgets = [];
      };
      dock = {
        animationSpeed = 1;
        backgroundOpacity = 1;
        colorizeIcons = false;
        deadOpacity = 0.6;
        displayMode = "auto_hide";
        enabled = true;
        floatingRatio = 1;
        inactiveIndicators = false;
        monitors = [];
        onlySameOutput = true;
        pinnedApps = [];
        pinnedStatic = false;
        position = "bottom";
        size = 1;
      };
      general = {
        allowPanelsOnScreenWithoutBar = true;
        allowPasswordWithFprintd = false;
        animationDisabled = false;
        animationSpeed = 1;
        autoStartAuth = false;
        avatarImage = "${config.home.homeDirectory}/.face"; # TODO: Source from dotfiles
        boxRadiusRatio = 1;
        clockFormat = "hh\\nmm";
        clockStyle = "custom";
        compactLockScreen = false;
        dimmerOpacity = 0.2;
        enableLockScreenCountdown = true;
        enableShadows = true;
        forceBlackScreenCorners = false;
        iRadiusRatio = 1;
        keybinds = {
          keyDown = ["Down"];
          keyEnter = ["Return"];
          keyEscape = ["Esc"];
          keyLeft = ["Left"];
          keyRemove = ["Del"];
          keyRight = ["Right"];
          keyUp = ["Up"];
        };
        language = "";
        lockOnSuspend = true;
        lockScreenAnimations = true;
        lockScreenBlur = 0;
        lockScreenCountdownDuration = 10000;
        lockScreenMonitors = [];
        lockScreenTint = 0;
        radiusRatio = 1;
        scaleRatio = 1;
        screenRadiusRatio = 1;
        shadowDirection = "bottom_right";
        shadowOffsetX = 2;
        shadowOffsetY = 3;
        showChangelogOnStartup = true;
        showHibernateOnLockScreen = true;
        showScreenCorners = false;
        showSessionButtonsOnLockScreen = true;
        telemetryEnabled = false;
      };
      hooks = {
        darkModeChange = "";
        enabled = false;
        performanceModeDisabled = "";
        performanceModeEnabled = "";
        screenLock = "";
        screenUnlock = "";
        session = "";
        startup = "";
        wallpaperChange = "";
      };
      location = {
        analogClockInCalendar = false;
        firstDayOfWeek = -1;
        hideWeatherCityName = false;
        hideWeatherTimezone = false;
        name = "Karlsruhe";
        showCalendarEvents = true;
        showCalendarWeather = true;
        showWeekNumberInCalendar = false;
        use12hourFormat = false;
        useFahrenheit = false;
        weatherEnabled = true;
        weatherShowEffects = true;
      };
      network = {
        airplaneModeEnabled = false;
        bluetoothDetailsViewMode = "grid";
        bluetoothHideUnnamedDevices = false;
        bluetoothRssiPollIntervalMs = 60000;
        bluetoothRssiPollingEnabled = false;
        disableDiscoverability = false;
        wifiDetailsViewMode = "grid";
        wifiEnabled = true;
      };
      nightLight = {
        autoSchedule = true;
        dayTemp = "6500";
        enabled = false;
        forced = false;
        manualSunrise = "06:30";
        manualSunset = "18:30";
        nightTemp = "4500";
      };
      notifications = {
        backgroundOpacity = 1;
        criticalUrgencyDuration = 15;
        density = "default";
        enableBatteryToast = true;
        enableKeyboardLayoutToast = true;
        enableMediaToast = false;
        enabled = true;
        location = "top_right";
        lowUrgencyDuration = 3;
        monitors = [];
        normalUrgencyDuration = 8;
        overlayLayer = true;
        respectExpireTimeout = true;
        saveToHistory = {
          critical = true;
          low = true;
          normal = true;
        };
        sounds = {
          criticalSoundFile = "";
          enabled = false;
          excludedApps = "discord,firefox,chrome,chromium,edge";
          lowSoundFile = "";
          normalSoundFile = "";
          separateSounds = false;
          volume = 0.5;
        };
      };
      osd = {
        autoHideMs = 2000;
        backgroundOpacity = 1;
        enabled = true;
        enabledTypes = [0 1 2]; # Low, Normal, High priority
        location = "top_right";
        monitors = [];
        overlayLayer = true;
      };
      plugins.autoUpdate = false;
      sessionMenu = {
        countdownDuration = 10000;
        enableCountdown = true;
        largeButtonsLayout = "single-row";
        largeButtonsStyle = true;
        position = "center";
        powerOptions = [
          {
            action = "lock";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "1";
          }
          {
            action = "suspend";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "2";
          }
          {
            action = "hibernate";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "3";
          }
          {
            action = "reboot";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "4";
          }
          {
            action = "logout";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "5";
          }
          {
            action = "shutdown";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "6";
          }
          {
            action = "rebootToUefi";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "";
          }
        ];
        showHeader = true;
        showKeybinds = true;
      };
      settingsVersion = 53;
      systemMonitor = {
        batteryCriticalThreshold = 5;
        batteryWarningThreshold = 20;
        cpuCriticalThreshold = 90;
        cpuWarningThreshold = 80;
        criticalColor = "";
        diskAvailCriticalThreshold = 10;
        diskAvailWarningThreshold = 20;
        diskCriticalThreshold = 90;
        diskWarningThreshold = 80;
        enableDgpuMonitoring = false;
        externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
        gpuCriticalThreshold = 90;
        gpuWarningThreshold = 80;
        memCriticalThreshold = 90;
        memWarningThreshold = 80;
        swapCriticalThreshold = 90;
        swapWarningThreshold = 80;
        tempCriticalThreshold = 90;
        tempWarningThreshold = 80;
        useCustomColors = false;
        warningColor = "";
      };
      templates = {
        activeTemplates = [];
        enableUserTheming = false;
      };
      ui = {
        bluetoothDetailsViewMode = "grid";
        bluetoothHideUnnamedDevices = false;
        boxBorderEnabled = false;
        fontDefault = "DejaVu Sans";
        fontDefaultScale = 1;
        fontFixed = "monospace";
        fontFixedScale = 1;
        networkPanelView = "wifi";
        panelBackgroundOpacity = 0.93;
        panelsAttachedToBar = true;
        settingsPanelMode = "attached";
        tooltipsEnabled = true;
        wifiDetailsViewMode = "grid";
      };
      wallpaper = {
        automationEnabled = false;
        directory = "${config.stylix.image}";
        enableMultiMonitorDirectories = false;
        enabled = true;
        favorites = [];
        fillColor = "#000000";
        fillMode = "crop";
        hideWallpaperFilenames = false;
        monitorDirectories = [];
        overviewBlur = 0.4;
        overviewEnabled = false;
        overviewTint = 0.6;
        panelPosition = "follow_bar";
        randomIntervalSec = 300;
        setWallpaperOnAllMonitors = true;
        showHiddenFiles = false;
        skipStartupTransition = false;
        solidColor = "#1a1a2e";
        sortOrder = "name";
        transitionDuration = 1500;
        transitionEdgeSmoothness = 0.05;
        transitionType = "random";
        useSolidColor = false;
        useWallhaven = false;
        viewMode = "single";
        wallhavenApiKey = "";
        wallhavenCategories = "111";
        wallhavenOrder = "desc";
        wallhavenPurity = "100";
        wallhavenQuery = "";
        wallhavenRatios = "";
        wallhavenResolutionHeight = "";
        wallhavenResolutionMode = "atleast";
        wallhavenResolutionWidth = "";
        wallhavenSorting = "relevance";
        wallpaperChangeMode = "random";
      };
    };
    pluginSettings = {};
  };
  systemd.user.services = {
    noctalia-shell.Unit.ConditionEnv = ["XDG_CURRENT_DESKTOP=niri"];
    swayidle.Unit.ConditionEnvironment = lib.mkForce [
      "WAYLAND_DISPLAY"
      "XDG_CURRENT_DESKTOP=niri"
    ];
  };
  stylix.targets.noctalia-shell.enable = false;

  home.packages = with pkgs; [
    # Optional noctalia dependencies
    cliphist
    cava
    ddcutil
    nautilus

    # Fonts, cursors, etc.
    lyra-cursors

    # Helper script block
    shikaneProfileSelector
    niriSwitchToWindow
    wlrLaunchers.common
    wlrLaunchers.media-control
    wlrLaunchers.dev-tools

    # Own
    thunarWithExtensions
    ytui-music
    gnome-calendar
    geary
  ];
  # TODO: Debug and redo polkit. KDE polkit still seems broken.

  services = {
    swayidle = let
      lock_cmd = noctaliaIpcCommand "lockScreen lock";
    in {
      enable = true;
      events = {
        lock = lock_cmd;
        before-sleep = "${noctaliaIpcCommand "media pause"}; ${lock_cmd}";
        after-resume = "${lock_cmd}";
      };
      timeouts = [
        {
          timeout = 300;
          command = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";
        }
        {
          # Longer default
          timeout = 900;
          command = "${lock_cmd}";
        }
        {
          timeout = 930;
          command = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";
        }
      ];
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
    shikane.enable = true;
  };
  # TODO: Set up fcitx5
}
