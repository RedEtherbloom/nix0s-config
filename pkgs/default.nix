{inputs, ...}: final: prev: let
  rimsort-pr = import inputs.rimsort-pr {
    config.allowUnfree = true;
    inherit (prev) system;
  };

  sillytavern = import inputs.sillytavern {
    config.allowUnfree = true;
    inherit (prev) system;
  };
in {
  fritz-logger = final.callPackage ./scripts/python/fritz-logger/default.nix {};
  byar-launcher = final.callPackage "${inputs.sergv-nixos-config}/beyond-all-reason-launcher.nix" {};

  python3 = let
    # Bug that has to be reported. Was blocking libretranslate build when CUDA enabled
    # Similar to https://github.com/NixOS/nixpkgs/pull/371640
    patchedCtranslate = prev.ctranslate2.override {stdenv = prev.cudaPackages.backendStdenv;};
  in
    prev.python3.override {
      packageOverrides = _: pythonPrev: {
        argostranslate = pythonPrev.argostranslate.override {ctranslate2-cpp = patchedCtranslate;};
      };
    };

  koboldcpp = prev.koboldcpp.overrideAttrs (_: pythonPrev: {
    pythonInputs = pythonPrev.pythonInputs ++ (builtins.attrValues {inherit (prev.python3Packages) psutil;});
  });

  # alvr = prev.alvr.overrideAttrs (finalAttrs: _: rec {
  #   pname = "alvr";
  #   version = "20.12.0";

  #   src = prev.fetchFromGitHub {
  #     owner = "alvr-org";
  #     repo = "ALVR";
  #     tag = "v${version}";
  #     fetchSubmodules = true;
  #     hash = "sha256-4tilgZCUY5PehR0SQDOBahLaPVH4n5cgE7Ghw+SCgQk=";
  #   };

  #   cargoDeps = prev.rustPlatform.fetchCargoVendor {
  #     name = "${pname}-vendor.tar.gz";
  #     inherit (finalAttrs) src;
  #     hash = "sha256-ocwNVdozZeF0hYDhYMshSbRHKfBFawIcO7UbTwk10xc=";
  #   };
  # });
  # alvr_debug = final.callPackage ./alvr.nix {};

  # oscavmgr = prev.oscavmgr.overrideAttrs (finalAttrs: _: rec {
  #   pname = "oscavmgr";
  #   version = "0.4.4";

  #   src = prev.fetchFromGitHub {
  #     owner = "galister";
  #     repo = "oscavmgr";
  #     tag = "v${version}";
  #     fetchSubmodules = true;
  #     hash = "sha256-Tx4FuKKorQLkuhBUbQXtfsm8sFdLgQCgXiGQsfX+MQg=";
  #   };

  #   patches = [
  #     ./oscavmgr-alvr.patch
  #   ];

  #   cargoDeps = prev.rustPlatform.fetchCargoVendor {
  #     name = "${pname}-vendor.tar.gz";
  #     inherit (finalAttrs) src patches;

  #     hash = "sha256-waF0T3feKgFlFnO1ZMxAEe93Ek4yEpvSgBQHFt2BePc=";
  #   };
  # });

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
    };

  nix-tree = inputs.nix-tree.packages.${prev.system}.default;
  # Fixes https://github.com/NixOS/nixpkgs/issues/418453
  waydroid = prev.waydroid.override {
    python3Packages = prev.python312Packages;
  };

  inherit (rimsort-pr) rimsort;
  inherit (sillytavern) sillytavern;
}
