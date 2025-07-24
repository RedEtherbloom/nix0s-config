{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  system,
  ...
}: let
  cfg = config.myOptions.plasma-manager;
in {
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  options.myOptions.plasma-manager = {
    enable = lib.mkOption {
      description = "Enable plasma manager and applications";
      type = lib.types.bool;
      default = false;
    };
    krohnkite = lib.mkOption {
      description = "Enable krohnkite tiling WM shortcuts";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.plasma = {
        enable = true;
        fonts = let
          normalSize = 10;
          guiSize = 9;
          generalFont = builtins.head osConfig.fonts.fontconfig.defaultFonts.serif;
        in {
          general = {
            family = generalFont;
            pointSize = normalSize;
          };
          fixedWidth = {
            family = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
            pointSize = normalSize;
          };
          small = {
            family = generalFont;
            pointSize = 7;
          };
          toolbar = {
            family = generalFont;
            pointSize = guiSize;
          };
          menu = {
            family = generalFont;
            pointSize = guiSize;
          };
          windowTitle = {
            family = generalFont;
            pointSize = guiSize;
          };
        };
        # TODO: Lookup keyformat
        shortcuts =
          lib.attrsets.recursiveUpdate
          {
            "KDE Keyboard Layout Switcher" = {
              "Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
              "Switch to Next Keyboard Layout" = "Meta+Alt+K";
            };
            kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
            kmix = {
              "decrease_microphone_volume" = "Microphone Volume Down";
              "decrease_volume" = "Volume Down";
              "decrease_volume_small" = "Shift+Volume Down";
              "increase_microphone_volume" = "Microphone Volume Up";
              "increase_volume" = "Volume Up";
              "increase_volume_small" = "Shift+Volume Up";
              "mic_mute" = ["Microphone Mute" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone"];
              "mute" = "Volume Mute";
            };
            ksmserver = {
              "Lock Session" = ["Meta+Del" "Screensaver" "Screensaver,Lock Session"];
              "Log Out" = "Ctrl+Alt+Del";
            };
            kwin = {
              # What is this?
              # TODO: May be useful for task switching
              #"Cycle Overview" = [];
              #"Cycle Overview Opposite" = [];
              "Edit Tiles" = "Meta+T";
              "Expose" = "Ctrl+F9";
              "ExposeAll" = ["Ctrl+F10" "Launch (C),Ctrl+F10" "Launch (C),Toggle Present Windows (All desktops)"];
              "ExposeClass" = "Ctrl+F7";
              "ExposeClassCurrentDesktop" = "Ctrl+F8,none,Toggle Present Windows (Window class on current desktop)";
              "Grid View" = "Meta+G";
              "Kill Window" = ["Meta+Ctrl+Esc" "Meta+Shift+X,Meta+Ctrl+Esc,Kill Window"];
              "MinimizeAll" = "Meta+Shift+PgDown,none,MinimizeAll";
              # TODO: Revisit when using tablet
              "Move Tablet to Next Output" = [];
              "MoveMouseToCenter" = "Meta+F6";
              "MoveMouseToFocus" = "Meta+F5";
              #"MoveZoomDown" = "none,Meta+Ctrl+Down,Move Down";
              #"MoveZoomLeft" = "none,Meta+Ctrl+Left,Move Left";
              #"MoveZoomRight" = "none,Meta+Ctrl+Right,Move Right";
              #"MoveZoomUp" = "none,Meta+Ctrl+Up,Move Up";
              "Overview" = "Meta+W";
              "Setup Window Shortcut" = "none,,Setup Window Shortcut";
              "Show Desktop" = "Meta+D";
              "ShowDesktopGrid" = "Meta+F8";
              # TODO: What is this useful for?
              "Suspend Compositing" = "Alt+Shift+F12";
              "Activate Window Demanding Attention" = "Meta+Ctrl+A";
              # TODO: What is this useful for?
              "Invert" = "Meta+Ctrl+I";
              # TODO: What is this useful for?
              #"Invert Screen Colors" = [];
              # TODO: What is this useful for?
              "InvertWindow" = "Meta+Ctrl+U";
              # TODO: Disabled, may help with keeping the layout better in our hand
              #"Switch One Desktop Down" = "Meta+Ctrl+Down";
              #"Switch One Desktop Up" = "Meta+Ctrl+Up";
              #"Switch One Desktop to the Left" = "Meta+Ctrl+Left";
              #"Switch One Desktop to the Right" = "Meta+Ctrl+Right";
              "Switch to Desktop 1" = "Meta+1";
              "Switch to Desktop 2" = "Meta+2";
              "Switch to Desktop 3" = "Meta+3";
              "Switch to Desktop 4" = "Meta+4";
              "Switch to Desktop 5" = "Meta+5";
              "Switch to Desktop 6" = "Meta+6";
              "Switch to Desktop 7" = "";
              "Switch to Desktop 8" = "";
              "Switch to Desktop 9" = "";
              "Switch to Desktop 10" = "";
              "Switch to Next Desktop" = "none";
              "Switch to Next Screen" = "none";
              "Switch to Previous Desktop" = "none";
              "Switch to Previous Screen" = "none";
              "Switch to Screen 0" = "Meta+Ctrl+1";
              "Switch to Screen 1" = "Meta+Ctrl+2";
              "Switch to Screen 2" = "Meta+Ctrl+3";
              "Switch to Screen 3" = "Meta+Ctrl+4";
              "Switch to Screen Above" = "Meta+Up";
              "Switch to Screen Below" = "Meta+Down";
              "Switch to Screen to the Left" = "Meta+Left";
              "Switch to Screen to the Right" = "Meta+Right";
              # Shift+1
              "Window to Desktop 1" = "Meta+!";
              # Shift+2
              "Window to Desktop 2" = "Meta+\"";
              # Shift+3
              "Window to Desktop 3" = "Meta+§";
              # Shift+4
              "Window to Desktop 4" = "Meta+$";
              # Shift+5
              "Window to Desktop 5" = "Meta+%";
              # Shift+6
              "Window to Desktop 6" = "Meta+&";
              "Window to Desktop 7" = "";
              "Window to Desktop 8" = "";
              "Window to Desktop 9" = "";
              # Disabled for better thinking
              "Window to Next Desktop" = "";
              "Window to Previous Desktop" = "";
              "Window to Previous Screen" = "";
              "Window to Next Screen" = "";
              "Window to Screen 0" = "Meta+Ctrl+!";
              "Window to Screen 1" = "Meta+Ctrl+\"";
              "Window to Screen 2" = "Meta+Ctrl+§";
              "Window to Screen 3" = "Meta+Ctrl+$";
              # TODO: Why do these not work?
              "Window One Screen Down" = "Meta+Shift+Down";
              "Window One Screen Up" = "Meta+Shift+Up";
              "Window One Screen to the Left" = "Meta+Shift+Left";
              "Window One Screen to the Right" = "Meta+Shift+Right";
              # "Walk Through Desktop List" = [ ];
              # "Walk Through Desktop List (Reverse)" = [ ];
              # "Walk Through Desktops" = [ ];
              # "Walk Through Desktops (Reverse)" = [ ];
              "Walk Through Windows" = "Alt+Tab";
              "Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
              # "Walk Through Windows Alternative" = "none,,Walk Through Windows Alternative";
              # "Walk Through Windows Alternative (Reverse)" = "none,,Walk Through Windows Alternative (Reverse)";
              "Walk Through Windows of Current Application" = "Meta+Ctrl+Tab,Alt+`,Walk Through Windows of Current Application";
              "Walk Through Windows of Current Application (Reverse)" = "Meta+Ctrl+Shift+Tab,Alt+~,Walk Through Windows of Current Application (Reverse)";
              # "Walk Through Windows of Current Application Alternative" = "none,,Walk Through Windows of Current Application Alternative";
              # "Walk Through Windows of Current Application Alternative (Reverse)" = "none,,Walk Through Windows of Current Application Alternative (Reverse)";
              "view_actual_size" = "Meta+0";
              "view_zoom_in" = ["Meta++" "Meta+=,Meta++" "Meta+=,Zoom In"];
              "view_zoom_out" = "Meta+-";
              # TODO: Lookup format after stylix issue got resolved
              "Window Close" = ["Meta+X" "Meta+Shift+Q" "Alt+F4,Close Window"];
              "Window Fullscreen" = "Ctrl+F11,,Make Window Fullscreen";
              # Very useful
              "ToggleCurrentThumbnail" = "Meta+Ctrl+T";
              # TODO: Is this disabled? It should be.
              "Toggle" = "none,Meta+Ctrl+Alt+P,Toggle Show Paint";
              "Toggle Night Color" = "Meta+Ctrl+Space,none,Suspend/Resume Night Light";
              # Disabled for better thinking
              # "Toggle Window Raise/Lower" = "none,,Toggle Window Raise/Lower";
              "TrackMouse" = [];
              # "Window Above Other Windows" = "none,,Keep Window Above Others";
              # "Window Below Other Windows" = "none,,Keep Window Below Others";
              "Window Maximize" = "Meta+PgUp";
              # "Window Maximize Horizontal" = "none,,Maximize Window Horizontally";
              # "Window Maximize Vertical" = "none,,Maximize Window Vertically";
              "Window Minimize" = "Meta+PgDown";
              # "Window Move" = "none,,Move Window";
              # "Window Move Center" = "none,,Move Window to the Center";
              # TODO: Would be good to have for Krohnkite
              "Window No Border" = "none,,Toggle Window Titlebar and Frame";
              # TODO: Would be good to have, but via f3 probably enough
              "Window On All Desktops" = "none,,Keep Window on All Desktops";
              "Window Operations Menu" = "Alt+F3";
              # TODO: Difference with Minimize
              "Window Raise" = "none,,Raise Window";
              "Window Lower" = "none,,Lower Window";
              # TODO: Is this opacity?
              "Window Shade" = "none,,Shade Window";
            };
            "org_kde_powerdevil" = {
              "Decrease Keyboard Brightness" = "Keyboard Brightness Down";
              "Decrease Screen Brightness" = "Monitor Brightness Down";
              "Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
              "Hibernate" = "Hibernate";
              "Increase Keyboard Brightness" = "Keyboard Brightness Up";
              "Increase Screen Brightness" = "Monitor Brightness Up";
              "Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
              "PowerDown" = "Power Down";
              "PowerOff" = "Power Off";
              "Sleep" = "Sleep";
              "Toggle Keyboard Backlight" = "Keyboard Light On/Off";
              "Turn Off Screen" = [];
              "powerProfile" = ["Battery" "Meta+B,Battery" "Meta+B,Switch Power Profile"];
            };
            plasmashell = {
              "activate application launcher" = "Meta";
              "activate task manager entry 1" = "";
              "activate task manager entry 2" = "";
              "activate task manager entry 3" = "";
              "activate task manager entry 4" = "";
              "activate task manager entry 5" = "";
              "activate task manager entry 6" = "";
              "activate task manager entry 7" = "";
              "activate task manager entry 8" = "";
              "activate task manager entry 9" = "";
              "activate task manager entry 10" = "";
              # Clipboard
              "clear-history" = "none,,Clear Clipboard History";
              "clipboard_action" = "Meta+Ctrl+X";
              "show-barcode" = "Meta+Shift+V,,Show Barcode…";
              "show-on-mouse-pos" = "Meta+V";
              # "edit_clipboard" = [];
              # What are panels?
              # "cycle-panels" = "Meta+Alt+P";
              # "cycleNextAction" = "none,,Next History Item";
              # "cyclePrevAction" = "none,,Previous History Item";
              "manage activities" = "Meta+Q";
              "next activity" = "Meta+Tab";
              "previous activity" = "Meta+Shift+Tab";
              # TODO: What does this do?
              "repeat_action" = "Meta+Ctrl+R";
              # Seems to show desktop
              "show dashboard" = "Ctrl+F12";
              # TODO: Revisit once learning activities(really want to watch a video about them)
              "stop current activity" = "Meta+S";
              "switch to next activity" = "none,,Switch to Next Activity";
              "switch to previous activity" = "none,,Switch to Previous Activity";
              # TODO: Think of settings
              "toggle do not disturb" = "none,,Toggle do not disturb";
            };
            # So useful
            mediacontrol = {
              "mediavolumedown" = "none,,Media volume down";
              "mediavolumeup" = "none,,Media volume up";
              "nextmedia" = ["Ctrl+Volume Mute" "Media Next,Media Next,Media playback next"];
              "pausemedia" = "Media Pause";
              "playmedia" = "none,,Play media playback";
              "playpausemedia" = ["Media Play" "Meta+Space" "Ctrl+Volume Down,Media Play,Play/Pause media playback"];
              "previousmedia" = ["Ctrl+Volume Up" "Media Previous,Media Previous,Media playback previous"];
              "stopmedia" = "Media Stop";
            };
            "services/firefox.desktop"."new-window" = "Meta+E";
            "services/kitty.desktop"."_launch" = "Ctrl+Alt+T";
            "services/obsidian.desktop"."_launch" = "Meta+O";
            "services/org.kde.dolphin.desktop"."_launch" = "Meta+Shift+E";
            "services/org.kde.konsole.desktop"."_launch" = [];
            "services/org.kde.krunner.desktop"."_launch" = ["Alt+F2" "Search" "Alt+Shift+Space"];
            "services/org.kde.plasma.emojier.desktop"."_launch" = "Meta+Ctrl+Alt+Shift+Space";
            "services/org.kde.spectacle.desktop"."RecordWindow" = [];
            "services/org.kde.spectacle.desktop"."_launch" = [];
            "services/systemsettings.desktop"."_launch" = ["Meta+C" "Tools"];
            "services/neovide.desktop"."_launch" = "Meta+Shift+N";
          }
          (lib.optionalAttrs cfg.krohnkite {
            kwin = {
              "KrohnkiteBTreeLayout" = [];
              "KrohnkiteColumnsLayout" = [];
              "KrohnkiteDecrease" = "Meta+Shift+I";
              # Can also tile all
              "KrohnkiteFloatAll" = "Meta+Shift+F";
              "KrohnkiteFloatingLayout" = "Meta+F";
              "KrohnkiteFocusDown" = "Meta+J";
              "KrohnkiteFocusLeft" = "Meta+H";
              "KrohnkiteFocusNext" = [];
              "KrohnkiteFocusPrev" = [];
              "KrohnkiteFocusRight" = "Meta+L";
              "KrohnkiteFocusUp" = "Meta+K";
              "KrohnkiteGrowHeight" = "Meta+Ctrl+J";
              "KrohnkitegrowWidth" = "Meta+Ctrl+L";
              "KrohnkiteIncrease" = "Meta+I";
              "KrohnkiteMonocleLayout" = "Meta+M";
              "KrohnkiteNextLayout" = "Meta+:";
              "KrohnkitePreviousLayout" = "Meta+;";
              "KrohnkiteQuarterLayout" = [];
              "KrohnkiteRotate" = "Meta+#";
              "KrohnkiteRotatePart" = "Meta+'";
              "KrohnkiteSetMaster" = "Meta+Return";
              "KrohnkiteShiftDown" = "Meta+Shift+J";
              "KrohnkiteShiftLeft" = "Meta+Shift+H";
              "KrohnkiteShiftRight" = "Meta+Shift+L";
              "KrohnkiteShiftUp" = "Meta+Shift+K";
              "KrohnkiteShrinkHeight" = "Meta+Ctrl+K";
              "KrohnkiteShrinkWidth" = "Meta+Ctrl+H";
              "KrohnkiteSpiralLayout" = [];
              "KrohnkiteSpreadLayout" = [];
              "KrohnkiteStackedLayout" = [];
              "KrohnkiteStairLayout" = [];
              "KrohnkiteTileLayout" = [];
              "KrohnkiteToggleFloat" = [];
              "KrohnkiteTreeColumnLayout" = [];
            };
          });
        hotkeys.commands = {
          "systemsettings-shortcuts" = {
            command = "kcmshell6 kcm_keys";
            keys = ["Meta+Shift+C"];
            comment = "Open the System Settings on the shortcut dialog";
          };
        };
        configFile =
          lib.attrsets.recursiveUpdate {
            baloofilerc."General" = {
              "dbVersion" = 2;
              "exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
              "exclude filters version" = 9;
              "only basic indexing" = true;
            };
            kdeglobals = {
              "General" = {
                "BrowserApplication" = "firefox.desktop";
                "TerminalApplication" = "kitty";
                "TerminalService" = "kitty.desktop";
                "UseSystemBell" = false;
              };
              "KDE" = {
                "AnimationDurationFactor" = 0;
                "ScrollbarLeftClickNavigatesByPage" = false;
                "SingleClick" = false;
              };
            };
            kiorc = {
              "Confirmations" = {
                "ConfirmDelete" = true;
                "ConfirmEmptyTrash" = true;
              };
              "Executable scripts"."behaviourOnLaunch" = "execute";
            };
            krunnerrc = {
              "General" = {
                "historyBehavior" = "ImmediateCompletion";
                "FreeFloating" = true;
                "RetainPriorSearch" = false;
              };
              "Plugins" = {
                "baloosearchEnabled" = true;
                "browserhistoryEnabled" = false;
                "browsertabsEnabled" = true;
                "krunner_bookmarksrunnerEnabled" = false;
                "krunner_systemsettingsEnabled" = true;
                "DictionaryEnabled" = false;
                "appstreamEnabled" = false;
                "desktopsessionsEnabled" = false;
                "konsoleprofilesEnabled" = false;
                "org.kde.activities2Enabled" = false;
                "org.kde.datetimeEnabled" = false;
              };
              "Plugins/Favorites"."plugins" = "krunner_services,windows";
            };
            # Do not restore from previous session
            kuriikwsfilterrc."General" = {
              "DefaultWebShortcut" = "google";
              "EnableWebShortcuts" = true;
              "KeywordDelimiter" = ":";
              "PreferredWebShortcuts" = "google,youtube,wikipedia,duckduckgo";
              "UsePreferredWebShortcutsOnly" = false;
            };
            kwinrc = {
              "Desktops" = {
                "Number" = 6;
                "Rows" = 2;
              };
              "EdgeBarrier" = {
                "CornerBarrier" = false;
                "EdgeBarrier" = 2;
              };
              "Effect-blur" = {
                "BlurStrength" = 4;
                "NoiseStrength" = 8;
              };
              "MouseBindings"."CommandTitlebarWheel" = "Change Opacity";
              "NightColor" = {
                "Active" = true;
                "EveningBeginFixed" = 2200;
                "Mode" = "Times";
                "NightTemperature" = 4500;
                "TransitionTime" = 60;
              };
              "Plugins" = {
                "blurEnabled" = true;
                "contrastEnabled" = false;
                "desktopchangeosdEnabled" = true;
                "magnifierEnabled" = true;
                "slidebackEnabled" = true;
                "zoomEnabled" = false;
                "dimscreenEnabled" = true;
                "hidecursorEnabled" = true;
                "krohnkiteEnabled" = true;
                "minimizeallEnabled" = true;
                "shakecursorEnabled" = true;
                "thumbnailasideEnabled" = true;
              };
              "Script-desktopchangeosd"."PopupHideDelay" = 250;
              "Windows" = {
                "ElectricBorderCooldown" = 300;
                "ElectricBorderDelay" = 250;
                "ElectricBorders" = 1;
                "FocusPolicy" = "FocusFollowsMouse";
                # Disable Mouse precedence mode. Hopefully should make application launcher more usable
                "NextFocusPrefersMouse" = false;
              };
              "Xwayland"."Scale" = 1;
              "Effect-hidecursor"."HideOnTyping" = false;
              "Effect-hidecursor"."InactivityDuration" = 60;
              "Effect-login"."FadeToBlack" = true;
              "Effect-shakecursor"."Magnification" = 7;
              "MouseBindings"."CommandAllWheel" = "Previous/Next Desktop";
              "TabBox" = {
                "LayoutName" = "compact";
                # Minimized after normal
                "OrderMinimizedMode" = 1;
                "ShowDesktopMode" = 1;
                # Stacking mode
                "SwitchingMode" = 1;
                "MultiScreenMode" = 0;
              };
            };
            kxkbrc."Layout" = {
              "LayoutList" = "de,de";
              "Model" = "pc105";
              "Options" = "caps:escape,shift:both_capslock_cancel";
              "ResetOldOptions" = true;
              "Use" = true;
              "VariantList" = "nodeadkeys,neo_qwertz";
            };
            plasma-localerc."Formats"."LANG" = osConfig.i18n.defaultLocale;
            plasmanotifyrc."Notifications" = {
              "PopupPosition" = "TopRight";
              "PopupTimeout" = 10000;
            };
            plasmaparc."General"."RaiseMaximumVolume" = true;
            systemsettingsrc."systemsettings_sidebar_mode"."HighlightNonDefaultSettings" = true;
            kded5rc = {
              "PlasmaBrowserIntegration"."shownCount" = 4;
              "Module-browserintegrationreminder"."autoload" = false;
              "Module-device_automounter"."autoload" = false;
            };
            klipperrc."General" = {
              "IgnoreImages" = false;
              "KeepClipboardContents" = false;
              "MaxClipItems" = 100;
            };
            ksmserverrc."General"."loginMode" = "emptySession";
            # ? "ksmserverrc"."General"."excludeApps" = "firefox,kitty";
          } (lib.optionals cfg.krohnkite {
            kwinrc."Script-krohnkite" = {
              "debug" = false;
              "debugActiveWin" = false;
              "enableBTreeLayout" = true;
              "enableFloatingLayout" = true;
              "enableQuarterLayout" = true;
              "enableStackedLayout" = true;
              "floatedWindowsLayer" = 2;
              "monocleMaximize" = true;
              "newWindowPosition" = 2;
              "screenGapBottom" = 3;
              "screenGapLeft" = 6;
              "screenGapRight" = 6;
              "screenGapTop" = 3;
              "tileLayoutGap" = 2;
              "tiledWindowsLayer" = 1;
            };
          });
      };
      services.kdeconnect = {
        enable = true;
        indicator = false;
        package = with pkgs; kdePackages.kdeconnect-kde;
      };
      home.packages = with pkgs.kdePackages;
        [
          kate
          kalk
        ]
        ++ [
          (pkgs.callPackage inputs.plasma-manager.packages.${system}.rc2nix.overrideAttrs {name = "plasma-rc2nix";})
        ]
        ++ lib.optionals cfg.krohnkite [krohnkite];
    }
    (lib.mkIf osConfig.security.ownAdditional.yubikey
      (let
        qt-pinentry = pkgs.pinentry-qt;
      in {
        # TODO: How to set the default e.g. ncurses as backup
        # May break curses via tmux when plugged into other device
        services.gpg-agent.pinentry.package = qt-pinentry;
        home.packages = [qt-pinentry];
      }))
  ]);
}
