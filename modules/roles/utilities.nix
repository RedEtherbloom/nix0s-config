{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.utilities;
in {
  options.myOptions.utilities = {
    enable = mkOption {
      description = "Enable various utilities";
      type = with types; bool;
      default = false;
    };
    minimum = mkOption {
      description = "Enable minimum utilities needed for our systems to be administrable(e.g. sops)";
      type = types.bool;
      default = true;
    };
    diverse = mkOption {
      description = "Enable diverse utilities that don't fit in other categories";
      type = types.bool;
      default = true;
    };
    wormhole = mkOption {
      description = "Enable wormhole";
      type = types.bool;
      default = true;
    };
    tmux = mkOption {
      description = "Enable tmux";
      type = types.bool;
      default = true;
    };
    ssh_utils = mkOption {
      description = "Enable ssh_utils";
      type = types.bool;
      default = true;
    };
    git = mkOption {
      description = "Enable git";
      type = types.bool;
      default = true;
    };
    python = mkOption {
      description = "Enable python";
      type = types.bool;
      default = true;
    };
    htop = mkOption {
      description = "Enable htop";
      type = types.bool;
      default = true;
    };
    cmdFileManagers = mkOption {
      description = "Enable cmdFileManagers";
      type = types.bool;
      default = true;
    };
    networkUtils = mkOption {
      description = "Enable network utils";
      type = types.bool;
      default = true;
    };
    rescueTools = mkOption {
      description = "Enable rescueTools";
      type = types.bool;
      default = false;
    };
    binaryTools = mkOption {
      description = "Enable binaryTools";
      type = types.bool;
      default = false;
    };
    pdfUtils = mkOption {
      description = "Enable pdf utilities";
      type = types.bool;
      default = false;
    };
    diskUtilities = mkOption {
      description = "Enable disk utilities(formatting, etc.)";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable (mkMerge [
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
          poppler_utils
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
