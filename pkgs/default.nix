{inputs, ...}: final: prev: {
  inherit
    (final.lixPackages.stable)
    nixpkgs-review
    nix-eval-jobs
    nix-fast-build
    colmena
    ;

  nix-search-tv = inputs.nix-search-tv.packages.${final.system}.default;

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
  });

  byar-launcher = final.callPackage "${inputs.sergv-nixos-config}/beyond-all-reason-launcher.nix" {};

  # python3 = let in final.python3.override { packageOverrides = _: pythonPrev: { }; };

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
      surround-ui-nvim = final.vimUtils.buildVimPlugin {
        name = "surround-ui.nvim";
        version = "2024-07-16";
        src = final.fetchFromGitHub {
          owner = "roobert";
          repo = "surround-ui.nvim";
          rev = "40abcba017a943d6d3dd304e523f34a43d80405b";
          hash = "sha256-sUtu+Z20rDh9mefTwvEJVI4g7oL+FuYdY9bmGrWcrM0=";
        };
        meta.homepage = "https://github.com/roobert/surround-ui.nvim";
      };
      vim-coach-nvim = final.vimUtils.buildVimPlugin {
        name = "vim-coach.nvim";
        version = "v2.0.0";
        buildInputs = [final.vimPlugins.snacks-nvim];
        src = final.fetchFromGitHub {
          owner = "shahshlok";
          repo = "vim-coach.nvim";
          rev = "ed31e7b9450691199288180a922d8166ae11a0b9";
          hash = "sha256-9Nnlghnor8wKKY4ETwNtGFjv1BUW64EWDKhRJJSj0pk=";
        };
        meta.homepage = "https://github.com/shahshlok/vim-coach.nvim";
      };
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

  kdePackages = prev.kdePackages.overrideScope (
    _: kdePrev: {
      kscreenlocker-patched = kdePrev.kscreenlocker.overrideAttrs (
        _: prevAttrs: {
          version = prevAttrs.version + "-pmanager-patched";
          __intentionallyOverridingVersion = true;
          patches = (prevAttrs.patches or []) ++ [./kscreenlocker-allow-screen-shortcuts.patch];
        }
      );
    }
  );

  gnupg-with-pin-caching = prev.gnupg.overrideAttrs (
    _: prevAttrs: {
      # Address missing PIn caching https://dev.gnupg.org/T7041
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

  clipvault = final.rustPlatform.buildRustPackage rec {
    pname = "clipvault";
    version = "1.1.0";
    src = final.fetchFromGitHub {
      owner = "rolv-apneseth";
      repo = "clipvault";
      rev = "v${version}";
      hash = "sha256-ahhbUGijNZOjZ/egjdecn/4M6Nicq7PDDac09FNZz/Y=";
    };
    cargoHash = "sha256-Mm0att6zu9Yknoa9NBsdrA8lz1o0Q6FzWS0UU+1f/f0=";
    # Tests fail to due logs dir location not being creatable
    doCheck = false;
    meta = {
      description = "Clipboard history manager for Wayland, inspired by cliphist.";
      homepage = "https://github.com/rolv-apneseth/clipvault";
      license = final.lib.licenses.gpl3Only;
      maintainers = [
        {
          email = "etherbloom@mailbox.org";
          github = "RedEtherbloom";
          githubId = "16244495";
          name = "Etherbloom";
        }
      ];
    };
  };
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

  hyprlock-styles.style-3 = final.stdenv.mkDerivation {
    pname = "hyprlock-styles-style-6";
    version = "0.0.1";
    src = final.fetchzip {
      url = "https://github.com/MrVivekRajan/Hyprlock-Styles/releases/download/style3/Style-3.tar.gz";
      hash = "sha256-A9fq1fDn86v6uORKAI8QviAeJzDip6PCije9Ml2s9Lk=";
    };

    installPhase = ''
      cp -r $src/ $out/
    '';
  };

  sddm-fallback-patched = prev.kdePackages.sddm.overrideAttrs (
    _: prevAttrs: {
      buildCommand = 
        prevAttrs.buildCommand + ''
          ln -s $out/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
        ''
      ;
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
    project = inputs.pyproject-nix.lib.project.loadRequirementsTxt { requirements = builtins.readFile "${requirements_txt}"; projectRoot = src;};
    python = final.python313;
  in final.dockerTools.buildImage {
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
          (python.withPackages (project.renderers.withPackages { inherit python;}))
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
}
