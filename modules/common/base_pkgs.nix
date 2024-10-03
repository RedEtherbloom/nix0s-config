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
    steam = mkOption {
      type = types.bool;
      default = true;
      description = "Steam";
    };
  };

  config = mkIf cfg.enabled (mkMerge [
    (mkIf cfg.systemPackages {
      environment.systemPackages = with pkgs; [
        comma
        age
        ssh-to-age
        sops

        file
        # losetup 
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
        nmap
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

        python3Full
        clang
        clang-tools
        nixfmt-rfc-style
        nixd
        direnv

        # KDE info packages
        clinfo
        glxinfo
        vulkan-tools
        wayland-utils
        pciutils
        aha

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
    (mkIf cfg.userPackages {
      users.users.inf.packages = with pkgs; [
        chromium
        tor-browser

        thunderbird
        kate
        obsidian
        kdePackages.kalk
        taskwarrior3
        taskwarrior-tui
        bitwarden
        bitwarden-cli
        wl-clipboard
        hyfetch

        joypixels
        warp
        zbar
        flameshot

        vlc
        mpv
        feh
        pavucontrol
        yt-dlp

        shotcut
        audacity
        helvum

        mindustry-wayland
        gcs

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
        discord
        betterdiscordctl
        mumble

        wireshark

        kicad
        openscad-unstable
        prusa-slicer

        kitty
        nushell
        rustup

        (vscode-with-extensions.override {
          vscodeExtensions =
            with vscode-extensions;
            [
              mhutchie.git-graph
              donjayamanne.githistory
              eamodio.gitlens
              ms-vscode-remote.remote-ssh
              vadimcn.vscode-lldb
              mkhl.direnv

              jnoortheen.nix-ide
              arrterian.nix-env-selector

              ms-python.python

              ms-azuretools.vscode-docker

              rust-lang.rust-analyzer

            ]
            ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
              {
                name = "openscad";
                publisher = "Antyos";
                version = "1.3.1";
                sha256 = "sha256-J4lJgZT0HXRC2B1eFUl4MoP0YT5EZjLPl3yIY+VLBiI=";
              }
            ];
        })
      ];

      programs.firefox.enable = true;
      programs.kdeconnect.enable = true;

      environment.sessionVariables = {
        # Smooth scrolling
        MOZ_USE_XINPUT2 = "1";
      };
    })
    (mkIf (config.userPackages && config.steam) {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        protontricks.enable = true;
        # X11 -> Wayland Input translation
        extest.enable = true;

        extraCompatPackages = with pkgs; [
          steamtinkerlaunch
        ];
      };
    })
  ]);
}
