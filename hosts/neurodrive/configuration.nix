{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/cachix.nix

    ../../modules/common/default.nix
    ../../modules/wireguard/default.nix

    ./hardware-configuration.nix
  ];

  nixpkgs.config = {
    cudaSupport = true;
    cudnnSupport = true;

    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "joypixels"
      ];
    joypixels.acceptLicense = true;
  };

  nix.settings = {
    # Logical cores: 12
    max-jobs = 10;
    # Max make some builds non deterministic
    cores = 10;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.consoleLogLevel = 7;
  # TODO: Redo
  boot.plymouth = with pkgs; {
    enable = true;
    theme = "breeze";
  };

  # Filesystems
  boot.initrd.luks.devices."nixos-root" = {
    device = "/dev/disk/by-uuid/36e0d35b-4ac0-41a9-a8a9-15a07696c2c4";
    bypassWorkqueues = true;
    # Weakens security
    allowDiscards = true;
  };

  boot.initrd.luks.devices."nixos-swap" = {
    device = "/dev/disk/by-uuid/69bd8d21-1c47-4aff-8533-31bf2610c181";
    bypassWorkqueues = true;
    # Weakens security
    allowDiscards = true;
  };
  fileSystems."/mnt/restic_data" = {
    device = "/dev/disk/by-uuid/2645230e-f8d1-4b00-ad11-c9ec192448cf";
    fsType = "ext4";
    options = [
      "nofail"
    ];
  };
  services.fstrim.enable = true;

  # Networking
  time.timeZone = "Europe/Berlin";
  networking.hostName = "neurodrive";
  networking.networkmanager.enable = true;
  networking.interfaces."enp0s25".wakeOnLan.enable = true;
  # Issues with builds randomly failing
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  networking.firewall.allowedTCPPorts = [
    #TODO: Pulseaudio Network Sharing. Probably only needed for publush
    4713
    (lib.strings.toInt config.services.restic.server.listenAddress)
  ];

  networking.ownWireguard = {
    enabled = true;
    lastIPDigit = 3;
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.xserver.xkb = {
    layout = "de";
  };

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.printing.enable = true;
  hardware.sane.enable = true;
  hardware.sane.drivers.scanSnap.enable = true;

  hardware.pulseaudio.enable = false;
  hardware.pulseaudio.zeroconf.discovery.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    wireplumber.enable = true;
  };

  hardware.enableAllFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      # Problems with Bose
      ControllerMode = "bredr";
    };
  };

  services.pipewire.wireplumber.extraConfig = {
    "disable-hfp-autoswitch" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
    "monitor.bluez.properties" = {
      "bluez5.enable-hw-volume" = true;
    };
    "bose-qc35-2-ldac-hq" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            {
              # Match any bluetooth device with ids equal to that of a Bose QC 35 ||
              "device.name" = "~bluez_card.*";
              "device.product.id" = "0x4020";
              "device.vendor.id" = "bluetooth:009e";
            }
          ];
          actions = {
            update-props = {
              # Set quality to high quality instead of the default of auto
              "bluez5.a2dp.ldac.quality" = "hq";
            };
          };
        }
      ];
    };

    #"log-level-debug" = {
    #  "context.properties" = {
    #      # Output Debug log messages as opposed to only the default level (Notice)
    #      "log.level" = "D";
    #    };
    #};
  };

  users.users.inf = {
    isNormalUser = true;
    description = "Infinity";
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "scanner"
      "lp"
      "docker"
    ];

    packages = with pkgs; [
      zenity
      yad

      tor-browser
      chromium
      kate
      obsidian
      vlc
      mpv
      yt-dlp
      feh
      gimp
      krita
      simple-scan
      flameshot
      thunderbird
      bitwarden
      bitwarden-cli
      obsidian
      taskwarrior3
      taskwarrior-tui
      nushell
      kitty
      kdePackages.kalk

      libreoffice-qt
      hunspell
      hunspellDicts.de_DE

      shotcut
      audacity
      helvum
      pavucontrol

      warp
      kdePackages.kdeconnect-kde
      wl-clipboard

      joypixels

      telegram-desktop
      threema-desktop
      signal-desktop
      mumble
      discord
      betterdiscordctl
      # Is this just for the desktop file?
      element-desktop
      element-desktop-wayland

      mindustry-wayland

      kicad
      openscad-unstable
      prusa-slicer
      intel-gpu-tools
      rustup

      (koboldcpp.override {
        cublasSupport = true;
      })
      wireshark

      # Does my bar approach need this?
      openal

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
  };

  programs.firefox.enable = true;
  programs.kdeconnect.enable = true;

  # Needs home-manager
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    vteIntegration = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      theme = "tonotdo";
      enable = true;
    };

    shellAliases = {
      ll = "ls -l";
      check-nix-config = "sudo nix-instantiate '<nixpkgs/nixos>' -A system";
      snvim = "sudo nvim";
      zix-shell = "nix-shell --command 'zsh'";
    };
    histSize = 10000;
  };
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    age
    file
    htop
    powertop
    dust
    dua
    ddrescue
    # losetup etc.
    util-linux
    zip
    unzip
    unar
    p7zip
    wget
    psmisc
    git
    git-lfs
    mosh
    tmux
    sshfs
    magic-wormhole
    magic-wormhole-rs
    hyfetch
    comma
    restic
    autorestic

    appimage-run
    fuse3
    fuse

    gnupg
    pinentry-qt

    ripgrep
    # pdfs 
    ripgrep-all
    fd
    jq
    fzf
    poppler_utils
    unixtools.xxd
    dig

    neovim
    ranger

    zoxide

    python3Full
    clang
    clang-tools
    nixfmt-rfc-style
    nixd
    direnv

    wireguard-tools

    cachix
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    nvtopPackages.full

    # KDE info packages
    clinfo
    glxinfo
    vulkan-tools
    wayland-utils
    pciutils
    aha

    ffmpeg-full
  ];

  services.fwupd.enable = true;
  programs.adb.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  environment.variables.EDITOR = "nvim";
  environment.sessionVariables = {
    # Smooth scrolling
    MOZ_USE_XINPUT2 = "1";
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

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

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Includes Wayland
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    #
    # May have improved now
    open = true;
  };

  security.wrappers.restic = {
    source = "${pkgs.restic.out}/bin/restic";
    owner = "restic";
    group = "users";
    permissions = "u=rwx,g=,o=";
    capabilities = "cap_dac_read_search=+ep";
  };

  services.restic.server = {
    enable = true;
    privateRepos = true;
    dataDir = "/mnt/restic_data/restic";
    listenAddress = "8193";
  };

  system.stateVersion = "24.05";
}
