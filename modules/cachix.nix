# WARN: this file will get overwritten by $ cachix use <name>
{lib, ...}: let
  folder = ./cachix;
  toImport = name: value: folder + ("/" + name);
  filterCaches = key: value: value == "regular" && lib.hasSuffix ".nix" key;
in {
  imports =
    [
      ./cachix/cuda-maintainers.nix
      ./cachix/hyprland.nix
    ]
    ++ (lib.mapAttrsToList toImport (lib.filterAttrs filterCaches (builtins.readDir folder)));
}
