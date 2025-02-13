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
