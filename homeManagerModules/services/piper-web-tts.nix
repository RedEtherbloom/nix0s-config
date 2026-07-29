{
  lib,
  pkgs,
  config,
  ...
}: {
  options.myOptions.services = {
    piper-web-tts = {
      enable = lib.mkOption {
        description = "Autostart a local piper server for fluid tts playback.";
        type = lib.types.bool;
        default = false;
      };
      package = lib.mkOption {
        description = "Piper package to use";
        type = lib.types.package;
        default = pkgs.piper-tts;
      };
      model = lib.mkOption {
        description = "Name of model or part to model";
        type = lib.types.either lib.types.str lib.types.path;
      };
      data-dir = lib.mkOption {
        description = "Data directory for model download";
        type = lib.types.either lib.types.str lib.types.path;
        default = "${config.xdg.stateHome}/piper";
      };
      install-in-speech-dispatcher = lib.mkOption {
        description = "Whether to install this piper instance as a speech-dispatcher option automatically";
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf config.myOptions.services.piper-web-tts.enable {
    systemd.user = {
      services = {
        piper-web-tts = {
          Unit = {
            Description = "Local Piper-Web Service for local TTS Streaming";
          };
          Service = {
            Type = "exec";

            ExecStart = let
              python = pkgs.python314.withPackages (_: [
                (pkgs.python3Packages.toPythonModule config.myOptions.services.piper-web-tts.package)
              ]);
            in
              lib.getExe (
                pkgs.writeShellApplication {
                  name = "piper-web-tts";
                  runtimeInputs = with pkgs; [
                    coreutils
                    fd
                    python
                    config.myOptions.services.piper-web-tts.package
                  ];

                  excludeShellChecks = [
                    "SC2046"
                    "SC2050"
                  ];

                  text = ''
                    export DATA_DIR="${config.myOptions.services.piper-web-tts.data-dir}"

                    mkdir -p "$DATA_DIR"
                    cd "$DATA_DIR"

                    # Check if the model is already downloaded, in case model is not a path.
                    if ! [[ "${config.myOptions.services.piper-web-tts.model}" =~ "/" ]] && ! [ $(fd -q "${config.myOptions.services.piper-web-tts.model}" "$DATA_DIR" ) ]; then
                      python -m piper.download_voices "${config.myOptions.services.piper-web-tts.model}"
                    fi

                    python -m piper.http_server -m ${config.myOptions.services.piper-web-tts.model}

                  '';
                }
              );
          };
          Install = {
            # Auto-start, to avoid delay
            # TODO: Offer startup via TCP socket
            WantedBy = ["default.target"];
          };
        };
      };
    };
  };
}
