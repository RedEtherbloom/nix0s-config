{
  flake.nixosModules.utilities = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myOptions.utilities;
  in {
    options.myOptions.utilities = {
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

    config = lib.mkMerge [
      {
        environment.systemPackages =
          lib.optionals cfg.minimum [
            pkgs.age
            pkgs.ssh-to-age
            pkgs.sops
          ]
          ++ lib.optionals cfg.diverse [
            pkgs.file
            pkgs.util-linux
            pkgs.psmisc
            pkgs.zip
            pkgs.unzip
            pkgs.unar
            pkgs.p7zip
            pkgs.ripgrep
            pkgs.fd
            pkgs.jq
            pkgs.fzf
            pkgs.lshw
            pkgs.fuse3
          ]
          ++ lib.optionals cfg.git [
            pkgs.git
            pkgs.git-lfs
          ]
          ++ lib.optionals cfg.python [
            pkgs.python3
          ]
          ++ lib.optionals cfg.htop [pkgs.htop]
          ++ lib.optionals cfg.cmdFileManagers [
            pkgs.ranger
            pkgs.dust
            pkgs.dua
            pkgs.ncdu
            pkgs.yazi # Rust based
          ]
          ++ lib.optionals cfg.networkUtils [
            pkgs.dig
            pkgs.wget
            pkgs.curl
          ]
          ++ lib.optionals cfg.rescueTools [
            pkgs.ddrescue
          ]
          ++ lib.optionals cfg.binaryTools [
            pkgs.unixtools.xxd
          ]
          ++ lib.optionals cfg.wormhole [
            pkgs.magic-wormhole
            pkgs.magic-wormhole-rs
            pkgs.warp
          ]
          ++ lib.optionals cfg.tmux [
            pkgs.tmux
          ]
          ++ lib.optionals cfg.ssh_utils [
            pkgs.sshfs
            pkgs.mosh
          ]
          ++ lib.optionals cfg.pdfUtils [
            pkgs.poppler-utils
            pkgs.ripgrep-all
          ]
          ++ lib.optionals cfg.diskUtilities [
            pkgs.parted
            pkgs.gparted
            pkgs.util-linux # For losetup and fdisk
          ];
      }
    ];
  };
}
