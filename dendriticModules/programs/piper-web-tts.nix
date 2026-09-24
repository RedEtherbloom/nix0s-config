{
  flake.homeModules.piper-web-tts = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = [
      pkgs.pied # Piper-tts voice management
    ];
    systemd.user = {
      services = {
        piper-web-tts = {
          Unit = {
            Description = "Local Piper-Web Service for local TTS Streaming";
          };
          Service = {
            Type = "exec";

            ExecStart = let
              pythonEnv = pkgs.python3.withPackages (_: [
                (pkgs.python3Packages.toPythonModule config.myOptions.services.piper-web-tts.package)
              ]);
            in
              lib.getExe (
                pkgs.writeShellApplication {
                  name = "piper-web-tts";
                  runtimeInputs = [
                    pkgs.coreutils
                    pkgs.fd
                    pythonEnv
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
          # Auto-start, to avoid delay
          # IDEA: Offer startup via TCP socket
          Install.WantedBy = ["default.target"];
        };
      };
    };
  };
}
