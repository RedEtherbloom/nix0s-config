final: prev: {
  fritz-logger = prev.callPackage ./scripts/python/fritz-logger/default.nix {};
  byar-launcher = prev.callPackage ./byar-launcher.nix {};
}
