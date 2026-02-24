{
  config,
  lib,
  inputs,
  pkgs,
  osConfig,
  ...
}: let
  mkWlrConfig = menuName: menu:
    pkgs.writeText "${menuName}-config.yaml" (pkgs.lib.generators.toYAML {} {
      anchor = "center";
      # TODO: Fill in options
      inherit menu;
    });
  mkWlrMenu = menuName: menu:
    pkgs.writeShellScriptBin "wlr-menu-${menuName}.sh" ''
      exec ${lib.getExe pkgs.wlr-which-key} ${mkWlrConfig menuName menu}
    '';
  noctaliaPackage = config.programs.noctalia-shell.package;
  noctaliaIpcCommand = command: "${noctaliaPackage}/bin/noctalia-shell ipc call ${command}";
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
        # TODO: Clipboard manager
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
        # TODO: Get a better tui
        key = "m";
        desc = "YouTube Music";
        cmd = "${lib.getExe pkgs.ytui-music}";
      }
    ];
    media-control = mkWlrMenu "noctalia-media-control" [
      {
        key = "Space";
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
        key = "Shift+n";
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
        key = "Shift+m";
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
          submenu = [
            {
              key = "n";
              desc = "Standard nvf";
              cmd = "neovide";
            }
            {
              key = "1";
              desc = "Standard nvf";
              cmd = "neovide";
            }
            {
              key = "2";
              desc = "New nvf";
              cmd = "neovide --neovim-bin ${config.myOptions.roles.nvf.newPackage}/bin/nvim";
            }
            {
              key = "3";
              desc = "Frankestein merge of new and current nvf";
              cmd = "neovide --neovim-bin ${config.myOptions.roles.nvf.frankenPackage}/bin/nvim";
            }
            {
              key = "4";
              desc = "Nvf stock maximal configuration(with patches)";
              cmd = "neovide --neovim-bin ${config.myOptions.roles.nvf.maximalPackage}/bin/nvim";
            }
          ];
        }
        {
          key = "o";
          desc = "Obsidian";
          cmd = "obsidian";
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
              key = "Shift+s";
              desc = "Stop listening to speech";
              cmd = "whisp-away stop";
              keep_open = true;
            }
          ];
        }
      ];
  };
  splitSpace = string: lib.strings.splitString " " string;
in {
  imports = [
    inputs.niri-flake.homeModules.niri
    inputs.noctalia-shell.homeModules.default
  ];

  # TODO: Read through niri-flake stylix module
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
      };
      # TODO: Fill in outputs

      layout = {
        background-color = "transparent";
        gaps = 16;
        center-focused-column = "on-overflow";

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
          width = 4;
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
        struts = {}; # Sort of outer gaps
      };

      # TODO: Setup waybar start
      # Add lines like this to spawn processes at startup.
      # Note that running niri as a session supports xdg-desktop-autostart,
      # which may be more convenient to use.
      # See the binds section below for more spawn examples.
      # spawn-at-startup "waybar"

      prefer-no-csd = true;

      screenshot-path = "${config.xdg.userDirs.pictures}/Screenshots/%Y-%m-%d_%H-%M-%S.png";

      # TODO: Setup workspace switch animations

      window-rules = [
        {
          # Noctalia requirement
          geometry-corner-radius = {
            top-left = 20.0;
            top-right = 20.0;
            bottom-left = 20.0;
            bottom-right = 20.0;
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
      xwayland-satellite.enable = true;
      hotkey-overlay.hide-not-bound = true;
      binds = {
        "Mod+Shift+Slash".action.show-hotkey-overlay = []; # Show important hotkeys. Should be Mod+?

        "Mod+T" = {
          hotkey-overlay.title = "Spawn terminal";
          action.spawn = "${lib.getExe config.programs.kitty.package}";
        };
        "Mod+D" = {
          hotkey-overlay.title = "Application launcher: fuzzel";
          action.spawn = "fuzzel";
        };
        "Mod+Shift+D" = {
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
        # Mod+J     = { focus-window-or-workspace-down; };
        # Mod+Ctrl+J     = { move-window-down-or-to-workspace-down; };

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

        # Mod+Shift+Ctrl+Left  = { move-workspace-to-monitor-left; }; # You can also move a whole workspace to another monitor:

        # You can bind mouse wheel scroll ticks using the following syntax.
        # Binds will change direction based on the natural-scroll setting.
        # To avoid scrolling through workspaces really fast, you can use
        # the cooldown-ms property.
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

        # Center all fully visible columns on screen.
        "Mod+Ctrl+C".action.center-visible-columns = [];

        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";

        "Mod+Shift+Minus".action.set-window-height = "-10%";
        "Mod+Shift+Equal".action.set-window-height = "+10%";

        "Mod+V".action.toggle-window-floating = [];
        "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];

        # Toggle tabbed column display mode.
        # Windows in this column will appear as vertical tabs,
        # rather than stacked on top of each other.
        "Mod+W".action.toggle-column-tabbed-display = [];

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

        "Mod+Shift+P".action.power-off-monitors = [];

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
        # TODO: Notification bindings
        # TODO: Swayidle
      };
    };
  };

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default.override {calendarSupport = true;};
    systemd.enable = true; # See doc warnings about experimental status
  };
  systemd.user.services.noctalia-shell.Unit.ConditionEnv = ["XDG_CURRENT_DESKTOP=Niri"];
  programs.fuzzel.enable = true;

  home.packages = with pkgs; [
    thunarWithExtensions
    ytui-music
    nautilus
    # TODO: Find a file manager with vim keybinds
  ];
  # TODO: Check if polkit kde something is fixed
}
