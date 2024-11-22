final: prev: {
  fritz-logger = prev.callPackage ./scripts/python/fritz-logger/default.nix {};
  byar-launcher = prev.callPackage ./byar-launcher.nix {};

  # Current fix
  git-sync = prev.git-sync.overrideAttrs {
    src = prev.fetchFromGitHub {
      owner = "RedEtherbloom";
      repo = "git-sync";
      rev = "68822d725e57b6875c13fe27076a18f235186a8e";
      hash = "sha256-t1NVgp+ELmTMK0N1fFFJCoKQd8mSYSMAIDG9+kNs3Ok=";
    };
  };
}
