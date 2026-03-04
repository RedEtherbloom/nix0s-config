{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myOptions.utilities;
in {
  options.myOptions.utilities = {
    enable = lib.mkOption {
      description = "Enable various utilities";
      type = lib.types.bool;
      default = false;
    };
    minimum = lib.mkOption {
      description = "Enable minimum utilities needed for our systems to be administrable(e.g. sops)";
      type = lib.types.bool;
      default = true;
    };
    diverse = lib.mkOption {
      description = "Enable diverse utilities that don't fit in other categories";
      type = lib.types.bool;
      default = true;
    };
    wormhole = lib.mkOption {
      description = "Enable wormhole";
      type = lib.types.bool;
      default = true;
    };
    tmux = lib.mkOption {
      description = "Enable tmux";
      type = lib.types.bool;
      default = true;
    };
    ssh_utils = lib.mkOption {
      description = "Enable ssh_utils";
      type = lib.types.bool;
      default = true;
    };
    git = lib.mkOption {
      description = "Enable git";
      type = lib.types.bool;
      default = true;
    };
    python = lib.mkOption {
      description = "Enable python";
      type = lib.types.bool;
      default = true;
    };
    htop = lib.mkOption {
      description = "Enable htop";
      type = lib.types.bool;
      default = true;
    };
    cmdFileManagers = lib.mkOption {
      description = "Enable cmdFileManagers";
      type = lib.types.bool;
      default = true;
    };
    networkUtils = lib.mkOption {
      description = "Enable network utils";
      type = lib.types.bool;
      default = true;
    };
    rescueTools = lib.mkOption {
      description = "Enable rescueTools";
      type = lib.types.bool;
      default = false;
    };
    binaryTools = lib.mkOption {
      description = "Enable binaryTools";
      type = lib.types.bool;
      default = false;
    };
    pdfUtils = lib.mkOption {
      description = "Enable pdf utilities";
      type = lib.types.bool;
      default = false;
    };
    diskUtilities = lib.mkOption {
      description = "Enable disk utilities(formatting, etc.)";
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = with pkgs;
        lib.optionals cfg.minimum [
          age
          ssh-to-age
          sops
        ]
        ++ lib.optionals cfg.diverse [
          file
          util-linux
          psmisc
          zip
          unzip
          unar
          p7zip
          ripgrep
          fd
          jq
          fzf
          lshw
          fuse3
        ]
        ++ lib.optionals cfg.git [
          git
          git-lfs
        ]
        ++ lib.optionals cfg.python [
          python3
        ]
        ++ lib.optionals cfg.htop [htop]
        ++ lib.optionals cfg.cmdFileManagers [
          ranger
          dust
          dua
          ncdu
          # Rust based
          yazi
        ]
        ++ lib.optionals cfg.networkUtils [
          dig
          wget
          curl
        ]
        ++ lib.optionals cfg.rescueTools [
          ddrescue
        ]
        ++ lib.optionals cfg.binaryTools [
          unixtools.xxd
        ]
        ++ lib.optionals cfg.wormhole [
          magic-wormhole
          magic-wormhole-rs
        ]
        ++ lib.optionals cfg.tmux [
          tmux
        ]
        ++ lib.optionals cfg.ssh_utils [
          sshfs
          mosh
        ]
        ++ lib.optionals cfg.pdfUtils [
          poppler-utils
          # pdfs
          ripgrep-all
        ]
        ++ lib.optionals cfg.diskUtilities [
          parted
          gparted
          # For losetup and fdisk
          util-linux
        ];
    }
  ]);
}
