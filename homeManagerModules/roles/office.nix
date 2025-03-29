{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myOptions.office;
in {
  options.myOptions.office = {
    enable = mkOption {
      description = "Enable office";
      type = with types; bool;
      default = osConfig.myOptions.office.enable;
    };

    audio_editing = mkOption {
      description = "Enable audio_editing";
      type = types.bool;
      default = true;
    };
    image_editing = mkOption {
      description = "Enable image_editing";
      type = types.bool;
      default = true;
    };
    text_editing = mkOption {
      description = "Enable text_editing";
      type = types.bool;
      default = true;
    };
    video_editing = mkOption {
      description = "Enable video_editing";
      type = types.bool;
      default = true;
    };
    scanning = mkOption {
      description = "Enable scanning";
      type = types.bool;
      default = osConfig.myOptions.office.scanning;
    };
    thunderbird = mkOption {
      description = "Enable thunderbird";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs;
        lib.optionals cfg.audio_editing [
          audacity
          reaper
          ocenaudio
        ]
        ++ lib.optionals cfg.image_editing [gimp]
        ++ lib.optionals cfg.text_editing [
          libreoffice-qt
          hunspell
          hunspellDicts.en_US
          hunspellDicts.de_DE
        ]
        ++ lib.optionals cfg.video_editing [shotcut]
        ++ lib.optionals cfg.scanning [simple-scan]
        # Turn into option, once we figured out it's profiles
        ++ lib.optionals cfg.thunderbird [thunderbird];
    }
  ]);
}
