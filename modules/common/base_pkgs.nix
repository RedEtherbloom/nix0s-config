{
  config,
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

        ranger
        htop
        dust
        dua
        ncdu

        dig
        wget
        curl

        restic
        autorestic

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

        git
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
        bitwarden
        bitwarden-cli
        
        wl-clipboard
        hyfetch

        # Attempts at notifications
        kdePackages.kdialog
        libnotify
        
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

        # TODO: Turn these into home-manager options
        kitty
        nushell
      ];

      programs.firefox.enable = true;

      environment.sessionVariables = {
        # Smooth scrolling
        MOZ_USE_XINPUT2 = "1";
        # Native Wayland for Chromium apps
        NIXOS_OZONE_WL = "1";
      };
    })
  ]);
}
