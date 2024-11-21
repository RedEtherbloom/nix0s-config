{ pkgs }: let
  # TODO: How is this license wise?
  byar-launcher =
    pkgs.fetchFromGitHub {
      owner = "sergv";
      repo = "nixos-config";
      rev = "9c6306c86af6130f76d277e382c346360ec124dd";
      sha256 = "sha256-FazhyLRMmg7A62SYgF/+h3AXnl0CNxElVfCp21cfsYY=";
    }
    + "/beyond-all-reason-launcher.nix";
in
  (pkgs.callPackage byar-launcher {})