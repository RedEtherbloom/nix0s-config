{
  inputs,
  self,
  ...
}: {
  flake = {
    # TODO: Move niri into niri.nix
    nixosModules.neural-augmenter = {
      config,
      lib,
      pkgs,
      secrets,
      ...
    }: let
      cfg = config.myOptions.hostRoles.neural-augmenter;
      appimage-run-with-libs = pkgs.appimage-run.override {
        extraPkgs = pkgs: [
          pkgs.ffmpeg
          pkgs.imagemagick
          pkgs.fuse
        ];
      };
    in {
      imports = [
        inputs.stylix.nixosModules.stylix
        inputs.niri-flake.nixosModules.niri
        self.homeModules.neural-augmenter
      ];

      options.myOptions.hostRoles.neural-augmenter = {
        setupGrubOptions = lib.mkOption {
          description = "Set common grub options among our setups.";
          type = lib.types.bool;
          default = true;
        };
        verboseSpecialisation = lib.mkOption {
          description = "Generate a second specialisation printing much more verbose boot logs.";
          type = lib.types.bool;
          default = false;
        };
        # TODO: Move to base.nix
        tailscale = lib.mkOption {
          description = "Enable tailscale support.";
          type = lib.types.bool;
          default = true;
        };
      };

      config = (
        lib.mkMerge [
          {
            # FIX: Move to module imports
            myOptions = {
              hostRoles.graphical.enable = lib.mkDefault true;
              hostRoles.base.enable = lib.mkDefault true;
              office.enable = true;
              utilities = {
                rescueTools = true;
                binaryTools = true;
                pdfUtils = true;
                diskUtilities = true;
              };
              roles = {
                i2p.enable = true;
                vtubing.enable = true;
                ssdp.enable = true;
              };
            };
            security = {
              rtkit.enable = true;
              pam.services.login.enableGnomeKeyring = true;
              ownAdditional.yubikey = true;
            };

            nix = {
              # Attempt to keep desktop devices more responsive during e.g. builds or optimization, at expense of longer build times
              daemonCPUSchedPolicy = "idle";
              daemonIOSchedClass = "idle";

              settings = {
                keep-outputs = true; # TODO: Needed?
                keep-derivations = true; # TODO: Needed?
                tarball-ttl = 7 * 24 * 3600; # Cache tars for seven days to improve dev experience
              };
            };

            stylix = {
              enable = false;
              polarity = "dark";
              targets.grub = {
                enable = true;
                useWallpaper = true;
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
              niri = {
                enable = true;
                package = pkgs.niri-unstable;
              };
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
              udev.packages = with pkgs; [
                platformio-core
                probe-rs-tools
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
              displayManager = {
                gdm.enable = true;
                defaultSession = "niri";
              };
              # ollama = {
              #   enable = true;
              #   environmentVariables.OLLAMA_ORIGINS = "*"; # Fix CORS errors on localhost
              #   loadModels = [
              #     "qwen3:1.7b"
              #     "qwen3:4b"
              #   ];
              # };
              # nextjs-ollama-llm-ui = {
              #   enable = true;
              #   port = 8154; # Reasonably close to ollama
              # };
              avahi = {
                enable = true;
                nssmdns4 = true;
                openFirewall = true;
              };
              tuned.enable = true;
              tlp.enable = lib.mkForce false; # Conflicts with tuned
              upower.enable = true;
              gnome.evolution-data-server.enable = true; # Noctalia calendar support
              earlyoom.enable = true; # Out of memory management
              pulseaudio = {
                enable = false;
                zeroconf.discovery.enable = true; # Just for the port. Check if I have to do this
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
                    # ControllerMode = "bredr"; # Problems with Bose
                    FastConnectable = true;
                    # Class = "0x000100"; # Generic desktop TODO: Do I need object major class as well?
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
              # askpass_helper = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
            in {
              # EXPERIMENT: Try if noctalia automatically picks up the slack
              # sessionVariables = {
              #   SUDO_ASKPASS = askpass_helper;
              #   SSH_ASKPASS = askpass_helper;
              # };
              # variables.SSH_ASKPASS = lib.mkForce askpass_helper; # Required due to nix conflict
              systemPackages = [
                pkgs.lm_sensors
                pkgs.nftables # vopono daemon
                pkgs.android-tools
                pkgs.piper-tts
                appimage-run-with-libs
                inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
              ];
            };

            # Don't garbage collect flake sources for our dev machines, for faster devflows. Copied from: https://github.com/NixOS/nix/issues/3995#issuecomment-2081164515
            # system.extraDependencies = let
            #   collectFlakeInputs = input:
            #     [input] ++ builtins.concatMap collectFlakeInputs (builtins.attrValues (input.inputs or {}));
            # in
            #   builtins.concatMap collectFlakeInputs (builtins.attrValues inputs);

            zramSwap.enable = true;
            virtualisation = {
              containers = {
                enable = true;
                registries.settings.registry = [
                  {location = "docker.io";}
                  {location = "quay.io";}
                  {location = "mirror.gcr.io";} # Google mirror
                ];
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
                mandoc.enable = true; # For some reason search is broken. Also in less.
                man-db.enable = false;
              };
            };

            systemd = {
              oomd.enable = true; # Out of memory management
              services = {
                NetworkManager-wait-online.enable = lib.mkForce false; # Issues with builds randomly failing
                vopono = {
                  description = "Vopono VPN";
                  after = ["network.target"];
                  requires = ["network.target"];
                  wantedBy = ["multi-user.target"];
                  serviceConfig = {
                    # TODO: Setup separate user
                    Type = "simple";
                    ExecStart = "${lib.getExe pkgs.vopono} daemon";
                    Restart = "on-failure";
                    RestartSec = "2s";
                    Environment = ["RUST_LOG=info"]; # Structured logging
                  };
                };
              };
              user.services.niri-flake-polkit.enable = false;
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
            boot = {
              kernelParams = [
                "PREEMPT=FULL" # Attempt to improve bluetooth reliability
              ];
              extraModprobeConfig = ''
                options btusb disable_autosuspend=1
                options btusb enable_autosuspend=0
              '';
            };
            # TODO: Switch font to nicer font, like jetbrains
            fonts = {
              fontDir.enable = true;
              packages = [
                pkgs.nerd-fonts.open-dyslexic
                # E.g. material fonts
                pkgs.nerd-fonts.symbols-only
                pkgs.noto-fonts
                pkgs.noto-fonts-cjk-sans
                pkgs.noto-fonts-color-emoji
                pkgs.noto-fonts-monochrome-emoji
              ];
              fontconfig = {
                # The default of slight always felt to fuzzy
                hinting.style = "medium";
                defaultFonts = {
                  serif = ["OpenDyslexic Nerd Font"];
                  sansSerif = ["OpenDyslexic Nerd Font"];
                  monospace = ["OpenDyslexicM Nerd Font Mono"];
                  emoji = ["Noto Color Emoji"];
                  # OpenDyslexic is very large by default. Too large for our taste.
                };
              };
            };
            stylix = {
              # DE independent
              fonts = {
                monospace = {
                  # TODO: Need a better mono font
                  package = pkgs.nerd-fonts.open-dyslexic;
                  name = "OpenDyslexicM Nerd Font Mono";
                };
                serif = {
                  package = pkgs.nerd-fonts.open-dyslexic;
                  name = "OpenDyslexic Nerd Font";
                };
                sansSerif = {
                  package = pkgs.nerd-fonts.open-dyslexic;
                  name = "OpenDyslexic Nerd Font";
                };
                sizes = {
                  applications = 10;
                  desktop = 8;
                  popups = 8;
                  terminal = 10;
                };
              };
            };
          }
          (lib.mkIf cfg.tailscale {
            services.tailscale.enable = true;
            networking = {
              nftables.enable = true;
              firewall = {
                trustedInterfaces = [config.services.tailscale.interfaceName];
                allowedUDPPorts = [config.services.tailscale.port];
              };
            };
            systemd.services.tailscaled.serviceConfig.Environment = [
              "TS_DEBUG_FIREWALL_MODE=nftables"
            ];
          })
          (lib.mkIf cfg.setupGrubOptions {
            boot = {
              loader = {
                efi.canTouchEfiVariables = true;
                timeout = 2;
                grub = lib.mkDefault {
                  enable = true;
                  enableCryptodisk = true;
                  efiSupport = true;
                  copyKernels = true;
                  fsIdentifier = "uuid";
                  useOSProber = true;
                  device = "nodev";
                  extraEntries = ''
                    menuentry "Poweroff" {
                      halt
                    }
                    menuentry "Reboot" {
                      reboot
                    }
                    menuentry "UEFI Setup" {
                      fwsetup
                    }
                  '';
                };
              };
              initrd.systemd = {
                enable = true;
                package = pkgs.systemd-token-timeout-patched;
              };
            };
          })
          (lib.mkIf cfg.verboseSpecialisation {
            specialisation.verbose-boot.configuration.boot.consoleLogLevel = 7;
          })
        ]
      );
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
      ];
      config = {
        # TODO: Convert into imports
        myOptions = {
          hostRoles.graphical.enable = lib.mkDefault true;
          roles = {
            development = {
              enable = lib.mkDefault true;
              electronics = lib.mkDefault true;
              reverseEngineering = lib.mkDefault true;
              vibecoding = lib.mkDefault true;
              fren-coding = lib.mkDefault true;
            };
            gamedev.enable = lib.mkDefault true;
            art = {
              enable = lib.mkDefault true;
              stitching = lib.mkDefault true;
            };
          };
          firefox.enable = lib.mkDefault true;
          socials.enable = lib.mkDefault true;
          services.piper-web-tts = {
            enable = true;
            model = "en_US-libritts_r-medium";
          };
        };

        home = {
          # TODO: Organize and cleanup
          packages =
            [
              pkgs.bitwarden-desktop
              pkgs.bitwarden-cli
              pkgs.rofi-rbw # rofi-bitwarden
              pkgs.tor-browser
              pkgs.restic
              pkgs.autorestic
              pkgs.krita
              pkgs.wl-clipboard
              pkgs.brightnessctl
              pkgs.hyfetch
              pkgs.feh # TODO: Recreate old shortcuts and configure via options instead

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
              pkgs.gst_all_1.gst-plugins-good
              pkgs.gst_all_1.gst-plugins-bad
              pkgs.imagemagick
              pkgs.yt-dlp
              pkgs.pavucontrol
              pkgs.pwvucontrol
              pkgs.coppwr # Debugging and low-level configuring of pipewire
              pkgs.raysession # Patchbay
              pkgs.rofi-bluetooth
              pkgs.vlc

              pkgs.gnome-keyring
              pkgs.seahorse

              pkgs.vopono
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

              # Fonts
              pkgs.nerd-fonts.commit-mono
              pkgs.powerline-symbols
              pkgs.powerline-fonts
              pkgs.noto-fonts-color-emoji # fcitx5
              pkgs.nerd-fonts.fira-code
              pkgs.fira-sans

              (pkgs.writeShellScriptBin "rofi-home-assistant-sops.sh" ''
                set -e

                export HASS_SERVER="http://100.108.50.97:8123"
                HASS_TOKEN="$(cat ${config.sops.secrets.hass_cli_token.path})"
                export HASS_TOKEN

                ${lib.getExe pkgs.rofi-home-assistant-changed}
              '')
              pkgs.wdisplays
              pkgs.wev

              # Emacs
              pkgs.git
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
              pkgs.nixfmt # Mostly to get rid of the warning. TODO: Make emacs use alejandra
              pkgs.isort
              pkgs.pipenv
              pkgs.uv
              pkgs.go-grip
              pkgs.gnumake
              pkgs.cmake
              pkgs.libtool
              # emacs-lsp-booster # Would require eglot
              pkgs.bash
              pkgs.shfmt
              pkgs.nodejs
              pkgs.graphviz-nox
              pkgs.python314Packages.black
              pkgs.python314Packages.pyflakes
              pkgs.python314Packages.pytest

              pkgs.supercollider_scel

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

              pkgs.kdePackages.rk
              pkgs.kdePackages.wenview
              pkgs.kdePackages.kular
              pkgs.kdePackages.ate
              pkgs.kdePackages.texteditor
              pkgs.kdePackages.olphin
              pkgs.kdePackages.olphin-plugins
              pkgs.kdePackages.aloo-widgets
              pkgs.kdePackages.fmpegthumbs
              pkgs.kdePackages.charselect # Font explorer
            ]
            ++ (lib.optionals osConfig.security.ownAdditional.yubikey [
              pkgs.yubioath-flutter
              pkgs.yubikey-manager
            ]);

          sessionVariables = let
            # askpass_helper = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
          in {
            MOZ_USE_XINPUT2 = "1"; # Smooth scrolling
            # QT_LOGGING_RULES = "*.debug=true";
            NIXOS_OZONE_WL = "1"; # Native Wayland for Chromium apps
            # EXPERIMENT: Try if noctalia automatically picks up the slack
            # SUDO_ASKPASS = askpass_helper;
            # SSH_ASKPASS = askpass_helper;
          };
          sessionPath = [
            "$HOME/.emacs.d/bin"
            "$HOME/.cargo/bin"
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
          nushell.enable = true;
          rofi = {
            enable = lib.mkDefault true;
            terminal = "${lib.getExe pkgs.kitty}";
            extraConfig.show-icons = true;
            theme = ../../dotfiles/rofi/launcher.rasi;
          };
          bat.enable = true;
          broot.enable = true; # TODO: Give a try for better comparison
          fish = {
            enable = true;
            functions = {
              "fish_greeting" = "";
            };
          };
          sioyek.enable = true;
          emacs = {
            enable = true;
            package = pkgs.emacs;
          };
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
          };
          tmux = {
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
          fzf.tmux.enableShellIntegration = true;
          btop.enable = true;
        };

        xdg = {
          autostart = {
            enable = true;
            entries = ["${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop"];
          };
          portal = {
            enable = lib.mkForce true;
            xdgOpenUsePortal = true;
            extraPortals = with pkgs;
              [
                gnome-keyring
                xdg-desktop-portal-gtk
              ]
              ++ osConfig.xdg.portal.extraPortals; # See github.com/nix-community/home-manager/issues/7124
          };
          stateFile = {
            # REFACTOR: piper module
            "piper-models/.keep".text = "";
            "home-manager/user-files/wallpapers" = {
              source = "${secrets}/dotfiles/wallpapers";
              recursive = true;
            };
            "home-manager/user-files/pfps" = {
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
          targets = {
            kde.enable = false;
            qt.enable = false;
            rofi.enable = false;
            emacs.enable = false;
            lazygit.enable = false;
            obsidian.enable = false;

            kitty.enable = true;
          };
          opacity.terminal = 0.8;
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
      };
    };
  };
}
