{ pkgs, ... }:
let
  generate-kscreen-doctor =
    name: text:
    pkgs.writeShellApplication {
      inherit name text;

      runtimeInputs = [ pkgs.kdePackages.libkscreen ];
    };
in
{
  imports = [
    ../../homeManagerModules/desktop.nix
  ];

  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    solaar

    krita

    # FNV Mod launcher
    zenity
    yad
    # Does my bar approach need this?
    openal

    koboldcpp

    # TODO: Maybe this will make KRunner less laggy
    egl-wayland

    # KDE: Screen monitors
    # Ivy: These sadly break with missing monitors :/
    (generate-kscreen-doctor "screen_aoc" "kscreen-doctor output.DP-3.enable output.DP-3.position.0,0 output.DP-2.disable output.DP-2.rotation.inverted")
    (generate-kscreen-doctor "screen_benq" "kscreen-doctor output.DP-3.disable output.DP-2.enable output.DP-2.rotation.normal output.DP-2.position.0,0")
    (generate-kscreen-doctor "screen_dual" "kscreen-doctor output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.inverted output.DP-3.position.1920,0")
  ];
}
