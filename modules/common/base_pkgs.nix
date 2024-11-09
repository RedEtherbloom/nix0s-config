{
  config,
  fetchFromGitHub,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.myOptions.basePkgs;
in
{
  options.myOptions.basePkgs = {
    enabled = mkEnableOption "standard system and user pkgs";
    systemPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Standard system packages";
    };
    userPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Standard user packages";
    };
  };

  config = mkIf cfg.enabled (mkMerge [
    (mkIf cfg.systemPackages {
      environment.systemPackages = with pkgs; [
        age
        ssh-to-age
        sops

        file
        # For losetup 
        util-linux
        psmisc
        zip
        unzip
        unar
        p7zip
        git
        git-lfs
        ripgrep
        # pdfs
        ripgrep-all
        fd
        jq
        fzf
        poppler_utils
        unixtools.xxd
        ddrescue
        lshw
        fuse3
        appimage-run
        gnupg
        pinentry-qt

        # ZSH
        zoxide
        thefuck

        neovim
        ranger
        htop
        dust
        dua
        ncdu

        dig
        wget
        curl

        sshfs
        mosh
        tmux
        magic-wormhole
        magic-wormhole-rs
        restic
        autorestic
        wireguard-tools

        # TODO. Refactgor into development.nix
        python3Full

        # KDE info packages
        clinfo
        glxinfo
        vulkan-tools
        wayland-utils
        pciutils
        aha

        # Monitor brightness control
        ddcutil

        usbutils
        intel-gpu-tools

        ffmpeg-full
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
      ];

      programs.gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-qt;
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
      };

      services.fwupd.enable = true;
      services.fstrim.enable = true;
      programs.adb.enable = true;
    })
    # TODO: These belong in home-manager
    (mkIf cfg.userPackages {
      users.users.inf.packages = with pkgs; [
        (chromium.override { enableWideVine = true; })
        tor-browser

        thunderbird
        kate
        obsidian
        kdePackages.kalk
        (taskwarrior-tui.overrideAttrs (oldAttrs: rec {
          version = oldAttrs.version + "-fix";

          src = (
            pkgs.fetchFromGitHub {
              owner = "RedEtherbloom";
              repo = "taskwarrior-tui";
              hash = "sha256-YNd4vtaWm+1fsB8ly3toq2u74Nicmhx2ey1m557q4K8=";
              rev = "ee24bfb4a36f246933e6d2502ab85d3fc6abb85b";
            }
          );

          cargoDeps = oldAttrs.cargoDeps.overrideAttrs (
            lib.const {
              name = "taskwarrior-tui-vendor.tar.gz";
              inherit src;
              outputHash = "sha256-jtVUXWVrBq6xS4y9HKz+JtXHc6LvIk0cC7xmiPB1+ro=";
            }
          );
        }))
        bitwarden
        bitwarden-cli
        wl-clipboard
        hyfetch

        # Attempts at notifications
        kdePackages.kdialog
        libnotify

        # Do we still need this with stylix/noto?
        joypixels
        warp
        # Needed for warp?
        zbar
        # If spectactle has feature parity(for drawing): Drop
        flameshot

        vlc
        mpv
        feh
        pavucontrol
        yt-dlp

        shotcut
        audacity
        helvum

        libreoffice-qt
        hunspell
        hunspellDicts.en_US
        hunspellDicts.de_DE
        simple-scan
        gimp

        element-desktop-wayland
        telegram-desktop
        threema-desktop
        signal-desktop
        mumble
        (pkgs.discord.override {
          withOpenASAR = true;
          withVencord = true;
        })

        # TODO: Turn these into home-manager options
        kitty
        nushell
      ];

      programs.firefox.enable = true;
      programs.kdeconnect.enable = true;

      environment.sessionVariables = {
        # Smooth scrolling
        MOZ_USE_XINPUT2 = "1";
        # Native Wayland for Chromium apps
        NIXOS_OZONE_WL = "1";
      };
    })
  ]);
}
