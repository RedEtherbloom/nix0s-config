{ lib, pkgs, ... }:
let
  generate-kscreen-doctor = name: text: hotkey: {
    home.packages = [
      (pkgs.writeShellApplication {
        inherit name text;

        runtimeInputs = [ pkgs.kdePackages.libkscreen ];
      })
    ];

    programs.plasma.hotkeys.commands = {
      "${name}" = {
        command = name;
        keys = [ hotkey ];
        comment = "Home screen layout";
      };
    };
  };
in
{
  imports = [
    ../../homeManagerModules/hostRoles/desktop.nix
  ];

  config = lib.mkMerge [
    {
      home.stateVersion = "24.05";
      home.packages = with pkgs; [
        solaar

        # FNV Mod launcher
        zenity
        yad
        # Does my bar approach need this?
        openal

        koboldcpp

        # TODO: Maybe this will make KRunner less laggy
        egl-wayland

        comfyuiPackages.comfyui-with-extensions
        comfyuiPackages.krita-with-extensions
      ];

      config.myOptions.development.electronics = true;
    }
    # KDE: Screen monitors
    # Ivy: These sadly break with missing monitors :/
    (generate-kscreen-doctor "screen-benq" "kscreen-doctor output.DP-3.disable output.DP-2.enable output.DP-2.rotation.normal output.DP-2.position.0,0" "ctrl+shift+f1")
    (generate-kscreen-doctor "screen-dual" "kscreen-doctor output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.inverted output.DP-3.position.1920,0" "ctrl+shift+f2")
    (generate-kscreen-doctor "screen-aoc" "kscreen-doctor output.DP-3.enable output.DP-3.position.0,0 output.DP-2.disable output.DP-2.rotation.inverted" "ctrl+shift+f3")
  ];
}
