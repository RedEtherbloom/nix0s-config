{
  lib,
  pkgs,
  ...
}: let
  generate-kscreen-doctor = name: text: hotkey: {
    home.packages = [
      (pkgs.writeShellApplication {
        inherit name text;

        runtimeInputs = [pkgs.kdePackages.libkscreen];
      })
    ];

    programs.plasma.hotkeys.commands = {
      "${name}" = {
        command = name;
        keys = [hotkey];
        comment = "Home screen layout";
      };
    };
  };
in {
  imports = [
    ../../homeManagerModules
  ];

  config = lib.mkMerge [
    {
      home.stateVersion = "24.05";
      home.packages = with pkgs; [
        # FNV Mod launcher
        zenity
        yad
        # Does my bar approach need this?
        openal

        koboldcpp

        # TODO: Maybe this will make KRunner less laggy
        egl-wayland

        comfyuiPackages.comfyui-with-extensions

        coolercontrol.coolercontrol-gui

        gsmartcontrol
        kdePackages.plasma-disks
      ];

      myOptions.solaar = {
        enable = true;
        autostart.enable = true;
      };

      # Part of valerie: Broken on 22.11.24
      # myOptions.roles.development.electronics = true;
    }
    # Ivy: These sadly break with missing monitors :/
    (generate-kscreen-doctor "screen-benq" "kscreen-doctor output.DP-3.disable output.HDMI-A-1.disable output.DP-2.enable output.DP-2.rotation.normal output.DP-2.position.0,0" "ctrl+shift+f1")
    (generate-kscreen-doctor "screen-dual" "kscreen-doctor output.HDMI-A-1.disable output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.inverted output.DP-3.position.1920,0" "ctrl+shift+f2")
    (generate-kscreen-doctor "screen-aoc" "kscreen-doctor output.HDMI-A-1.disable output.DP-3.enable output.DP-3.position.0,0 output.DP-2.disable" "ctrl+shift+f3")
    (generate-kscreen-doctor "screen-lg" "kscreen-doctor output.DP-2.disable output.DP-3.disable output.HDMI-A-1.enable output.HDMI-A-1.position.0,0" "ctrl+shift+f4")
    (generate-kscreen-doctor "screen-lg-aoc" "kscreen-doctor output.DP-2.disable output.HDMI-A-1.enable output.HDMI-A-1.position.1920,0 output.HDMI-A-1.priority.1 output.DP-3.enable output.DP-3.position.0,0 output.DP-3.rotation.inverted" "ctrl+shift+f5")
    (generate-kscreen-doctor "screen-trial" "kscreen-doctor output.DP-2.enable output.DP-2.position.0,0 output.DP-2.priority.1 output.DP-2.rotation.normal output.DP-3.enable output.DP-3.rotation.inverted output.DP-3.position.1920,0 output.DP-3.priority.2 output.HDMI-A-1.enable output.HDMI-A-1.position.3840,0 output.HDMI-A-1.rotation.normal output.HDMI-A-1.priority.3" "ctrl+shift+f6")
  ];
}
