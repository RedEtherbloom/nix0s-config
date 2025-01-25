{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.plasma-manager;
in {
  imports = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];

  options.myOptions.plasma-manager = {
    enable = mkOption {
      description = "Enable plasma manager and applications";
      type = with types; bool;
      default = false;
    };
    krohnkite = mkOption {
      description = "Enable krohnkite tiling WM shortcuts";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      # We're only coding shortcuts for screens 0-3
      shortcuts =
        lib.attrsets.recursiveUpdate
        {
          "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
          "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
          "kaccess"."Toggle Screen Reader On and Off" = "Meta+Alt+S";
          "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
          "kmix"."decrease_volume" = "Volume Down";
          "kmix"."decrease_volume_small" = "Shift+Volume Down";
          "kmix"."increase_microphone_volume" = "Microphone Volume Up";
          "kmix"."increase_volume" = "Volume Up";
          "kmix"."increase_volume_small" = "Shift+Volume Up";
          "kmix"."mic_mute" = ["Microphone Mute" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone"];
          "kmix"."mute" = "Volume Mute";
          "ksmserver"."Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
          "ksmserver"."Lock Session" = ["Meta+Del" "Screensaver,Meta+L" "Screensaver,Lock Session"];
          "ksmserver"."Log Out" = "Ctrl+Alt+Del";
          "ksmserver"."Log Out Without Confirmation" = "none,,Log Out Without Confirmation";
          "ksmserver"."LogOut" = "none,,Log Out";
          "ksmserver"."Reboot" = "none,,Reboot";
          "ksmserver"."Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
          "ksmserver"."Shut Down" = "none,,Shut Down";
          # What is this?
          # TODO: May be useful for task switching
          #"kwin"."Cycle Overview" = [];
          #"kwin"."Cycle Overview Opposite" = [];
          "kwin"."Edit Tiles" = "Meta+T";
          "kwin"."Expose" = "Ctrl+F9";
          "kwin"."ExposeAll" = ["Ctrl+F10" "Launch (C),Ctrl+F10" "Launch (C),Toggle Present Windows (All desktops)"];
          "kwin"."ExposeClass" = "Ctrl+F7";
          "kwin"."ExposeClassCurrentDesktop" = "Ctrl+F8,none,Toggle Present Windows (Window class on current desktop)";
          "kwin"."Grid View" = "Meta+G";
          "kwin"."Kill Window" = "Meta+Ctrl+Esc,Alt+F4";
          "kwin"."MinimizeAll" = "Meta+Shift+PgDown,none,MinimizeAll";
          # TODO: Revisit when using tablet
          "kwin"."Move Tablet to Next Output" = [];
          "kwin"."MoveMouseToCenter" = "Meta+F6";
          "kwin"."MoveMouseToFocus" = "Meta+F5";
          #"kwin"."MoveZoomDown" = "none,Meta+Ctrl+Down,Move Down";
          #"kwin"."MoveZoomLeft" = "none,Meta+Ctrl+Left,Move Left";
          #"kwin"."MoveZoomRight" = "none,Meta+Ctrl+Right,Move Right";
          #"kwin"."MoveZoomUp" = "none,Meta+Ctrl+Up,Move Up";
          "kwin"."Overview" = "Meta+W";
          "kwin"."Setup Window Shortcut" = "none,,Setup Window Shortcut";
          "kwin"."Show Desktop" = "Meta+D";
          "kwin"."ShowDesktopGrid" = "Meta+F8";
          # TODO: What is this useful for?
          "kwin"."Suspend Compositing" = "Alt+Shift+F12";
          "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
          # TODO: What is this useful for?
          "kwin"."Invert" = "Meta+Ctrl+I";
          # TODO: What is this useful for?
          #"kwin"."Invert Screen Colors" = [];
          # TODO: What is this useful for?
          "kwin"."InvertWindow" = "Meta+Ctrl+U";
          # TODO: Disabled, may help with keeping the layout better in our hand
          #"kwin"."Switch One Desktop Down" = "Meta+Ctrl+Down";
          #"kwin"."Switch One Desktop Up" = "Meta+Ctrl+Up";
          #"kwin"."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
          #"kwin"."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
          "kwin"."Switch to Desktop 1" = "Meta+1";
          "kwin"."Switch to Desktop 2" = "Meta+2";
          "kwin"."Switch to Desktop 3" = "Meta+3";
          "kwin"."Switch to Desktop 4" = "Meta+4";
          "kwin"."Switch to Desktop 5" = "Meta+5";
          "kwin"."Switch to Desktop 6" = "Meta+6";
          "kwin"."Switch to Desktop 7" = "";
          "kwin"."Switch to Desktop 8" = "";
          "kwin"."Switch to Desktop 9" = "";
          "kwin"."Switch to Desktop 10" = "";
          # TODO: Come up with good shortcut for that
          "kwin"."Switch to Next Desktop" = "none";
          "kwin"."Switch to Next Screen" = "none";
          "kwin"."Switch to Previous Desktop" = "none";
          "kwin"."Switch to Previous Screen" = "none";
          "kwin"."Switch to Screen 0" = "Meta+Ctrl+1";
          "kwin"."Switch to Screen 1" = "Meta+Ctrl+2";
          "kwin"."Switch to Screen 2" = "Meta+Ctrl+3";
          "kwin"."Switch to Screen 3" = "Meta+Ctrl+4";
          "kwin"."Switch to Screen Above" = "none,,Switch to Screen Above";
          "kwin"."Switch to Screen Below" = "none,,Switch to Screen Below";
          "kwin"."Switch to Screen to the Left" = "none,,Switch to Screen to the Left";
          "kwin"."Switch to Screen to the Right" = "none,,Switch to Screen to the Right";

          # Shift+1
          "kwin"."Window to Desktop 1" = "Meta+!";
          # Shift+2
          "kwin"."Window to Desktop 2" = "Meta+\"";
          # Shift+3
          "kwin"."Window to Desktop 3" = "Meta+§";
          # Shift+4
          "kwin"."Window to Desktop 4" = "Meta+$";
          # Shift+5
          "kwin"."Window to Desktop 5" = "Meta+%";
          # Shift+6
          "kwin"."Window to Desktop 6" = "Meta+&";
          "kwin"."Window to Desktop 7" = "";
          "kwin"."Window to Desktop 8" = "";
          "kwin"."Window to Desktop 9" = "";
          # Disabled for better thinking
          "kwin"."Window to Next Desktop" = "";
          "kwin"."Window to Previous Desktop" = "";
          "kwin"."Window to Previous Screen" = "";
          "kwin"."Window to Next Screen" = "";
          "kwin"."Window to Screen 0" = "Meta+Ctrl+!";
          "kwin"."Window to Screen 1" = "Meta+Ctrl+\"";
          "kwin"."Window to Screen 2" = "Meta+Ctrl+§";
          "kwin"."Window to Screen 3" = "Meta+Ctrl+$";
          "kwin"."Window One Screen Down" = "Meta+Shift+Down,,Move Window One Screen Down";
          "kwin"."Window One Screen Up" = "Meta+Shift+Up,,Move Window One Screen Up";
          "kwin"."Window One Screen to the Left" = "Meta+Shift+Left,,Move Window One Screen to the Left";
          "kwin"."Window One Screen to the Right" = "Meta+Shift+Right,,Move Window One Screen to the Right";

          # "kwin"."Walk Through Desktop List" = [ ];
          # "kwin"."Walk Through Desktop List (Reverse)" = [ ];
          # "kwin"."Walk Through Desktops" = [ ];
          # "kwin"."Walk Through Desktops (Reverse)" = [ ];

          "kwin"."Walk Through Windows" = "Alt+Tab";
          "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
          # "kwin"."Walk Through Windows Alternative" = "none,,Walk Through Windows Alternative";
          # "kwin"."Walk Through Windows Alternative (Reverse)" = "none,,Walk Through Windows Alternative (Reverse)";
          "kwin"."Walk Through Windows of Current Application" = "Meta+Ctrl+Tab,Alt+`,Walk Through Windows of Current Application";
          "kwin"."Walk Through Windows of Current Application (Reverse)" = "Meta+Ctrl+Shift+Tab,Alt+~,Walk Through Windows of Current Application (Reverse)";
          # "kwin"."Walk Through Windows of Current Application Alternative" = "none,,Walk Through Windows of Current Application Alternative";
          # "kwin"."Walk Through Windows of Current Application Alternative (Reverse)" = "none,,Walk Through Windows of Current Application Alternative (Reverse)";

          "kwin"."view_actual_size" = "Meta+0";
          "kwin"."view_zoom_in" = ["Meta++" "Meta+=,Meta++" "Meta+=,Zoom In"];
          "kwin"."view_zoom_out" = "Meta+-";

          "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
          "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
          "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
          "org_kde_powerdevil"."Hibernate" = "Hibernate";
          "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
          "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
          "org_kde_powerdevil"."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
          "org_kde_powerdevil"."PowerDown" = "Power Down";
          "org_kde_powerdevil"."PowerOff" = "Power Off";
          "org_kde_powerdevil"."Sleep" = "Sleep";
          "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
          "org_kde_powerdevil"."Turn Off Screen" = [];
          "org_kde_powerdevil"."powerProfile" = ["Battery" "Meta+B,Battery" "Meta+B,Switch Power Profile"];

          "plasmashell"."activate application launcher" = ["Meta,Meta" "Alt+F1,Activate Application Launcher"];
          "plasmashell"."activate task manager entry 1" = [];
          "plasmashell"."activate task manager entry 2" = [];
          "plasmashell"."activate task manager entry 3" = [];
          "plasmashell"."activate task manager entry 4" = [];
          "plasmashell"."activate task manager entry 5" = [];
          "plasmashell"."activate task manager entry 6" = [];
          "plasmashell"."activate task manager entry 7" = [];
          "plasmashell"."activate task manager entry 8" = [];
          "plasmashell"."activate task manager entry 9" = [];
          "plasmashell"."activate task manager entry 10" = [];

          # So useful
          "mediacontrol"."mediavolumedown" = "none,,Media volume down";
          "mediacontrol"."mediavolumeup" = "none,,Media volume up";
          "mediacontrol"."nextmedia" = "Media Next";
          "mediacontrol"."pausemedia" = "Media Pause";
          "mediacontrol"."playmedia" = "none,,Play media playback";
          "mediacontrol"."playpausemedia" = ["Meta+Space" "Media Play,Media Play,Play/Pause media playback"];
          "mediacontrol"."previousmedia" = "Media Previous";
          "mediacontrol"."stopmedia" = "Media Stop";

          "kwin"."Window Close" = ["Alt+F4" "Meta+Shift+Q,Alt+F4,Close Window"];
          "kwin"."Window Fullscreen" = "Ctrl+F11,,Make Window Fullscreen";

          # Clipboard
          "plasmashell"."clear-history" = "none,,Clear Clipboard History";
          "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
          "plasmashell"."show-barcode" = "Meta+Shift+V,,Show Barcode…";
          "plasmashell"."show-on-mouse-pos" = "Meta+V";
          # "plasmashell"."edit_clipboard" = [];
          # What are panels?
          # "plasmashell"."cycle-panels" = "Meta+Alt+P";
          # "plasmashell"."cycleNextAction" = "none,,Next History Item";
          # "plasmashell"."cyclePrevAction" = "none,,Previous History Item";
          "plasmashell"."manage activities" = "Meta+Q";
          "plasmashell"."next activity" = "Meta+Tab";
          "plasmashell"."previous activity" = "Meta+Shift+Tab";
          # TODO: What does this do?
          "plasmashell"."repeat_action" = "Meta+Ctrl+R";
          # Seems to show desktop
          "plasmashell"."show dashboard" = "Ctrl+F12";
          # TODO: Revisit once learning activities(really want to watch a video about them)
          "plasmashell"."stop current activity" = "Meta+S";
          "plasmashell"."switch to next activity" = "none,,Switch to Next Activity";
          "plasmashell"."switch to previous activity" = "none,,Switch to Previous Activity";
          # TODO: Think of settings
          "plasmashell"."toggle do not disturb" = "none,,Toggle do not disturb";

          # Very useful
          "kwin"."ToggleCurrentThumbnail" = "Meta+Ctrl+T";

          # TODO: Is this disabled? It should be.
          "kwin"."Toggle" = "none,Meta+Ctrl+Alt+P,Toggle Show Paint";
          "kwin"."Toggle Night Color" = "Meta+Ctrl+Space,none,Suspend/Resume Night Light";
          # Disabled for better thinking
          # "kwin"."Toggle Window Raise/Lower" = "none,,Toggle Window Raise/Lower";
          "kwin"."TrackMouse" = [];
          # "kwin"."Window Above Other Windows" = "none,,Keep Window Above Others";
          # "kwin"."Window Below Other Windows" = "none,,Keep Window Below Others";
          "kwin"."Window Maximize" = "Meta+PgUp";
          # "kwin"."Window Maximize Horizontal" = "none,,Maximize Window Horizontally";
          # "kwin"."Window Maximize Vertical" = "none,,Maximize Window Vertically";
          "kwin"."Window Minimize" = "Meta+PgDown";
          # "kwin"."Window Move" = "none,,Move Window";
          # "kwin"."Window Move Center" = "none,,Move Window to the Center";
          # TODO: Would be good to have for Krohnkite
          "kwin"."Window No Border" = "none,,Toggle Window Titlebar and Frame";
          # TODO: Would be good to have, but via f3 probably enough
          "kwin"."Window On All Desktops" = "none,,Keep Window on All Desktops";
          "kwin"."Window Operations Menu" = "Alt+F3";
          # TODO: Difference with Minimize
          "kwin"."Window Raise" = "none,,Raise Window";
          "kwin"."Window Lower" = "none,,Lower Window";
          # TODO: Is this opacity?
          "kwin"."Window Shade" = "none,,Shade Window";

          "services/firefox.desktop"."new-window" = "Meta+E";
          "services/kitty.desktop"."_launch" = "Ctrl+Alt+T";
          "services/obsidian.desktop"."_launch" = "Meta+Shift+O";
          "services/org.kde.dolphin.desktop"."_launch" = "Meta+Shift+E";
          "services/org.kde.konsole.desktop"."_launch" = [];
          "services/org.kde.krunner.desktop"."_launch" = ["Alt+F2" "Search" "Alt+Shift+Space"];
          "services/org.kde.plasma.emojier.desktop"."_launch" = "Meta+Ctrl+Alt+Shift+Space";
          # TODO: This is missing most of the Spectacle specific shortcuts. They for some reason did not get recorded with the plasma-manager config dump.
          # "services/org.kde.spectacle.desktop"."RecordWindow" = [];
          "services/org.kde.spectacle.desktop"."_launch" = ["Print"];
          "services/systemsettings.desktop"."_launch" = ["Meta+C" "Tools"];

          # TODO: Taskwarrior-Tui shortcut
        }
        (lib.optionalAttrs cfg.krohnkite {
          "kwin"."KrohnkiteBTreeLayout" = [];
          "kwin"."KrohnkiteColumnsLayout" = [];
          "kwin"."KrohnkiteDecrease" = [];
          "kwin"."KrohnkiteFloatAll" = "Meta+Shift+F";
          "kwin"."KrohnkiteFloatingLayout" = "Meta+F";
          "kwin"."KrohnkiteFocusDown" = "Meta+J";
          "kwin"."KrohnkiteFocusLeft" = "Meta+H";
          "kwin"."KrohnkiteFocusNext" = [];
          "kwin"."KrohnkiteFocusPrev" = [];
          "kwin"."KrohnkiteFocusRight" = "Meta+L";
          "kwin"."KrohnkiteFocusUp" = "Meta+K";
          "kwin"."KrohnkiteGrowHeight" = "Meta+Ctrl+J";
          "kwin"."KrohnkitegrowWidth" = "Meta+Ctrl+L";
          "kwin"."KrohnkiteIncrease" = "Meta+I";
          "kwin"."KrohnkiteMonocleLayout" = "Meta+M";
          "kwin"."KrohnkiteNextLayout" = "Meta+:";
          "kwin"."KrohnkitePreviousLayout" = "Meta+;";
          "kwin"."KrohnkiteQuarterLayout" = [];
          "kwin"."KrohnkiteRotate" = [];
          "kwin"."KrohnkiteRotatePart" = [];
          "kwin"."KrohnkiteSetMaster" = "Meta+Return";
          "kwin"."KrohnkiteShiftDown" = "Meta+Shift+J";
          "kwin"."KrohnkiteShiftLeft" = "Meta+Shift+H";
          "kwin"."KrohnkiteShiftRight" = "Meta+Shift+L";
          "kwin"."KrohnkiteShiftUp" = "Meta+Shift+K";
          "kwin"."KrohnkiteShrinkHeight" = "Meta+Ctrl+K";
          "kwin"."KrohnkiteShrinkWidth" = "Meta+Ctrl+H";
          "kwin"."KrohnkiteSpiralLayout" = [];
          "kwin"."KrohnkiteSpreadLayout" = [];
          "kwin"."KrohnkiteStackedLayout" = [];
          "kwin"."KrohnkiteStairLayout" = [];
          "kwin"."KrohnkiteTileLayout" = [];
          "kwin"."KrohnkiteToggleFloat" = [];
          "kwin"."KrohnkiteTreeColumnLayout" = [];
        });
      configFile = {
        "baloofilerc"."General"."dbVersion" = 2;
        "baloofilerc"."General"."exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
        "baloofilerc"."General"."exclude filters version" = 9;
        "baloofilerc"."General"."only basic indexing" = true;
        # "kcminputrc"."Libinput/1133/16461/Logitech K400 Plus"."MiddleButtonEmulation" = true;
        # "kcminputrc"."Libinput/1133/16461/Logitech K400 Plus"."PointerAcceleration" = 0.400;
        # "kcminputrc"."Libinput/1133/16461/Logitech K400 Plus"."ScrollFactor" = 1;
        # "kcminputrc"."Libinput/7119/2084/SunplusIT SmartMouse"."NaturalScroll" = false;
        # "kcminputrc"."Libinput/7119/2084/SunplusIT SmartMouse"."PointerAcceleration" = 0.400;
        # "kcminputrc"."Libinput/7119/2084/SunplusIT SmartMouse"."ScrollFactor" = 2;
        "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
        "kded5rc"."Module-device_automounter"."autoload" = false;
        "kdeglobals"."General"."BrowserApplication" = "firefox.desktop";
        "kdeglobals"."General"."TerminalApplication" = "kitty";
        "kdeglobals"."General"."TerminalService" = "kitty.desktop";
        # TODO: Disabled as it got annoying
        "kdeglobals"."General"."UseSystemBell" = false;
        # TODO: What does this do?
        # "kdeglobals"."KFileDialog Settings"."Allow Expansion" = true;
        # "kdeglobals"."KFileDialog Settings"."Automatically select filename extension" = true;
        # "kdeglobals"."KFileDialog Settings"."Breadcrumb Navigation" = false;
        # "kdeglobals"."KFileDialog Settings"."Decoration position" = 2;
        # "kdeglobals"."KFileDialog Settings"."LocationCombo Completionmode" = 5;
        # "kdeglobals"."KFileDialog Settings"."PathCombo Completionmode" = 5;
        # "kdeglobals"."KFileDialog Settings"."Show Bookmarks" = false;
        # "kdeglobals"."KFileDialog Settings"."Show Full Path" = true;
        # "kdeglobals"."KFileDialog Settings"."Show Inline Previews" = false;
        # "kdeglobals"."KFileDialog Settings"."Show Preview" = false;
        # "kdeglobals"."KFileDialog Settings"."Show Speedbar" = true;
        # "kdeglobals"."KFileDialog Settings"."Show hidden files" = false;
        # "kdeglobals"."KFileDialog Settings"."Sort by" = "Name";
        # "kdeglobals"."KFileDialog Settings"."Sort directories first" = true;
        # "kdeglobals"."KFileDialog Settings"."Sort hidden files last" = false;
        # "kdeglobals"."KFileDialog Settings"."Sort reversed" = false;
        # "kdeglobals"."KFileDialog Settings"."View Style" = "DetailTree";
        "kiorc"."Confirmations"."ConfirmDelete" = true;
        "kiorc"."Confirmations"."ConfirmEmptyTrash" = true;
        "kiorc"."Executable scripts"."behaviourOnLaunch" = "execute";
        "krunnerrc"."General"."historyBehavior" = "ImmediateCompletion";
        "krunnerrc"."Plugins"."baloosearchEnabled" = true;
        "krunnerrc"."Plugins"."browserhistoryEnabled" = false;
        "krunnerrc"."Plugins"."browsertabsEnabled" = true;
        "krunnerrc"."Plugins"."krunner_bookmarksrunnerEnabled" = false;
        "krunnerrc"."Plugins"."krunner_systemsettingsEnabled" = true;
        "krunnerrc"."Plugins/Favorites"."plugins" = "krunner_services,windows";
        # ? "ksmserverrc"."General"."excludeApps" = "firefox,kitty";
        "kuriikwsfilterrc"."General"."DefaultWebShortcut" = "google";
        "kuriikwsfilterrc"."General"."EnableWebShortcuts" = true;
        "kuriikwsfilterrc"."General"."KeywordDelimiter" = ":";
        "kuriikwsfilterrc"."General"."PreferredWebShortcuts" = "google,youtube,wikipedia,duckduckgo";
        "kuriikwsfilterrc"."General"."UsePreferredWebShortcutsOnly" = false;
        "kwinrc"."Desktops"."Number" = 6;
        "kwinrc"."Desktops"."Rows" = 2;
        "kwinrc"."EdgeBarrier"."CornerBarrier" = false;
        "kwinrc"."EdgeBarrier"."EdgeBarrier" = 2;
        "kwinrc"."Effect-blur"."BlurStrength" = 4;
        "kwinrc"."Effect-blur"."NoiseStrength" = 8;
        "kwinrc"."MouseBindings"."CommandTitlebarWheel" = "Change Opacity";
        "kwinrc"."NightColor"."Active" = true;
        "kwinrc"."NightColor"."EveningBeginFixed" = 2200;
        "kwinrc"."NightColor"."Mode" = "Times";
        "kwinrc"."NightColor"."NightTemperature" = 4000;
        "kwinrc"."NightColor"."TransitionTime" = 120;
        "kwinrc"."Plugins"."blurEnabled" = true;
        "kwinrc"."Plugins"."contrastEnabled" = false;
        "kwinrc"."Plugins"."desktopchangeosdEnabled" = true;
        "kwinrc"."Plugins"."magnifierEnabled" = true;
        "kwinrc"."Plugins"."slidebackEnabled" = true;
        "kwinrc"."Plugins"."zoomEnabled" = false;
        "kwinrc"."Script-desktopchangeosd"."PopupHideDelay" = 250;
        "kwinrc"."Windows"."ElectricBorderCooldown" = 300;
        "kwinrc"."Windows"."ElectricBorderDelay" = 250;
        "kwinrc"."Windows"."ElectricBorders" = 1;
        "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
        "kwinrc"."Windows"."NextFocusPrefersMouse" = true;
        "kwinrc"."Xwayland"."Scale" = 1;
        "kxkbrc"."Layout"."DisplayNames" = ",,";
        "kxkbrc"."Layout"."LayoutList" = "de,de,de";
        "kxkbrc"."Layout"."Model" = "pc105";
        "kxkbrc"."Layout"."Options" = "caps:escape,shift:both_capslock_cancel";
        "kxkbrc"."Layout"."ResetOldOptions" = true;
        "kxkbrc"."Layout"."Use" = true;
        "kxkbrc"."Layout"."VariantList" = ",nodeadkeys,neo";

        "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
        "plasmanotifyrc"."Notifications"."PopupPosition" = "TopRight";
        "plasmanotifyrc"."Notifications"."PopupTimeout" = 7000;
        "plasmaparc"."General"."RaiseMaximumVolume" = true;
        "systemsettingsrc"."systemsettings_sidebar_mode"."HighlightNonDefaultSettings" = true;

        # "kcminputrc"."Libinput/2/10/TPPS\\/2 IBM TrackPoint"."PointerAcceleration" = 0.800;
        # "kcminputrc"."Libinput/2/10/TPPS\\/2 IBM TrackPoint"."PointerAccelerationProfile" = 1;
        # "kcminputrc"."Libinput/2/10/TPPS\\/2 IBM TrackPoint"."ScrollFactor" = 3;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."ClickMethod" = 2;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."MiddleButtonEmulation" = true;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."NaturalScroll" = true;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."PointerAcceleration" = 0.600;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."PointerAccelerationProfile" = 2;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."ScrollFactor" = 0.75;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."ScrollMethod" = 2;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."TapDragLock" = false;
        # "kcminputrc"."Libinput/2/7/SynPS\\/2 Synaptics TouchPad"."TapToClick" = true;
        # "kcminputrc"."Mouse"."X11LibInputXAccelProfileFlat" = true;
        "kded5rc"."PlasmaBrowserIntegration"."shownCount" = 4;
        "kdeglobals"."KDE"."AnimationDurationFactor" = 0.5;
        "kdeglobals"."KDE"."ScrollbarLeftClickNavigatesByPage" = false;
        "kdeglobals"."KDE"."SingleClick" = false;
        # TODO: Figure out what KHotkeys are. They seem to be more than just hotkeys
        "klipperrc"."General"."IgnoreImages" = false;
        "klipperrc"."General"."KeepClipboardContents" = false;
        "klipperrc"."General"."MaxClipItems" = 100;
        # TODO: OwO, what's this?
        "krunnerrc"."General"."FreeFloating" = true;
        "krunnerrc"."General"."RetainPriorSearch" = false;
        "krunnerrc"."Plugins"."DictionaryEnabled" = false;
        "krunnerrc"."Plugins"."appstreamEnabled" = false;
        "krunnerrc"."Plugins"."desktopsessionsEnabled" = false;
        "krunnerrc"."Plugins"."konsoleprofilesEnabled" = false;
        "krunnerrc"."Plugins"."org.kde.activities2Enabled" = false;
        "krunnerrc"."Plugins"."org.kde.datetimeEnabled" = false;
        "kwinrc"."Effect-hidecursor"."HideOnTyping" = false;
        "kwinrc"."Effect-hidecursor"."InactivityDuration" = 60;
        "kwinrc"."Effect-login"."FadeToBlack" = true;
        "kwinrc"."Effect-shakecursor"."Magnification" = 7;
        "kwinrc"."MouseBindings"."CommandAllWheel" = "Previous/Next Desktop";
        "kwinrc"."Plugins"."dimscreenEnabled" = true;
        "kwinrc"."Plugins"."hidecursorEnabled" = true;
        "kwinrc"."Plugins"."krohnkiteEnabled" = true;
        "kwinrc"."Plugins"."minimizeallEnabled" = true;
        "kwinrc"."Plugins"."shakecursorEnabled" = true;
        "kwinrc"."Plugins"."thumbnailasideEnabled" = true;
        "kwinrc"."Script-krohnkite"."enableBTreeLayout" = true;
        "kwinrc"."Script-krohnkite"."enableFloatingLayout" = true;
        "kwinrc"."Script-krohnkite"."enableQuarterLayout" = true;
        "kwinrc"."Script-krohnkite"."enableStackedLayout" = true;
        # TODO: Floating windows should be above others. Check.
        "kwinrc"."Script-krohnkite"."floatedWindowsLayer" = 2;
        "kwinrc"."Script-krohnkite"."monocleMaximize" = false;
        "kwinrc"."Script-krohnkite"."screenGapBottom" = 3;
        "kwinrc"."Script-krohnkite"."screenGapLeft" = 6;
        "kwinrc"."Script-krohnkite"."screenGapRight" = 6;
        "kwinrc"."Script-krohnkite"."screenGapTop" = 3;
        "kwinrc"."Script-krohnkite"."tileLayoutGap" = 2;
        "kwinrc"."TabBox"."LayoutName" = "compact";
        # Minimized after normal
        "kwinrc"."TabBox"."OrderMinimizedMode" = 1;
        "kwinrc"."TabBox"."ShowDesktopMode" = 1;
        # Stacking mode
        "kwinrc"."TabBox"."SwitchingMode" = 1;
        "kwinrc"."TabBox"."MultiScreenMode" = 0;
      };
      hotkeys.commands = {
        "systemsettings-shortcuts" = {
          command = "kcm_shell6 kcm_keys";
          keys = ["Meta+Shift+C"];
          comment = "Open the System Settings on the shortcut dialog";
        };
      };
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
      ++ lib.optionals cfg.krohnkite [krohnkite];
  };
}
