{
  lib,
  inputs,
  ...
}: final: prev: let
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

  # Current fix
  git-sync = prev.git-sync.overrideAttrs {
    src = prev.fetchFromGitHub {
      owner = "simonthum";
      repo = "git-sync";
      rev = "7242291edf543ecc1bb9de8f47086bb69a5cb9f7";
      hash = "sha256-t1NVgp+ELmTMK0N1fFFJCoKQd8mSYSMAIDG9+kNs3Ok=";
    };
  };

  python3 = let
    # Bug that has to be reported. Was blocking libretranslate build when CUDA enabled
    # Similar to https://github.com/NixOS/nixpkgs/pull/371640
    patchedCtranslate = prev.ctranslate2.override {stdenv = prev.cudaPackages.backendStdenv;};
  in
    prev.python3.override {
      packageOverrides = pythonFinal: pythonPrev: {
        argostranslate = pythonPrev.argostranslate.override {ctranslate2-cpp = patchedCtranslate;};
      };
    };

  koboldcpp = prev.koboldcpp.overrideAttrs (pythonFinal: pythonPrev: {
    pythonInputs = pythonPrev.pythonInputs ++ (builtins.attrValues {inherit (prev.python3Packages) psutil;});
  });

  inherit (rimsort-pr) rimsort;
  inherit (sillytavern) sillytavern;
}
