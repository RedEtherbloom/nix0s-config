{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = config.myOptions.office;
in {
  options.myOptions.office = {
    enable = lib.mkOption {
      description = "Enable office";
      type = lib.types.bool;
      default = osConfig.myOptions.office.enable;
    };

    audio_editing = lib.mkOption {
      description = "Enable audio_editing";
      type = lib.types.bool;
      default = true;
    };
    image_editing = lib.mkOption {
      description = "Enable image_editing";
      type = lib.types.bool;
      default = true;
    };
    text_editing = lib.mkOption {
      description = "Enable text_editing";
      type = lib.types.bool;
      default = true;
    };
    pdf_editing = lib.mkOption {
      description = "Install pdf editing utilities.";
      type = lib.types.bool;
      default = true;
    };
    video_editing = lib.mkOption {
      description = "Enable video_editing";
      type = lib.types.bool;
      default = true;
    };
    scanning = lib.mkOption {
      description = "Enable scanning";
      type = lib.types.bool;
      default = osConfig.myOptions.office.scanning;
    };
    thunderbird = lib.mkOption {
      description = "Enable thunderbird";
      type = lib.types.bool;
      default = true;
    };
    music = lib.mkOption {
      description = "Enable less-distracting music players.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = with pkgs;
        lib.optionals cfg.audio_editing [
          audacity
          reaper
          ocenaudio
        ]
        ++ lib.optionals cfg.image_editing [gimp]
        ++ lib.optionals cfg.text_editing [
          libreoffice-qt6-fresh
          hunspell
          hunspellDicts.en_US
          hunspellDicts.de_DE
        ]
        ++ lib.optionals cfg.pdf_editing [pdfarranger]
        ++ lib.optionals cfg.video_editing [shotcut]
        ++ lib.optionals cfg.scanning [simple-scan]
        ++ lib.optionals cfg.music [
          pear-desktop
          youtube-tui
        ];
    }
    (lib.mkIf cfg.thunderbird {
      programs.thunderbird = {
        enable = true;
        package = pkgs.thunderbird-bin;
        # nativeMessagingHosts = [pkgs.thunderbird-external-editor-revived]; # TODO: Not setup properly
        profiles.personal = {
          isDefault = true;
          withExternalGnupg = true;
        };
      };
    })
  ]);
}
