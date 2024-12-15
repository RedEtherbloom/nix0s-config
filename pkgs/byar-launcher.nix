{
  inputs,
  pkgs,
}: let
  # TODO: How is this license wise?
  byar-launcher = "${inputs.sergv-nixos-config}/beyond-all-reason-launcher.nix";
in (pkgs.callPackage byar-launcher {})
