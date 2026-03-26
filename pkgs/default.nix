{inputs, ...}: final: prev: {
  inherit
    (final.lixPackages.latest)
    nixpkgs-review
    nix-eval-jobs
    nix-fast-build
    colmena
    ;

  thunderbird-external-editor-revived = final.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "thunderbird-external-editor-revived";
    version = "1.2.0";
    src = final.fetchFromGitHub {
      owner = "Frederick888";
      repo = "external-editor-revived";
      rev = "v${finalAttrs.version}";
      hash = "sha256-K5agRpFJ8iqvPnx3IIMTvrkObT/GB962EtdvWf7Eq4w=";
    };
    cargoHash = "sha256-QYSsdEBNwjpR7lppyOcsc0F8ombBY+dlFRY1GO/D8so=";
    meta = {
      description = "Native messaging host for the MailExtension Vim addon for Thunderbird.";
      homepage = "https://github.com/Frederick888/external-editor-revived";
      license = final.lib.licenses.unlicense;
      maintainers = [
        {
          email = "etherbloom@mailbox.org";
          github = "RedEtherbloom";
          githubId = "16244495";
          name = "Etherbloom";
        }
      ];
    };
  }); # TODO: Fix

  koboldcpp = prev.koboldcpp.overrideAttrs (
    _: pythonPrev: {
      pythonInputs =
        pythonPrev.pythonInputs ++ (builtins.attrValues {inherit (final.python3Packages) psutil;});
    }
  );

  vimPlugins =
    (prev.vimPlugins or [])
    // {
      music-controls-nvim = let
        base = final.vimUtils.buildVimPlugin {
          pname = "music-controls.nvim";
          version = "2025-01-01";
          src = final.fetchFromGitHub {
            owner = "AntonVanAssche";
            repo = "music-controls.nvim";
            rev = "35e6a644d66e916aeaad47b3f76f3dc608a32b68";
            hash = "sha256-cPam2gwmEHq1OPB65It9797PZ9xXVLXGMYsHfM2LJeA=";
          };
          meta.homepage = "https://github.com/troydm/zoomwintab.vim/";
          meta.hydraPlatforms = [];
        };
      in
        base.overrideAttrs (
          _: prevAttrs: {
            buildInputs =
              (prevAttrs.buildInputs or [])
              ++ (with final; [
                playerctl
              ]);
          }
        );
      jj-nvim = final.vimUtils.buildVimPlugin {
        pname = "jj.nvim";
        version = "0.3.0-unstable-2026-01-06";
        src = final.fetchFromGitHub {
          owner = "NicolasGB";
          repo = "jj.nvim";
          rev = "ba48ed08b5c08a7192b1a47a689e0c9f949fe5a4";
          hash = "sha256-bmLNfG5J2wtjzpsfd5Pkk9n7hYw+rw2b8CmnVwQY2Co=";
        };
        meta.homepage = "https://github.com/NicolasGB/jj.nvim/";
        meta.hydraPlatforms = [];
      };
    };

  gnupg-with-pin-caching = prev.gnupg.overrideAttrs (
    _: prevAttrs: {
      # Address missing pin caching https://dev.gnupg.org/T7041
      patches = (prevAttrs.patches or []) ++ [./0001-allow-shared-pin-cache.patch];
    }
  );

  # Eve: Account for bug: https://fractalsoftworks.com/forum/index.php?topic=30633.0
  starsector-gl-fix = prev.starsector.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [final.makeWrapper];
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        wrapProgram "$out/bin/starsector" --set __GL_THREADED_OPTIMIZATIONS 0
      '';
  });

  speechd-patched = prev.speechd.overrideAttrs (
    _: prevAttrs: {
      version = prevAttrs.version + "-sh-patch";
      src = final.fetchFromGitHub {
        owner = "brailcom";
        repo = "speechd";
        rev = "909ac9bd7f310a9917262c889318e009cdda4286";
        hash = "sha256-ZZhOG3+g8sj/BUsVoAc+v72BN/SZ9mKkYE4O8NSGwuM=";
      };
    }
  );

  waystt = final.rustPlatform.buildRustPackage rec {
    pname = "waystt";
    version = "0.3.0";
    description = "Minimal Speech-To-Text tool for Wayland";
    src = final.fetchFromGitHub {
      owner = "sevos";
      repo = "waystt";
      rev = "v${version}";
      hash = "sha256-7RKYqED2/aPDvofNGAa48DTexQYdUqkQzb7BX0CsDCU=";
    };
    cargoHash = "sha256-W2pfYDPFyo/ICZ5Y0nLsP4ZeUe7lBffItelnWXrOSLc=";
    nativeBuildInputs = with final; [
      pkg-config
      cmake
      git
    ];
    buildInputs = with final; [
      alsa-lib.dev
      openssl.dev
    ];
    env = {
      LIBCLANG_PATH = "${final.llvmPackages.libclang.lib}/lib";
    };
  };

  sddm-fallback-patched = prev.kdePackages.sddm.overrideAttrs (
    _: prevAttrs: {
      buildCommand =
        prevAttrs.buildCommand
        + ''
          ln -s $out/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
        '';
    }
  );

  # WARN: BROKEN and will be removed
  flathunter-image = let
    src = final.fetchFromGitHub {
      owner = "flathunters";
      repo = "flathunter";
      rev = "fb66e768faba869e115b5d8a81981fe867f0fd30";
      hash = "sha256-PoZ9VwydJ1zVDlpuLR4OJgrh3T4KvvUjYzQHZxVlgQ0=";
    };
    requirements_txt = final.runCommand "flathunter-requirements.txt" {} ''
      mkdir home
      export HOME=$(pwd)/home
      cd ${src}
      ${final.pipenv}/bin/pipenv requirements > $out
    '';
    project = inputs.pyproject-nix.lib.project.loadRequirementsTxt {
      requirements = builtins.readFile "${requirements_txt}";
      projectRoot = src;
    };
    python = final.python313;
  in
    final.dockerTools.buildImage {
      name = "flathunter";
      tag = "latest";
      copyToRoot = final.buildEnv {
        name = "image-root";
        pathsToLink = [
          "/bin"
        ];
        paths = with final; [
          undetected-chromedriver
          coreutils
          (python.withPackages (project.renderers.withPackages {inherit python;}))
        ];
      };
    };

  flathunter-docker-image = final.stdenv.mkDerivation {
    name = "flathunter-docker-image";
    src = final.fetchFromGitHub {
      owner = "flathunters";
      repo = "flathunter";
      rev = "fb66e768faba869e115b5d8a81981fe867f0fd30";
      hash = "sha256-PoZ9VwydJ1zVDlpuLR4OJgrh3T4KvvUjYzQHZxVlgQ0=";
    };

    nativeBuildInputs = with final; [
      podman
      openssh
    ];

    buildPhase = ''
      runHook preBuild
      # Docker build fails due to no home directory
      mkdir home
      export HOME=$(pwd)/home

      ls .
      pwd
      podman machine init
      podman machine start
      podman --log-level trace build --tag flathunter -f $src/Dockerfile .
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp $src/flathunter.tar $out
      runHook postInstall
    '';
  };

  thunarWithExtensions = final.thunar.override {
    thunarPlugins = with final; [
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-vcs-plugin
    ];
  };

  jambi = inputs.jambi-transcript.packages.${final.stdenv.hostPlatform.system}.default;

  # TODO: nix-update-script
  shellbeats = final.stdenv.mkDerivation {
    pname = "shellbeats";
    version = "0-unstable-2026-02-11";

    src = final.fetchFromGitHub {
      owner = "lalo-space";
      repo = "shellbeats";
      rev = "280e5cabcc2e84a6a5f4b91c70c99f7b094a0c3f";
      hash = "sha256-fqqqa8cCWo0uAi6cWCaLDl9UKN81HH4JOqko5mYEn+o=";
    };

    nativeBuildInputs = with final; [
      makeWrapper
      pkg-config
      ncurses.dev
    ];

    buildInputs = with final; [
      yt-dlp
      mpv
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp shellbeats $out/bin
    '';

    meta = {
      homepage = "https://github.com/lalo-space/shellbeats";
      description = "CLI music player for Linux/Mac. Stream YouTube audio and mp3 download. Minimal, fast, keyboard driven.";
      license = final.lib.licenses.gpl3;
      mainProgram = "shellbeats";
    };
  };

  rofi-home-assistant = final.stdenvNoCC.mkDerivation {
    pname = "rofi-home-assistant";
    version = "0-unstable-2021-07-29";

    src = final.fetchFromGitHub {
      owner = "flxai";
      repo = "rofi-home-assistant";
      rev = "aa348dee26763e1c8c394c55788d84b83aff4c73";
      hash = "sha256-2kZgMYZ1GR7fwEnXXg4vn5b6xwxjCoPYI/YENbrea2Q=";
    };

    dontBuild = true;

    buildInputs = with final; [
      rofi
      jq
      home-assistant-cli
      libnotify
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp bin/rofi-hass $out/bin/rofi-home-assistant
    '';

    postFixup = ''
      substituteInPlace $out/bin/rofi-home-assistant \
        --replace "light)" "light|switch|automation)"
    '';

    meta.mainProgram = "rofi-home-assistant";
  };

  rofi-home-assistant-verbose = final.rofi-home-assistant.overrideAttrs (_: prevAttrs: {
    postFixup =
      prevAttrs.postFixup or ""
      + ''
        substituteInPlace $out/bin/rofi-home-assistant \
          --replace " &>/dev/null" ""
      '';
  });

  rofi-home-assistant-changed = let
    desiredTypes = [
      "light"
      "switch"
    ];
    extraTypes = [
      "scene"
    ];
  in
    final.writeShellScriptBin "rofi-home-assistant-changed.sh" ''
      raw_json=$(${final.lib.getExe final.home-assistant-cli} -o json state list 2>/dev/null)
      json=$(${final.lib.getExe final.jq} --argjson types '${builtins.toJSON (desiredTypes ++ extraTypes)}' -r 'map(.entity_id as $id | select(any($types[]; . as $el | $id | startswith($el))))' <<< "$raw_json")
      idx=$(${final.lib.getExe final.jq} -r '.[] | [.entity_id, .state] | join(" ")' <<< "$json" | ${final.util-linux}/bin/column -t | ${final.lib.getExe final.rofi} -dmenu -i -markup-rows -format d)
      item=$(${final.lib.getExe final.jq} -r '.[].entity_id' <<< "$json" | ${final.lib.getExe final.gnused} "''${idx}q;d")
      itype=$(${final.lib.getExe final.gnused} -r 's/\..+$//' <<< "$item")

      case "$itype" in
          ${final.lib.strings.concatStringsSep "|" desiredTypes})
              ${final.lib.getExe final.home-assistant-cli} state toggle "$item"
              ;;
          ${final.lib.strings.concatStringsSep "|" extraTypes})
              ${final.lib.getExe final.home-assistant-cli} service call --arguments entity_id="$item" scene.turn_on
              ;;
          *)
              ${final.libnotify}/bin/notify-send "Error" "Event type '$itype' not implemented yet. Do you have time to file an issue or write a PR?"
              ;;
      esac
    '';

  taskwarrior-tui = prev.taskwarrior-tui.overrideAttrs (
    _: oldAttrs: rec {
      version = oldAttrs.version + "-fix";
      src = final.fetchFromGitHub {
        owner = "RedEtherbloom";
        repo = "taskwarrior-tui";
        hash = "sha256-YNd4vtaWm+1fsB8ly3toq2u74Nicmhx2ey1m557q4K8=";
        rev = "ee24bfb4a36f246933e6d2502ab85d3fc6abb85b";
      };
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-7q85YszWmetjWry9nvc2irQeLFCWHwOAkEUHtc9CK/c=";
      };
    }
  );

  wlr-which-key-fork = final.wlr-which-key.overrideAttrs (finalAttrs: _: {
    version = "1.3.0-pr-46-2026-02-26";

    src = final.fetchFromGitHub {
      owner = "RedEtherbloom";
      repo = "wlr-which-key";
      hash = "sha256-N8iueJT8H77AuhuE5B1jF6JiSGZeQrUnnIEB5DtGMxc=";
      rev = "207039df24dfcbe9dcc6bc14d17a77d530f38f52";
    };
    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      hash = "sha256-v+4/lD00rjJvrQ2NQqFusZc0zQbM9mBG5T9bNioNGKQ=";
    };
  });
}
