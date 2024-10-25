{ pkgs, ... }: {
  fritz-logger = pkgs.callPackage ./scripts/python/fritz-logger/default.nix;
}