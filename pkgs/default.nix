{inputs, ...}: final: prev: let
  rimsort-pr = import inputs.rimsort-pr {
    config.allowUnfree = true;
    inherit (prev) system;
  };
  nixpkgs-stable = import inputs.nixpkgs-stable {
    inherit (prev) system;
    config.allowUnfree = prev.config.allowUnfree;
  };
in {
  logger = final.callPackage ./scripts/python/fritz-logger/default.nix {};
  nix-tree = inputs.nix-tree.packages.${prev.system}.default;
  nix-search-tv = inputs.nix-search-tv.packages.${prev.system}.default;

  thunderbird-external-editor-revived = prev.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "thunderbird-external-editor-revived";
    version = "1.2.0";
    src = prev.fetchFromGitHub {
      owner = "Frederick888";
      repo = "external-editor-revived";
      rev = "v${finalAttrs.version}";
      hash = "sha256-K5agRpFJ8iqvPnx3IIMTvrkObT/GB962EtdvWf7Eq4w=";
    };
    cargoHash = "sha256-QYSsdEBNwjpR7lppyOcsc0F8ombBY+dlFRY1GO/D8so=";
    meta = {
      description = "Native messaging host for the MailExtension Vim addon for Thunderbird.";
      homepage = "https://github.com/Frederick888/external-editor-revived";
      license = prev.lib.licenses.unlicense;
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
  nixpkgs-stable = nixpkgs-stable;
  inherit (rimsort-pr) rimsort;
  # TODO: Figure out how to override name of script for shellApplication
  plasma-rc2nix = inputs.plasma-manager.packages.${prev.system}.rc2nix.overrideAttrs {name = "plasma-rc2nix";};

  # python3 = let in prev.python3.override { packageOverrides = _: pythonPrev: { }; };

  koboldcpp = prev.koboldcpp.overrideAttrs (_: pythonPrev: {
    pythonInputs = pythonPrev.pythonInputs ++ (builtins.attrValues {inherit (prev.python3Packages) psutil;});
  });

  vimPlugins =
    (prev.vimPlugins or [])
    // {
      music-controls-nvim = let
        base = prev.vimUtils.buildVimPlugin {
          pname = "music-controls.nvim";
          version = "2025-01-01";
          src = prev.fetchFromGitHub {
            owner = "AntonVanAssche";
            repo = "music-controls.nvim";
            rev = "35e6a644d66e916aeaad47b3f76f3dc608a32b68";
            hash = "sha256-cPam2gwmEHq1OPB65It9797PZ9xXVLXGMYsHfM2LJeA=";
          };
          meta.homepage = "https://github.com/troydm/zoomwintab.vim/";
          meta.hydraPlatforms = [];
        };
      in
        base.overrideAttrs (_: prevAttrs: {
          buildInputs =
            (prevAttrs.buildInputs or [])
            ++ (with prev; [
              playerctl
            ]);
        });
      surround-ui-nvim = prev.vimUtils.buildVimPlugin {
        name = "surround-ui.nvim";
        version = "2024-07-16";
        src = prev.fetchFromGitHub {
          owner = "roobert";
          repo = "surround-ui.nvim";
          rev = "40abcba017a943d6d3dd304e523f34a43d80405b";
          hash = "sha256-sUtu+Z20rDh9mefTwvEJVI4g7oL+FuYdY9bmGrWcrM0=";
        };
        meta.homepage = "https://github.com/roobert/surround-ui.nvim";
      };
      vim-coach-nvim = prev.vimUtils.buildVimPlugin {
        name = "vim-coach.nvim";
        version = "v2.0.0";
        buildInputs = [prev.vimPlugins.snacks-nvim];
        src = prev.fetchFromGitHub {
          owner = "shahshlok";
          repo = "vim-coach.nvim";
          rev = "ed31e7b9450691199288180a922d8166ae11a0b9";
          hash = "sha256-9Nnlghnor8wKKY4ETwNtGFjv1BUW64EWDKhRJJSj0pk=";
        };
        meta.homepage = "https://github.com/shahshlok/vim-coach.nvim";
      };
    };

  # Fixes https://github.com/NixOS/nixpkgs/issues/418453
  waydroid = prev.waydroid.override {python3Packages = prev.python312Packages;};

  sonic-pi = prev.sonic-pi.overrideAttrs (_: prevAttrs: {
    buildInputs = (prevAttrs.buildInputs or []) ++ [prev.libsForQt5.qt5.qtwayland];
  });

  kdePackages = prev.kdePackages.overrideScope (_: kdePrev: {
    # breeze-with-kscreen-timer-patch = kdePrev.breeze.overrideAttrs (_: prevAttrs: {
    #   # TODO: Lookup build tutorial for copying
    # });
    plasma-desktop = kdePrev.plasma-desktop.overrideAttrs (_: prevAttrs: {
      patches = (prevAttrs.patches or []) ++ [./shorten-grace-lock.patch];
    });
    kscreenlocker = kdePrev.kscreenlocker.overrideAttrs (_: prevAttrs: {
      version = prevAttrs.version + "-pmanager-patched";
      __intentionallyOverridingVersion = true;
      patches = (prevAttrs.patches or []) ++ [./kscreenlocker-allow-screen-shortcuts.patch];
    });
  });

  # See issue: https://github.com/NixOS/nixpkgs/issues/417312
  podman = prev.podman.overrideAttrs (_: rec {
    version = "5.4.1";
    src = prev.fetchFromGitHub {
      owner = "containers";
      repo = "podman";
      tag = "v${version}";
      hash = "sha256-RirMBb45KeBLdBJrRa86WxI4FiXdBar+RnVQ2ezEEYc=";
    };
  });

  gnupg-with-pin-caching = prev.gnupg.overrideAttrs (_: prevAttrs: {
    # Address missing PIn caching https://dev.gnupg.org/T7041
    patches = (prevAttrs.patches or []) ++ [./0001-allow-shared-pin-cache.patch];
  });

  # Eve: Account for bug: https://fractalsoftworks.com/forum/index.php?topic=30633.0
  starsector-gl-fix = prev.starsector.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [prev.makeWrapper];
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        wrapProgram "$out/bin/starsector" --set __GL_THREADED_OPTIMIZATIONS 0
      '';
  });
  # Force installation from nixpkgs to avoid rebuilding mlt and krita due to cuda
  krita-upstream = inputs.nixpkgs.legacyPackages.${prev.system}.krita;
}
