{inputs, ...}: final: prev: {
  fritz-logger = prev.callPackage ./scripts/python/fritz-logger/default.nix {};
  byar-launcher = prev.callPackage "${inputs.sergv-nixos-config}/beyond-all-reason-launcher.nix" {};

  # Current fix
  git-sync = prev.git-sync.overrideAttrs {
    src = prev.fetchFromGitHub {
      owner = "simonthum";
      repo = "git-sync";
      rev = "7242291edf543ecc1bb9de8f47086bb69a5cb9f7";
      hash = "sha256-t1NVgp+ELmTMK0N1fFFJCoKQd8mSYSMAIDG9+kNs3Ok=";
    };
  };
}
