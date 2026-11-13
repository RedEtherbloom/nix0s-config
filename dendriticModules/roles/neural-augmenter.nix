{
  inputs,
  self,
  ...
}: let
  base16Scheme = pkgs: "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
in {
  flake = {
    nixosModules.neural-augmenter = {
      lib,
      pkgs,
      secrets,
      ...
    }: let
      appimage-run-with-libs = pkgs.appimage-run.override {
        extraPkgs = pkgs: [
          pkgs.ffmpeg
          pkgs.imagemagick
          pkgs.fuse
        ];
      };
    in {
      imports = [
        inputs.nixpkgs.nixosModules.readOnlyPkgs # Set here instead of flake.nix as some platform fixes, e.g. for the Pi kernel for audiosink have to add additional overlays
        inputs.stylix.nixosModules.stylix
        self.nixosModules.base
        self.nixosModules.office
        self.nixosModules.email
        self.nixosModules.calendar
        self.nixosModules.vtubing
        self.nixosModules.niri
        self.nixosModules.openrazer
        self.nixosModules.gaming
        self.nixosModules.zswap
        self.nixosModules.accessibility
        self.nixosModules.gnome-dependencies
        self.nixosModules.hibernate
        self.nixosModules.grub
        self.nixosModules.desktop-streaming
      ];
      home-manager.sharedModules = [
        self.homeModules.neural-augmenter
      ];

      # FIX: Move to module imports
      myOptions.utilities = {
        rescueTools = true;
        binaryTools = true;
        pdfUtils = true;
        diskUtilities = true;
      };
      security = {
        rtkit.enable = true;
        pam.services.login.enableGnomeKeyring = true;
        ownAdditional.yubikey = true;
      };

      boot.kernelPackages = pkgs.linuxPackages_zen;
      nix = {
        # Attempt to keep desktop devices more responsive during e.g. builds or optimization, at expense of longer build times
        daemonCPUSchedPolicy = "idle";
        daemonIOSchedClass = "idle";

        settings = {
          keep-outputs = true;
          keep-derivations = true;
          tarball-ttl = 7 * 24 * 3600; # Cache tars for seven days to improve dev experience
        };
      };

      stylix = {
        overlays.enable = false;
        base16Scheme = base16Scheme pkgs;
        autoEnable = false;
        enable = true;
        fonts = {
          monospace = {
            name = "OpenDyslexicM Nerd Font Mono";
            package = pkgs.nerd-fonts.open-dyslexic;
          };
          sansSerif = {
            name = "OpenDyslexic Nerd Font";
            package = pkgs.nerd-fonts.open-dyslexic;
          };
          serif = {
            name = "OpenDyslexic Nerd Font";
            package = pkgs.nerd-fonts.open-dyslexic;
          };
          sizes = {
            applications = 10;
            desktop = 8;
            popups = 8;
            terminal = 10;
          };
        };
        polarity = "dark";
        targets = {
          grub = {
            enable = true;
            useWallpaper = true;
          };
          gtksourceview.enable = lib.mkForce false;
        };
      };
      programs = {
        # Open the ports for KDE-Connect as home manager sadly can't do it
        kdeconnect = {
          enable = true;
          package = lib.mkForce pkgs.kdePackages.kdeconnect-kde;
        };
        ausweisapp = {
          enable = true;
          openFirewall = true;
        };
        extra-container.enable = true;
        nix-ld.enable = true;
        chrysalis.enable = true;
        nh = {
          enable = true;
          flake = "/home/inf/Projects/nix0s-config/";
          clean = {
            enable = true;
            dates = "daily";
            extraArgs = "--keep 5 --keep-since 7d --optimise";
          };
        };
        ydotool.enable = true;
        appimage = {
          binfmt = true;
          package = appimage-run-with-libs;
        };
      };
      nix = {
        gc.automatic = false;
        optimise.automatic = false;
      };

      services = {
        udev.packages = [
          pkgs.platformio-core
          pkgs.probe-rs-tools
        ];
        colord.enable = true;
        samba.enable = true;
        xserver.wacom.enable = true;
        flatpak.enable = true;
        hardware = {
          bolt.enable = true;
          openrgb = {
            enable = true;
            package = pkgs.openrgb-with-all-plugins;
          };
        };
        wivrn = {
          enable = true;
          openFirewall = true;
          steam.importOXRRuntimes = true;
        };
        displayManager.gdm.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
        tuned.enable = true;
        tlp.enable = lib.mkForce false; # Conflict with tuned
        upower.enable = true;
        gnome.evolution-data-server.enable = true; # Noctalia calendar support
        earlyoom.enable = true; # Out of memory management
        pulseaudio = {
          enable = false;
          zeroconf.discovery.enable = true;
        };
        pipewire = {
          enable = true;
          pulse.enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          jack.enable = false;
          raopOpenFirewall = true;
          wireplumber.enable = true;
        };
        gvfs.enable = true;
        locate = {
          enable = true;
          interval = "hourly";
          package = pkgs.plocate;
          pruneNames = [
            ".bzr"
            ".cache"
            ".git"
            ".hg"
            ".svn"
            ".jj"
            ".pio"
            ".fingerprint"
            ".direnv"
            "target"
          ];
        };
        speechd.enable = true;
        lorri.enable = true;
      };

      hardware = {
        enableAllFirmware = lib.mkDefault true;
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Experimental = true;
              KernelExperimental = true;
              FastConnectable = true;
              # ControllerMode = "bredr"; # Problems with Bose
              # JustWorksRepairing = true; # Security implications?
            };
          };
        };
        i2c.enable = true;
        sensor.iio.enable = true; # Autorotation
        opentabletdriver.enable = true; # May improve krita comfort
        rtl-sdr.enable = true;
      };
      environment = let
        askpass_helper = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      in {
        # EXPERIMENT: Try if noctalia automatically picks up the slack
        sessionVariables = {
          SUDO_ASKPASS = askpass_helper;
          SSH_ASKPASS = askpass_helper;
        };
        variables.SSH_ASKPASS = lib.mkForce askpass_helper; # Required due to nix conflict
        systemPackages = [
          inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
          appimage-run-with-libs
          pkgs.lm_sensors
          pkgs.nftables
          pkgs.android-tools
          pkgs.piper-tts
          pkgs.base16-schemes
        ];
      };

      virtualisation = {
        containers = {
          enable = true;
          registries.settings = {
            unqualified-search-registries = [
              "docker.io"
              "quay.io"
              "mirror.gcr.io"
            ];
            registry = [
              {location = "docker.io";}
              {location = "quay.io";}
              {location = "mirror.gcr.io";} # Google mirror
            ];
          };
        };
        podman = {
          enable = true;
          dockerSocket.enable = true;
          autoPrune.enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
        };
        oci-containers.backend = "podman";
        waydroid.enable = true;
      };

      sops.secrets."registry/dockerhub/password".sopsFile = "${secrets}/secrets/services/docker.yaml";
      users = {
        users."inf" = {
          autoSubUidGidRange = true; # Needed for podman
          extraGroups = [
            "plugdev"
            "ydotool"
          ];
        };
        groups.plugdev = {};
      };
      documentation = {
        dev.enable = true;
        man = {
          cache.enable = true;
          man-db.enable = true;
        };
      };

      systemd = {
        oomd.enable = true; # Out of memory management
        services.NetworkManager-wait-online.enable = lib.mkForce false;
      };
      networking = {
        networkmanager = {
          enable = true;
          wifi.powersave = false;
        };
        firewall = {
          allowedTCPPorts = [
            22000 # SyncThing
          ];
          allowedUDPPorts = [
            21027 # SyncThing
            22000 # SyncThing
          ];
        };
      };
      boot.extraModprobeConfig = ''
        options btusb disable_autosuspend=1
        options btusb enable_autosuspend=0
      '';
      # TODO: Switch font to nicer font, like jetbrains
      fonts = {
        fontDir.enable = true;
        packages = [
          pkgs.nerd-fonts.open-dyslexic
          pkgs.nerd-fonts.symbols-only
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-color-emoji
          pkgs.noto-fonts-monochrome-emoji
        ];
        fontconfig = {
          hinting.style = "medium";
          defaultFonts = {
            serif = ["OpenDyslexic Nerd Font"];
            sansSerif = ["OpenDyslexic Nerd Font"];
            monospace = ["OpenDyslexicM Nerd Font Mono"];
            emoji = ["Noto Color Emoji"];
          };
        };
      };
    };

    homeModules.neural-augmenter = {
      config,
      lib,
      osConfig,
      pkgs,
      secrets,
      ...
    }: let
      jsonFormatter = pkgs.formats.json {};
    in {
      imports = [
        self.homeModules.piper-web-tts
        self.homeModules.firefox
        self.homeModules.art
        self.homeModules.development
        self.homeModules.social
        self.homeModules.flatpak
      ];
      config = {
        myOptions = {
          roles.development = {
            electronics = true;
            reverseEngineering = true;
            fren-coding = true;
          };
          services.piper-web-tts.model = "en_US-libritts_r-medium";
        };

        home = {
          # TODO: Split and clean up
          packages =
            [
              pkgs.bitwarden-cli
              pkgs.rofi-rbw # rofi-bitwarden
              pkgs.tor-browser
              pkgs.restic
              pkgs.autorestic
              pkgs.krita
              pkgs.wl-clipboard
              pkgs.brightnessctl
              pkgs.hyfetch
              pkgs.feh

              # KDE info packages
              pkgs.clinfo
              pkgs.mesa-demos
              pkgs.vulkan-tools
              pkgs.wayland-utils
              pkgs.pciutils
              pkgs.aha
              pkgs.ddcutil
              pkgs.usbutils

              pkgs.ffmpeg-full
              pkgs.gst_all_1.gstreamer
              pkgs.gst_all_1.gst-plugins-base
              pkgs.gst_all_1.gst-plugins-good
              pkgs.gst_all_1.gst-plugins-bad
              pkgs.imagemagick
              pkgs.yt-dlp
              pkgs.pwvucontrol
              pkgs.coppwr # Debugging and low-level configuring of pipewire
              pkgs.raysession # Patchbay
              pkgs.rofi-bluetooth
              pkgs.vlc

              pkgs.gnome-keyring
              pkgs.seahorse

              # Certificate creation
              pkgs.xca
              pkgs.dumbpipe

              pkgs.speedread

              pkgs.scrcpy
              pkgs.android-tools

              pkgs.podman
              pkgs.dive
              pkgs.podman-tui
              pkgs.podman-compose
              pkgs.systemctl-tui

              pkgs.feishin # Subsonic player

              # Banking
              pkgs.hledger
              pkgs.hledger-ui
              pkgs.hledger-web
              pkgs.hledger-fmt
              pkgs.aqbanking

              pkgs.wivrn
              pkgs.wayvr

              # dbus debugging
              pkgs.bustle
              pkgs.d-spy

              pkgs.easyeffects

              pkgs.qalculate-qt # TODO: Choose different calculator
              pkgs.nautilus

              pkgs.sdrpp # TODO: Move to a ham role

              pkgs.camset # Webcam image settings gui

              # TODO: Add from common font list
              # Fonts
              pkgs.nerd-fonts.commit-mono
              pkgs.powerline-symbols
              pkgs.powerline-fonts
              pkgs.noto-fonts-color-emoji # fcitx5
              pkgs.nerd-fonts.fira-code
              pkgs.fira-sans

              (pkgs.writeShellScriptBin "rofi-home-assistant-sops.sh" ''
                set -e

                export HASS_SERVER="http://${self.deploy.nodes.neurodrive.hostname}:8123"
                HASS_TOKEN="$(cat ${config.sops.secrets.hass_cli_token.path})"
                export HASS_TOKEN

                ${lib.getExe pkgs.rofi-home-assistant-changed}
              '')
              pkgs.wdisplays
              pkgs.wev

              # Emacs
              pkgs.gitFull
              pkgs.ripgrep
              pkgs.coreutils
              pkgs.fd
              pkgs.clang
              pkgs.symbola
              pkgs.shellcheck # Bash
              pkgs.pandoc # Markdown
              pkgs.gopls
              pkgs.gomodifytags
              pkgs.gotests
              pkgs.gore
              pkgs.ledger # Compatible with hledger?
              pkgs.nixfmt # Mostly to get rid of the warning.
              pkgs.isort
              pkgs.pipenv
              pkgs.uv
              pkgs.go-grip
              pkgs.gnumake
              pkgs.cmake
              pkgs.libtool
              pkgs.bash
              pkgs.shfmt
              pkgs.nodejs
              pkgs.graphviz-nox
              pkgs.python314Packages.black
              pkgs.python314Packages.pyflakes
              pkgs.python314Packages.pytest

              pkgs.blanket # Local noise generator

              config.services.activitywatch.package

              pkgs.winetricks
              pkgs.wineWow64Packages.waylandFull
              pkgs.dxvk_2

              # Voice typing
              pkgs.voxd
              pkgs.pixelflasher
              pkgs.beeref

              pkgs.obsidian

              pkgs.alarm-clock-applet

              pkgs.pear-desktop
              pkgs.youtube-tui

              pkgs.kdePackages.ark
              pkgs.kdePackages.gwenview
              pkgs.kdePackages.okular
              pkgs.kdePackages.kate
              pkgs.kdePackages.ktexteditor
              pkgs.kdePackages.dolphin
              pkgs.kdePackages.dolphin-plugins
              pkgs.kdePackages.baloo-widgets
              pkgs.kdePackages.ffmpegthumbs
              pkgs.kdePackages.kcharselect # Font explorer
            ]
            ++ (lib.optionals osConfig.security.ownAdditional.yubikey [
              pkgs.yubioath-flutter
              pkgs.yubikey-manager
            ]);

          sessionVariables = let
            # TODO: Redo the askpass helpers. They just don't work
            askpass_helper = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
          in {
            MOZ_USE_XINPUT2 = "1"; # Smooth scrolling
            # QT_LOGGING_RULES = "*.debug=true";
            NIXOS_OZONE_WL = "1"; # Native Wayland for Chromium apps
            # EXPERIMENT: Try if noctalia automatically picks up the slack
            SUDO_ASKPASS = askpass_helper;
            SSH_ASKPASS = askpass_helper;
          };
          sessionPath = [
            "$HOME/.emacs.d/bin" # TODO: Move to emacs role
            "$HOME/.cargo/bin" # TODO: Move to rust dev
          ];
          pointerCursor = {
            enable = true;
            gtk.enable = true;
            package = pkgs.breeze-hacked-cursor-theme;
            name = "Breeze_Hacked";
            size = 36;
          };
          activation.rebuildKdeXdgCache = lib.hm.dag.entryAfter [
            "writeBoundary"
          ] "run ${pkgs.kdePackages.kservice.out}/bin/kbuildsycoca6"; # Rebuild cache for dolphin
          file.".face".source = "${secrets}/dotfiles/pfp/cute_blushing_growth.jpg";
        };

        services = {
          syncthing.enable = true;
          playerctld.enable = true;
          kdeconnect = {
            enable = true;
            indicator = true;
            package = pkgs.kdePackages.kdeconnect-kde;
          };
          emacs = {
            enable = true;
            client.enable = true;
            defaultEditor = true;
            socketActivation.enable = true;
            startWithUserSession = true;
          };

          activitywatch = {
            enable = true;
            package = pkgs.aw-server-rust;
            watchers = {
              awatcher = {
                package = pkgs.awatcher;
                settings = {
                  # Defaults
                  idle-timeout-seconds = 180;
                  poll-time-idle-seconds = 5;
                  poll-time-window-seconds = 1;
                };
              };
            };
          };
        };
        programs = {
          chromium = {
            enable = lib.mkDefault true;
            package = pkgs.chromium.override {enableWideVine = true;};
          };
          nushell = {
            enable = true;
            loadSessionVariables = true;
          };
          rofi = {
            enable = lib.mkDefault true;
            theme = "noctalia";
            settings = {
              terminal = "${lib.getExe pkgs.kitty}";
              show-icons = true;
            };
          };
          bat.enable = true;
          fish.enable = true;
          sioyek.enable = true;
          emacs = {
            enable = true;
            package = pkgs.emacs;
          };
          vim.defaultEditor = false;
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
            keybindings = {
              # Paste commands on screen to execute
              "ctrl+shift+p>$" = "kitten hints --program \"-\" --type regex --regex '(?m)^\\s*\\$\\s(.*)$'";
            };
          };
          tmux = {
            enable = true;
            clock24 = true;
            # Hope this doesn't blow up
            keyMode = "vi";
            mouse = true;
            newSession = true;
            # May require passthrough set to all
            extraConfig = ''
              set -g allow-passthrough on
            '';
          };
          btop.enable = true;
        };

        xdg = {
          # FIX: Current implementation doesn't pick up everything. Some services/calls like e.g. gnome-calendars call to gnome-online-accounts don't get properly resolved
          portal = {
            enable = lib.mkForce true;
            xdgOpenUsePortal = true;
            config.common = {
              default = [
                "luminous"
                "wlr"
                "gnome"
                "gtk"
              ];
              "org.freedesktop.impl.portal.RemoteDesktop" = ["luminous"];
            };
            extraPortals =
              [
                pkgs.xdg-desktop-portal-gnome
                pkgs.xdg-desktop-portal-luminous
                pkgs.xdg-desktop-portal-wlr
                pkgs.gnome-keyring
                pkgs.xdg-desktop-portal-gtk
              ]
              ++ osConfig.xdg.portal.extraPortals; # See github.com/nix-community/home-manager/issues/7124
          };
          stateFile = {
            "home-manager-user-files/wallpapers" = {
              source = "${secrets}/dotfiles/wallpapers";
              recursive = true;
            };
            "home-manager-user-files/pfps" = {
              source = "${secrets}/dotfiles/pfp";
              recursive = true;
            };
          };
          # TODO: Move into an audio module
          configFile = {
            "wireplumber/wireplumber.conf.d/no-headset-autoswitch.conf".source =
              jsonFormatter.generate "no-headset-autoswitch"
              {
                "wireplumber.settings" = {
                  "bluetooth.autoswitch-to-headset-profile" = false;
                  "device.routes.mute-on-bluetooth-playback-removed" = true;
                };
              };
            "wireplumber/wireplumber.conf.d/bluez-longer-pause.conf".source =
              jsonFormatter.generate "bluez-longer-pause"
              {
                "monitor.bluez.rules" = [
                  {
                    matches = [
                      {"node.name" = "~bluez_output.*";}
                      {"node.name" = "~bluez_input.*";}
                    ];
                    actions.update-props."session.suspend-timeout-seconds" = 15;
                  }
                ];
              };
            "wireplumber/wireplumber.conf.d/log-level-debug.conf".source =
              jsonFormatter.generate "log-level-debug"
              {
                "context.properties"."log.level" = "2";
              };
            "pipewire/pipewire.conf.d/log-level-debug.conf".source = jsonFormatter.generate "log-level-debug" {
              "log.level" = "2";
            };
            "pipewire/pipewire.conf.d/airplay.conf".source = jsonFormatter.generate "airplay" {
              "context.modules" = [{name = "libpipewire-module-raop-discover";}]; # In case of lagging: Increase buffer size
            };
            "pipewire/pipewire-pulse.conf.d/switch-on-connect.conf".source =
              jsonFormatter.generate "switch-on-connect"
              {
                "pulse.cmd" = [
                  {
                    "cmd" = "load-module";
                    "args" = "module-switch-on-connect";
                  }
                ];
              };
          };
        };

        stylix = {
          enable = true;
          autoEnable = false;
          inherit (osConfig.stylix) image polarity;
          base16Scheme = base16Scheme pkgs;
          opacity.terminal = 0.8;
          targets = {
            kde.enable = false;
            qt.enable = false;
            rofi.enable = false;
            emacs.enable = false;
            lazygit.enable = false;
            obsidian.enable = false;
            nixos-icons.enable = false; # Broken targets
            gtksourceview.enable = lib.mkForce false; # See: Constant rebuilds of e.g. inkscape caused by this
            kitty.enable = true;
          };
        };

        # Required for waybar and some other animations to properly function
        gtk = {
          gtk2.extraConfig = ''
            gtk-enable-animations = true;
          '';
          gtk3.extraConfig.gtk-enable-animations = true;
          gtk4 = {
            inherit (config.gtk) theme;
            extraConfig.gtk-enable-animations = true;
          };
        };
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            enable-animations = true;
          };
        };
        sops.secrets."hass_cli_token" = {
          sopsFile = "${secrets}/secrets/services/home-assistant.yaml";
          key = "access_tokens/cli";
        };
        # TODO: Neccessary?
        systemd.user.services.emacs.Unit.X-SwitchMethod = "keep-old";
        systemd.user.sockets.emacs.Unit.X-SwitchMethod = "keep-old";
      };
    };
  };
}
